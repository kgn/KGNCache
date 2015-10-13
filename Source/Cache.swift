//
//  Cache.swift
//  Tilt
//
//  Created by David Keegan on 8/12/15.
//  Copyright © 2015 David Keegan. All rights reserved.
//

import UIKit
import CryptoSwift

private let diskQueue = dispatch_queue_create("com.davidkeegan.KGNCache.disk", DISPATCH_QUEUE_SERIAL)

extension String {
    func sha1() -> String? {
        guard let data = self.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        guard let hash = Hash.md5(data).calculate() else {
            return nil
        }
        return hash.toHexString()
    }
}

private class CacheObject: NSObject, NSCoding {
    var key: String!
    var object: AnyObject!

    var date: NSDate!
    var expires: NSDateComponents?

    init(key: String, object: AnyObject, expires: NSDateComponents? = nil) {
        self.key = key
        self.object = object
        self.expires = expires
        self.date = NSDate()
    }

    @objc required init?(coder aDecoder: NSCoder) {
        if let key = aDecoder.decodeObjectForKey("key") as? String {
            self.key = key
        }
        if let object = aDecoder.decodeObjectForKey("object") {
            self.object = object
        }
        if let date = aDecoder.decodeObjectForKey("date") as? NSDate {
            self.date = date
        }
        if let expires = aDecoder.decodeObjectForKey("expires") as? NSDateComponents {
            self.expires = expires
        }
    }

    @objc private func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.key, forKey: "key")
        aCoder.encodeObject(self.object, forKey: "object")
        aCoder.encodeObject(self.expires, forKey: "expires")
        aCoder.encodeObject(self.date, forKey: "date")
    }

    func hasExpired() -> Bool {
        guard let components = self.expires else {
            return false
        }
        guard let calander = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) else {
            return false
        }
        guard let componentsDate = calander.dateByAddingComponents(components, toDate: self.date, options: []) else {
            return false
        }
        return (componentsDate.compare(NSDate()) != .OrderedDescending)
    }
}

public enum CacheError: ErrorType {
    case NoCacheDirectory
    case UnableToHashKey
}

public class Cache {

    var cacheName: String

    private let memoryCache = NSCache()

    private func cacheDirectory(create: Bool = false) throws -> String {
        guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
            throw CacheError.NoCacheDirectory
        }

        let cachePath = "\(cacheDirectory)/\(self.cacheName)"
        if create && !NSFileManager().fileExistsAtPath(cachePath) {
            try NSFileManager().createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil)
        }

        return cachePath
    }

    public init(named: String? = nil) {
        var cacheName = NSBundle.mainBundle().bundleIdentifier
        if named != nil {
            cacheName = "\(cacheName!).\(named!)"
        }
        self.cacheName = cacheName!
    }

    public func setup() throws {
        try self.cacheDirectory(true)
    }

    private func objectFromCacheObject(cacheObject: CacheObject?) -> AnyObject? {
        if cacheObject?.hasExpired() == true {
            return nil
        }
        return cacheObject?.object
    }

    public func objectForKey(key: String, callback: (object: AnyObject?) -> Void) throws {
        guard let keyHash = key.sha1() else {
            throw CacheError.UnableToHashKey
        }

        if let cacheObject = self.memoryCache.objectForKey(keyHash) as? CacheObject {
            callback(object: self.objectFromCacheObject(cacheObject))
            return
        }

        let cacheDirectory = try self.cacheDirectory()
        let cacheObjectPath = "\(cacheDirectory)/\(keyHash)"
        if NSFileManager().fileExistsAtPath(cacheObjectPath) {
            dispatch_async(diskQueue, {
                if let cacheObject = NSKeyedUnarchiver.unarchiveObjectWithFile(cacheObjectPath) as? CacheObject {
                    self.memoryCache.setObject(cacheObject, forKey: keyHash)
                    callback(object: self.objectFromCacheObject(cacheObject))
                } else {
                    callback(object: nil)
                }
            })
        } else {
            callback(object: nil)
        }
    }

    public func setObject(object: AnyObject, forKey key: String, expires: NSDateComponents? = nil) throws {
        guard let keyHash = key.sha1() else {
            throw CacheError.UnableToHashKey
        }

        let cacheObject = CacheObject(key: key, object: object, expires: expires)

        self.memoryCache.setObject(cacheObject, forKey: keyHash)

        let cacheDirectory = try self.cacheDirectory()
        let cacheObjectPath = "\(cacheDirectory)/\(keyHash)"
        let data = NSKeyedArchiver.archivedDataWithRootObject(cacheObject)
        dispatch_async(diskQueue, {
            data.writeToFile(cacheObjectPath, atomically: true)
        })
    }

    public func removeObjectForKey(key: String) throws {
        guard let keyHash = key.sha1() else {
            throw CacheError.UnableToHashKey
        }

        self.memoryCache.removeObjectForKey(keyHash)

        let cacheDirectory = try self.cacheDirectory()
        let cacheObjectPath = "\(cacheDirectory)/\(keyHash)"
        try NSFileManager().removeItemAtPath(cacheObjectPath)
    }

    public func clearCache() throws {
        self.memoryCache.removeAllObjects()
        try NSFileManager().removeItemAtPath(self.cacheDirectory())
        try self.cacheDirectory(true)
    }

}
