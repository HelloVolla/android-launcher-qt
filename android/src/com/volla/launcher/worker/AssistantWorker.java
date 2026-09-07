package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.util.Log;

import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.qtproject.qt5.android.QtNative;

public class AssistantWorker {

    private static final String TAG = "AssistantWorker";

    private static final String ASSISTANT_INIT = "volla.launcher.assistantInitAction";
    private static final String ASSISTANT_ASK = "volla.launcher.assistantAction";
    private static final String ASSISTANT_READY = "volla.launcher.assistantReadyResponse";
    private static final String ASSISTANT_RESPONSE = "volla.launcher.assistantResponse";
    private static final String ASSISTANT_PARTIAL = "volla.launcher.assistantPartialResponse";
    private static final String ASSISTANT_ERROR = "volla.launcher.assistantErrorResponse";

    private static final ExecutorService executor = Executors.newSingleThreadExecutor();

    private static final AssistantNative llama = new AssistantNative();

    private static volatile boolean loaded = false;
    private static volatile boolean startRequested = false;

    static {
        llama.setTokenListener(new AssistantNative.TokenListener() {
            public void onPartialToken(String text) {
                Map reply = new HashMap();
                reply.put("token", text);
                SystemDispatcher.dispatch(ASSISTANT_PARTIAL, reply);
            }
        });

        SystemDispatcher.addListener(new SystemDispatcher.Listener() {
            public void onDispatched(String type, Map message) {
                if (type.equals(ASSISTANT_INIT)) {
                    Log.d(TAG, "Assistant init requested");
                    initEngine();
                } else if (type.equals(ASSISTANT_ASK)) {
                    ask((String) message.get("prompt"));
                }
            }
        });
    }

    private static void dispatchError(String message) {
        Log.e(TAG, message);
        Map reply = new HashMap();
        reply.put("message", message);
        SystemDispatcher.dispatch(ASSISTANT_ERROR, reply);
    }

    private static void initEngine() {
        if (startRequested) {
            return;
        }
        startRequested = true;

        executor.execute(new Runnable() {
            public void run() {
                Activity activity = QtNative.activity();
                if (activity == null) {
                    startRequested = false;
                    dispatchError("Assistant cannot start: no activity");
                    return;
                }

                String filesDir = activity.getFilesDir().getAbsolutePath();
                String configPath = filesDir + "/configs/assistant_config.json";
                String modelPath = filesDir + "/models/assistant/model.gguf";

                File cacheDir = new File(activity.getCacheDir(), "assistant");
                cacheDir.mkdirs();
                String cachePath = new File(cacheDir, "cache.bin").getAbsolutePath();

                if (!new File(configPath).exists()) {
                    startRequested = false;
                    dispatchError("Assistant config is missing at " + configPath);
                    return;
                }
                if (!new File(modelPath).exists()) {
                    startRequested = false;
                    dispatchError("Assistant model is missing at " + modelPath);
                    return;
                }

                Log.d(TAG, "Loading model " + modelPath);
                int res = llama.init(configPath, modelPath, cachePath);
                if (res != AssistantNative.OK) {
                    startRequested = false;
                    dispatchError("Assistant failed to start: " + AssistantNative.errorMessage(res));
                    return;
                }

                loaded = true;
                Log.d(TAG, "Assistant ready");
                SystemDispatcher.dispatch(ASSISTANT_READY, new HashMap());
            }
        });
    }

    private static void ask(final String prompt) {
        if (prompt == null || prompt.trim().length() == 0) {
            return;
        }

        executor.execute(new Runnable() {
            public void run() {
                if (!loaded) {
                    dispatchError("The assistant is not available");
                    return;
                }

                Log.d(TAG, "Running inference");
                int res = llama.ask(prompt);
                if (res != AssistantNative.OK) {
                    dispatchError("Assistant failed: " + AssistantNative.errorMessage(res));
                    return;
                }

                String answer = llama.response();

                if (llama.isAgentCalled(answer)) {
                    String agentId = llama.extractAgentId(answer);
                    Log.d(TAG, "Model requested agent " + agentId);
                    dispatchError("Agent '" + agentId + "' is not available yet");
                    return;
                }

                Map reply = new HashMap();
                reply.put("response", answer);
                SystemDispatcher.dispatch(ASSISTANT_RESPONSE, reply);
            }
        });
    }
}
