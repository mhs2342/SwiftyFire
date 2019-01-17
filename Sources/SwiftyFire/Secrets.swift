//
//  Sensitive.swift
//  SwiftyFire
//
//  Created by Matthew Sanford on 1/9/19.
//

import Foundation
import SwiftJWT
import Logging

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
    var _access_token: GoogleAccessToken?
    private var timer: DispatchSourceTimer?
    private var logger: PrintLogger = PrintLogger()
    private var jwtString: String

    public init(url: String, private_key: String, service_account: String) throws {
        logger.debug("Setting up SwiftyFire Secrets")
        self.databaseURL = url
        self.googlePrivateKeyString = private_key
        self.firebaseServiceAccount = service_account

        let myClaims = MyClaims(iss: firebaseServiceAccount,
                                scope: "https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email",
                                exp: Int(Date().addingTimeInterval(60 * 30).timeIntervalSince1970),
                                aud: "https://www.googleapis.com/oauth2/v4/token",
                                iat: Int(Date().timeIntervalSince1970))
        let header = Header(typ: "JWT")
        var jwt = JWT(header: header, claims: myClaims)
        logger.debug("Getting Private key")
        guard let data = private_key.data(using: .utf8) else { throw  SwiftyFireError.badPrivateKey }
        logger.debug("Creating Signer")
        let jwtSigner = JWTSigner.rs256(privateKey: data)
        logger.debug("Signing private key")
        jwtString = try jwt.sign(using: jwtSigner)
    }

    /// Create GoogleOAuthToken from signed JWT
    ///
    /// - Parameters:
    ///   - jwtString: JWT containing the private key and neccessary claims + headers
    ///   - completion: A valid request will return a GoogleAccesstoken and a nil Error param
    func getGoogleAuthToken(completion: @escaping (GoogleAccessToken?, Error?) -> Void) {
        self.logger.debug("Launching")
        guard let url = URL(string: "https://www.googleapis.com/oauth2/v4/token") else {
                self.logger.error("Error creating url \(SwiftyFireError.unableToCreateRequest)")
                completion(nil, SwiftyFireError.unableToCreateRequest)
                return

        }
        logger.debug("Creating request")
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        logger.debug("Generating post string")
        guard let postString = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwtString)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            self.logger.error("Error creating post string \(SwiftyFireError.unableToCreateRequest)")
            completion(nil, SwiftyFireError.unableToCreateRequest)
            return
        }
        logger.debug("Setting request body")
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.logger.error("Error retrieving token \(error.localizedDescription)")
                completion(nil, error)
                return
            }

            if let data = data {
                do {
                    let token = try JSONDecoder().decode(GoogleAccessToken.self, from: data)
                    self.logger.debug("Successfully decoded access token")
                    self._access_token = token
                    completion(token, nil)
                }
                catch {
                    print(error.localizedDescription)
                    completion(nil, error)
                }
            }
        }
        logger.debug("Requesting Google Access Token")
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

