package com.volla.launcher.util;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class NetworkPacket {

    private long mId;
    String mType;
    private JSONObject mBody;
    private volatile boolean canceled;

    private NetworkPacket() {

    }

    public NetworkPacket(String type) {
        mId = System.currentTimeMillis();
        mType = type;
        mBody = new JSONObject();
    }

    public boolean isCanceled() { return canceled; }
    public void cancel() { canceled = true; }

    public String getType() {
        return mType;
    }

    public long getId() {
        return mId;
    }

    //Most commons getters and setters defined for convenience
    public String getString(String key) {
        return mBody.optString(key, "");
    }

    public String getString(String key, String defaultValue) {
        return mBody.optString(key, defaultValue);
    }

    public void set(String key, String value) {
        if (value == null) return;
        try {
            mBody.put(key, value);
        } catch (Exception ignored) {
        }
    }

    public int getInt(String key) {
        return mBody.optInt(key, -1);
    }

    public int getInt(String key, int defaultValue) {
        return mBody.optInt(key, defaultValue);
    }

    public void set(String key, int value) {
        try {
            mBody.put(key, value);
        } catch (Exception ignored) {
        }
    }

    public long getLong(String key) {
        return mBody.optLong(key, -1);
    }

    public long getLong(String key, long defaultValue) {
        return mBody.optLong(key, defaultValue);
    }

    public void set(String key, long value) {
        try {
            mBody.put(key, value);
        } catch (Exception ignored) {
        }
    }

    public boolean getBoolean(String key) {
        return mBody.optBoolean(key, false);
    }

    public boolean getBoolean(String key, boolean defaultValue) {
        return mBody.optBoolean(key, defaultValue);
    }

    public void set(String key, boolean value) {
        try {
            mBody.put(key, value);
        } catch (Exception ignored) {
        }
    }

    public double getDouble(String key) {
        return mBody.optDouble(key, Double.NaN);
    }

    public double getDouble(String key, double defaultValue) {
        return mBody.optDouble(key, defaultValue);
    }

    public void set(String key, double value) {
        try {
            mBody.put(key, value);
        } catch (Exception ignored) {
        }
    }

    public JSONArray getJSONArray(String key) {
        return mBody.optJSONArray(key);
    }

    public void set(String key, JSONArray value) {
        try {
            mBody.put(key, value);
        } catch (Exception ignored) {
        }
    }

    public JSONObject getJSONObject(String key) {
        return mBody.optJSONObject(key);
    }

    public void set(String key, JSONObject value) {
        try {
            mBody.put(key, value);
        } catch (JSONException ignored) {
        }
    }

    private Set<String> getStringSet(String key) {
        JSONArray jsonArray = mBody.optJSONArray(key);
        if (jsonArray == null) return null;
        Set<String> list = new HashSet<>();
        int length = jsonArray.length();
        for (int i = 0; i < length; i++) {
            try {
                String str = jsonArray.getString(i);
                list.add(str);
            } catch (Exception ignored) {
            }
        }
        return list;
    }

    public Set<String> getStringSet(String key, Set<String> defaultValue) {
        if (mBody.has(key)) return getStringSet(key);
        else return defaultValue;
    }

    public void set(String key, Set<String> value) {
        try {
            JSONArray jsonArray = new JSONArray();
            for (String str : value) {
                jsonArray.put(str);
            }
            mBody.put(key, jsonArray);
        } catch (Exception ignored) {
        }
    }

    public List<String> getStringList(String key) {
        JSONArray jsonArray = mBody.optJSONArray(key);
        if (jsonArray == null) return null;
        List<String> list = new ArrayList<>();
        int length = jsonArray.length();
        for (int i = 0; i < length; i++) {
            try {
                String str = jsonArray.getString(i);
                list.add(str);
            } catch (Exception ignored) {
            }
        }
        return list;
    }

    public List<String> getStringList(String key, List<String> defaultValue) {
        if (mBody.has(key)) return getStringList(key);
        else return defaultValue;
    }

    public void set(String key, List<String> value) {
        try {
            JSONArray jsonArray = new JSONArray();
            for (String str : value) {
                jsonArray.put(str);
            }
            mBody.put(key, jsonArray);
        } catch (Exception ignored) {
        }
    }

    public boolean has(String key) {
        return mBody.has(key);
    }

    public String serialize() throws JSONException {
        JSONObject jo = new JSONObject();
        jo.put("id", mId);
        jo.put("type", mType);
        jo.put("body", mBody);
        //QJSon does not escape slashes, but Java JSONObject does. Converting to QJson format.
        return jo.toString().replace("\\/", "/") + "\n";
    }

    static public NetworkPacket unserialize(String s) throws JSONException {
        NetworkPacket np = new NetworkPacket();
        JSONObject jo = new JSONObject(s);
        np.mId = jo.getLong("id");
        np.mType = jo.getString("type");
        np.mBody = jo.getJSONObject("body");
        return np;
    }
}