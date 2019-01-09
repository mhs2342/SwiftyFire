//
//  Value.swift
//  SwiftyFire
//
//  Created by Matthew Sanford on 1/9/19.
//

import Foundation

public enum Value: Equatable {
    // We cannot determine if two generic dictionaries are equatable so we must assume they do not
    public static func == (lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (let .bool(val1), let .bool(val2)):
            return val1 == val2

        case (let .string(val1), let .string(val2)):
            return val1 == val2

        case (let .number(val1), let .number(val2)):
            return val1 == val2

        case (.null, .null):
            return true
        default:
            return false
        }
    }

    case dictionary(val: [String: AnyObject])
    case number(val: Int)
    case string(val: String)
    case bool(val: Bool)
    case null
}
