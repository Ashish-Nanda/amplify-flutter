package com.amazonaws.amplify.amplify_api

import android.os.Handler
import android.os.Looper
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

    fun sendEvent(event: String) {
        handler.post {
            eventSink?.success(event)
        }
    }
}