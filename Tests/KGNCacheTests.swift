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
    var date: Date!

    init(int: Int, double: Double, string: String, date: Date) {
        self.int = int
        self.double = double
        self.string = string
        self.date = Date()
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
        if let date = aDecoder.decodeObject(forKey: "date") as? Date {
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

    func runCacheTest(forKey key: String, object: AnyObject, callback: @escaping (_ cacheObject: AnyObject?) -> Void) {
        let setObjectExpectation = self.expectation(description: "\(key).\(object).setObject")
        self.cache.set(object: object, forKey: key) { location in
            XCTAssertEqual(location, CacheLocation.disk)
            setObjectExpectation.fulfill()
        }

        let objectForKeyExpectation = self.expectation(description: "\(key).\(object).objectForKey")
        self.cache.object(forKey: key) { [weak self] cacheObject, location in
            callback(cacheObject)
            self?.cache.removeObject(forKey: key)
            objectForKeyExpectation.fulfill()
        }

        let removeObjectForKeyExpectation = self.expectation(description: "\(key).\(object).removeObjectForKey")
        self.cache.removeObject(forKey: key)
        self.cache.object(forKey: key) { cacheObject, location in
            XCTAssertNil(cacheObject)
            removeObjectForKeyExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 2, handler: nil)
    }

    func testKeyHash() {
        let cache = Cache(named: "hash")
        XCTAssertEqual(cache.hash(forKey: "name"), "6ae999552a0d2dca14d62e2bc8b764d377b1dd6c")
        XCTAssertEqual(cache.hash(forKey: "123567890"), "11b730ae8337329ad82603e5f6f31eda371cd6e6")
        XCTAssertEqual(cache.hash(forKey: "The quick brown fox jumps over the lazy dog."), "408d94384216f890ff7a0c3528e8bed1e0b01621")
    }

    func testInt() {
        let negative = -35
        self.runCacheTest(forKey: #function, object: negative as AnyObject) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, negative)
        }

        let zero = 0
        self.runCacheTest(forKey: #function, object: zero as AnyObject) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, zero)
        }

        let seven = 7
        self.runCacheTest(forKey: #function, object: seven as AnyObject) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, seven)
        }

        let three = 432
        self.runCacheTest(forKey: #function, object: three as AnyObject) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, three)
        }

        let six = 100_000
        self.runCacheTest(forKey: #function, object: six as AnyObject) {
            XCTAssertNotEqual($0 as? Int, 12)
            XCTAssertEqual($0 as? Int, six)
        }
    }

    func testDouble() {
        let zero: Double = 0
        self.runCacheTest(forKey: #function, object: zero as AnyObject) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, zero)
        }

        let pi: Double = 3.14
        self.runCacheTest(forKey: #function, object: pi as AnyObject) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, pi)
        }

        let three: Double = 423.534
        self.runCacheTest(forKey: #function, object: three as AnyObject) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, three)
        }

        let six: Double = 23423.542434
        self.runCacheTest(forKey: #function, object: six as AnyObject) {
            XCTAssertNotEqual($0 as? Double, 12)
            XCTAssertEqual($0 as? Double, six)
        }
    }

    func testString() {
        let blank = ""
        self.runCacheTest(forKey: #function, object: blank as AnyObject) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, blank)
        }

        let name = "Steve Jobs"
        self.runCacheTest(forKey: #function, object: name as AnyObject) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, name)
        }

        let sentence = "The quick brown fox jumps over the lazy dog"
        self.runCacheTest(forKey: #function, object: sentence as AnyObject) {
            XCTAssertNotEqual($0 as? String, "something")
            XCTAssertEqual($0 as? String, sentence)
        }
    }

    func testObject() {
        let object1 = TestObject(int: 12, double: 3.14, string: "Hello World", date: Date())
        let object2 = TestObject(int: 21, double: 41.3, string: "World Hello", date: Date())
        self.runCacheTest(forKey: #function, object: object1) {
            XCTAssertNotEqual($0 as? TestObject, object2)
            XCTAssertEqual($0 as? TestObject, object1)
        }
    }


    func testArray() {
        let ints = [1, 2, 3]
        self.runCacheTest(forKey: #function, object: ints as AnyObject) {
            XCTAssertNotEqual($0 as! [Int], [])
            XCTAssertEqual($0 as! [Int], ints)
        }

        let doubles = [1.1, 2.2, 3.3]
        self.runCacheTest(forKey: #function, object: doubles as AnyObject) {
            XCTAssertEqual($0 as! [Double], doubles)
        }

        let strings = ["this", "is", "a", "test"]
        self.runCacheTest(forKey: #function, object: strings as AnyObject) {
            XCTAssertEqual($0 as! [String], strings)
        }
    }

    func testExpires() {
        let one = 1
        let key = "One"

        let delay = 1
        var dateComponents = DateComponents()
        dateComponents.second = delay
        self.cache.set(object: one as AnyObject, forKey: key, expires: dateComponents)

        let expectation1 = self.expectation(description: "\(#function)1")
        self.cache.object(forKey: key) { object, location in
            XCTAssertEqual(object as? Int, one)
            expectation1.fulfill()
        }

        let expectation2 = self.expectation(description: "\(#function)2")
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(delay)) {
            self.cache.object(forKey: key) { object, location in
                XCTAssertNil(object)
                expectation2.fulfill()
            }
        }

        self.waitForExpectations(timeout: TimeInterval(delay+1), handler: nil)
    }
    
    func testClearCache() {
        let key = "hello"
        let value = "Hello World"
        self.cache.set(object: value as AnyObject, forKey: key)
        
        let expectation1 = self.expectation(description: "\(#function)1")
        self.cache.object(forKey: key) { object, location in
            XCTAssertEqual(object as? String, value)
            expectation1.fulfill()
        }
        
        self.cache.clear()
        
        let expectation2 = self.expectation(description: "\(#function)2")
        self.cache.object(forKey: key) { object, location in
            XCTAssertNil(object)
            expectation2.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
}
