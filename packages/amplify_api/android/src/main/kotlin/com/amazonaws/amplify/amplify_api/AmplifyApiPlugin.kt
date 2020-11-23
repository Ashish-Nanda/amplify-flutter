package com.amazonaws.amplify.amplify_api

import android.os.Handler
import android.os.Looper
import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.amplifyframework.core.Amplify
import com.amplifyframework.api.aws.AWSApiPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar


/** AmplifyApiPlugin */
class AmplifyApiPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var mainActivity: Activity? = null
  private val handler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "com.amazonaws.amplify/api")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    // Uncomment the line below once a valid backend configuration is used for API
    // Amplify.addPlugin(AWSApiPlugin())
    Log.i("AmplifyFlutter", "Added API plugin")
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "com.amazonaws.amplify/api")
      // Uncomment the line below once a valid backend configuration is used for API
      // Amplify.addPlugin(AWSApiPlugin())
      Log.i("AmplifyFlutter", "Added API plugin")
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "query" ->
        onQuery(result, call.arguments as Map<String, Any>)
      else -> result.notImplemented()
    }
  }

  fun onQuery(flutterResult: Result, request: Map<String, Any>) {
    try {
    Log.i("AmplifyFlutter", "API.query request :$request");
    var result: Map<String, Any> = mapOf(
            "getTodo" to mapOf(
                    "id" to "123",
                    "name" to "test todo"
            )
    )
      handler.post { flutterResult.success(result) }
  } catch (error: Exception) {
      postFlutterError(
              flutterResult,
              "ERROR_IN_PLATFORM_CODE",
              error)
    }
  }

  private fun postFlutterError(flutterResult: Result, msg: String, @NonNull error: Exception) {
    handler.post { flutterResult.error("AmplifyException", msg, error.toString()) }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.mainActivity = binding.activity
  }

  override fun onDetachedFromActivity() {
    this.mainActivity = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
