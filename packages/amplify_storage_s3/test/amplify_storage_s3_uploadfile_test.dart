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
import 'package:flutter_test/flutter_test.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_storage_s3/src/Exceptions/StorageExceptionMessages.dart'
    as Messages;
import 'package:amplify_core/amplify_core.dart';
import 'dart:io';

void main() {
  const MethodChannel storageChannel =
      MethodChannel('com.amazonaws.amplify/storage_s3');
  const MethodChannel coreChannel = MethodChannel('com.amazonaws.amplify/core');
  var isConfigured = false;

  Amplify amplify = new Amplify();
  AmplifyStorageS3 storage = AmplifyStorageS3();

  configureAmplify() async {
    await amplify.addPlugin(storagePlugins: [storage]);
    await amplify.configure('{}');
    isConfigured = true;
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  int testCode = 0;

  setUp(() {
    storageChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (testCode) {
        case 1:
          return {
            'key': 'keyForFile',
          };
        case 2:
          return {};
        case 3:
          throw PlatformException(
              code: 'AMPLIFY_EXCEPTION',
              message: Messages.UPLOAD_FILE_FAILED,
              details: {});
      }
    });

    coreChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return true;
    });

    if (!isConfigured) {
      configureAmplify();
    }
  });

  tearDown(() {
    storageChannel.setMockMethodCallHandler(null);
    coreChannel.setMockMethodCallHandler(null);
  });

  test(
      'uploadFile request returns the correct UploadFileResult in the happy case',
      () async {
    testCode = 1;
    var uploadFileResult = await Amplify.Storage.uploadFile(
        key: 'keyForFile', local: File('path/to/file'));
    expect(uploadFileResult, isInstanceOf<UploadFileResult>());
    expect(uploadFileResult.key, 'keyForFile');
  });

  test(
      'Throws StorageException when method channel result does not include the key',
      () async {
    testCode = 2;
    try {
      await Amplify.Storage.uploadFile(
          key: 'keyForFile', local: File('path/to/file'));
    } on StorageException catch (err) {
      expect(err.message, Messages.MALFORMED_PLATFORM_CHANNEL_RESULT);
      return;
    }
    throw new Exception('Expected a StorageException');
  });

  test('A PlatformException results in a StorageException being thrown',
      () async {
    testCode = 3;
    try {
      await Amplify.Storage.uploadFile(
          key: 'keyForFile', local: File('path/to/file'));
    } on StorageException catch (err) {
      expect(err.message, Messages.UPLOAD_FILE_FAILED);
      return;
    }
    throw new Exception('Expected a StorageException');
  });
}
