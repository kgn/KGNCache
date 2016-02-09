# KGNCache

`KGNCache` is a memory and file based cache. If the object exists on the file system it’s returned from there and added to the memory cache. `KGNCache` uses `NSCache` under the hood for the memory cache so will automatically clear out objects under memory pressure.

[![iOS 8.0+](http://img.shields.io/badge/iOS-8.0%2B-blue.svg)]()
[![Xcode 7.0](http://img.shields.io/badge/Xcode-7.0-blue.svg)]()
[![Swift 2.0](http://img.shields.io/badge/Swift-2.0-blue.svg)]()
[![Release](https://img.shields.io/github/release/kgn/KGNCache.svg)](/releases)
[![Build Status](http://img.shields.io/badge/License-MIT-lightgrey.svg)](/LICENSE)

[![Build Status](https://travis-ci.org/kgn/KGNCache.svg)](https://travis-ci.org/kgn/KGNCache)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/KGNCache.svg)](https://cocoapods.org/pods/KGNCache)
[![CocoaPods Platforms](https://img.shields.io/cocoapods/p/KGNCache.svg)](https://cocoapods.org/pods/KGNCache)

[![Twitter](https://img.shields.io/badge/Twitter-@iamkgn-55ACEE.svg)](http://twitter.com/iamkgn)

## Installing

### Carthage
```
github "kgn/KGNCache"
```

### CocoaPods
```
pod 'KGNCache'
```

## Examples

``` Swift
let name = "Steve Jobs"

let cache = Cache(named: "names")
cache.setObject(name, forKey: "name")

cache.objectForKey(key) {
    print($0) // Steve Jobs
}
```

TODO:
- [ ] Travis (Figure out why tests are passing, but failing on Travis...)
- [ ] Badges (Create release)
- [X] Tests
- [X] Carthage
- [ ] CocoaPods (Just need to publish)
- [ ] Description (Add expiration example)
- [X] Documentation
