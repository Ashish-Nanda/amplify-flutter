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

import XCTest
import Amplify
import amplify_core

@testable import AmplifyPlugins
@testable import amplify_api

var eventSentExp: XCTestExpectation?

class GraphQLApiUnitTests: XCTestCase {
    typealias ResultType = String
    
    func test_query_success() throws {
        let testRequest: [String: Any] = [
            "document": "test document",
            "variables": ["test key": "test value"],
            "cancelToken" : "someCode"
        ]
        
        class MockApiBridge: ApiBridge {
            override func query<ResultType>(request: GraphQLRequest<ResultType>, listener: GraphQLOperation<ResultType>.ResultListener?) -> GraphQLOperation<ResultType>  {
                XCTAssertEqual("test document", request.document)
                XCTAssertEqual(["test key":"test value"], request.variables as! [String:String])

                let data: ResultType = "result data" as! ResultType
                let response = GraphQLResponse<ResultType>.success(data)
                listener?(.success(response))
                
                let graphQLOperation = getMockGraphQLOperation(request: request)
                return graphQLOperation
            }
        }
        
        let pluginUnderTest = SwiftAmplifyApiPlugin(bridge: MockApiBridge())

        pluginUnderTest.handle(
            FlutterMethodCall(methodName: "query", arguments: testRequest),
            result: { (result) in
                XCTAssertEqual((result as! [String:Any])["data"] as! String, "result data")
            })
    }
    
    func test_query_api_error() throws {
        let testRequest: [String: Any] = [
            "document": "test document",
            "variables": ["test key":"test value"],
            "cancelToken" : "someCode"
        ]
        
        class MockApiBridge: ApiBridge {
            override func query<ResultType>(request: GraphQLRequest<ResultType>, listener: GraphQLOperation<ResultType>.ResultListener?) -> GraphQLOperation<ResultType>  {
                XCTAssertEqual("test document", request.document)
                XCTAssertEqual(["test key":"test value"], request.variables as! [String:String])
                
                listener?(.failure(APIError.invalidConfiguration("test error", "test recovery suggestion")))
                
                let graphQLOperation = getMockGraphQLOperation(request: request)
                return graphQLOperation
            }
        }
        
        
        FlutterGraphQLApi.query(
            flutterResult: { (result) -> Void in
                if let exception = result as? FlutterError {
                    XCTAssertEqual("ApiException", exception.code)
                    XCTAssertEqual(ErrorMessages.defaultFallbackErrorMessage, exception.message)
                    
                    let errorMap: [String: String] = exception.details as! [String : String]
                    XCTAssertEqual("test error", errorMap["message"])
                    XCTAssertEqual("test recovery suggestion", errorMap["recoverySuggestion"])
                } else {
                    XCTFail()
                }
            },
            request: testRequest,
            bridge: MockApiBridge()
        )
        
    }
    
    func test_query_malformed_request_error() throws {
        let testRequest: [String: Any] = [:]
        
        class MockApiBridge: ApiBridge {
            override func query<ResultType>(request: GraphQLRequest<ResultType>, listener: GraphQLOperation<ResultType>.ResultListener?) -> GraphQLOperation<ResultType>  {
                
                XCTFail("The ApiBridge should not be called if the request is malformed")
                
                let graphQLOperation = getMockGraphQLOperation(request: request)
                return graphQLOperation
            }
        }
        
        
        FlutterGraphQLApi.query(
            flutterResult: { (result) -> Void in
                if let exception = result as? FlutterError {
                    XCTAssertEqual("ApiException", exception.code)
                    XCTAssertEqual(ErrorMessages.defaultFallbackErrorMessage, exception.message)

                    let errorMap: [String: String] = exception.details as! [String : String]
                    XCTAssertEqual("The graphQL document request argument was not passed as a String", errorMap["message"])
                    XCTAssertEqual("The request should include the graphQL document as a String", errorMap["recoverySuggestion"])
                } else {
                    XCTFail()
                }
            },
            request: testRequest,
            bridge: MockApiBridge()
        )
        
    }
    
    func test_mutate_success() throws {
        let testRequest: [String: Any] = [
            "document": "test document",
            "variables": ["test key":"test value"],
            "cancelToken" : "someCode"
        ]
        
        class MockApiBridge: ApiBridge {
            override func mutate<ResultType>(request: GraphQLRequest<ResultType>, listener: GraphQLOperation<ResultType>.ResultListener?) -> GraphQLOperation<ResultType>  {
                XCTAssertEqual("test document", request.document)
                XCTAssertEqual(["test key":"test value"], request.variables as! [String:String])
                
                let data: ResultType = "result data" as! ResultType
                let response = GraphQLResponse<ResultType>.success(data)
                listener?(.success(response))
                
                let graphQLOperation = getMockGraphQLOperation(request: request)
                return graphQLOperation
            }
        }
        
        FlutterGraphQLApi.mutate(flutterResult: { (result) in
            XCTAssertEqual((result as! [String:Any])["data"] as! String, "result data")
        },
        request: testRequest,
        bridge: MockApiBridge()
        )
        
    }
    
