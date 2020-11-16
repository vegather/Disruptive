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

The endpoints implemented on the `Disruptive` struct will typically return a value of the type `Result` (read more about that type [here](https://developer.apple.com/documentation/swift/result/writing_failable_asynchronous_apis)). This will contain the value you requested on `.success` (if any, `Void` if not), or a `DisruptiveError` on `.failure`.

The following sections will provide a brief guide to the most common use-cases of the API. Check out the [full API documentation](https://vegather.github.io/Disruptive/) for more.


### Authentication

Authentication is done by initializing the `Disruptive` instance with a type that conforms to the `AuthProvider` protocol. The recommended type for this is `OAuth2ServiceAccount` which will authenticate a service account using the OAuth2 flow. A service account can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu.

Here's an example of how to authenticate a service account with the OAuth2 flow:

```swift
let serviceAccount = ServiceAccount(email: "<EMAIL>", key: "<KEY_ID>", secret: "<SECRET>")
let authProvider = OAuth2ServiceAccount(account: serviceAccount)
let disruptive = Disruptive(authProvider: authProvider)

// Call methods on disruptive...
```

### Requesting Orgs, Projects, and Devices

The endpoints that returns a list (such as `getOrganizations` or `getProjects`), are paginated automatically in the background. This could mean that multiple networking requests are made and their results group together before returning the final list. The end result is that you just call one method, and get back one array of items.

Example of fetching all organizations available to the authenticated account:

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

Fetching projects lets you filter on both the organization (by identifier) as well as a keyword based query. The following example will search for projects with a specified organization id (fetched from the `getOrganizations` endpoint for example) that has `Building 1` in its name:

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

When fetching devices you need to specify the identifier of the project to fetch the devices for. This identifier could be fetched from the `getProjects` endpoint for example.

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

It is also possible to look-up a single device just by the identifier of the device. This is useful if you can an identifier by scanning a QR code for example:

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

### Requesting Historical Events

Fetching historical events for a device is similar to fetching other lists of data (like `getOrganizations` or `getProjects`). You need to specify the identifier of the project and the device, and optionally the start/end time and which events to fetch (certain event types are only available for certain device types, eg. `temperature`). If the result was `.success`, you will receive a value of type `Events` that contains an optional array of events for each event type. Only the event types that were actually returned will be non-nil, not necessarily the one specified in the `eventTypes` parameter.

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


### Subscribing to Device Events

When subscribing to device events you have two options: Either subscribe to a single device, or to a list of devices. If you want to subscribe to a list of devices, you can filter on which devices to subscribe to based on both device types and labels. Either way, you will get a value of type `ServerSentEvents` back that will let you set up a callback for the various event types.

Example of subscribing to temperature events for a single temperature sensor:
```swift
let stream = disruptive.subscribeToDevice(
    projectID  : "<PROJECT_ID>", 
    deviceID   : "<DEVICE_ID>", 
    eventTypes : [.temperature]
)
stream?.onError = { error in
    print("Got stream error: \(error)")
}
stream?.onTemperature = { deviceID, temperatureEvent in
    print("Got temperature \(temperatureEvent) for device with id \(deviceID)")
}
```


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
