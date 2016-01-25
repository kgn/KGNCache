//
//  KGNCacheTests.swift
//  KGNCacheTests
//
//  Created by David Keegan on 10/12/15.
//  Copyright © 2015 David Keegan. All rights reserved.
//

// TODO: Test memory cache
// TODO: Test disk cache

import XCTest
@testable import KGNCache

class TestObject: NSObject, NSCoding {
    var int: Int!
    var double: Double!
    var string: String!
    var date: NSDate!

    init(int: Int, double: Double, string: String, date: NSDate) {
        self.int = int
        self.double = double
        self.string = string
        self.date = NSDate()
    }

    @objc required init?(coder aDecoder: NSCoder) {
        if let int = aDecoder.decodeObjectForKey("int") as? Int {
            self.int = int
        }
        if let double = aDecoder.decodeObjectForKey("double") as? Double {
            self.double = double
        }
        if let string = aDecoder.decodeObjectForKey("string") as? String {
            self.string = string
        }
        if let date = aDecoder.decodeObjectForKey("date") as? NSDate {
            self.date = date
        }
    }

    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.int, forKey: "int")
        aCoder.encodeObject(self.double, forKey: "double")
        aCoder.encodeObject(self.string, forKey: "string")
        aCoder.encodeObject(self.date, forKey: "date")
    }
}

class KGNCacheTests: XCTestCase {

    var cache = Cache(named: "test")

    func runCacheTest(key: String, object: AnyObject, callback: (cacheObject: AnyObject?) -> Void) {
        let setObjectExpectation = expectationWithDescription("\(key).\(object).setObject")
        self.cache.setObject(object, forKey: key) { location in
            XCTAssertEqual(location, .Disk)
            setObjectExpectation.fulfill()
        }

        let objectForKeyExpectation = expectationWithDescription("\(key).\(object).objectForKey")
        self.cache.objectForKey(key) { cacheObject, location in
            callback(cacheObject: cacheObject)
            self.cache.clearCache()
            objectForKeyExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testInt() {
        let negative = -35
        self.runCacheTest(__FUNCTION__, object: negative) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, negative)
        }

        let zero = 0
        self.runCacheTest(__FUNCTION__, object: zero) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, zero)
        }

        let seven = 7
        self.runCacheTest(__FUNCTION__, object: seven) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, seven)
        }

        let three = 432
        self.runCacheTest(__FUNCTION__, object: three) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, three)
        }

        let six = 100_000
        self.runCacheTest(__FUNCTION__, object: six) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, six)
        }
    }

    func testDouble() {
        let zero: Double = 0
        self.runCacheTest(__FUNCTION__, object: zero) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, zero)
        }

        let pi: Double = 3.14
        self.runCacheTest(__FUNCTION__, object: pi) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, pi)
        }

        let three: Double = 423.534
        self.runCacheTest(__FUNCTION__, object: three) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, three)
        }

        let six: Double = 23423.542434
        self.runCacheTest(__FUNCTION__, object: six) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, six)
        }
    }

    func testString() {
        let blank = ""
        self.runCacheTest(__FUNCTION__, object: blank) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, blank)
        }

        let name = "Steve Jobs"
        self.runCacheTest(__FUNCTION__, object: name) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, name)
        }

        let sentence = "The quick brown fox jumps over the lazy dog"
        self.runCacheTest(__FUNCTION__, object: sentence) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, sentence)
        }
    }

    func testObject() {
        let object1 = TestObject(int: 12, double: 3.14, string: "Hello World", date: NSDate())
        let object2 = TestObject(int: 21, double: 41.3, string: "World Hello", date: NSDate())
        self.runCacheTest(__FUNCTION__, object: object1) {
            XCTAssertNotEqual($0 as? TestObject, object2)
            XCTAssertEqual($0 as? TestObject, object1)
        }
    }


    func testArray() {
        let ints = [1, 2, 3]
        self.runCacheTest(__FUNCTION__, object: ints) {
            XCTAssertNotEqual($0 as! [Int], [])
            XCTAssertEqual($0 as! [Int], ints)
        }

        let doubles = [1.1, 2.2, 3.3]
        self.runCacheTest(__FUNCTION__, object: doubles) {
            XCTAssertEqual($0 as! [Double], doubles)
        }

        let strings = ["this", "is", "a", "test"]
        self.runCacheTest(__FUNCTION__, object: strings) {
            XCTAssertEqual($0 as! [String], strings)
        }
    }
    
}
