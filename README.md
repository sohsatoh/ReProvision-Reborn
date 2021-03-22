## ReProvision Reborn

This project provides automatic re-provisioning of iOS and tvOS applications to avoid the 7-day expiration associated with free certificates, along with a macOS application to manually provision a given `.ipa` file.

### Why 'Reborn'?

This project had been EOL and I have resurrected it.

One thing to note is that I do not intend to update for non-iOS. Perhaps an update for iOS make it incompatible with other operating systems.

**ReProvision Reborn does not wish to be a competitor to AltStore. It's an option**

**Please don't bother the original developer about issues on this version.**

#### Changes

- Add support for iOS 14
- Add support for arm64e devices
- Fix errors related to certificate (Thanks: [@nyuszika7h](https://github.com/nyuszika7h))
- Fix signing issues (Thanks: AltSign by [@rileytestut](https://github.com/rileytestut/))

... and more!

This tool uses the code taken from [AltSign](https://github.com/rileytestut/AltSign) by [@rileytestut](https://github.com/rileytestut/).

## Original Description

### Features

Provisioning is undertaken via the user's Apple ID credentials, and supports both paid and free development accounts. These credentials are stored in the user's Keychain for subsequent re-use, and are only sent to Apple's iTunes Connect API for authentication.

#### iOS

- Automatic re-signing of locally provisioned applications.
- Basic settings to configure alerts shown by the automatic re-signing.
- Ability to install any `.ipa` file downloaded through Safari from the device.
- Support for re-signing Apple Watch applications.
- 3D Touch menu for starting a new re-signing routine directly from the Homescreen.

Battery optimisations are also in place through the usage of a background daemon to handle automatic signing.

Please note that only jailbroken devices are supported at this time. Follow [issues/44](https://github.com/Matchstic/ReProvision/issues/44) for progress regarding stock devices.

#### tvOS [TODO]

- Automatic re-signing of locally provisioned applications.
- Basic settings to configure alerts shown by the automatic re-signing.
- Ability to install any `.ipa` file downloaded to the device.

#### macOS [N/A]

- Not viable with this codebase. See AltDeploy instead: https://github.com/pixelomer/AltDeploy

### Pre-Requisites

~~For compiling the iOS project into a Debian archive, `ldid2` and (currently) `iOSOpenDev`. I plan to integrate these two dependencies into this repository.~~ These are now integrated into this repository under `/bin`.

CocoaPods is also utilised.

### Building

To build this project, make sure to have the above pre-requisites installed.

1. Clone the project; `git clone https://github.com/sohsatoh/ReProvision.git`
2. Update CocoaPods, by running `pod install` in the project's root directory.
3. Open `ReProvision.xcworkspace`, and roll from there.

### Third-Party Libraries

**iOS**

A third-party library notice can be found [here](https://raw.githubusercontent.com/sohsatoh/ReProvision/master/iOS/HTML/openSourceLicenses.html).

### License

Licensed under the AGPLv3 License.

However, if you modify or redistribute this software, you must obtain permission from me, sohsatoh.

Furthermore, ReProvision (and by extension, libProvision as found in `/Shared/`) IS NOT FOR PIRACY. It is intended to allow users to ensure applications signed with a free development certificate remain signed past the usual 7-day window.

Absolutely no warranty or guarantee is provided; the software is provided AS-IS.