    func test_mutate_api_error() throws {
        let testRequest: [String: Any] = [
            "document": "test document",
            "variables": ["test key":"test value"],
            "cancelToken" : "someCode"
        ]
        
        class MockApiBridge: ApiBridge {
            override func mutate<ResultType>(request: GraphQLRequest<ResultType>, listener: GraphQLOperation<ResultType>.ResultListener?) -> GraphQLOperation<ResultType>  {
                XCTAssertEqual("test document", request.document)
                XCTAssertEqual(["test key":"test value"], request.variables as! [String:String])
                
                listener?(.failure(APIError.invalidConfiguration("test error", "test recovery suggestion")))
                
                let graphQLOperation = getMockGraphQLOperation(request: request)
                return graphQLOperation
            }
        }
        
        
        FlutterGraphQLApi.mutate(
            flutterResult: { (result) -> Void in
                if let exception = result as? FlutterError {
                    XCTAssertEqual("ApiException", exception.code)
                    XCTAssertEqual(ErrorMessages.defaultFallbackErrorMessage, exception.message)
                    let errorMap: [String: String] = exception.details as! [String : String]
                    XCTAssertEqual("test error", errorMap["message"])
                    XCTAssertEqual("test recovery suggestion", errorMap["recoverySuggestion"])

                } else {
                    XCTFail()
                }
            },
            request: testRequest,
            bridge: MockApiBridge()
        )
        
    }
    
    func test_mutate_malformed_request_error() throws {
        let testRequest: [String: Any] = [:]
        
        class MockApiBridge: ApiBridge {
            override func mutate<ResultType>(request: GraphQLRequest<ResultType>, listener: GraphQLOperation<ResultType>.ResultListener?) -> GraphQLOperation<ResultType>  {
                
                XCTFail("The ApiBridge should not be called if the request is malformed")
                
                let graphQLOperation = getMockGraphQLOperation(request: request)
                return graphQLOperation
            }
        }
        
        
        FlutterGraphQLApi.mutate(
            flutterResult: { (result) -> Void in
                if let exception = result as? FlutterError {
                    XCTAssertEqual("ApiException", exception.code)
                    XCTAssertEqual(ErrorMessages.defaultFallbackErrorMessage, exception.message)
                    let errorMap: [String: String] = exception.details as! [String : String]
                    XCTAssertEqual("The graphQL document request argument was not passed as a String", errorMap["message"])
                    XCTAssertEqual("The request should include the graphQL document as a String", errorMap["recoverySuggestion"])
                } else {
                    XCTFail()
                }
            },
            request: testRequest,
            bridge: MockApiBridge()
        )
        
    }
    
    func test_subscribe_success_event() throws {
        let testRequest: [String: Any] = [
            "document": "test document",
            "variables": ["test key":"test value"],
            "cancelToken" : "someCode"
        ]
        
        eventSentExp = expectation(description: "event was sent")
        
        class MockApiBridge: ApiBridge {
            override func subscribe<ResultType>(request: GraphQLRequest<ResultType>,
                                       valueListener: GraphQLSubscriptionOperation<ResultType>.InProcessListener?,
                                       completionListener: GraphQLSubscriptionOperation<ResultType>.ResultListener?)
                  -> GraphQLSubscriptionOperation<ResultType> {
                let data: ResultType = "result data" as! ResultType
                let response = GraphQLResponse<ResultType>.success(data)
                valueListener?(.data(response))
                let graphQLSubscriptionOperation = getMockGraphQLSubscriptionOperation(request: request)
                return graphQLSubscriptionOperation
            }
        }
        
        class MockStreamHandler: GraphQLSubscriptionsStreamHandler {
            override func sendEvent(payload: [String : Any?]?, id: String, type: GraphQLSubscriptionEventTypes) {
                            eventSentExp?.fulfill()
                            let data = payload?["data"] as! String
                            XCTAssertEqual("result data", data)
                            XCTAssertEqual(GraphQLSubscriptionEventTypes.DATA, type)
                            XCTAssertEqual("someCode", id)
                }
                }
        
        
        FlutterGraphQLApi.subscribe(
            flutterResult: { (result) -> Void in
                XCTFail()
            },
            request: testRequest,
            bridge: MockApiBridge(),
            graphQLSubscriptionsStreamHandler: MockStreamHandler()
        )
        wait(for: [eventSentExp!], timeout: 1)
    }
    
