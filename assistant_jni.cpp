/*
 * JNI bridge between com.volla.launcher.worker.AssistantNative and the
 * assistant core libraries.
 */

#include <jni.h>

#include <string.h>
#include <string>
#include <sys/stat.h>

#include <android/log.h>

#include "agent_core.h"
#include "config.h"
#include "inference.h"
#include "states.h"

#define LOG_TAG "AssistantJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Error codes returned to Java.
enum {
    ASSISTANT_OK = 0,
    ASSISTANT_ERR_CONFIG = 1,
    ASSISTANT_ERR_MODEL = 2,
    ASSISTANT_ERR_VOCAB = 3,
    ASSISTANT_ERR_CONTEXT = 4,
    ASSISTANT_ERR_SAMPLER = 5,
    ASSISTANT_ERR_PROMPT = 6,
    ASSISTANT_ERR_INFERENCE = 7,
    ASSISTANT_ERR_NOT_LOADED = 8,
    ASSISTANT_ERR_BAD_ARGUMENT = 9
};

static llama_inference g_inference;
static state_type g_state;
static bool g_loaded = false;

static llama_inference g_agentInference;
static agent_state g_agentState;
static bool g_agentLoaded = false;


static JNIEnv *g_env = nullptr;
static jobject g_thiz = nullptr;
static jmethodID g_partiallyUpdate = nullptr;

static void setCallback(JNIEnv *env, jobject thiz)
{
    g_env = env;
    g_thiz = thiz;

    if (thiz != nullptr) {
        jclass clazz = env->GetObjectClass(thiz);
        g_partiallyUpdate = env->GetMethodID(clazz, "partiallyUpdate", "(Ljava/lang/String;)V");
        env->DeleteLocalRef(clazz);
    } else {
        g_partiallyUpdate = nullptr;
    }
}

static size_t utf8PrefixLength(const char *text)
{
    if (text == nullptr)
        return 0;

    const unsigned char *bytes = reinterpret_cast<const unsigned char *>(text);
    size_t pos = 0;

    while (bytes[pos] != '\0') {
        const unsigned char c = bytes[pos];
        size_t len = 0;

        if (c <= 0x7F)
            len = 1;
        else if ((c >> 5) == 0x6)
            len = 2;
        else if ((c >> 4) == 0xE)
            len = 3;
        else if ((c >> 3) == 0x1E)
            len = 4;
        else
            break;

        for (size_t i = 1; i < len; ++i) {
            if ((bytes[pos + i] >> 6) != 0x2)
                return pos;
        }
        pos += len;
    }

    return pos;
}

static jstring newStringSafe(JNIEnv *env, const char *utf8)
{
    if (utf8 == nullptr)
        return env->NewStringUTF("");

    const size_t valid = utf8PrefixLength(utf8);
    if (valid == strlen(utf8))
        return env->NewStringUTF(utf8);

    const std::string trimmed(utf8, valid);
    return env->NewStringUTF(trimmed.c_str());
}

void callPartiallyUpdate(const char *text)
{
    if (g_env == nullptr || g_thiz == nullptr || g_partiallyUpdate == nullptr)
        return;

    jstring jtext = newStringSafe(g_env, text);
    g_env->CallVoidMethod(g_thiz, g_partiallyUpdate, jtext);
    g_env->DeleteLocalRef(jtext);
}


static bool fileExists(const char *path)
{
    struct stat st;
    return path != nullptr && stat(path, &st) == 0;
}

static void releaseAssistant()
{
    free_ptr(&g_state);
    free_llama_inference(&g_inference);
    g_loaded = false;
}

static void appendUserTurn(const char *prompt, bool thinker)
{
    g_state.messages = extend_messages(g_state.messages, "<|im_start|>user\n");
    if (g_state.messages == nullptr)
        return;

    g_state.messages = extend_messages(g_state.messages, prompt);
    if (g_state.messages == nullptr)
        return;

    g_state.messages = extend_messages(g_state.messages,
                                       thinker
                                           ? "<|im_end|><|im_start|>assistant\n<think>\n\n</think>\n\n"
                                           : "<|im_end|><|im_start|>assistant\n");
}

static void appendAssistantTurn()
{
    if (g_state.messages == nullptr)
        return;

    g_state.messages = extend_messages(g_state.messages, g_state.assistant_response);
    if (g_state.messages == nullptr)
        return;

    g_state.kv_applied_chars = strlen(g_state.messages);
    g_state.messages = extend_messages(g_state.messages, "<|im_end|>");
}

