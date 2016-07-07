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

    required init?(coder aDecoder: NSCoder) {
        if let int = aDecoder.decodeObject(forKey: "int") as? Int {
            self.int = int
        }
        if let double = aDecoder.decodeObject(forKey: "double") as? Double {
            self.double = double
        }
        if let string = aDecoder.decodeObject(forKey: "string") as? String {
            self.string = string
        }
        if let date = aDecoder.decodeObject(forKey: "date") as? NSDate {
            self.date = date
        }
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.int, forKey: "int")
        aCoder.encode(self.double, forKey: "double")
        aCoder.encode(self.string, forKey: "string")
        aCoder.encode(self.date, forKey: "date")
    }
}

class KGNCacheTests: XCTestCase {

    var cache = Cache(named: "test")

    func runCacheTest(key: String, object: AnyObject, callback: (cacheObject: AnyObject?) -> Void) {
        let setObjectExpectation = self.expectation(withDescription: "\(key).\(object).setObject")
        self.cache.set(object: object, forKey: key) { location in
            XCTAssertEqual(location, CacheLocation.disk)
            setObjectExpectation.fulfill()
        }

        let objectForKeyExpectation = self.expectation(withDescription: "\(key).\(object).objectForKey")
        self.cache.object(forKey: key) { cacheObject, location in
            callback(cacheObject: cacheObject)
            self.cache.clearCache()
            objectForKeyExpectation.fulfill()
        }

        let removeObjectForKeyExpectation = self.expectation(withDescription: "\(key).\(object).removeObjectForKey")
        self.cache.removeObject(forKey: key)
        self.cache.object(forKey: key) { cacheObject, location in
            XCTAssertNil(cacheObject)
            removeObjectForKeyExpectation.fulfill()
        }

        self.waitForExpectations(withTimeout: 2, handler: nil)
    }

    func testKeyHash() {
        let cache = Cache(named: "hash")
        XCTAssertEqual(cache.hash(forKey: "name"), "6ae999552a0d2dca14d62e2bc8b764d377b1dd6c")
        XCTAssertEqual(cache.hash(forKey: "123567890"), "11b730ae8337329ad82603e5f6f31eda371cd6e6")
        XCTAssertEqual(cache.hash(forKey: "The quick brown fox jumps over the lazy dog."), "408d94384216f890ff7a0c3528e8bed1e0b01621")
    }

    func testInt() {
        let negative = -35
        self.runCacheTest(key: #function, object: negative) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, negative)
        }

        let zero = 0
        self.runCacheTest(key: #function, object: zero) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, zero)
        }

        let seven = 7
        self.runCacheTest(key: #function, object: seven) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, seven)
        }

        let three = 432
        self.runCacheTest(key: #function, object: three) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, three)
        }

        let six = 100_000
        self.runCacheTest(key: #function, object: six) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, six)
        }
    }

    func testDouble() {
        let zero: Double = 0
        self.runCacheTest(key: #function, object: zero) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, zero)
        }

        let pi: Double = 3.14
        self.runCacheTest(key: #function, object: pi) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, pi)
        }

        let three: Double = 423.534
        self.runCacheTest(key: #function, object: three) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, three)
        }

        let six: Double = 23423.542434
        self.runCacheTest(key: #function, object: six) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, six)
        }
    }

    func testString() {
        let blank = ""
        self.runCacheTest(key: #function, object: blank) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, blank)
        }

        let name = "Steve Jobs"
        self.runCacheTest(key: #function, object: name) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, name)
        }

        let sentence = "The quick brown fox jumps over the lazy dog"
        self.runCacheTest(key: #function, object: sentence) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, sentence)
        }
    }

    func testObject() {
        let object1 = TestObject(int: 12, double: 3.14, string: "Hello World", date: NSDate())
        let object2 = TestObject(int: 21, double: 41.3, string: "World Hello", date: NSDate())
        self.runCacheTest(key: #function, object: object1) {
            XCTAssertNotEqual($0 as? TestObject, object2)
            XCTAssertEqual($0 as? TestObject, object1)
        }
    }


    func testArray() {
        let ints = [1, 2, 3]
        self.runCacheTest(key: #function, object: ints) {
            XCTAssertNotEqual($0 as! [Int], [])
            XCTAssertEqual($0 as! [Int], ints)
        }

        let doubles = [1.1, 2.2, 3.3]
        self.runCacheTest(key: #function, object: doubles) {
            XCTAssertEqual($0 as! [Double], doubles)
        }

        let strings = ["this", "is", "a", "test"]
        self.runCacheTest(key: #function, object: strings) {
            XCTAssertEqual($0 as! [String], strings)
        }
    }

    func testExpires() {
        let one = 1
        let key = "One"

        let delay = 1
        var dateComponents = DateComponents()
        dateComponents.second = delay
        self.cache.set(object: one, forKey: key, expires: dateComponents)

        let expectation1 = self.expectation(withDescription: "\(#function)1")
        self.cache.object(forKey: key) { object, location in
            XCTAssertEqual(object as? Int, one)
            expectation1.fulfill()
        }

        let expectation2 = self.expectation(withDescription: "\(#function)2")
        DispatchQueue.main.after(when: .now() + TimeInterval(delay)) {
            self.cache.object(forKey: key) { object, location in
                XCTAssertNil(object)
                expectation2.fulfill()
            }
        }

        self.waitForExpectations(withTimeout: TimeInterval(delay+1), handler: nil)
    }
    
}
