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

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:amplify_api_plugin_interface/amplify_api_plugin_interface.dart';

import 'amplify_api.dart';

const MethodChannel _channel = MethodChannel('com.amazonaws.amplify/api');

class AmplifyAPIMethodChannel extends AmplifyAPI {
  var _allSubscriptionsStream = null;

  @override
  GraphQLOperation<T> query<T>({@required GraphQLRequest<T> request}) {
    Future<GraphQLResponse<T>> response =
        _getMethodChannelResponse(methodName: 'query', request: request);

    GraphQLOperation<T> result =
        GraphQLOperation<T>(cancel: () {}, response: response);

    return result;
  }

  @override
  GraphQLOperation<T> mutate<T>({@required GraphQLRequest<T> request}) {
    Future<GraphQLResponse<T>> response =
        _getMethodChannelResponse(methodName: 'mutate', request: request);

    GraphQLOperation<T> result =
        GraphQLOperation<T>(cancel: () {}, response: response);

    return result;
  }

  Future<GraphQLResponse<T>> _getMethodChannelResponse<T>({
    @required String methodName,
    @required GraphQLRequest<T> request,
  }) async {
    try {
      final Map<String, dynamic> result =
          await _channel.invokeMapMethod<String, dynamic>(
        methodName,
        request.serializeAsMap(),
      );

      final errors = _deserializeGraphQLResponseErrors(result);

      GraphQLResponse<T> response =
          GraphQLResponse<T>(data: result['data'], errors: errors);

      return response;
    } on PlatformException catch (e) {
      print('In catch for getMethodChannelResponse');
      throw _formatError(e);
    }
  }

  Future<void> _cancelSubscription({@required String id}) async {
    try {
      await _channel.invokeMethod('cancelSubscription', {'id': id});
      print("Cancel subscription succeeded");
    } on PlatformException catch (e) {
      print('Cancel Subscrption failed');
      throw _formatError(e);
    }
  }

  @override
  Future<GraphQLSubscriptionOperation<T>> subscribe<T>(
      {@required GraphQLRequest request,
      void Function() onEstablished,
      @required void Function(Map<String, dynamic>) onData,
      void Function(dynamic) onError,
      void Function() onDone}) async {
    const _eventChannel =
        EventChannel('com.amazonaws.amplify/api_observe_events');
    _allSubscriptionsStream =
        _allSubscriptionsStream ?? _eventChannel.receiveBroadcastStream(0);

    try {
      final String subscriptionId = await _channel.invokeMethod<String>(
        'subscribe',
        request.serializeAsMap(),
      );

      onEstablished();

      Stream<Map<String, dynamic>> filteredStream = _allSubscriptionsStream
          .where((event) {
            return event["id"] == subscriptionId;
          })
          // TODO: Improve this map function
          .map((event) => {
                "data": event["payload"]["data"],
                "errors": event["payload"]["errors"],
                "type": event["type"]
              })
          .asBroadcastStream()
          .cast<Map<String, dynamic>>();

      StreamSubscription _subscription = filteredStream.listen((msg) {
        if (msg["type"] == "DONE") {
          onDone();
        } else {
          onData(msg);
        }
      });
      _subscription.onError(onError);

      Function cancel = () {
        _subscription.cancel();
        _cancelSubscription(id: subscriptionId);
      };

      return GraphQLSubscriptionOperation(cancel: cancel);
    } on PlatformException catch (e) {
      if (e.message == "AMPLIFY_API_SUBSCRIBE_FAILED_TO_CONNECT") {
        onError(e);
      } else {
        throw _formatError(e);
      }
    }
  }

  ApiError _formatError(PlatformException e) {
    print('API error');
    return ApiError(code: e.code, message: e.message, details: e.details);
  }

  List<GraphQLResponseError> _deserializeGraphQLResponseErrors(
      Map<String, dynamic> result) {
    //TODO: Deserialize errors list into List<GraphQLResponseError>
    return [];
  }
}
