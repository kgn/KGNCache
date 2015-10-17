//
//  KGNCacheTests.swift
//  KGNCacheTests
//
//  Created by David Keegan on 10/12/15.
//  Copyright © 2015 David Keegan. All rights reserved.
//

import XCTest
@testable import KGNCache

class KGNCacheTests: XCTestCase {

    var cache: Cache!

    override func setUp() {
        super.setUp()

        do {
            try self.cache = Cache(named: "test")
        } catch let error {
            XCTAssertNotNil(error, "error: \(error)")
        }
    }
    
    override func tearDown() {
        do {
            try self.cache.clearCache()
        } catch let error {
            XCTAssertNotNil(error, "error: \(error)")
        }

        super.tearDown()
    }
    
    func testString() {
        let value = "Steve Jobs"

        do {
            try self.cache.setObject(value, forKey: "name")
        } catch let error {
            XCTAssertNotNil(error, "error: \(error)")
        }

        do {
            try self.cache.objectForKey("name") {
                XCTAssertEqual($0 as? String, value)
            }
        } catch let error {
            XCTAssertNotNil(error, "error: \(error)")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
