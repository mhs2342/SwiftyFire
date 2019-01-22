# SwiftyFire
[![Build Status](https://travis-ci.com/mhs2342/SwiftyFire.svg?branch=master)](https://travis-ci.com/mhs2342/SwiftyFire)

A description of this package.

## Swift Package Manager 
```swift
.package(url: "https://github.com/mhs2342/SwiftyFire.git", from: "0.2.0"),

```

## Usage
```swift
import SwiftyFire

let fire = SwiftyFire(jwt: String, db_url: String, delegate: SwiftyFireDelegate)
fire.setup { GoogleAccessToken?, Error? in 
// This is required to generate the `GoogleAccessToken` 
// SF will internally hang on to the token
}
```

### JWT
The authentication mechanism for firebase requires that we obtain a Google Access token that is passed into each `REST` request made to your database. The process for this is done by creating what is known as a JWT ([JSON Web Token](https://www.jwt.io)). Further releases of this library will include automatic generation of JWT's but as of now you must pass in your own to SF. 

Creating a JWT is not difficult and I chose to do so with the [Vapor JWT library](https://github.com/vapor/jwt).

#### Package.swift
```swift
.package(url: "https://github.com/vapor/jwt.git", from: "3.0.0")
```

#### FirebaseJWT.swift
```swift
import JWT

struct FirebaseJWT: JWTPayload {
    var iss: String   // Issuer of the token
    var scope: String // What services we want access to
    var exp: Int      // Expiration of the token
    var aud: String   // Audience
    var iat: Int      // When the token was initiated 

    func verify(using signer: JWTSigner) throws {
	// leave this blank
    }
}
```

#### JWT Creation
```swift
import Crypto
import JWT

let payload = FirebaseJWT(iss: fsa,
                          scope: "https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email",
                          exp: Int(Date().addingTimeInterval(60 * 30).timeIntervalSince1970),
                          aud: "https://www.googleapis.com/oauth2/v4/token",
                          iat: Int(Date().timeIntervalSince1970))
let key = try RSAKey.private(pem: gpk)
let data = try JWT<FirebaseJWT>(payload: payload).sign(using: JWTSigner.rs256(key: key))
let jwt = String(data: data, encoding: .utf8) ?? ""
```
The key you use needs to be an RSA private key that you obtain from your firebase project settings. The key you download will *not* be an RSA key, but you can easily transform that into an RSA key using openssl.

### Values
SwiftyFire will return 4 possible values from any request you perform, `.dictionary(val: [String: AnyObject])`, `.string(val: String)`, `.bool(val: Bool)` and `.null`

### Operations
SF supports all of the main operations that the Firebase REST API supports. 
#### POST
```swift
/// Issue a post request. The returned dictionary will be of the format { "name": <auto generated id> }.
/// the value will be the key at which you may access your saved data. i.e. /path/to/<auto generated id>
///
/// - Parameters:
///   - path: desired location of data
///   - val: data to be saved
///   - completion: callback function with an optional value of the data just saved and optional error
public func post(path: String, val: [String: AnyObject], completion: @escaping SFCallback)
```
#### PATCH
```swift
/// Issue a patch request. Patch is a non-destructive request, meaning it will not overwrite that node with your data.
///
/// - Parameters:
///   - path: desired location of data
///   - val: data to be saved
///   - completion: callback function with an optional value of the data just saved and optional error
public func patch(path: String, val: [String: AnyObject], completion: @escaping SFCallback)
```
#### PUT
```swift
/// Issue a put request. Put is a destructive request, meaning it will overwrite that node with your data.
///
/// - Parameters:
///   - path: desired location of data
///   - val: data to be saved
///   - completion: callback function with an optional value of the data just saved and optional error
public func put(path: String, val: [String: AnyObject], completion: @escaping SFCallback)
```
#### GET
```swift
/// Issue a get request. Retrieve the data at that location
///
/// - Parameters:
///   - path: location of desired data
///   - completion: callback function with an optional value and optional error
public func get(path: String, completion: @escaping SFCallback)
```
#### DELETE
```swift
/// Issue a delete request. Delete the data at that location
///
/// - Parameters:
///   - path: location of data to be deleted
///   - completion: callback function with an optional value and optional error
public func delete(path: String, completion: @escaping SFCallback)
```

## Testing
There some tests written that are dependent on environment variables because there shall not be any private resources contributed to the repo. 

`google_private_key`: This is your RSA formatted private key that is obtained from your firebase project settings

`firebase_service_account`: this is the email that firebase provides for you and which can be found in your project settings.

`database_url`: This is the url of your database. By default, all tests are written to the `<host>/` node, so I would recommend adding a `testing/ node to prevent cluttering your root database nodes`.
	Should you choose to run the tests, expect them to fail unless you have the above environment variables set via the Xcode scheme editor.
