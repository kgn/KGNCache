# KGNCache

`KGNCache` is a memory and file based cache. If the object exists on the file system it’s returned from there and added to the memory cache. `KGNCache` uses `NSCache` under the hood for the memory cache so will automatically clear out objects under memory pressure.

[![Release](https://img.shields.io/github/release/kgn/KGNCache.svg)](/releases)
[![License](http://img.shields.io/badge/License-MIT-lightgrey.svg)](/LICENSE)

[![Build Status](https://travis-ci.org/kgn/KGNCache.svg)](https://travis-ci.org/kgn/KGNCache)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-Compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/KGNCache.svg)](https://cocoapods.org/pods/KGNCache)
[![CocoaPods Platforms](https://img.shields.io/cocoapods/p/KGNCache.svg)](https://cocoapods.org/pods/KGNCache)

[![Twitter](https://img.shields.io/badge/Twitter-@iamkgn-55ACEE.svg)](http://twitter.com/iamkgn)
[![Follow](https://img.shields.io/github/followers/kgn.svg?style=social&label=Follow%20%40kgn)](https://github.com/kgn)
[![Star](https://img.shields.io/github/stars/kgn/KGNCache.svg?style=social&label=Star)](https://github.com/kgn/KGNCache)

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
- [X] Travis
- [X] Badges
- [X] Tests
- [X] Carthage
- [ ] CocoaPods (Just need to publish)
- [ ] Description (Add expiration example)
- [X] Documentation
- [X] AppleTV
- [X] AppleWatch
- [X] Prebuilt Frameworks
- [ ] Travis Test Matrix
