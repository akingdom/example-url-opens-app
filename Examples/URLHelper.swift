//
// SUMMARY
//
// AK: Splits and joins various components of a URL
//
//  URLThings.swift
//  OpenThings
//
//  Created by Andrew on 11/5/23.
//

import Foundation

public class URLHelper {
    
    public static let encodingFailure = "%3F%3F"  // "%3F%3F" decodes to "??" (per the next line):
    public static let decodingFailure = "??"  // We use this to show that the unicode string could not be encoded or decoded (very rare -- eg. UTF16 hex d8 00 big-endian).
    
    
    ///
    ///
    /// Define key-values in a dictionary, if you want the url to send any values when opened
    ///
    /// bundleId is a url scheme (such as an ip-name)
    /// scenePath is a url path
    /// keyValues is like a url query
    ///
    /// Example:
    /// let url = urlScheme( ... keyValues: ["recordindex": indexString]}  // include the record number to try to open
    /// ...might become...
    /// OpenThings?index=1
    ///
    /// - Parameters:
    ///
    ///
    public static func urlBuilder ( bundleId: String, pathItems: [String]?, keyValues: Dictionary<String,String>? ) -> String {
        
        // encode...
        
        // RFC 1808 - Relative Uniform Resource Locators
        
        var components = URLComponents()
        components.scheme = bundleId  // will percent-encode
        components.host = ""  // required in order to get the necessary ://
        components.pathComponents = pathItems ?? ["/"]  // will percent-encoded
        components.queryComponents = keyValues ?? [:]  // will be percent-encoded
        return "\(components.url?.absoluteString ?? "??")"
    }
    
    /// transforms a URL query string into a key-value pair dictionary
    public static func keyValuesFrom(url:URL) -> Dictionary<String,String> {
        if let query = url.query {
            return keyValuesFrom(query: query)
        } else {
            return [:]
        }
    }
    /// transforms a URL query string into a key-value pair dictionary
    public static func keyValuesFrom(query:String) -> Dictionary<String,String> {
        let querycomponents = URLComponents( string: "?\(query)" )
        let queryItems : [URLQueryItem] = querycomponents?.queryItems ?? [],
        querydict : [String:String] = queryItems.reduce(into: [String: String]()) { let key = $1.name; $0[key] = $1.value }
        return querydict
    }

}

extension UUID {
    /// A default value for UUID
    public static var zero : UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}

extension URLComponents {
    
    /// The path subcomponent split into an array of path components.
    /// Equivalent to url.pathComponents
    ///
    /// The getter for this property removes any percent encoding this component may have (if the component allows percent encoding). Setting this property assumes the path component string are not percent encoded and will add percent encoding (if the component allows percent encoding).
    public var pathComponents : [String] {
        get {
            var parts = self.path.components(separatedBy: "/")
            if let first = parts.first, first.isEmpty {parts[0] = "/"}  // include empty path prefix as '/'
            if let last = parts.last, last.isEmpty {parts.removeLast()}  // skip empty path suffix
            return parts
        }
        set {
            if newValue.count > 0, newValue[0].starts(with: "/") {
                self.path = "\(newValue.joined(separator: "/"))"
            } else {
                self.path = "/\(newValue.joined(separator: "/"))"  // must have leading slash or there's an error decoding the host
            }
        }
    }
    
    /// Transforms a URL query string <-> a key-value pair dictionary
    public var queryComponents : Dictionary<String,String> {
        get {
            if let query = self.query {
                return URLHelper.keyValuesFrom(query: query)
            } else {
                return [:]
            }
        }
        set {
            self.queryItems = newValue.compactMap { URLQueryItem(name: $0, value: $1) }  // keyvalue dictionary to array of URLQueryItem keyvalues, each
        }
    }
}

extension URLHelper {
    public static func testURLHelper() {
        
        // Pass test values through the entire URL encode-decode pipeline, checking they are the same at the end.
        
        let recordIndex: UUID = UUID(uuidString: "f3e0ee97-c3f4-4404-beb5-a2a52633b9ab")!  // example -- could also be UUID() to generate one
        let recordString: String = "\(recordIndex.uuidString)"
        let testValue = "a!@#$%^&*()_-+={[}]|\"\\/?:;.<>,|≈ßÍ∑🇬🇷♥️⚠️🔗🛠🤔Z"
        let bundleId: String = Bundle.main.bundleIdentifier!
        let scenePath: [String] = ["This","That"]
        let keyValues: Dictionary<String,String> = ["recordindex": recordString, "something": testValue]
        
        // encode...
        
        let urlstring = urlBuilder(bundleId: bundleId, pathItems: scenePath, keyValues: keyValues),
            url = URL(string: urlstring)!
        print(url.absoluteString)
        
        // decode
        
//        let port = url.port  // nil
//        let host = url.host  // nil
        let scheme = url.scheme  // == bundleId - instead of 'https' for example
//        let path = url.path  //  == "/This/That"
        let pathcomponents = url.pathComponents  // ["/", "This", "That"]
//        let fragment = url.fragment  // nil
//        let query = url.query  // ?recordindex=F3E0EE97-C3F4-4404-BEB5-A2A52633B9AB&something=a!@%23$%25%5E%26*()_-+%3D%7B%5B%7D%5D%7C%22%5C/?:;.%3C%3E,%7C%EF%A3%BF%E2%89%88%C3%9F%C3%8D%E2%88%91%F0%9F%87%AC%F0%9F%87%B7%E2%99%A5%EF%B8%8F%E2%9A%A0%EF%B8%8F%F0%9F%94%97%F0%9F%9B%A0%F0%9F%A4%94Z
        let querydict : [String:String] = URLHelper.keyValuesFrom(url: url)
//        ▿ 2 elements
//          ▿ 0 : 2 elements
//            - key : "recordindex"
//            - value : "F3E0EE97-C3F4-4404-BEB5-A2A52633B9AB"
//          ▿ 1 : 2 elements
//            - key : "something"
//            - value : "a!@#$%^&*()_-+={[}]|\"\\/?:;.<>,|≈ßÍ∑🇬🇷♥️⚠️🔗🛠🤔Z"
        let recordIndex2 = UUID(uuidString: querydict["recordindex"]!)
        let testValue2 = querydict["something"]

        assert(pathcomponents[0] == "/" && pathcomponents[1] == scenePath[0] && pathcomponents[2] == scenePath[1])
        assert(scheme == bundleId)
        assert(recordIndex == recordIndex2)
        assert(testValue == testValue2)
        
        return
    }
}
