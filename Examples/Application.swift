//
//  ExamplesApp.swift
//  Examples
//
//  Created by Andrew on 11/5/23.
//

import SwiftUI




@main
@MainActor
struct Application: App {

    let persistenceController = PersistenceController.shared

    @StateObject private var cache = UnionCache()  // AK: This caches event registrations
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            
            .onOpenURL { url in  // AK: Called when an external URL link is passed to this app.
                
                // AK: Process the URL.
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return}
                guard let scheme = components.scheme else { return }
                if( scheme != Bundle.main.bundleIdentifier! ) {
                    return
                }
                let path = components.path  // could be used for selecting scene, etc.
                let params = components.queryComponents
                guard path == "/Children", let index = params["index"] else {return }
                let uuid = UUID(uuidString: index)
                
                // tell ContextView about the new selection
                let targetId = "#selectedIndex"
                let passKey = "uuid"
                let passValue = uuid
                let dict = [passKey:passValue as Any]
                UnionEventController.send(id: targetId,data:dict)
            }
            
//            .onAppear(perform: {
//                URLHelper.testURLHelper()  // proving that the helper methods work.
//            })

        }
    }
    
}

