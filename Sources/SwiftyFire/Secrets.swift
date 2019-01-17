//
//  Sensitive.swift
//  SwiftyFire
//
//  Created by Matthew Sanford on 1/9/19.
//

import Foundation
import Logging

class SFSecrets {
    var databaseURL: String

    // See RFC 7519 <https://tools.ietf.org/html/rfc7519#section-4.1>
    var _access_token: GoogleAccessToken?
    private var timer: DispatchSourceTimer?
    private var logger: PrintLogger = PrintLogger()
    private var jwtString: String

    public init(url: String, jwt: String) {
        logger.debug("Setting up SwiftyFire Secrets")
        self.databaseURL = url
        jwtString = jwt
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

