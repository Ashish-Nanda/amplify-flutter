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

library amplify_api_plugin_interface;

import 'dart:async';
import 'package:amplify_api_plugin_interface/src/SubscriptionOperation.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/types.dart';
export 'src/types.dart';

abstract class APIPluginInterface extends PlatformInterface {
  APIPluginInterface({@required Object token}) : super(token: token);

  Future<Map> query({@required GraphQLRequest request}) {
    throw UnimplementedError('query() has not been implemented.');
  }

  Future<Map> mutate({@required GraphQLRequest request}) {
    throw UnimplementedError('mutate() has not been implemented.');
  }

  Future<SubscriptionOperation> subscribe({@required GraphQLRequest request}) {
    throw UnimplementedError('subscribe() has not been implemented.');
  }
}