//
//  GoogleAccessToken.swift
//  SwiftyFire
//
//  Created by Matthew Sanford on 1/9/19.
//

import Foundation

public final class GoogleAccessToken: NSObject, Decodable {
    override public var description: String {
        get {
            return "access_token: \(access_token)\ntoken_type:\(token_type)\nexpires_in:\(expires_in)"
        }
    }
    let access_token: String
    let token_type: String
    let expires_in: Int
}
