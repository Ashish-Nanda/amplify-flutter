package com.amazonaws.amplify.amplify_api

import android.os.Handler
import android.os.Looper
import com.amplifyframework.api.graphql.GraphQLResponse
import io.flutter.plugin.common.EventChannel

class ApiSubscriptionStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendEvent(data: String?, errors: List<GraphQLResponse.Error>, id: String) {
        handler.post {
            var result: Map<String, Any?> = mapOf(
                    "id" to id,
                    "data" to data,
                    "errors" to errors.map {it.message}
            )

            eventSink?.success(result)
        }
    }
}