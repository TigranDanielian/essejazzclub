//
//  ApiTests.swift
//  Tests
//
//  Created by Tigran Danielian on 14.05.2025.
//

import XCTest
import Combine
//@testable import Services
@testable import API

final class APITests: XCTestCase {
    var mockClient: MockAPIClient!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        mockClient = MockAPIClient()
    }

    override func tearDown() {
        mockClient = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testRequestData_Success() {
        let jsonData = Data()
        mockClient.responseData = jsonData

        struct User: Decodable { let name: String }
        let endpoint = ApiEndpoint(method: .get, path: "/user")
        let expectation = XCTestExpectation(description: "Request should succeed")

        mockClient.request(endpoint: endpoint)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got error: \(error)")
                }
            }, receiveValue: { data in
                XCTAssertNotNil(data)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRequestModel_Success() {
        let jsonData = "{\"name\": \"Jane Doe\"}".data(using: .utf8)!
        mockClient.responseData = jsonData

        struct User: Decodable { let name: String }
        let endpoint = ApiEndpoint(method: .get, path: "/user")
        let expectation = XCTestExpectation(description: "Request should succeed")

        mockClient.requestModel(endpoint: endpoint)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got error: \(error)")
                }
            }, receiveValue: { (user: User) in
                XCTAssertEqual(user.name, "Jane Doe")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

//    func testRequest_Error() async throws {
//        mockClient.error = .invalidURL
//
//        struct User: Decodable { let name: String }
//        let endpoint = ApiEndpoint(method: .get, path: "/user")
//
//        do {
//            let _: User = try await mockClient.request(endpoint, as: User.self)
//            XCTFail("Expected error but got success")
//        } catch {
//            XCTAssertEqual(error as? NetworkError, .invalidURL)
//        }
//    }
}

