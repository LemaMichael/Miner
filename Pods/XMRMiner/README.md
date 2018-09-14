# XMRMiner

XMRMiner is an embeddable [Monero](https://getmonero.org/) miner written in Swift. It can be used to repurpose old iPhones/iPads, or as an alternative to in-app ads as a means for generating revenue. *Use it responsibly.*

[![Version](https://img.shields.io/cocoapods/v/XMRMiner.svg?style=flat)](http://cocoapods.org/pods/XMRMiner)

![Miner Working](./Assets/xmrminer.gif)

## Why Monero?

There are a [lot of reasons](https://www.monero.how/why-monero-vs-bitcoin). More importantly, however, it can be mined profitably on low-end CPUs which makes it perfect for the ARM chips in iPhones and iPads. It's also the currency similar [web-based offerings](https://coin-hive.com) use.

We tested it on a variety of devices. As an example, an iPhone 7 Plus can operate at a hashrate of 50 H/s when the library is compiled with the `-Ofast` optimization profile. At the time of this writing, that means it will generate approximately $2.37/month according to [this calculator](https://www.cryptocompare.com/mining/calculator/xmr?HashingPower=50&HashingUnit=H%2Fs&PowerConsumption=0&CostPerkWh=0).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

To get started, you'll need to set up a Monero wallet and get a Monero address. You can either set up a wallet locally by following a guide [like this one](https://moneroeric.com/install-monero-wallet-address/), or use an online wallet like [MyMonero](https://mymonero.com/#/). 

Also, you'll need at least the following:

- iOS 10.0+
- Xcode 9+
- Swift 4+

## Installation and Usage

### Getting the library

XMRMiner is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'XMRMiner'
```

### Integrating the miner into an application

First, import the library:

```swift
import XMRMiner
```

Next, you'll need to instantiate a `Miner`. If you're just getting started, most of the default parameters should be fine. See `Miner.swift` for the other parameters that can be passed to the `Miner` constructor. We did this in `AppDelegate.swift`.

```swift 
let miner = Miner(destinationAddress: "<your Monero address>")
```

You'll then want to set the Miner's delegate, and implement the status method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    miner.delegate = window?.rootViewController as? MinerDelegate
    return true
}
```

In our app's `ViewController.swift`:

```swift
extension ViewController: MinerDelegate {
    func miner(updatedStats stats: MinerStats) {
        hashrateLabel.text = "\(stats.hashRate) H/s"
        submittedHashesLabel.text = "\(stats.submittedHashes)"
    }
}
```

Finally, you'll want to configure your app to start/stop the Miner at appropriate times. Again, in `AppDelegate.swift`:

```swift
func applicationWillResignActive(_ application: UIApplication) {
    miner.stop()
}
    
func applicationDidBecomeActive(_ application: UIApplication) {
    do {
        try miner.start()
    }
    catch {
        print("something bad happened")
    }
}
```

## Author

Nick Lee, [nick@tendigi.com](mailto:nick@tendigi.com)

## License / Credits

Portions of this software are subject to additional license restrictions, as they have been ported from the [Xmonarch repository](https://github.com/noahdesu/xmonarch). They can be found in the `Vendor/crypto` folder.

XMRMiner is available under the MIT license.