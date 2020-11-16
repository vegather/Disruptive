![DT Logo](https://raw.githubusercontent.com/vegather/Disruptive/master/dt_logo.png)

# Disruptive - Swift API

Swift library for accessing data from Disruptive Technologies.


## Documentation

The full API documentation for this library is available [here](https://vegather.github.io/Disruptive/)

Documentation for the Disruptive Technologies REST API is available [here](https://support.disruptive-technologies.com/hc/en-us/articles/360012807260)


## Installation

This library is currently only available through the Swift Package Manager (SPM).

If you're running Xcode 11 or later, installing this library can be done by going to `File -> Swift Packages -> Add Package Dependency...` in Xcode, and pasting in the URL to this repo: https://github.com/vegather/Disruptive

If you want to add it manually, you can add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vegather/Disruptive.git", .upToNextMajor(from: "2.0.0"))
]
```


## Guides

### Overview

To use this Swift library, you start by initializing an instance of the `Disruptive` struct. This will be the entry-point for all the requests to the Disruptive Technologies servers. This `Disruptive` instance will automatically handle things such as authentication, pagination, re-sending of events after rate-limiting, and other recoverable errors. 

The following sections will provide a brief guide to the most common use-cases of the API. Check out the [full API documentation](https://vegather.github.io/Disruptive/) for more.


### Authentication

Authentication is done by initializing the `Disruptive` instance with a type that conforms to the `AuthProvider` protocol. The recommended type for this is `OAuth2ServiceAccount` which will authenticate a service account using the OAuth2 flow. A service account can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu.

Here's an example of how to authenticate a service account with the OAuth2 flow:

```swift
let serviceAccount = ServiceAccount(email: "<EMAIL>", key: "<KEY_ID>", secret: "<SECRET>")
let authProvider = OAuth2ServiceAccount(account: serviceAccount)
let disruptive = Disruptive(authProvider: authProvider)
```

### Requesting Orgs, Projects, and Devices

### Requesting Historical Events

### Subscribing to Device Events

### Misc Tips

* Some basic debug logs can be enabled by setting `disruptive.loggingEnabled = true` 



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


## Todo

- [ ] Add unit tests. Would like to try to get a test harness set up based on `URLProtocol` as described in this blog post: https://medium.com/@dhawaldawar/how-to-mock-urlsession-using-urlprotocol-8b74f389a67a
- [ ] Provide better control of pagination. At the moment, this library will automatically fetch all pages before returning the data. Ideally, the caller would be able to decide whether or not they want this automatic behavior, or do it by themselves instead. This would be useful when there are a lot of items in a list, and paging all the items would take too much time.
- [ ] Labels changed support. The `labelsChanged` event has a slightly different structure than the rest of the event types. It was added to this repo before this was realized, so the implementation is simply commented-out until proper parsing logic is implemented. 
- [ ] Finish documenting all types, properties, and methods.


## License

The Disruptive Swift library is released under the MIT license. [See LICENSE](https://github.com/vegather/Disruptive/blob/master/LICENSE) for details.
