![DT Logo](https://raw.githubusercontent.com/vegather/Disruptive/master/dt_logo.png)

# Disruptive - Swift API

![Swift](https://github.com/vegather/Disruptive/workflows/Swift/badge.svg?branch=master)
![Code Coverage](https://raw.githubusercontent.com/vegather/Disruptive/master/.github/badges/coverage.svg)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvegather%2FDisruptive%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/vegather/Disruptive)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvegather%2FDisruptive%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/vegather/Disruptive)
[![API Docs](https://img.shields.io/badge/API-Documentation-333)](https://vegather.github.io/Disruptive/)
[![License](https://img.shields.io/badge/Licence-MIT-333)](https://github.com/vegather/Disruptive/blob/master/LICENSE)

Swift library for accessing data from [Disruptive Technologies](https://disruptive-technologies.com).

---

- [API Documentation](#api-documentation)
- [Installation](#installation)
- [Guides](#guides)
    - [Overview](#overview)
    - [Authentication](#authentication)
    - [Requesting Organizations, Projects, and Devices](#requesting-organizations-projects-and-devices)
        - [Fetch Organizations](#fetch-organizations)
        - [Fetch Projects](#fetch-projects)
        - [Fetch Devices](#fetch-devices)
        - [Single Device Lookup](#single-device-lookup)
    - [Requesting Historical Events](#requesting-historical-events)
    - [Subscribing to Device Events](#subscribing-to-device-events)
    - [Misc Tips](#misc-tips)
- [Endpoints Implemented](#endpoints-implemented)
- [Todo](#todo)
- [License](#license)


## API Documentation

The full Swift API documentation for this library is available [here](https://vegather.github.io/Disruptive/)

Documentation for the Disruptive Technologies REST API is available [here](https://support.disruptive-technologies.com/hc/en-us/articles/360012807260)


## Installation

This library is currently only available through the Swift Package Manager (SPM).

To add this Swift Package as a dependency in Xcode:

1. Go to `File -> Swift Packages -> Add Package Dependency...`
2. Enter the following repository URL: `https://github.com/vegather/Disruptive`
3. Specify the version of the API you want. The default should be fine
4. Make sure your app target is selected, and click "Finish"
5. You can now import the Disruptive Swift API with `import Disruptive`

If you want to add it manually to your Swift project, you can add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vegather/Disruptive.git", from: "0.3.0")
]
```


## Guides

### Overview

To use this Swift library, you start by initializing an instance of the `Disruptive` struct. This will be your entry-point for all the requests to the Disruptive Technologies servers. This `Disruptive` instance will automatically handle things such as authentication, pagination, re-sending of events after rate-limiting, and other recoverable errors.

The endpoints implemented on the `Disruptive` struct are asynchronous, and will return its results in a  closure you provide with an argument of type `Result` (read more about the `Result` type [on Apple's developer site](https://developer.apple.com/documentation/swift/result/writing_failable_asynchronous_apis)). This `Result` will contain the value you requested on `.success` (`Void` if no values makes sense), or a `DisruptiveError` on `.failure`.

**Note**: The callback with the `Result` will always be called on the `main` queue, even if networking/processing is done in a background queue.

The following sections will provide a brief guide to the most common use-cases of the API. Check out the [full Swift API documentation](https://vegather.github.io/Disruptive/) for more.


### Authentication

Authentication is done by initializing the `Disruptive` instance with a type that conforms to the `AuthProvider` protocol. The recommended type for this is `OAuth2Authenticator` which will authenticate a service account using the OAuth2 flow. A service account can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu.

Here's an example of how to authenticate a service account with the OAuth2 flow:

```swift
import Disruptive

let credentials = ServiceAccountCredentials(email: "<EMAIL>", key: "<KEY_ID>", secret: "<SECRET>")
let authenticator = OAuth2Authenticator(credentials: credentials)
let disruptive = Disruptive(authProvider: authenticator)

// All methods called on the disruptive instance will be authenticated
```

[`OAuth2Authenticator` documentation](https://vegather.github.io/Disruptive/OAuth2Authenticator/)

### Requesting Organizations, Projects, and Devices

The endpoints that returns a list (such as `getOrganizations` or `getProjects`), are paginated automatically in the background. This could mean that multiple networking requests are made in the background, the result of each of those requests are grouped together, and the final array is returned within the `Result` in the callback. The end result is that you just call one method, and get back one array of items.


#### Fetch Organizations

Here's an example of fetching all the organizations available to the authenticated account:

```swift
disruptive.getOrganizations { result in
    switch result {
        case .success(let organizations):
            print(organizations)
        case .failure(let error):
            print("Failed to get organizations: \(error)")
    }
}
```
[`getOrganizations` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getorganizations(completion:))


#### Fetch Projects

Fetching projects lets you optionally filter on both the organization (by identifier) as well as a keyword based query. You can also leave both of those parameters out to fetch all projects available to the authenticated account. The following example will search for projects with a specified organization id (fetched from the `getOrganizations` endpoint for example) that has `Building 1` in its name:

```swift
disruptive.getProjects(organizationID: "<ORG_ID>", query: "Building 1") { result in
    switch result {
        case .success(let projects):
            print(projects)
        case .failure(let error):
            print("Failed to get projects: \(error)")
    }
}
```
[`getProjects` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getprojects(organizationid:query:completion:))


#### Fetch Devices

When fetching devices, you need to specify the identifier of the project to fetch the devices for (this identifier could be fetched from the `getProjects` endpoint for example). Here's an example of how to fetch all the devices within a specified project id:

```swift
disruptive.getDevices(projectID: "<PROJECT_ID>") { result in
    switch result {
        case .success(let devices):
            print(devices)
        case .failure(let error):
            print("Failed to get devices: \(error)")
    }
}
```
[`getDevices` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdevices(projectid:completion:))


#### Single Device Lookup

It is also possible to look up a single device just by the identifier of the device. This is useful if you got a device identifier by scanning a QR code for example. Here's an example:

```swift
disruptive.getDevice(deviceID: "<DEVICE_ID>") { result in
    switch result {
        case .success(let device):
            print(device)
        case .failure(let error):
            print("Failed to get device: \(error)")
    }
}
```
[`getDevice` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdevice(projectid:deviceid:completion:))


### Requesting Historical Events

Fetching historical events for a device is similar to fetching other lists of data (like `getOrganizations` or `getProjects`). You need to specify the identifier of the project and the device, and optionally the start/end time and which events to fetch (certain event types are only available for certain device types, eg. `temperature` events are only available for `temperature` sensors). If the `Result` returned in the callback was `.success`, you will receive a value of type `Events` that contains an optional array of events for each event type. Only the event types that were actually returned will be non-nil, not necessarily the one specified in the `eventTypes` parameter.

Example of fetching just temperature events for a temperature sensor (defaults to last 24 hours):

```swift
disruptive.getEvents(projectID: "<PROJECT_ID>", deviceID: "<DEVICE_ID>", eventTypes: [.temperature]) { result in
    switch result {
        case .success(let events):
            if let temperatureEvents = events.temperature {
                print(temperatureEvents)
            }
        case .failure(let error):
            print("Failed to get temperature events: \(error)")
    }
}
```
[`getEvents` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getevents(projectid:deviceid:startdate:enddate:eventtypes:completion:))


### Subscribing to Device Events

When subscribing to device events you have two options: Either subscribe to a single device, or to a list of devices. If you want to subscribe to a list of devices, you can filter on which devices to subscribe to based on both device types and labels. Either way, you will get a value of type `ServerSentEvents` back that will let you set up a callbacks for each the various event types. Only the event types specified in the `eventTypes` parameter will actually receive callbacks.

Example of subscribing to temperature events for a single temperature sensor:
```swift
let stream = disruptive.subscribeToDevice(
    projectID  : "<PROJECT_ID>", 
    deviceID   : "<DEVICE_ID>", 
    eventTypes : [.temperature] // optional
)
stream?.onError = { error in
    print("Got stream error: \(error)")
}
stream?.onTemperature = { deviceID, temperatureEvent in
    print("Got temperature \(temperatureEvent) for device with id \(deviceID)")
}
```
[`subscribeToDevice` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.subscribetodevices(projectid:deviceids:devicetypes:labelfilters:eventtypes:))


### Misc Tips

* Some basic debug logs can be enabled by setting `Disruptive.loggingEnabled = true` 



## Endpoints Implemented

The following is a list of all the available endpoints in the Disruptive Technologies REST API, with a checkmark next to the ones that have been implemented in this Swift library.

Progress: ![Progress](https://progress-bar.dev/37/?scale=54&suffix=%20%2f%2054)

- [x] ~~GET /projects/{project}/devices~~
- [x] ~~POST /projects/{project}/devices:batchUpdate~~
- [x] ~~POST /projects/{project}/devices:transfer~~
- [x] ~~GET /projects/{project}/devices/{device}~~
- [x] ~~POST /projects/{project}/devices/{device}/labels (implicitly through `POST /projects/{project}/devices:batchUpdate`)~~
- [x] ~~PATCH /projects/{project}/devices/{device}/labels/{label} (implicitly through `POST /projects/{project}/devices:batchUpdate`)~~
- [x] ~~DELETE /projects/{project}/devices/{device}/labels/{label} (implicitly through `POST /projects/{project}/devices:batchUpdate`)~~
- [x] ~~GET /projects/{project}/devices/{device}/events~~
- [x] ~~GET /projects/{project}/devices:stream~~
- [x] ~~GET /projects/{project}/devices/{device}:stream (implicitly through `GET /projects/{project}/devices:stream`)~~
- [x] ~~GET /projects/{project}/dataconnectors~~
- [x] ~~POST /projects/{project}/dataconnectors~~
- [x] ~~GET /projects/{project}/dataconnectors/{dataconnector}~~
- [x] ~~PATCH /projects/{project}/dataconnectors/{dataconnector}~~
- [x] ~~DELETE /projects/{project}/dataconnectors/{dataconnector}~~
- [x] ~~GET /projects/{project}/dataconnectors/{dataconnector}:metrics~~
- [x] ~~POST /projects/{project}/dataconnectors/{dataconnector}:sync~~
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
- [x] ~~GET /roles~~
- [x] ~~GET /roles/{role}~~
- [x] ~~GET /organizations~~
- [x] ~~GET /organizations/{organization}~~
- [x] ~~GET /projects~~
- [x] ~~POST /projects~~
- [x] ~~GET /projects/{project}~~
- [x] ~~PATCH /projects/{project}~~
- [x] ~~DELETE /projects/{project}~~
- [x] ~~GET /projects/{project}/serviceaccounts~~
- [x] ~~POST /projects/{project}/serviceaccounts~~
- [x] ~~GET /projects/{project}/serviceaccounts/{serviceaccount}~~
- [x] ~~PATCH /projects/{project}/serviceaccounts/{serviceaccount}~~
- [x] ~~DELETE /projects/{project}/serviceaccounts/{serviceaccount}~~
- [x] ~~GET /projects/{project}/serviceaccounts/{serviceaccount}/keys~~
- [x] ~~POST /projects/{project}/serviceaccounts/{serviceaccount}/keys~~
- [x] ~~GET /projects/{project}/serviceaccounts/{serviceaccount}/keys/{key}~~
- [x] ~~DELETE /projects/{project}/serviceaccounts/{serviceaccount}/keys/{key}~~

Emulator
- [ ] GET /projects/{project}/devices
- [ ] POST /projects/{project}/devices
- [ ] GET /projects/{project}/devices/{device}
- [ ] DELETE /projects/{project}/devices/{device}
- [ ] POST /projects/{project}/devices/{device}:publish


## Todo

- [x] ~~Add unit tests. Would like to try to get a test harness set up based on `URLProtocol` as described in this blog post: https://medium.com/@dhawaldawar/how-to-mock-urlsession-using-urlprotocol-8b74f389a67a~~
- [ ] Provide better control of pagination. At the moment, this library will automatically fetch all pages before returning the data. Ideally, the caller would be able to decide whether or not they want this automatic behavior, or do it by themselves instead. This would be useful when there are a lot of items in a list, and paging all the items would take too much time.
- [ ] Labels changed support. The `labelsChanged` event has a slightly different structure than the rest of the event types. It was added to this repo before this was realized, so the implementation is simply commented-out until proper parsing logic is implemented. 
- [x] ~~Finish documenting all types, properties, and methods.~~
- [ ] Improve `DTLog` to include file and line numbers in a nicely formatted output. At this point it could also be a public function.
- [x] Reach 90%+ code coverage for the unit tests.
- Areas that still needs unit testing
    - [ ] `Authentication.swift` - `getActiveAccessToken` and error handling in `OAuth2Authenticator.refreshAccessToken`
    - [x] `DeviceEventStream.swift`
    - [ ] `EventTypes.swift`
    - [ ] `Requests.swift`
    - [ ] `RetryScheme.swift`
    - [x] `Stream.swift`
    - [ ] Network Tests: pagination, errors
- [ ] Add Combine support for server sent events.
- [ ] Add global option not wait for re-attempts when rate-limiting, and just return the error instead.
- [ ] Handle 5XX errors from the backend. These shows up as `InternalError`s, and should have a retry-policy with an exponential backoff.
    


## License

The Disruptive Swift library is released under the MIT license. [See LICENSE](https://github.com/vegather/Disruptive/blob/master/LICENSE) for details.
