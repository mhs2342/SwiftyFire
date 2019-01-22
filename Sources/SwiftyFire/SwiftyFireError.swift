//
//  SwiftyFireError.swift
//  SwiftyFire
//
//  Created by Matthew Sanford on 1/9/19.
//

import Foundation

public enum SwiftyFireError: Error {
    case invalidURLString
    case unableToCreateRequest
    case notFound
    case invalidDatabase
    case badRequest
    case unauthorized
    case serverError
    case databaseUnavailable
    case unknownError
    case authenticationTokenWasNotRefreshed
    case badPrivateKey
    case environmentVariablesNotFound
}
