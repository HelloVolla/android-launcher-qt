package com.volla.launcher.worker;

/*
 * Binding to assistant_jni.cpp.
 *
 */
public class AssistantNative {

    // Mirrors the error codes in assistant_jni.cpp.
    public static final int OK = 0;
    public static final int ERR_CONFIG = 1;
    public static final int ERR_MODEL = 2;
    public static final int ERR_VOCAB = 3;
    public static final int ERR_CONTEXT = 4;
    public static final int ERR_SAMPLER = 5;
    public static final int ERR_PROMPT = 6;
    public static final int ERR_INFERENCE = 7;
    public static final int ERR_NOT_LOADED = 8;
    public static final int ERR_BAD_ARGUMENT = 9;

    public interface TokenListener {
        void onPartialToken(String text);
    }

    private TokenListener listener;

    public void setTokenListener(TokenListener listener) {
        this.listener = listener;
    }

    public native int init(String configPath, String modelPath, String cachePath);

    public native int ask(String prompt);

    public native String response();

    public native int release();

    public native boolean isAgentCalled(String response);

    public native String extractAgentId(String response);

    public native int agentInit(String agentId);

    public native int agentAsk(String prompt);

    public native String agentResponse();

    public native int agentReset();

    public void partiallyUpdate(String text) {
        TokenListener l = this.listener;
        if (l != null && text != null) {
            l.onPartialToken(text);
        }
    }

    public static String errorMessage(int code) {
        switch (code) {
            case ERR_CONFIG: return "assistant config could not be loaded";
            case ERR_MODEL: return "assistant model could not be loaded";
            case ERR_VOCAB: return "assistant vocabulary could not be read";
            case ERR_CONTEXT: return "assistant context could not be created";
            case ERR_SAMPLER: return "assistant sampler could not be created";
            case ERR_PROMPT: return "assistant prompt could not be prepared";
            case ERR_INFERENCE: return "assistant inference failed";
            case ERR_NOT_LOADED: return "assistant is not loaded";
            case ERR_BAD_ARGUMENT: return "assistant received an invalid argument";
            default: return "assistant failed with code " + code;
        }
    }
}
