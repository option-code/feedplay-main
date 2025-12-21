package com.betapix.feedplay

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.betapix.feedplay/shortcuts"
    private var gameDeepLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle deep link if app was opened from shortcut
        handleIntent(intent)
        
        // Configure WebView for better stability with AdMob
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                // Isolate WebView data directory to prevent conflicts
                WebView.setDataDirectorySuffix("gameplus")
            } catch (exception: Throwable) {
                Log.w("GamePlusMainActivity", "Unable to set WebView data directory suffix", exception)
            }
        }
        
        // Enable WebView debugging for better diagnostics (helps with AdMob WebView issues)
        try {
            WebView.setWebContentsDebuggingEnabled(true)
        } catch (exception: Throwable) {
            Log.w("GamePlusMainActivity", "Unable to enable WebView debugging", exception)
        }
        
        // Pre-warm WebView process before AdMob initialization
        // This helps prevent "Unable to obtain a JavascriptEngine" errors
        try {
            preWarmWebView()
        } catch (exception: Throwable) {
            Log.w("GamePlusMainActivity", "Unable to pre-warm WebView", exception)
        }
    }
    
    /**
     * Pre-warm WebView by creating a dummy instance
     * This initializes the WebView renderer process early, before AdMob tries to use it
     */
    private fun preWarmWebView() {
        try {
            // Create a dummy WebView to initialize the renderer process
            val webView = WebView(this)
            webView.settings.javaScriptEnabled = true
            webView.settings.domStorageEnabled = true
            webView.webViewClient = WebViewClient()
            
            // Load a minimal HTML page to fully initialize the renderer
            webView.loadDataWithBaseURL(
                null,
                "<html><body></body></html>",
                "text/html",
                "UTF-8",
                null
            )
            
            // Keep reference briefly, then clear it
            // The WebView process will stay alive even after we release the reference
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    webView.destroy()
                } catch (e: Exception) {
                    // Ignore - process stays alive anyway
                }
            }, 1000)
            
            Log.d("GamePlusMainActivity", "WebView pre-warmed successfully")
        } catch (exception: Throwable) {
            Log.w("GamePlusMainActivity", "WebView pre-warm failed", exception)
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent != null) {
            val action = intent.action
            val data = intent.data
            
            if (Intent.ACTION_VIEW == action && data != null) {
                // Handle deep link
                val gameId = data.getQueryParameter("gameId")
                if (gameId != null) {
                    gameDeepLink = gameId
                    Log.d("GamePlusMainActivity", "Deep link received: gameId=$gameId")
                }
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "native_ad_factory", NativeAdFactoryImpl(applicationContext))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createShortcuts" -> {
                    try {
                        val gamesJson = call.argument<String>("games")
                        if (gamesJson != null) {
                            createShortcuts(gamesJson)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "Games JSON is null", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getDeepLinkGameId" -> {
                    val gameId = gameDeepLink
                    gameDeepLink = null // Clear after reading
                    result.success(gameId)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun createShortcuts(gamesJson: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            try {
                val shortcutManager = getSystemService(android.content.pm.ShortcutManager::class.java)
                val shortcuts = mutableListOf<android.content.pm.ShortcutInfo>()
                
                // Parse games JSON (simple format: gameId1|gameName1|gameImage1,gameId2|gameName2|gameImage2)
                val games = gamesJson.split(",")
                var index = 0
                
                for (gameData in games) {
                    if (index >= 2) break // Only create 2 shortcuts
                    
                    val parts = gameData.split("|")
                    if (parts.size >= 2) {
                        val gameId = parts[0]
                        val gameName = parts[1]
                        val gameImage = if (parts.size >= 3) parts[2] else null
                        
                        // Create deep link intent
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("gameplus://game?gameId=$gameId"))
                        intent.setPackage(packageName)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        
                        // Create shortcut info
                        val shortcutBuilder = android.content.pm.ShortcutInfo.Builder(this, "game_shortcut_$gameId")
                            .setShortLabel(gameName.take(20)) // Max 20 chars for short label
                            .setLongLabel(gameName.take(25)) // Max 25 chars for long label
                            .setIntent(intent)
                        
                        // Set icon (optional - Android will use default if not set)
                        // Using app's launcher icon if available
                        try {
                            val iconResId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
                            if (iconResId != 0) {
                                val icon = android.graphics.drawable.Icon.createWithResource(this, iconResId)
                                shortcutBuilder.setIcon(icon)
                            }
                        } catch (e: Exception) {
                            // Icon is optional - shortcut will work without it
                            // Android will automatically use a default icon
                        }
                        
                        shortcuts.add(shortcutBuilder.build())
                        index++
                    }
                }
                
                if (shortcuts.isNotEmpty()) {
                    shortcutManager?.dynamicShortcuts = shortcuts
                    Log.d("GamePlusMainActivity", "Created ${shortcuts.size} shortcuts")
                }
            } catch (e: Exception) {
                Log.e("GamePlusMainActivity", "Error creating shortcuts", e)
            }
        }
    }
}

