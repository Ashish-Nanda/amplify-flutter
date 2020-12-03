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
  String _queryResult = '';
  bool _isAmplifyConfigured = false;
  Amplify amplify = new Amplify();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    AmplifyAPI apiPlugin = AmplifyAPI();

    await amplify.addPlugin(apiPlugins: [apiPlugin]);

    // Configure
    await amplify.configure(amplifyconfig);
    setState(() {
      _isAmplifyConfigured = true;
    });
    var result = await Amplify.API.subscribe(
        request: GraphQLRequest(document: '''subscription MySubscription {
        onCreateBlog {
          id
          name
          createdAt
        }
      }''', variables: {}));

    Stream<String> stream = result.stream;

    stream.listen((event) {
      print("Subscription event: $event");
    }).onError((error) => print("Subscription error $error"));
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
    var result = await Amplify.API.query(
        request: GraphQLRequest(document: graphQLDocument, variables: {}));
    print('Query Result $result');

    setState(() {
      _queryResult = result.toString();
    });
  }

  mutate() async {
    String graphQLDocument = '''mutation MyMutation(\$name: String!) {
      createBlog(input: {name: \$name}) {
        id
        name
      }
    }''';
    var result = await Amplify.API.mutate(
        request: GraphQLRequest(
            document: graphQLDocument, variables: {"name": "Test App Blog"}));

    setState(() {
      _queryResult = result.toString();
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
              Padding(padding: EdgeInsets.all(5.0)),
              // replace with any or all query results as needed
              Text('Query Result: \n$_queryResult\n'),
            ],
          ),
        ),
      ),
    );
  }
}
