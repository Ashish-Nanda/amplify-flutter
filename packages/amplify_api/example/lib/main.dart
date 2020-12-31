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

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_core/amplify_core.dart';
import 'amplifyconfiguration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _result = '';
  Function _unsubscribe;
  bool _isAmplifyConfigured = false;
  Amplify amplify = new Amplify();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    AmplifyAPI apiPlugin = AmplifyAPI();

    await amplify.addPlugin(apiPlugins: [apiPlugin]);

    // Configure
    await amplify.configure(amplifyconfig);
    setState(() {
      _isAmplifyConfigured = true;
    });
  }

  subscribe() async {
    print('In subscribe');
    String graphQLDocument = '''subscription MySubscription {
        onCreateBlog {
          id
          name
          createdAt
        }
      }''';
    var operation = await Amplify.API.subscribe(
        request: GraphQLRequest(document: graphQLDocument),
        onData: (msg) {
          print("Subscription Message received: $msg");
        },
        onEstablished: () {
          print("Subscription established");
        },
        onError: (e) {
          print("Error occurred");
          print(e);
        },
        onDone: () {
          print("Subscription has been closed successfully");
        });

    // Stream<Map<String, dynamic>> stream = operation.stream;

    // stream.listen((event) {
    //   print("Subscription event: $event");
    // }).onError((error) => print("Subscription error $error"));

    var unsubscribe = () {
      operation.cancel();
    };

    setState(() {
      _unsubscribe = unsubscribe;
    });
  }

  query() async {
    String graphQLDocument = '''query MyQuery {
      listBlogs {
        items {
          id
          name
          createdAt
        }
      }
    }''';

    var operation = await Amplify.API
        .query<String>(request: GraphQLRequest(document: graphQLDocument));

    var response = await operation.response;
    var data = response.data;

    print('Result data: ' + data);
    setState(() {
      _result = data;
    });
  }

  mutate() async {
    String graphQLDocument = '''mutation MyMutation(\$name: String!) {
      createBlog(input: {name: \$name}) {
        id
        name
        createdAt
      }
    }''';

    var operation = await Amplify.API.mutate(
        request: GraphQLRequest<String>(
            document: graphQLDocument, variables: {"name": "Test App Blog"}));

    var response = await operation.response;
    var data = response.data;

    print('Result data: ' + data);
    setState(() {
      _result = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('API example app'),
        ),
        body: Center(
          child: ListView(
            padding: EdgeInsets.all(5.0),
            children: <Widget>[
              Padding(padding: EdgeInsets.all(10.0)),
              Center(
                child: RaisedButton(
                  onPressed: _isAmplifyConfigured ? query : null,
                  child: Text('Run Query'),
                ),
              ),
              Padding(padding: EdgeInsets.all(10.0)),
              Center(
                child: RaisedButton(
                  onPressed: _isAmplifyConfigured ? mutate : null,
                  child: Text('Run Mutation'),
                ),
              ),
              Padding(padding: EdgeInsets.all(10.0)),
              Center(
                child: RaisedButton(
                  onPressed: _isAmplifyConfigured ? subscribe : null,
                  child: Text('Subscribe'),
                ),
              ),
              Padding(padding: EdgeInsets.all(10.0)),
              Center(
                child: RaisedButton(
                  onPressed: _isAmplifyConfigured ? _unsubscribe : null,
                  child: Text('Unsubscribe'),
                ),
              ),
              Padding(padding: EdgeInsets.all(5.0)),
              Text('Result: \n$_result\n'),
            ],
          ),
        ),
      ),
    );
  }
}
