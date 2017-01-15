//
//  Cache.swift
//  Cache
//
//  Created by David Keegan on 8/12/15.
//  Copyright © 2015 David Keegan. All rights reserved.
//

import Foundation
import Crypto

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
            self.object = object as AnyObject!
        }
        if let date = aDecoder.decodeObject(forKey: "date") as? Date {
            self.date = date
        }
        if let expires = aDecoder.decodeObject(forKey: "expires") as? DateComponents {
            self.expires = expires
        }
    }

    @objc fileprivate func encode(with aCoder: NSCoder) {
        aCoder.encode(self.key, forKey: "key")
        aCoder.encode(self.object, forKey: "object")
        aCoder.encode(self.expires, forKey: "expires")
        aCoder.encode(self.date, forKey: "date")
    }

    fileprivate func hasExpired() -> Bool {
        guard let components = self.expires else {
            return false
        }
        
        let calander = Calendar(identifier: .gregorian)
        guard let componentsDate = calander.date(byAdding: components, to: self.date, wrappingComponents: false) else {
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

open class Cache {

    private let cacheName: String!
    private let memoryCache = NSCache<AnyObject, CacheObject>()

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

    internal func hash(forKey key: String) -> String? {
        return key.sha1
    }

    // MARK: - Public Methods

    /**
     Create a `Cache` object. This sets up both the memory and disk cache.

     - Parameter named: The name of the cache.
     */
    public init(named: String) {
        self.cacheName = "\(Bundle.main.bundleIdentifier ?? "kgn.cache").\(named)"
        _ = self.cacheDirectory(create: true)
    }

    /**
     Retrieve an object from the cache by it's key.

     - Parameter key: The key of the object in the cache.
     - Parameter callback: The method to call with the retrieved object from the cache.
     The retrieved object may be nil if an object for the given key does not exist, or if it has expired.
     */
    open func object(forKey key: String, callback: @escaping (_ object: AnyObject?, _ location: CacheLocation?) -> Void) {
        guard let keyHash = self.hash(forKey: key) else {
            callback(nil, nil)
            return
        }

        if let cacheObject = self.memoryCache.object(forKey: keyHash as AnyObject) {
            callback(self.object(fromCacheObject: cacheObject), .memory)
            return
        }

        guard let cacheObjectPath = self.cacheObjectPath(withKeyHash: keyHash) else {
            callback(nil, nil)
            return
        }

        DispatchQueue.global().async { [weak self] in
            if FileManager().fileExists(atPath: cacheObjectPath) {
                if let cacheObject = NSKeyedUnarchiver.unarchiveObject(withFile: cacheObjectPath) as? CacheObject {
                    self?.memoryCache.setObject(cacheObject, forKey: keyHash as AnyObject)
                    callback(self?.object(fromCacheObject: cacheObject), .disk)
                } else {
                    callback(nil, nil)
                }
            } else {
                callback(nil, nil)
            }
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
    open func set(object: AnyObject, forKey key: String, expires: DateComponents? = nil, callback: ((_ location: CacheLocation?) -> Void)? = nil) {
        guard let keyHash = self.hash(forKey: key) else {
            callback?(nil)
            return
        }
        
        let cacheObject = CacheObject(key: key, object: object, expires: expires)

        self.memoryCache.setObject(cacheObject, forKey: keyHash as AnyObject)

        guard let cacheObjectPath = self.cacheObjectPath(withKeyHash: keyHash) else {
            callback?(.memory)
            return
        }

        DispatchQueue.global().async {
            let data = NSKeyedArchiver.archivedData(withRootObject: cacheObject)
            if (try? data.write(to: URL(fileURLWithPath: cacheObjectPath), options: [.atomic])) != nil {
                callback?(.disk)
            } else {
                callback?(.memory)
            }
        }
    }

    /**
     Remove an object from the cache.

     - Parameter forKey: The key of the object in the cache.
     */
    open func removeObject(forKey key: String) {
        guard let keyHash = self.hash(forKey: key) else {
            return
        }
        
        self.memoryCache.removeObject(forKey: keyHash as AnyObject)
        if let cacheObjectPath = self.cacheObjectPath(withKeyHash: keyHash) {
            DispatchQueue.global().async {
                try? FileManager().removeItem(atPath: cacheObjectPath)
            }
        }
    }

    /// Remove all objects from the cache.
    open func clear() {
        self.memoryCache.removeAllObjects()
        if let cacheDirectory = self.cacheDirectory() {
            DispatchQueue.global().async {
                try? FileManager().removeItem(atPath: cacheDirectory)
            }
        }
    }

}
