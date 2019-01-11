//
//  Sensitive.swift
//  SwiftyFire
//
//  Created by Matthew Sanford on 1/9/19.
//

import Foundation
import SwiftJWT

class SFSecrets {
    var databaseURL: String
    var googlePrivateKeyString: String
    var firebaseServiceAccount: String

    var googlePrivateKey: Data? {
        get {
            let keyString = googlePrivateKeyString
            return keyString.data(using: .utf8)
        }
    }

    // See RFC 7519 <https://tools.ietf.org/html/rfc7519#section-4.1>
    private let header = Header(typ: "JWT")
    var jwt: String? {
        get {
            let myClaims = MyClaims(iss: firebaseServiceAccount,
                                    scope: "https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email",
                                    exp: Int(Date().addingTimeInterval(60 * 30).timeIntervalSince1970),
                                    aud: "https://www.googleapis.com/oauth2/v4/token",
                                    iat: Int(Date().timeIntervalSince1970))
            var myJWT = JWT(header: header, claims: myClaims)
            do {
                guard let privateKey: Data = googlePrivateKey else { return nil }
                let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
                let signedJWT = try myJWT.sign(using: jwtSigner)
                return signedJWT
            } catch  {
                return nil
            }
        }
    }

    var _access_token: GoogleAccessToken?
    private var timer: DispatchSourceTimer?

    public init(url: String, private_key: String, service_account: String) {
        self.databaseURL = url
        self.googlePrivateKeyString = private_key
        self.firebaseServiceAccount = service_account
        setup()
    }

    private func setup() {
        let queue = DispatchQueue(label: "com.swiftyfire.timer.authToken")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(60 * 29))
        timer?.setEventHandler { [weak self] in
            self?.refreshToken()
        }
        timer?.resume()
    }

    private func refreshToken() {
        getGoogleAuthToken { [weak self] (token, error) in
            guard let self = self else { return }
            if let token = token {
                self._access_token = token
            }
        }
    }

    /// Method for retrieving environment variables
    ///
    /// - Parameter name: key of the variable
    /// - Returns: value stored at key
    static func getEnvironmentVar(_ name: String) -> String? {
        guard let rawValue = getenv(name) else { return nil }
        return String(utf8String: rawValue)
    }

    /// Create GoogleOAuthToken from signed JWT
    ///
    /// - Parameters:
    ///   - jwtString: JWT containing the private key and neccessary claims + headers
    ///   - completion: A valid request will return a GoogleAccesstoken and a nil Error param
    func getGoogleAuthToken(completion: @escaping (GoogleAccessToken?, Error?) -> Void) {
        guard let url = URL(string: "https://www.googleapis.com/oauth2/v4/token"),
            let jwt = jwt else {
                return

        }
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        guard let postString = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return
        }
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }

            if let data = data {
                do {
                    let token = try JSONDecoder().decode(GoogleAccessToken.self, from: data)
                    self._access_token = token
                    completion(token, nil)
                }
                catch {
                    print(error.localizedDescription)
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
}

fileprivate struct MyClaims: Claims {
    let iss: String
    let scope: String
    let exp: Int
    let aud: String
    let iat: Int
}