static bool g_isThinker = false;

extern "C" {


JNIEXPORT jint JNICALL
Java_com_volla_launcher_worker_AssistantNative_init(JNIEnv *env, jobject,
                                                   jstring jconfigPath,
                                                   jstring jmodelPath,
                                                   jstring jcachePath)
{
    if (jconfigPath == nullptr || jmodelPath == nullptr || jcachePath == nullptr)
        return ASSISTANT_ERR_BAD_ARGUMENT;

    const char *configPath = env->GetStringUTFChars(jconfigPath, nullptr);
    const char *modelPath = env->GetStringUTFChars(jmodelPath, nullptr);
    const char *cachePath = env->GetStringUTFChars(jcachePath, nullptr);

    jint result = ASSISTANT_OK;
    model_config config;

    memset(&g_inference, 0, sizeof(llama_inference));
    memset(&g_state, 0, sizeof(state_type));

    if (config.load_config(configPath) != 0) {
        LOGE("init: cannot load config '%s'", configPath);
        result = ASSISTANT_ERR_CONFIG;
        goto done;
    }

    g_isThinker = config.is_thinker();

    init_default_state(&g_state, config.get_system_prompt().c_str());
    load_backend();

    g_inference.n_threads = config.get_n_threads();
    g_inference.n_batch = config.get_n_batch();
    g_inference.n_ctx = config.get_n_ctx();

    if (load_model(modelPath, &g_inference) != 0) {
        LOGE("init: cannot load model '%s'", modelPath);
        releaseAssistant();
        result = ASSISTANT_ERR_MODEL;
        goto done;
    }
    if (get_vocab(&g_inference) != 0) {
        releaseAssistant();
        result = ASSISTANT_ERR_VOCAB;
        goto done;
    }
    if (create_ctx(&g_inference) != 0) {
        releaseAssistant();
        result = ASSISTANT_ERR_CONTEXT;
        goto done;
    }
    if (set_sampler(&g_inference) != 0) {
        releaseAssistant();
        result = ASSISTANT_ERR_SAMPLER;
        goto done;
    }

    if (fileExists(cachePath) && load_memory(cachePath, &g_inference) == 0) {
        LOGI("init: kv-cache loaded from '%s'", cachePath);
    } else {
        if (allocate_prompt(&g_inference, &g_state) != 0) {
            releaseAssistant();
            result = ASSISTANT_ERR_PROMPT;
            goto done;
        }
        if (digest_prompt(&g_inference) != 0) {
            releaseAssistant();
            result = ASSISTANT_ERR_PROMPT;
            goto done;
        }
        if (save_memory(cachePath, &g_inference) != 0)
            LOGI("init: could not save kv-cache to '%s' (non-fatal)", cachePath);
    }

    g_state.kv_applied_chars = g_state.messages != nullptr ? strlen(g_state.messages) : 0;
    g_loaded = true;
    LOGI("init: ready, %zu prompt chars digested", g_state.kv_applied_chars);

done:
    env->ReleaseStringUTFChars(jconfigPath, configPath);
    env->ReleaseStringUTFChars(jmodelPath, modelPath);
    env->ReleaseStringUTFChars(jcachePath, cachePath);
    return result;
}

JNIEXPORT jint JNICALL
Java_com_volla_launcher_worker_AssistantNative_ask(JNIEnv *env, jobject thiz,
                                                  jstring jprompt)
{
    if (!g_loaded)
        return ASSISTANT_ERR_NOT_LOADED;
    if (jprompt == nullptr)
        return ASSISTANT_ERR_BAD_ARGUMENT;

    const char *prompt = env->GetStringUTFChars(jprompt, nullptr);
    if (prompt == nullptr)
        return ASSISTANT_ERR_BAD_ARGUMENT;

    appendUserTurn(prompt, g_isThinker);
    env->ReleaseStringUTFChars(jprompt, prompt);

    if (g_state.messages == nullptr) {
        releaseAssistant();
        return ASSISTANT_ERR_PROMPT;
    }

    if (allocate_prompt(&g_inference, &g_state) != 0) {
        releaseAssistant();
        return ASSISTANT_ERR_PROMPT;
    }

    setCallback(env, thiz);
    const int res = run_inference_stream(&g_inference, &g_state);
    setCallback(nullptr, nullptr);

    if (res != 0) {
        LOGE("ask: inference failed");
        releaseAssistant();
        return ASSISTANT_ERR_INFERENCE;
    }

    appendAssistantTurn();

    return ASSISTANT_OK;
}

JNIEXPORT jstring JNICALL
Java_com_volla_launcher_worker_AssistantNative_response(JNIEnv *env, jobject)
{
    if (!g_loaded)
        return env->NewStringUTF("");
    return newStringSafe(env, g_state.assistant_response);
}

JNIEXPORT jint JNICALL
Java_com_volla_launcher_worker_AssistantNative_release(JNIEnv *, jobject)
{
    releaseAssistant();
    return ASSISTANT_OK;
}

JNIEXPORT jboolean JNICALL
Java_com_volla_launcher_worker_AssistantNative_isAgentCalled(JNIEnv *env, jobject,
                                                            jstring jresponse)
{
    if (jresponse == nullptr)
        return JNI_FALSE;

    const char *text = env->GetStringUTFChars(jresponse, nullptr);
    const bool called = text != nullptr && is_agent_called(std::string(text));
    if (text != nullptr)
        env->ReleaseStringUTFChars(jresponse, text);

    return called ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jstring JNICALL
Java_com_volla_launcher_worker_AssistantNative_extractAgentId(JNIEnv *env, jobject,
                                                              jstring jresponse)
{
    if (jresponse == nullptr)
        return env->NewStringUTF("");

    const char *text = env->GetStringUTFChars(jresponse, nullptr);
    const std::string id = text != nullptr ? extract_agent_id(std::string(text)) : std::string();
    if (text != nullptr)
        env->ReleaseStringUTFChars(jresponse, text);

    return env->NewStringUTF(id.c_str());
}


JNIEXPORT jint JNICALL
Java_com_volla_launcher_worker_AssistantNative_agentInit(JNIEnv *env, jobject,
                                                         jstring jagentId)
{
    if (jagentId == nullptr)
        return ASSISTANT_ERR_BAD_ARGUMENT;

    const char *agentId = env->GetStringUTFChars(jagentId, nullptr);
    if (agentId == nullptr)
        return ASSISTANT_ERR_BAD_ARGUMENT;

    const int res = init_agent(std::string(agentId), g_agentInference, g_agentState);
    env->ReleaseStringUTFChars(jagentId, agentId);

    g_agentLoaded = (res == 0);
    if (res != 0)
        LOGE("agentInit: failed, code %d", res);

    return res == 0 ? ASSISTANT_OK : ASSISTANT_ERR_CONFIG;
}

JNIEXPORT jint JNICALL
Java_com_volla_launcher_worker_AssistantNative_agentAsk(JNIEnv *env, jobject thiz,
                                                        jstring jprompt)
{
    if (!g_agentLoaded)
        return ASSISTANT_ERR_NOT_LOADED;
    if (jprompt == nullptr)
        return ASSISTANT_ERR_BAD_ARGUMENT;

    const char *promptChars = env->GetStringUTFChars(jprompt, nullptr);
    if (promptChars == nullptr)
        return ASSISTANT_ERR_BAD_ARGUMENT;

    std::string prompt(promptChars);
    env->ReleaseStringUTFChars(jprompt, promptChars);

    if (digest_user_prompt(g_agentInference, g_agentState, prompt) != 0) {
        LOGE("agentAsk: cannot digest prompt");
        reset_agent(g_agentInference, g_agentState);
        return ASSISTANT_ERR_PROMPT;
    }

    setCallback(env, thiz);
    const int res = stream_agent_response(g_agentInference, g_agentState);
    setCallback(nullptr, nullptr);

    if (res != 0) {
        LOGE("agentAsk: generation failed");
        reset_agent(g_agentInference, g_agentState);
        return ASSISTANT_ERR_INFERENCE;
    }

    return ASSISTANT_OK;
}

JNIEXPORT jstring JNICALL
Java_com_volla_launcher_worker_AssistantNative_agentResponse(JNIEnv *env, jobject)
{
    if (!g_agentLoaded)
        return env->NewStringUTF("");
    return newStringSafe(env, g_agentState.core.assistant_response);
}

JNIEXPORT jint JNICALL
Java_com_volla_launcher_worker_AssistantNative_agentReset(JNIEnv *, jobject)
{
    if (!g_agentLoaded)
        return ASSISTANT_ERR_NOT_LOADED;
    return reset_agent(g_agentInference, g_agentState) == 0 ? ASSISTANT_OK
                                                            : ASSISTANT_ERR_INFERENCE;
}

} // extern "C"
