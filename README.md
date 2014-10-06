# EDHFinder

[![Version](https://img.shields.io/cocoapods/v/EDHFinder.svg?style=flat)](http://cocoadocs.org/docsets/EDHFinder)
[![License](https://img.shields.io/cocoapods/l/EDHFinder.svg?style=flat)](http://cocoadocs.org/docsets/EDHFinder)
[![Platform](https://img.shields.io/cocoapods/p/EDHFinder.svg?style=flat)](http://cocoadocs.org/docsets/EDHFinder)

File management interface for iOS, developed for [Edhita](https://github.com/tnantoka/edhita).  
EDHFinder is available through [CocoaPods](http://cocoapods.org).

![](/screenshot.png)

## Requirements

* iOS 8.0

## Demo

```
pod try EDHFinder
```

## Installation

With [CocoaPods](http://cocoapods.org).

```
# Podfile
pod 'EDHFinder', '~> 0.1'
```

```
$ pod install
```

## Usage

```
#import "EDHFinder.h"

UINavigationController *navController = [[EDHFinder sharedFinder] listNavigationControllerWithDelegate:detailController];
```

See also [Example](/Example).

## Author

[tnantoka](https://twitter.com/tnantoka)

## License

The MIT license

