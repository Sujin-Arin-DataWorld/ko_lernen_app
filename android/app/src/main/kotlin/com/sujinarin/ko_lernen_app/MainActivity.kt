package com.sujinarin.ko_lernen_app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // SDK 35 enforces edge-to-edge on Android 15. FlutterActivity is an
        // android.app.Activity rather than ComponentActivity, so use the
        // WindowCompat equivalent that also works with Flutter's embedding.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
