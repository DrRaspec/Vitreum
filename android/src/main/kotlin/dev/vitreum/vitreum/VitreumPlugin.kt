package dev.vitreum.vitreum

import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VitreumPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "dev.vitreum/capabilities")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "getCapabilities") {
            result.notImplemented()
            return
        }
        result.success(
            mapOf(
                "platform" to "android",
                "osVersion" to Build.VERSION.RELEASE,
                "nativeApiExists" to false,
                "nativeViewCanBeCreated" to false,
                "nativeBackdropCompositionValidated" to false,
                "nativeSingleOverlayCompositionValidated" to false,
                "nativeInteractiveEffectAvailable" to false,
                "simulatedRendererAvailable" to true,
                "shaderAvailable" to false,
                "reducedTransparency" to false,
                "selectedAutomaticBackend" to "flutterBalanced",
            ),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
