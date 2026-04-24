package com.tripletile.matchpuzzle

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        FacebookSdk.setAutoInitEnabled(true)
        // Fix Android 15 edge-to-edge deprecation warnings
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        AppEventsLogger.activateApp(application)
    }
}
