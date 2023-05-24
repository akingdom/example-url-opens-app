//
//  Examples only -- not required
//
//  Examples.swift
//  OpenThings
//
//  Created by Andrew on 11/5/23.
//
// See README.md file.
//
import UIKit

class Examples {
    
    /// AK: Example to open an application
    ///
    public func example1_openApp() {
        
        let url = URL(string: "andrewkingdom.bizz.page.OpenThings:Children?index=1")
        
        UIApplication.shared.open(url!) { (result) in
            if result {
                // The URL was delivered successfully!
            }
        }
    }

    /// AK: Functionally identical to example1
    ///  but we build the URL programmatically.
    ///
    public func example2_openApp() {
       
        let url = URL(string: URLHelper.urlScheme(
            bundleId: "andrewkingdom.bizz.page.OpenThings",
            scenePath: "Children",
            keyValues: ["index" : "1"]  // dictionary
        ))

        UIApplication.shared.open(url!) { (result) in
            if result {
                // The URL was delivered successfully!
            }
        }
    }
    
    /// AK: Functionally identical to example1
    ///  but we build the URL programmatically
    ///  and use the bundle-id as the app
    ///
    public func example3_openApp() {
       
        let url = URL(string: URLHelper.urlScheme(
            bundleId: Bundle.main.bundleIdentifier!,
            scenePath: "Children",
            keyValues: ["index" : "1"]  // dictionary
        ))

        UIApplication.shared.open(url!) { (result) in
            if result {
                // The URL was delivered successfully!
            }
        }
    }
}
