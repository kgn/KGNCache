//
//  Cache.swift
//  Cache
//
//  Created by David Keegan on 8/12/15.
//  Copyright © 2015 David Keegan. All rights reserved.
//

import Foundation
//import CryptoSwift

private class CacheObject: NSObject, NSCoding {
    var key: String!
    var object: AnyObject!

    var date: Date!
    var expires: DateComponents?

    init(key: String, object: AnyObject, expires: DateComponents? = nil) {
        self.key = key
        self.object = object
        self.expires = expires
        self.date = Date()
    }

    @objc required init?(coder aDecoder: NSCoder) {
        if let key = aDecoder.decodeObject(forKey: "key") as? String {
            self.key = key
        }
        if let object = aDecoder.decodeObject(forKey: "object") {
            self.object = object
        }
        if let date = aDecoder.decodeObject(forKey: "date") as? Date {
            self.date = date
        }
        if let expires = aDecoder.decodeObject(forKey: "expires") as? DateComponents {
            self.expires = expires
        }
    }

    @objc private func encode(with aCoder: NSCoder) {
        aCoder.encode(self.key, forKey: "key")
        aCoder.encode(self.object, forKey: "object")
        aCoder.encode(self.expires, forKey: "expires")
        aCoder.encode(self.date, forKey: "date")
    }

    private func hasExpired() -> Bool {
        guard let components = self.expires else {
            return false
        }
        guard let calander = Calendar(calendarIdentifier: Calendar.Identifier.gregorian) else {
            return false
        }
        guard let componentsDate = calander.date(byAdding: components, to: self.date, options: []) else {
            return false
        }
        return (componentsDate.compare(Date()) != .orderedDescending)
    }
}

/// The location of where the cache data came from.
public enum CacheLocation {
    case memory
    case disk
}

public class Cache {

    private let cacheName: String!
    private let memoryCache = Foundation.Cache<AnyObject, CacheObject>()

    private func cacheDirectory(create: Bool = false) -> String? {
        guard let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }

        let cachePath = "\(cacheDirectory)/\(self.cacheName)"
        if create && !FileManager().fileExists(atPath: cachePath) {
            do {
                try FileManager().createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }

        return cachePath
    }

    private func object(fromCacheObject cacheObject: CacheObject?) -> AnyObject? {
        if cacheObject?.hasExpired() == true {
            return nil
        }
        return cacheObject?.object
    }

    internal func cacheObjectPath(withKeyHash keyHash: String) -> String? {
        guard let cacheDirectory = self.cacheDirectory() else {
            return nil
        }

        return "\(cacheDirectory)/\(keyHash)"
    }

    private func removeFileItem(atPath path: String) -> Bool? {
        do {
            try FileManager().removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    internal func hash(forKey key: String) -> String {
        return key//key.sha1()
    }

    // MARK: - Public Methods

    /**
     Create a `Cache` object. This sets up both the memory and disk cache.

     - Parameter named: The name of the cache.
     */
    public init(named: String) {
        self.cacheName = "\(Bundle.main().bundleIdentifier ?? "kgn.cache").\(named)"
        _ = self.cacheDirectory(create: true)
    }

    /**
     Retrieve an object from the cache by it's key.

     - Parameter key: The key of the object in the cache.
     - Parameter callback: The method to call with the retrieved object from the cache.
     The retrieved object may be nil if an object for the given key does not exist, or if it has expired.
     */
    public func object(forKey key: String, callback: (object: AnyObject?, location: CacheLocation?) -> Void) {
        let keyHash = self.hash(forKey: key)

        if let cacheObject = self.memoryCache.object(forKey: keyHash) {
            callback(object: self.object(fromCacheObject: cacheObject), location: .memory)
            return
        }

        guard let cacheObjectPath = self.cacheObjectPath(withKeyHash: keyHash) else {
            callback(object: nil, location: nil)
            return
        }

        if FileManager().fileExists(atPath: cacheObjectPath) {
            DispatchQueue.global(attributes: .qosDefault).async { [weak self] in
                if let cacheObject = NSKeyedUnarchiver.unarchiveObject(withFile: cacheObjectPath) as? CacheObject {
                    self?.memoryCache.setObject(cacheObject, forKey: keyHash)
                    callback(object: self?.object(fromCacheObject: cacheObject), location: .disk)
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
    public func set(object: AnyObject, forKey key: String, expires: DateComponents? = nil, callback: ((location: CacheLocation?) -> Void)? = nil) {
        let keyHash = self.hash(forKey: key)
        let cacheObject = CacheObject(key: key, object: object, expires: expires)

        self.memoryCache.setObject(cacheObject, forKey: keyHash)

        guard let cacheObjectPath = self.cacheObjectPath(withKeyHash: keyHash) else {
            callback?(location: .memory)
            return
        }

        let data = NSKeyedArchiver.archivedData(withRootObject: cacheObject)
        DispatchQueue.global(attributes: .qosDefault).async {
            if (try? data.write(to: URL(fileURLWithPath: cacheObjectPath), options: [.dataWritingAtomic])) != nil {
                callback?(location: .disk)
            } else {
                callback?(location: .memory)
            }
        }
    }

    /**
     Remove an object from the cache.

     - Parameter forKey: The key of the object in the cache.
     */
    public func removeObject(forKey key: String) {
        let keyHash = self.hash(forKey: key)
        self.memoryCache.removeObject(forKey: keyHash)
        if let cacheObjectPath = self.cacheObjectPath(withKeyHash: keyHash) {
            _ = self.removeFileItem(atPath: cacheObjectPath)
        }
    }

    /// Remove all objects from the cache.
    public func clearCache() {
        self.memoryCache.removeAllObjects()
        if let cacheDirectory = self.cacheDirectory() {
            _ = self.removeFileItem(atPath: cacheDirectory)
        }
    }

}
