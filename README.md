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
    - [Permissions](#permissions)
    - [Making Requests](#making-requests)
        - [Lists & Pagination](#lists--pagination)
        - [Fetching Historical Events](#fetching-historical-events)
        - [Subscribing to Device Events](#subscribing-to-device-events)
        - [Other Common Requests](#other-common-requests)
    - [Misc Tips](#misc-tips)
- [License](#license)




## API Documentation

* [Full Swift API documentation](https://vegather.github.io/Disruptive/)
* [REST API reference documentation](https://support.disruptive-technologies.com/hc/en-us/articles/360012807260)





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
    .package(url: "https://github.com/vegather/Disruptive.git", from: "1.0.0")
]
```





## Guides

### Overview

To use this Swift library, you start by initializing an instance of the `Disruptive` struct with the credentials for a Service Account (see the [Authentication](#authentication) section below). This will be your entry-point for all the requests to the Disruptive Technologies service. This `Disruptive` instance will automatically handle things such as authentication, pagination, re-sending of events after rate-limiting, and other recoverable errors.

The endpoints implemented on the `Disruptive` struct are asynchronous, and will return its results in a closure you provide with an argument of type `Result` (read more about the `Result` type [on Apple's developer site](https://developer.apple.com/documentation/swift/result/writing_failable_asynchronous_apis)). This `Result` will contain the value you requested on `.success` (`Void` if no values makes sense), or a `DisruptiveError` on `.failure`.

**Note**: The callback with the `Result` will always be called on the `main` queue, even if networking/processing is done in a background queue.

The following sections will provide a brief guide to the most common use-cases of the API. Check out the [full Swift API documentation](https://vegather.github.io/Disruptive/) for more.



### Authentication

Authentication is done by initializing the `Disruptive` instance with a type that conforms to the `Authenticator` protocol. The recommended type for this is `OAuth2Authenticator` which will authenticate a Service Account using the OAuth2 flow. Once authenticated, the `Disruptive` instance will make sure it always has a non-expired access token, and will add that to the `Authorization` header of the request before sending it. If the access token is expired when a request is made, a new access token will be fetched automatically before sending the request.

A service account can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu. Create a new key for the Service Account and make sure to note down the key id, secret, and email for the Service Account. Note that by default, the Service Account will not have access to any resources. See the section below about [Permissions](#permissions) to learn how to grant the Service Account access to your resources.

Here's an example of how to authenticate a service account with the OAuth2 flow:

```swift
import Disruptive

let credentials = ServiceAccountCredentials(email: "<EMAIL>", keyID: "<KEY_ID>", secret: "<SECRET>")
let authenticator = OAuth2Authenticator(credentials: credentials)
let disruptive = Disruptive(authenticator: authenticator)

// All methods called on the disruptive instance will be authenticated
```

[`OAuth2Authenticator` documentation](https://vegather.github.io/Disruptive/OAuth2Authenticator/)



### Permissions

Access levels for the Disruptive API can be described in terms of members, roles, and permissions. For an account (Service Account or user) to have access to a resource, it has to be a member in the project or organization that is a parent of that resource. A member will always have a role for the project/organization it's a member of (such as project user, project admin, etc). Each of those roles as a list of permissions that describes which CRUD (create, read, update, delete) operations it can perform on various resources. Examples of permissions would be `"project.read"`, `"membership.create"`, `"serviceaccount.key.delete"`, etc. To list the available roles and permissions, use the [`getRoles`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getroles(completion:)) and [`getPermissions`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getpermissions(projectid:completion:)) functions.

In order for a Service Account to be able to access a given resource, it must have sufficient permissions for that resource. By default, a Service Account does not have access to any resources.  The easiest way to get started with a Service Account is by granting access for the relevant projects/organizations in [DT Studio](https://studio.disruptive-technologies.com). You can give it a role in the current project by selecting `Role in current Project` when viewing the Service Account under `API Integrations -> Service Accounts`. You can also give it access to other projects/organizations by going to the list of members (in `Project Settings` for project members), and then adding the Service Account as a member using the Service Account's email address, and selecting an appropriate role.

Once you have the credentials for a Service Account and have created a `Disruptive` instance, you can use the API to create new Service Accounts and add them as a members to your projects. See the [`createServiceAccount`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.createserviceaccount(projectid:displayname:basicauthenabled:completion:)) and [`inviteMember`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.invitemember(projectid:roles:email:completion:)) functions for more details.

See the [Service Accounts](https://support.disruptive-technologies.com/hc/en-us/articles/360012295100-Service-Accounts) article on the developer website for more details about Service Accounts in general.




### Making Requests

Once an instance of the `Disruptive` struct has been created, it will be the main entry point to make requests against the Disruptive API. See the [API reference](https://vegather.github.io/Disruptive/Disruptive/) for an overview of all the functionality available on the `Disruptive` struct.


#### Lists & Pagination

There are two main approaches to fetching a list of resources (such as a list of `Device`s or `Project`s): You can either fetch them all at once, or one page at a time. Fetching all the items of a resource at once is more convenient, but if there are a lot of items this can take a long time as multiple network requests might be made in the background to get all the pages automatically. 

Fetching one page of items at a time is slightly more cumbersome to implement, but provides full control of how many items are fetched at a time and when to fetch the next page of items. Fetching one page at a time is available for `Organization`, `Project`, `Device`, `DataConnector`, `Member`, `ServiceAccount`, and `ServiceAccount.Key`. It is not available for `Role` and `Permission` as those have a well-known, small number of items to list. It is also not available for fetching events as events can be paged by specifying start and end timestamps to fetch events between.

Here are examples of both of these approaches for fetching a list of `Device`s.

Fetching all `Device`s in a project at once:
```swift
disruptive.getAllDevices(projectID: "<PROJECT_ID>") { result in
    switch result {
        case .success(let devices):
            print(devices)
        case .failure(let error):
            print("Failed to get devices: \(error)")
    }
}
```
[`getAllDevices` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getalldevices(projectid:completion:))


Fetching `Device`s one page at a time:
```swift
var fetchedDevices = [Device]()
var nextPageToken: String?

func fetchNextPage(pageToken: String?) {
    disruptive.getDevicesPage(projectID: "<PROJECT_ID>", pageSize: 25, pageToken: pageToken) { result in
        switch result {
            case .success(let page):
                // Keep track of the page token to use for the next page.
                // Note that this will be `nil` when the last page is received.
                nextPageToken = page.nextPageToken
                
                // Update the list of all the devices we have found so far
                fetchedDevices.append(contentsOf: page.devices)
                
                print("Fetched \(page.devices.count) more devices. \(fetchedDevices.count) devices fetched in total")
            case .failure(let error):
                print("Failed to get devices: \(error)")
        }
    }
}

// Fetch the first page
fetchNextPage(pageToken: nil)

// Fetch subsequent pages when it makes sense (for example when pre-fetching data
// for a UITableView). Note that `nextPageToken` will be set to `nil` when the last
// page is received.
if let pageToken = nextPageToken {
    fetchNextPage(pageToken: pageToken)
}
```
[`getDevicesPage` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdevicespage(projectid:pagesize:pagetoken:completion:))


#### Fetching Historical Events

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


#### Subscribing to Device Events

When subscribing to device events you have two options: Either subscribe to a single device, or to a list of devices. If you want to subscribe to a list of devices, you can filter on which devices to subscribe to based on both device types and labels. Either way, you will get a value of type `DeviceEventStream` back that will let you set up a callbacks for each the various event types. Only the event types specified in the `eventTypes` parameter will actually receive callbacks.

Example of subscribing to temperature events for a single temperature sensor:
```swift
let stream = disruptive.subscribeToDevice(
    projectID  : "<PROJECT_ID>", 
    deviceID   : "<DEVICE_ID>", 
    eventTypes : [.temperature] // optional
)
stream?.onTemperature = { deviceID, temperatureEvent in
    print("Got temperature \(temperatureEvent) for device with id \(deviceID)")
}
stream?.onError = { error in
    print("Got stream error: \(error)")
}
```
[`subscribeToDevice` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.subscribetodevice(projectid:deviceid:eventtypes:))



#### Other Common Requests

##### Search / Filter Devices

The requests to fetch devices has various parameters to search and/or filter devices. All of these parameters are optional (except for `projectID`), and can be mixed and matched as desired.

When specifying the order to retrieve the devices in, a field as well as an ascending/descending flag is included in a tuple. The value of this field is based on the JSON structure of the devices. Examples of `field`s to use include `id` (identifier), `type` (device type), `labels.name` (displayName). All events will have the format `reported.<event_type>.<field>`, eg. `reported.networkStatus.signalStrength`. See the [REST API](https://support.disruptive-technologies.com/hc/en-us/articles/360012807260#/Devices/get_projects__project__devices) documentation for the `GET Devices` endpoint to get hints for which fields are available.

Here is an example of how to use all the parameters:
```swift
disruptive.getAllDevices(
    projectID    : "<PROJECT_ID>",
    query        : "Air Vent",
    deviceIDs    : ["<DEVICE_ID>", "<DEVICE_ID>"],
    deviceTypes  : [.temperature],
    labelFilters : ["kit": "perform-compare-establish"],
    orderBy      : (field: "reported.networkStatus.updateTime", ascending: false))
{ result in
    ...
}
```

##### Single Device Lookup

A single device can be looked up just by the identifier of the device. This is useful if you got a device identifier by scanning a QR code for example. Here's an example:

```swift
disruptive.getDevice(deviceID: "<DEVICE_ID>") { result in
    ...
}
```
[`getDevice` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdevice(projectid:deviceid:completion:))



##### Emulated Devices

Emulated devices can be created and used to publish events using the API. This enables testing out other parts of the API (such as listing devices) and developing a solution around the API without having access to physical devices.

Here's an example for how to create a new emulated temperature sensor:

```swift
disruptive.createEmulatedDevice(
    projectID   : "<PROJECT_ID>",
    deviceType  : .temperature,
    displayName : "Emulated Temperature Sensor")
{ result in
    ...
}
```
[`createEmulatedDevice` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.createemulateddevice(projectid:devicetype:displayname:labels:completion:))

Here's an example for how to publish a `TemperatureEvent` for an emulated sensor:

```swift
disruptive.publishEmulatedEvent(
    projectID : "<PROJECT_ID>",
    deviceID  : "<DEVICE_ID>",
    event     : TemperatureEvent(celsius: 42, timestamp: Date()))
{ result in
    ...
}
```
[`publishEmulatedEvent` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.publishemulatedevent(projectid:deviceid:event:completion:))



##### Fetch Projects & Organizations

Fetching projects lets you optionally filter on both the organization (by identifier) as well as a keyword based query. You can also leave both of those parameters out to fetch all projects available to the authenticated account. The following example will search for projects with a specified organization id (fetched from the `getOrganizations` endpoint for example) that has `Building 1` in its name:

```swift
disruptive.getAllProjects(organizationID: "<ORG_ID>", query: "Building 1") { result in
    ...
}
```
[`getAllProjects` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getallprojects(organizationid:query:completion:))


Here's an example of fetching all the organizations available to the authenticated account:

```swift
disruptive.getAllOrganizations { result in
    ...
}
```
[`getAllOrganizations` documentation](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getallorganizations(completion:))





### Misc Tips

* Some basic debug logs can be enabled by setting `Disruptive.loggingEnabled = true` 
    





## License

The Disruptive Swift library is released under the MIT license. [See LICENSE](https://github.com/vegather/Disruptive/blob/master/LICENSE) for details.
