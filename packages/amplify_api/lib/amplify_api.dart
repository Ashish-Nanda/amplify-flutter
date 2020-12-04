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

library amplify_api_plugin;

import 'package:amplify_api_plugin_interface/amplify_api_plugin_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:amplify_api_plugin_interface/src/SubscriptionOperation.dart';
import './method_channel_api.dart';
import 'package:flutter/foundation.dart';
export 'package:amplify_api_plugin_interface/src/types.dart';

class AmplifyAPI extends APIPluginInterface {
  static final Object _token = Object();

  /// Constructs a AmplifyAPIPlugin.
  AmplifyAPI() : super(token: _token);

  static AmplifyAPI _instance = AmplifyAPIMethodChannel();

  /// The default instance of [AmplifyAPIPlugin] to use.
  static APIPluginInterface get instance => _instance;

  static set instance(APIPluginInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  @override
  Future<Map> query({@required GraphQLRequest request}) {
    return _instance.query(request: request);
  }

  @override
  Future<Map> mutate({@required GraphQLRequest request}) {
    return _instance.mutate(request: request);
  }

  @override
  Future<SubscriptionOperation> subscribe({@required GraphQLRequest request}) {
    return _instance.subscribe(request: request);
  }
}
