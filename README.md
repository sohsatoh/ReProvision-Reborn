## ReProvision Reborn
Re-sign applications on your device.

This project aims at making it easier to (re-)sign iOS and Apple Watch applications on a **jailbroken** iOS device, allowing users to avoid the 7-day limit of free certificates associated with their normal Apple account.

### Features
- Automatic re-signing of locally provisioned applications
- Basic settings to configure alerts shown when applications are (re-)signed
- Ability to install any ``.ipa`` file downloaded through Safari from the device
- Support for (re-)signing Apple Watch applications
- 3D Touch menu for starting a new re-signing routine directly from the Homescreen

Battery optimisations are also in place through the usage of a background daemon to handle automatic signing.

## Notes
The original project, ReProvision, has been EOL after Apple changed the process of application provisioning on their servers. This fork of ReProvision attempts to maintain the project and get it up-to-date with support for iOS 13 and above, which also explains the rename of the project.

Although this is an attempt at resurrecting the project, I ask that you **do not bother** the original developer about specific updates made to **this** fork, since they're no longer behind the project.

### Support
Attempting to maintain this fork comes at the cost of "dropping" tvOS and macOS support, since other viable options, such as [AltStore](https://github.com/rileytestut/AltStore) and AltDeploy are available for their respective platforms; the main focus of this fork is iOS.

Furthermore, while re-distribution of this software is allowed, support for modified versions of this software will not be provided.  

### Account Handling
Like most provisioning software, ReProvision supports free and paid development Apple accounts. While crendentials are stored in the device's Keychain for subsequent re-use, they're only sent to Apple's iTunes Connect API for authentication.

### AltStore vs ReProvision
What separates AltStore and this project is the fact that ReProvision doesn't require a computer, making it a viable option for easy, on-device provisioning. Aside from that, this fork of ReProvision uses the same techniques that AltStore uses to tackle provisioning, and by no means should be considered as a competitor.

### Contributing
Pull requests, which add a new feature or fix a bug/error, or issue tickets are welcome. Check out the [contributing guidelines](https://github.com/sohsatoh/ReProvision-Reborn/blob/master/CONTRIBUTING.md) for further information.

## Building
As long as you have standard libraries for Xcode projects, the only dependencies you need are [CocoaPods](https://github.com/CocoaPods/CocoaPods) and [Git](https://git-scm.com/downloads). You can build the project with 3 simple steps
1. ``git clone https://github.com/sohsatoh/ReProvision-Reborn.git``
2. ``pod install`` in the project's root directory
3. Open ``ReProvision.xcworkspace``, and roll from there

## License and Third-Party Libraries
Licensed under the AGPLv3 license. This project occupies specific third-party libraries, which have all been listed (and given credit to) in this [notice](https://raw.githubusercontent.com/sohsatoh/ReProvision/master/iOS/HTML/openSourceLicenses.html).

The software, ReProvision Reborn (and by extension, ``libReprovision`` as found in ``/Shared/``), and all consecutive copies of the software, are provided without warranty and AS-IS. **This project is NOT intended for piracy.**

Special thanks to [Matchstic](https://github.com/Matchstic) for originally developing ReProvision, and [rileytestut](https://github.com/rileytestut) for his amazing work on AltStore.