    func test_subscribe_api_error() throws {
        let testRequest: [String: Any] = [
            "document": "test document",
            "variables": ["test key":"test value"],
            "cancelToken" : "someCode"
        ]
        
        class MockApiBridge: ApiBridge {
            override func subscribe<ResultType>(request: GraphQLRequest<ResultType>,
                                       valueListener: GraphQLSubscriptionOperation<ResultType>.InProcessListener?,
                                       completionListener: GraphQLSubscriptionOperation<ResultType>.ResultListener?)
                  -> GraphQLSubscriptionOperation<ResultType> {
                completionListener?(.failure(APIError.invalidConfiguration("test error", "test recovery suggestion")))
                let graphQLSubscriptionOperation = getMockGraphQLSubscriptionOperation(request: request)
                return graphQLSubscriptionOperation
            }
        }
        
        class MockStreamHandler: GraphQLSubscriptionsStreamHandler {
            override func sendEvent(payload: [String : Any?]?, id: String, type: GraphQLSubscriptionEventTypes) {
                XCTFail()
            }
            
            override func sendError(msg: String, errorMap: [String: Any]) {
                XCTFail()
            }
        }
        
        
        FlutterGraphQLApi.subscribe(
            flutterResult: { (result) -> Void in
                if let exception = result as? FlutterError {
                    XCTAssertEqual("AmplifyException", exception.code)
                    XCTAssertEqual(FlutterApiErrorMessage.ESTABLISH_SUBSCRIPTION_FAILED.rawValue, exception.message)
                    let errorMap: [String: Any] = exception.details as! [String : Any]
                    XCTAssertEqual(
                        ["platform": "iOS", "localizedErrorMessage": "test error", "recoverySuggestion": "test recovery suggestion"],
                        errorMap["PLATFORM_EXCEPTIONS"] as? [String: String])
                } else {
                    XCTFail()
                }
            },
            request: testRequest,
            bridge: MockApiBridge(),
            graphQLSubscriptionsStreamHandler: MockStreamHandler()
        )
    }
    
    func test_subscribe_malformed_request_error() throws {
        let testRequest: [String: Any] = [:]
        
        class MockApiBridge: ApiBridge {
            override func subscribe<R>(request: GraphQLRequest<R>,
                                       valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?,
                                       completionListener: GraphQLSubscriptionOperation<R>.ResultListener?)
                  -> GraphQLSubscriptionOperation<R> {
                XCTFail("The ApiBridge should not be called if the request is malformed")
                
                let graphQLSubscriptionOperation = getMockGraphQLSubscriptionOperation(request: request)
                return graphQLSubscriptionOperation
            }
        }
        
        class MockStreamHandler: GraphQLSubscriptionsStreamHandler {
            override func sendEvent(payload: [String : Any?]?, id: String, type: GraphQLSubscriptionEventTypes) {
                XCTFail()
            }
            
            override func sendError(msg: String, errorMap: [String: Any]) {
                XCTFail()
            }
        }
        
        
        FlutterGraphQLApi.subscribe(
            flutterResult: { (result) -> Void in
                if let exception = result as? FlutterError {
                    XCTAssertEqual("AmplifyException", exception.code)
                    XCTAssertEqual(FlutterApiErrorMessage.MALFORMED.rawValue, exception.message)
                    let errorMap: [String: Any] = exception.details as! [String : Any]
                    XCTAssertEqual(
                        ["platform": "iOS", "localizedErrorMessage": "The graphQL document request argument was not passed as a String", "recoverySuggestion": "The request should include the graphQL document as a String"],
                        errorMap["PLATFORM_EXCEPTIONS"] as? [String: String])
                } else {
                    XCTFail()
                }
            },
            request: testRequest,
            bridge: MockApiBridge(),
            graphQLSubscriptionsStreamHandler: MockStreamHandler()
        )
    }
    
}

func getMockGraphQLOperation<R>(request: GraphQLRequest<R>) -> GraphQLOperation<R> {
    let operationRequest = GraphQLOperationRequest.init(apiName: request.apiName, operationType: GraphQLOperationType.mutation, document: request.document, responseType: R.self, options: GraphQLOperationRequest.Options())
    return GraphQLOperation<R>(categoryType: .api, eventName: operationRequest.operationType.hubEventName, request: operationRequest)
}

func getMockGraphQLSubscriptionOperation<R>(request: GraphQLRequest<R>) -> GraphQLSubscriptionOperation<R> {
    let operationRequest = GraphQLOperationRequest.init(apiName: request.apiName, operationType: GraphQLOperationType.mutation, document: request.document, responseType: R.self, options: GraphQLOperationRequest.Options())
    return GraphQLSubscriptionOperation<R>(categoryType: .api, eventName: operationRequest.operationType.hubEventName, request: operationRequest)
}
