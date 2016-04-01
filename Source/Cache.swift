//
//  Cache.swift
//  Cache
//
//  Created by David Keegan on 8/12/15.
//  Copyright © 2015 David Keegan. All rights reserved.
//

import Foundation
import CryptoSwift
import KGNThread

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

    private func hasExpired() -> Bool {
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

/// The location of where the cache data came from.
public enum CacheLocation {
    case Memory
    case Disk
}

public class Cache {

    private let cacheName: String!
    private let memoryCache = NSCache()

    private func cacheDirectory(create create: Bool = false) -> String? {
        guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
            return nil
        }

        let cachePath = "\(cacheDirectory)/\(self.cacheName)"
        if create && !NSFileManager().fileExistsAtPath(cachePath) {
            do {
                try NSFileManager().createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }

        return cachePath
    }

    private func objectFromCacheObject(cacheObject: CacheObject?) -> AnyObject? {
        if cacheObject?.hasExpired() == true {
            return nil
        }
        return cacheObject?.object
    }

    internal func cacheObjectPath(keyHash: String) -> String? {
        guard let cacheDirectory = self.cacheDirectory() else {
            return nil
        }

        return "\(cacheDirectory)/\(keyHash)"
    }

    private func removeFileItem(path: String) -> Bool? {
        do {
            try NSFileManager().removeItemAtPath(path)
            return true
        } catch {
            return false
        }
    }

    internal func keyHash(key: String) -> String {
        return key.sha1()
    }

    // MARK: - Public Methods

    /**
     Create a `Cache` object. This sets up both the memory and disk cache.

     - Parameter named: The name of the cache.
     */
    public init(named: String) {
        self.cacheName = "\(NSBundle.mainBundle().bundleIdentifier ?? "kgn.cache").\(named)"
        self.cacheDirectory(create: true)
    }

    /**
     Retrieve an object from the cache by it's key.

     - Parameter key: The key of the object in the cache.
     - Parameter callback: The method to call with the retrieved object from the cache.
     The retrieved object may be nil if an object for the given key does not exist, or if it has expired.
     */
    public func objectForKey(key: String, callback: (object: AnyObject?, location: CacheLocation?) -> Void) {
        let keyHash = self.keyHash(key)

        if let cacheObject = self.memoryCache.objectForKey(keyHash) as? CacheObject {
            callback(object: self.objectFromCacheObject(cacheObject), location: .Memory)
            return
        }

        guard let cacheObjectPath = self.cacheObjectPath(keyHash) else {
            callback(object: nil, location: nil)
            return
        }

        if NSFileManager().fileExistsAtPath(cacheObjectPath) {
            Thread.Disk { [weak self] in
                if let cacheObject = NSKeyedUnarchiver.unarchiveObjectWithFile(cacheObjectPath) as? CacheObject {
                    self?.memoryCache.setObject(cacheObject, forKey: keyHash)
                    callback(object: self?.objectFromCacheObject(cacheObject), location: .Disk)
                } else {
                    callback(object: nil, location: nil)
                }
            }
        } else {
            callback(object: nil, location: nil)
        }
    }

    /**
     Store an object in the cache for a given key. 
     An optional expiration date components object may be set if the object should expire.

     - Parameter object: The object to store in the cache.
     - Parameter forKey: The key of the object in the cache.
     - Parameter expires: An optional date components object that defines how long the object should be cached for.
     - Parameter callback: This method is called when the object has been stored.
     */
    public func setObject(object: AnyObject, forKey key: String, expires: NSDateComponents? = nil, callback: ((location: CacheLocation?) -> Void)? = nil) {
        let keyHash = self.keyHash(key)
        let cacheObject = CacheObject(key: key, object: object, expires: expires)

        self.memoryCache.setObject(cacheObject, forKey: keyHash)

        guard let cacheObjectPath = self.cacheObjectPath(keyHash) else {
            callback?(location: nil)
            return
        }

        let data = NSKeyedArchiver.archivedDataWithRootObject(cacheObject)
        Thread.Disk {
            data.writeToFile(cacheObjectPath, atomically: true)
            callback?(location: .Disk)
        }
    }

    /**
     Remove an object from the cache.

     - Parameter forKey: The key of the object in the cache.
     */
    public func removeObjectForKey(key: String) {
        let keyHash = self.keyHash(key)
        self.memoryCache.removeObjectForKey(keyHash)
        if let cacheObjectPath = self.cacheObjectPath(keyHash) {
            self.removeFileItem(cacheObjectPath)
        }
    }

    /// Remove all objects from the cache.
    public func clearCache() {
        self.memoryCache.removeAllObjects()
        if let cacheDirectory = self.cacheDirectory() {
            self.removeFileItem(cacheDirectory)
        }
    }

}
