![DT Logo](https://raw.githubusercontent.com/vegather/Disruptive/master/dt_logo.png)

# Disruptive - Swift API

Swift library for accessing data from Disruptive Technologies.


## Documentation

The full documentation is available [here](https://vegather.github.io/Disruptive/)


## Installation

This library is currently only available through the Swift Package Manager (SPM).

If you're running Xcode 11 or later, installing this library can be done by going to `File -> Swift Packages -> Add Package Dependency...` , in Xcode, and pasting in the URL to this repo: https://github.com/vegather/Disruptive

If you want to add it manually, you can add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vegather/Disruptive.git", .upToNextMajor(from: "2.0.0"))
]
```


## Examples


## Endpoints Implemented

The following is a list of all the available endpoints in the Disruptive Technologies REST API, with a checkmark next to the ones that have been implemente in this Swift library.

- [x] ~~GET /projects/{project}/devices~~
- [x] ~~POST /projects/{project}/devices:batchUpdate~~
- [x] ~~POST /projects/{project}/devices:transfer~~
- [x] ~~GET /projects/{project}/devices/{device}~~
- [x] ~~POST /projects/{project}/devices/{device}/labels (implicitly through `POST /projects/{project}/devices:batchUpdate`)~~
- [x] ~~PATCH /projects/{project}/devices/{device}/labels/{label} (implicitly through `POST /projects/{project}/devices:batchUpdate`)~~
- [ ] DELETE /projects/{project}/devices/{device}/labels/{label}
- [x] ~~GET /projects/{project}/devices/{device}/events~~
- [x] ~~GET /projects/{project}/devices:stream~~
- [x] ~~GET /projects/{project}/devices/{device}:stream (implicitly through `GET /projects/{project}/devices:stream`)~~
- [ ] GET /projects/{project}/dataconnectors
- [ ] POST /projects/{project}/dataconnectors
- [ ] GET /projects/{project}/dataconnectors/{dataconnector}
- [ ] PATCH /projects/{project}/dataconnectors/{dataconnector}
- [ ] DELETE /projects/{project}/dataconnectors/{dataconnector}
- [ ] GET /projects/{project}/dataconnectors/{dataconnector}:metrics
- [ ] POST /projects/{project}/dataconnectors/{dataconnector}:sync
- [ ] GET /organizations/{organization}/members
- [ ] POST /organizations/{organization}/members
- [ ] GET /organizations/{organization}/members/{member}
- [ ] PATCH /organizations/{organization}/members/{member}
- [ ] DELETE /organizations/{organization}/members/{member}
- [ ] GET /organizations/{organization}/members/{member}:getInviteUrl
- [x] ~~GET /organizations/{organization}/permissions~~
- [ ] GET /projects/{project}/members
- [ ] POST /projects/{project}/members
- [ ] GET /projects/{project}/members/{member}
- [ ] PATCH /projects/{project}/members/{member}
- [ ] DELETE /projects/{project}/members/{member}
- [ ] GET /projects/{project}/members/{member}:getInviteUrl
- [x] ~~GET /projects/{project}/permissions~~
- [ ] GET /roles
- [ ] GET /roles/{role}
- [x] ~~GET /organizations~~
- [ ] GET /organizations/{organization}
- [x] ~~GET /projects~~
- [x] ~~POST /projects~~
- [x] ~~GET /projects/{project}~~
- [x] ~~PATCH /projects/{project}~~
- [ ] DELETE /projects/{project}
- [ ] GET /projects/{project}/serviceaccounts
- [ ] POST /projects/{project}/serviceaccounts
- [ ] GET /projects/{project}/serviceaccounts/{serviceaccount}
- [ ] PATCH /projects/{project}/serviceaccounts/{serviceaccount}
- [ ] DELETE /projects/{project}/serviceaccounts/{serviceaccount}
- [ ] GET /projects/{project}/serviceaccounts/{serviceaccount}/keys
- [ ] POST /projects/{project}/serviceaccounts/{serviceaccount}/keys
- [ ] GET /projects/{project}/serviceaccounts/{serviceaccount}/keys/{key}
- [ ] DELETE /projects/{project}/serviceaccounts/{serviceaccount}/keys/{key}

Emulator
- [ ] GET /projects/{project}/devices
- [ ] POST /projects/{project}/devices
- [ ] GET /projects/{project}/devices/{device}
- [ ] DELETE /projects/{project}/devices/{device}
- [ ] POST /projects/{project}/devices/{device}:publish


## License

The Disruptive Swift library is released under the MIT license. [See LICENSE](https://github.com/vegather/Disruptive/blob/master/LICENSE) for details.
