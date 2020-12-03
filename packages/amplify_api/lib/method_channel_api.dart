/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:amplify_api_plugin_interface/amplify_api_plugin_interface.dart';
import 'package:amplify_api_plugin_interface/src/SubscriptionOperation.dart';

import 'amplify_api.dart';

const MethodChannel _channel = MethodChannel('com.amazonaws.amplify/api');

/// An implementation of [AmplifyPlatform] that uses method channels.
class AmplifyAPIMethodChannel extends AmplifyAPI {
  var _allSubscriptionsStream = null;

  @override
  Future<Map<String, dynamic>> query({@required GraphQLRequest request}) async {
    try {
      final Map<String, dynamic> result =
          await _channel.invokeMapMethod<String, dynamic>(
        'query',
        request.serializeAsMap(),
      );
      return result;
    } on PlatformException catch (e) {
      throw (e);
    }
  }

  @override
  Future<Map<String, dynamic>> mutate(
      {@required GraphQLRequest request}) async {
    try {
      final Map<String, dynamic> result =
          await _channel.invokeMapMethod<String, dynamic>(
        'mutate',
        request.serializeAsMap(),
      );
      return result;
    } on PlatformException catch (e) {
      throw (e);
    }
  }

  @override
  Future<SubscriptionOperation> subscribe(
      {@required GraphQLRequest request}) async {
    // Step #1. Open the event channel if it's not already open. Note
    // that there is only one event channel for all subscriptions.
    const _eventChannel =
        EventChannel('com.amazonaws.amplify/api_observe_events');
    _allSubscriptionsStream =
        _allSubscriptionsStream ?? _eventChannel.receiveBroadcastStream(0);

    // Step #2. Subscribe and get back the unique id of the subscription.
    // Then filter the stream for this id.
    try {
      final String subscriptionId = await _channel.invokeMethod<String>(
        'subscribe',
        request.serializeAsMap(),
      );

      Stream<String> filteredStream = _allSubscriptionsStream
          .where((event) {
            return event["id"] == subscriptionId;
          })
          .map((event) => event["data"])
          .asBroadcastStream()
          .cast<String>();

      return SubscriptionOperation(id: subscriptionId, stream: filteredStream);
    } on PlatformException catch (e) {
      throw (e);
    }
  }
}
