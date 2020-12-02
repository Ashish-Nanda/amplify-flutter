package com.amazonaws.amplify.amplify_api

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.amazonaws.amplify.amplify_api.types.FlutterApiFailureMessage
import com.amplifyframework.api.aws.AWSApiPlugin
import com.amplifyframework.api.aws.GsonVariablesSerializer
import com.amplifyframework.api.graphql.GraphQLOperation
import com.amplifyframework.api.graphql.SimpleGraphQLRequest
import com.amplifyframework.core.Amplify
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.*
import kotlin.collections.HashMap


/** AmplifyApiPlugin */
class AmplifyApiPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var eventchannel: EventChannel
  private lateinit var context: Context
  private var mainActivity: Activity? = null
  private val handler = Handler(Looper.getMainLooper())
  private val subscriptions: MutableMap<String, GraphQLOperation<String>?>
  private val apiSubscriptionStreamHandler: ApiSubscriptionStreamHandler

  constructor() {
    subscriptions = HashMap()
    apiSubscriptionStreamHandler = ApiSubscriptionStreamHandler()
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "com.amazonaws.amplify/api")
    channel.setMethodCallHandler(this)
    eventchannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.amazonaws.amplify/api_observe_events")
    eventchannel.setStreamHandler(apiSubscriptionStreamHandler)
    context = flutterPluginBinding.applicationContext
    Amplify.addPlugin(AWSApiPlugin())
    Log.i("AmplifyFlutter", "Added API plugin")
  }

  companion object {
    // TODO: Revisit this to determine if we're keeping it and, if so, how we make it consistent with onAttachedToEngine
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "com.amazonaws.amplify/api")
      Amplify.addPlugin(AWSApiPlugin())
      Log.i("AmplifyFlutter", "Added API plugin")
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "query" ->
        onQuery(result, call.arguments as Map<String, Any>)
      "mutate" ->
        onMutate(result, call.arguments as Map<String, Any>)
      else -> result.notImplemented()
    }
  }

  fun onQuery(flutterResult: Result, request: Map<String, Any>) {
    var document: String
    var variables: Map<String, Any>

    try {
      document = request["document"] as String
      variables = request["variables"] as Map<String, Any>
    } catch (e: ClassCastException) {
      postFlutterError(
              flutterResult,
              FlutterApiFailureMessage.ERROR_CASTING_INPUT_IN_PLATFORM_CODE.toString(),
              e)
      return
    } catch (e: Exception) {
      postFlutterError(
              flutterResult,
              FlutterApiFailureMessage.AMPLIFY_REQUEST_MALFORMED.toString(),
              e)
      return
    }

    Amplify.API.query(
        SimpleGraphQLRequest<String>(
                document,
                variables,
                String::class.java,
                GsonVariablesSerializer()
        ),
        {
          var result: Map<String, Any> = mapOf(
                  "data" to it.data,
                  "errors" to it.errors
          )
          handler.post { flutterResult.success(result) }
        },
        {
          postFlutterError(
                  flutterResult,
                  FlutterApiFailureMessage.AMPLIFY_API_QUERY_FAILED.toString(),
                  it)
        }
    )
  }

  fun onMutate(flutterResult: Result, request: Map<String, Any>) {
    var document: String
    var variables: Map<String, Any>

    try {
      document = request["document"] as String
      variables = request["variables"] as Map<String, Any>
    } catch (e: ClassCastException) {
      postFlutterError(
              flutterResult,
              FlutterApiFailureMessage.ERROR_CASTING_INPUT_IN_PLATFORM_CODE.toString(),
              e)
      return
    } catch (e: Exception) {
      postFlutterError(
              flutterResult,
              FlutterApiFailureMessage.AMPLIFY_REQUEST_MALFORMED.toString(),
              e)
      return
    }

    Amplify.API.mutate(
            SimpleGraphQLRequest<String>(
                    document,
                    variables,
                    String::class.java,
                    GsonVariablesSerializer()
            ),
            {
              var result: Map<String, Any> = mapOf(
                      "data" to it.data,
                      "errors" to it.errors
              )
              handler.post { flutterResult.success(result) }
            },
            {
              postFlutterError(
                      flutterResult,
                      FlutterApiFailureMessage.AMPLIFY_API_MUTATE_FAILED.toString(),
                      it)
            }
    )
  }

  fun onSubscribe(flutterResult: Result, request: Map<String, Any>) {
    var id: String = UUID.randomUUID().toString()
    var document: String
    var variables: Map<String, Any>

    try {
      document = request["document"] as String
      // TODO: This needs to be modified to support variables as an optional parameter
      variables = request["variables"] as Map<String, Any>
    } catch (e: ClassCastException) {
      postFlutterError(
              flutterResult,
              FlutterApiFailureMessage.ERROR_CASTING_INPUT_IN_PLATFORM_CODE.toString(),
              e)
      return
    } catch (e: Exception) {
      postFlutterError(
              flutterResult,
              FlutterApiFailureMessage.AMPLIFY_REQUEST_MALFORMED.toString(),
              e)
      return
    }

    var operation: GraphQLOperation<String>? = Amplify.API.subscribe(
            SimpleGraphQLRequest<String>(
                    document,
                    variables,
                    String::class.java,
                    GsonVariablesSerializer()
            ),
            {
              // Subscription established - return the internal id for the subscription
              flutterResult.success(id)
            },
            {
              apiSubscriptionStreamHandler.sendEvent(it.data)
            },
            {
              this.subscriptions.remove(id)
              postFlutterError(
                      flutterResult,
                      FlutterApiFailureMessage.AMPLIFY_API_SUBSCRIBE_FAILED_TO_CONNECT.toString(),
                      it)
            },
            {
              this.subscriptions.remove(id)
            }
    )

    subscriptions.put(id, operation)
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
