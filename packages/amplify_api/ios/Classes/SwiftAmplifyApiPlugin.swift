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

import Flutter
import UIKit
import Amplify
import AmplifyPlugins

public class SwiftAmplifyApiPlugin: NSObject, FlutterPlugin {
    
    private var subcription: GraphQLSubscriptionOperation<String>!
    private var graphQLSubscriptionsStreamHandler = GraphQLSubscriptionsStreamHandler()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.amazonaws.amplify/api", binaryMessenger: registrar.messenger())
        let eventchannel = FlutterEventChannel(name: "com.amazonaws.amplify/api_observe_events", binaryMessenger: registrar.messenger())
        let instance = SwiftAmplifyApiPlugin()
        eventchannel.setStreamHandler(instance.graphQLSubscriptionsStreamHandler)
        registrar.addMethodCallDelegate(instance, channel: channel)
        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            print("Successfully added API Plugin")
        } catch {
            print("Failed to add Amplify API Plugin \(error)")
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as! Dictionary<String,AnyObject>
        switch call.method {
        case "query":
            query(flutterResult: result, request: arguments)
        case "mutate":
            mutate(flutterResult: result, request: arguments)
        case "subscribe":
            subscribe(flutterResult: result, request: arguments)
        case "cancelSubscription":
            cancelSubscription(flutterResult: result, request: arguments)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func query(flutterResult: @escaping FlutterResult, request: [String: Any]) {
        do  {
            let document = try FlutterApiRequestUtils.getGraphQLDocument(methodChannelRequest: request)
            let variables = try FlutterApiRequestUtils.getVariables(methodChannelRequest: request)
            
            let request = GraphQLRequest<String>(document: document,
                                                 variables: variables,
                                                 responseType: String.self)
            
            Amplify.API.query(request: request) { result in
                switch result {
                case .success(let response):
                    switch response {
                    case .success(let data):
                        let result: [String: Any] = [
                            "data": data,
                            "errors": []
                        ]
                        print("GraphQL query operation succeeded with response : \(result)")
                        flutterResult(result)
                    case .failure(let errorResponse):
                        FlutterApiResponseUtils.handleGraphQLErrorResponse(flutterResult: flutterResult, errorResponse: errorResponse, failureMessage: FlutterApiErrorMessage.QUERY_FAILED.rawValue)
                    }
                case .failure(let apiError):
                    print("GraphQL query operation failed: \(apiError)")
                    FlutterApiErrorUtils.handleAPIError(flutterResult: flutterResult, error: apiError, msg: FlutterApiErrorMessage.QUERY_FAILED.rawValue)
                }}
            
        } catch let error as APIError {
            print("Failed to parse query arguments with \(error)")
            FlutterApiErrorUtils.handleAPIError(flutterResult: flutterResult, error: error, msg: FlutterApiErrorMessage.MALFORMED.rawValue)
        }
        catch {
            print("An unexpected error occured when parsing query arguments: \(error)")
            let errorMap = FlutterApiErrorUtils.createErrorMap(localizedError: "\(error.localizedDescription).\nAn unrecognized error has occurred", recoverySuggestion: "See logs for details")
            FlutterApiErrorUtils.createFlutterError(flutterResult: flutterResult, msg: FlutterApiErrorMessage.MALFORMED.rawValue, errorMap: errorMap)
        }
    }
    
    func mutate(flutterResult: @escaping FlutterResult, request: [String: Any]) {
        do  {
            let document = try FlutterApiRequestUtils.getGraphQLDocument(methodChannelRequest: request)
            let variables = try FlutterApiRequestUtils.getVariables(methodChannelRequest: request)
            
            let request = GraphQLRequest<String>(document: document,
                                                 variables: variables,
                                                 responseType: String.self)
            
            Amplify.API.mutate(request: request) { result in
                switch result {
                case .success(let response):
                    switch response {
                    case .success(let data):
                        let result: [String: Any] = [
                            "data": data,
                            "errors": []
                        ]
                        print("GraphQL mutate operation succeeded with response : \(result)")
                        flutterResult(result)
                    case .failure(let errorResponse):
                        FlutterApiResponseUtils.handleGraphQLErrorResponse(flutterResult: flutterResult, errorResponse: errorResponse, failureMessage: FlutterApiErrorMessage.MUTATE_FAILED.rawValue)
                    }
                case .failure(let apiError):
                    print("GraphQL mutate operation failed: \(apiError)")
                    FlutterApiErrorUtils.handleAPIError(flutterResult: flutterResult, error: apiError, msg: FlutterApiErrorMessage.MUTATE_FAILED.rawValue)
                }
            }
        } catch let error as APIError {
            print("Failed to parse mutate arguments with \(error)")
            FlutterApiErrorUtils.handleAPIError(flutterResult: flutterResult, error: error, msg: FlutterApiErrorMessage.MALFORMED.rawValue)
        }
        catch {
            print("An unexpected error occured when parsing mutate arguments: \(error)")
            let errorMap = FlutterApiErrorUtils.createErrorMap(localizedError: "\(error.localizedDescription).\nAn unrecognized error has occurred", recoverySuggestion: "See logs for details")
            FlutterApiErrorUtils.createFlutterError(flutterResult: flutterResult, msg: FlutterApiErrorMessage.MALFORMED.rawValue, errorMap: errorMap)
        }
    }
    
    func subscribe(flutterResult: @escaping FlutterResult, request: [String: Any]) {
        do  {
            let document = try FlutterApiRequestUtils.getGraphQLDocument(methodChannelRequest: request)
            let variables = try FlutterApiRequestUtils.getVariables(methodChannelRequest: request)
            let id = "SubscriptioniOS"
            
            let request = GraphQLRequest<String>(document: document,
                                                 variables: variables,
                                                 responseType: String.self)
            
            subcription = Amplify.API.subscribe(request: request, valueListener: { (subscriptionEvent) in
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        print("Subscription connect state is \(subscriptionConnectionState)")
                        if(subscriptionConnectionState == SubscriptionConnectionState.connected) {
                            flutterResult(id)
                        }
                    case .data(let result):
                        switch result {
                        case .success(let data):
                            print("Successfully got event data: \(data)")
                            let result: [String: Any] = [
                                "data": data,
                                "errors": []
                            ]
                            self.graphQLSubscriptionsStreamHandler.sendEvent(flutterEvent: result, id: id)
                        case .failure(let error):
                            print("Got failed result with \(error.errorDescription)")
                        }
                    }
                }) { result in
                    switch result {
                    case .success:
                        print("Subscription has been closed successfully")
                    case .failure(let apiError):
                        print("Subscription has terminated with \(apiError)")
                    }
                }
        } catch let error as APIError {
            print("Failed to parse mutate arguments with \(error)")
            FlutterApiErrorUtils.handleAPIError(flutterResult: flutterResult, error: error, msg: FlutterApiErrorMessage.MALFORMED.rawValue)
        }
        catch {
            print("An unexpected error occured when parsing mutate arguments: \(error)")
            let errorMap = FlutterApiErrorUtils.createErrorMap(localizedError: "\(error.localizedDescription).\nAn unrecognized error has occurred", recoverySuggestion: "See logs for details")
            FlutterApiErrorUtils.createFlutterError(flutterResult: flutterResult, msg: FlutterApiErrorMessage.MALFORMED.rawValue, errorMap: errorMap)
        }
    }
    
    func cancelSubscription(flutterResult: @escaping FlutterResult, request: [String: Any]) {
            subcription.cancel()
            print("Subscription Cancelled")
        }
    
}
