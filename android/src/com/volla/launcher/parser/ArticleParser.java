package com.volla.launcher.parser;

import androidnative.SystemDispatcher;
import android.util.Log;
import java.util.Map;
import java.util.HashMap;
import org.qtproject.qt5.android.QtNative;
import com.chimbori.crux.articles.ArticleExtractor;
import com.chimbori.crux.articles.Article;
import org.jsoup.nodes.Document;

public class ArticleParser {

    private static final String TAG = "ArticleParser";

    public static final String GET_ARTICLE = "volla.launcher.articleAction";
    public static final String GOT_ARTICLE = "volla.launcher.articleResponse";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                if (type.equals(GET_ARTICLE)) {
                    getArticle(message);
                }
            }
        });
    }

    static void getArticle(Map message) {
        Log.d(TAG, "Invoked JAVA getArticle" );

        Map reply = new HashMap();

        String url = (String) message.get("url");
        String rawHTML = (String) message.get("rawHTML");

        Article article = ArticleExtractor.with(url, rawHTML)
            .extractMetadata()
            .extractContent()  // If you only need metadata, you can skip `.extractContent()`
            .article();

        reply.put("title", article.title);
        reply.put("description", article.description);
        reply.put("imageUrl", article.imageUrl);
        reply.put("videoUrl", article.videoUrl);
        reply.put("html", article.document.html());

        SystemDispatcher.dispatch(GOT_ARTICLE, reply);
    }
}
