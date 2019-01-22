//
//  FirebaseJWT.swift
//  App
//
//  Created by Matthew Sanford on 1/17/19.
//

import Foundation
import JWT

struct FirebaseJWT: JWTPayload {
    var iss: String
    var scope: String
    var exp: Int
    var aud: String
    var iat: Int

    func verify(using signer: JWTSigner) throws {

    }
}
