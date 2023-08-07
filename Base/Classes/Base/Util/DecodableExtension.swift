//
//  DecodableExtension.swift
//  ThingCameraSDKSampleApp
//
//  Created by Dasom Kim on 2023/04/10.
//

import Foundation

// MARK: - Decodable Extension
extension Decodable {
    init(jsonDictionary: [String: Any]) throws {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
        self = try decoder.decode(Self.self, from: data)
    }
    
}

/// Provides a default value for missing `Decodable` data.
///
/// `DefaultCodableStrategy` provides a generic strategy type that the `DefaultCodable` property wrapper can use to provide a reasonable default value for missing Decodable data.
public protocol DefaultCodableStrategy {
    associatedtype RawValue: Codable
    
    static var defaultValue: RawValue { get }
}

/// Decodes values with a reasonable default value
///
/// `@Defaultable` attempts to decode a value and falls back to a default type provided by the generic `DefaultCodableStrategy`.
@propertyWrapper
public struct DefaultCodable<Default: DefaultCodableStrategy>: Codable {
    public var wrappedValue: Default.RawValue
    
    public init(wrappedValue: Default.RawValue) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode(Default.RawValue.self)) ?? Default.defaultValue
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension DefaultCodable: Equatable where Default.RawValue: Equatable { }
extension DefaultCodable: Hashable where Default.RawValue: Hashable { }

// MARK: - KeyedDecodingContainer
public extension KeyedDecodingContainer {

    /// Default implementation of decoding a DefaultCodable
    ///
    /// Decodes successfully if key is available if not fallsback to the default value provided.
    func decode<P>(_: DefaultCodable<P>.Type, forKey key: Key) throws -> DefaultCodable<P> {
        if let value = try decodeIfPresent(DefaultCodable<P>.self, forKey: key) {
            return value
        } else {
            return DefaultCodable(wrappedValue: P.defaultValue)
        }
    }
}

public struct DefaultFalseStrategy: DefaultCodableStrategy {
    public static var defaultValue: Bool { return false }
}

/// Decodes Bools defaulting to `false` if applicable
///
/// `@DefaultFalse` decodes Bools and defaults the value to false if the Decoder is unable to decode the value.
public typealias DefaultFalse = DefaultCodable<DefaultFalseStrategy>

public struct DefaultEmptyStringStrategy: DefaultCodableStrategy {
    public static var defaultValue: String { return "" }
}

/// Decodes Bools defaulting to `Empty String` if applicable
///
/// `@DefaultEmptyString` decodes Strings and defaults the value to false if the Decoder is unable to decode the value.
public typealias DefaultEmptyString = DefaultCodable<DefaultEmptyStringStrategy>
