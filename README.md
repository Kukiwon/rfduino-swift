# RFDuino
A Pod that let's you easily connect to and communicate with RFDuino and other Bluetooth Smart devices.

[![Version](https://img.shields.io/cocoapods/v/RFDuino.svg?style=flat)](http://cocoapods.org/pods/RFDuino)
[![License](https://img.shields.io/cocoapods/l/RFDuino.svg?style=flat)](http://cocoapods.org/pods/RFDuino)
[![Platform](https://img.shields.io/cocoapods/p/RFDuino.svg?style=flat)](http://cocoapods.org/pods/RFDuino)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

The RFDuino or any other device that you want this library to work with must support Bluetooth Smart (also refered to as Bluetooth Low Energy). For now, the external device needs to be in the "peripheral" role. You'll also need an iPhone 4S or higher to connect to these devices.

## Features

* The plugin comes with a Manager class that allows you to easily:
  * discover new bluetooth devices
  * connect to bluetooth devices
  * find out when a device times out (because it is not visible anymore)
  * discover services on a bluetooth device
  * discover characteristics on a bluetooth device
* It allows you to work with custom UUIDS user in the Bluetooth protocol
* It comes with an RFDuino class that allows you to easily pass around devices in your code and operate on them:
  * write data to this device
  * read data from this device
  * connect / disconnect from the device
* The pod comes with two demo applications: RFDuino Example and RBL Nano Example, see [Red Bear Lab Nano](http://redbearlab.com/blenano/) that allow you to:
  * connect to a device
  * disconnect from a connected device
  * discover services and characteristics on a device, once it is connected
  * send (write) data to the connected device

## Installation

RFDuino is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "RFDuino"
```

## Author

Jordy van Kuijk, info@noproblem.software

## License

RFDuino is available under the MIT license. See the LICENSE file for more info.
