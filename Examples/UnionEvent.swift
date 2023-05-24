// SUMMARY
//
// AK: Passes data to a view
//    (from anywhere, not just from inside the view hierarchy like Environment)
//
// MARK:  .onUpdatedView
//      ViewModifier
//      Action triggered whenever the view is updated.
//
// MARK:  .onReceivedData
//      ViewModifier
//      Action triggered by calling UnionEventController.send with optional data.
//      This is a simple and reliable way to pass data from a remote event.
//
//  UnionEvent.swift
//
//  Created by Andrew on 20/5/23.
//  Copyright (C) Andrew Kingdom 2023. All rights reserved.
//  License: MIT.
// // // // // // // // // // // //

import SwiftUI

// MARK: -
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension View   {

    // MARK: .onUpdatedView

    // TODO: describe this once working
    /// A function that is called when the associated view updates (reloads)
    ///
    /// In the following code example, `onUpdatedView` is called
    /// when the view loads. `event` contains related values and functions.
    ///
    ///     struct ContentView: View {
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 TextField("Input:",text: $input)
    ///                     .id("Ducky")
    ///                     .tag("Quack")
    ///                     .border(.red)
    ///                     .padding()
    ///                     .onUpdatedView { event in
    ///
    ///                         // displays 'Ducky updated.'
    ///                         print("\(event.ids.last) updated.")
    ///
    ///                     }
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// - Parameter action: The action that you want SwiftUI to perform when
    ///   the view is updated -- when update() is called.
    ///
    /// - Returns: A view that calls `action` when the view updates.
    ///
    @inlinable
    public func onUpdatedView(
        perform action: @escaping ((_ event: UnionEvent) -> Void)
    ) -> some View   // return allows daisychaining, since this is in an extension
    {
        let content = self  // transparent -- not modified

        let union = UnionEvent.initialize(from: content)
        union._action = action
        union.eventType = .onUpdatedView
        action(union)
        return content  // allow daisychaining
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension View   {

    // MARK: .onReceivedData
    
    // TODO: describe this once working
    /// A function that is called when the associated view updates (reloads)
    ///
    /// Requires an `id` proxy value to bind the view.
    /// For example, the following code example, `ContentView` passes both the old and new
    /// values to the model. `event` contains related values and functions.
    ///
    ///     struct ContentView: View {
    ///
    ///         var body: some View {
    ///             VStack {
    ///
    ///                 TextField("Input:",text: $input)
    ///                     .id("Ducky")
    ///                     .border(.red)
    ///                     .onReceivedData { event in
    ///
    ///                         // Displays 'Ducky updated with a puddle.'...
    ///                         let guard let id = event.ids.last as? String,  // get the above ID
    ///                                   let title = event.data["Title"] as? String  // get the sent value
    ///                         else { return }
    ///                         print("\(event.ids.last) updated with \(title).")
    ///
    ///                     }
    ///                     .padding()
    ///
    ///                 Button("Go") {
    ///                     // Send some data...
    ///                     let targetId = "Ducky"
    ///                     let passKey = "Title"
    ///                     let passValue = "a puddle"
    ///                     let dict = [passKey:passValue]
    ///                     UnionEventController.send(id: targetId,data:dict)
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// - Parameter action: The action that you want SwiftUI to perform when
    ///   the view is updated.
    ///
    /// - Returns: A view that calls `action` when `UnionEventController.send`
    ///   is called with a matching `ID`.
    ///
    @inlinable
    public func onReceivedData (
        perform action:   @escaping ((_ event: UnionEvent) -> Void)
    ) -> some View  // return allows daisychaining, since this is in an extension
    {
        let content = self  // transparent -- not modified
        
        let union = UnionEvent.initialize(from: content)
        union.eventType = .onReceivedData
        union._action = action
        UnionEventController.setEventRegistration( union )
        return content  // allow daisychaining
    }
}


/// A struct to control UnionEvent
public struct UnionEventController {

    public static func setEventRegistration( _ event : UnionEvent ) {
        if(cache == nil) { assertionFailure("Requires a `UnionCache` instance variable to be declared in the Scene or App"); return }
        cache!.setEventRegistration(event)
    }

    /// Get the registration details of a given UnionEvent
    public static func getEvent(id:AnyHashable) -> UnionEvent? {
        if(cache == nil) { return nil }
        return cache!.getRegistration(id: id)
    }

    /// Send an event.
    /// This sends the specified`data` dictionary to the `.receiver` `View modifier` with the specified `ID`.
    /// This is included in the `UnionEvent` registration details of the event.
    ///
    public static func send(id: AnyHashable,data:[AnyHashable:Any]) {
        if(cache == nil) { assertionFailure("Requires a `UnionCache` instance variable to be declared in the Scene or App"); return }
        cache!.send(id: id, data: data)
    }
    public static weak var cache: UnionCache?
}


/// A class that persists the Event registration information during and beyond View updates.
///
/// Requires a single instance to be defined as a variable on either a Scene or App struct.
/// For example:
///
///     struct MyScene: Scene {
///         @Environment(\.scenePhase) private var scenePhase
///         @StateObject private var cache = UnionCache()
///
///         var body: some Scene {
///             WindowGroup {
///                 Text("")
///                     ContentView()
///                 }
///                 .onChange(of: scenePhase) { newScenePhase in
///                 if newScenePhase == .background {
///                     cache.empty()
///                 }
///             }
///         }
///     }
///
///
public class UnionCache : ObservableObject {
    private var eventRegistry = [AnyHashable:UnionEvent]()
    
    init() {
        UnionEventController.cache = self  // Replace existing.
    }
    /// set the event registration for a given ID
    public func setEventRegistration( _ union : UnionEvent ) {
        for id in union.ids {
            
            if let old = getRegistration(id:id) {
                // We could merge some values over, if desired...
                union.data = old.data
                // replace existing event
                setRegistration(id: id, event: union)
                print("Replacing existing event")
            } else {
                setRegistration(id:id, event: union)
            }
        }
    }
    /// get the registration for a given ID
    public func getRegistration(id:AnyHashable) -> UnionEvent? {
        return eventRegistry[id]
    }
    /// set the registration for a given ID
    private func setRegistration(id:AnyHashable, event : UnionEvent) {
        eventRegistry[id] = event
    }
    /// Clear the cache by deregistering all events
    public func empty() {
        eventRegistry.removeAll()
    }
    /// Send an event.
    /// This sends the specified`data` dictionary to the `.receiver` `View modifier` with the specified `ID`.
    /// This is included in the `UnionEvent` registration details of the event.
    ///
    public func send(id: AnyHashable,data:[AnyHashable:Any]) {
        if let event = getRegistration(id: id) {
            // #### NOT BEING CALLED -- WHY??? -- no wrapped Event
            event.data = data
            event.eventType = .onReceivedData
            event._action?(event)
        }
    }
}


public class UnionEvent {
    public enum EventType {case onUpdatedView,onReceivedData }
    
    /// The action that you want SwiftUI to perform when the event is triggered.
    /// Don't ever call action from within the action function itself -- that's an infinite loop.
    public var _action:   ((_ union: UnionEvent) -> Void)?
    
    public var eventType: EventType = .onUpdatedView  // default -- this gets changed
    
    // Values from other modifiers of the associated View...
    public var ids = [AnyHashable]()
    public var data = [AnyHashable:Any]()
    public var tags = [AnyHashable]()
    public var textbindings = [Binding<String>]()
    
    public init() {}
}
extension UnionEvent
{
    /// Called by .`onReceiveData` and .`onUpdatedView`
    public static func initialize<T> (from: T) -> UnionEvent where T:View {
        let instance = UnionEvent()  // new instance
        instance.fill(from: from)
        return instance
    }
    /// Fetch the associated .id modifier, so we can register by ID.
    /// Also fetches other values, though we don't strictly need them.
    /// Walks the modifier linked list chain for the associated View, to collect interesting information.
    ///     - .id("some ID") --> ids array
    ///     - .tag("some TAG") --> tags array
    ///     - Binding<String> --> textbindings array
    /// This is all a bit messy as we don't easily know exactly where and what we're dealing with in the hierarchy, so it's a bit of pot-luck as to what we end up with. Future: refine this. Ideally we want to know: current keypath within hirarchy, current generic type (erased of sub-types, for correct identification?)
    private func fill<T>(from: T) {
        let mirror = Mirror(reflecting: from)
        mirror.children.forEach { child in
            switch child.label {
            case "content":
                self.fill(from: child.value)  // walk the hierarchy
                break
            case "modifier":  // Value is single modifier
                let tagged = mirror.descendant("modifier", "value", "tagged")  // Tags are messy to pull apart
                if(tagged != nil) {
                    if let hashableTagged = tagged as? AnyHashable
                    {
                        self.tags.append( hashableTagged )
                    }
                }
                break
            case "modifiers":  // Value is array
                break
            case "id":  // Value is an ID (e.g. String)
                let id = child.value  // never nil
                if let hashableId = id as? AnyHashable
                {
                    self.ids.append( hashableId )
                }
            case "storage":  // Future... do this to allow indirect setting of the storage value
                break
            case "isSecure":  // value is boolean, from (e.g.) TextField
                break
            case "_text":
                if let textbinding = child.value as? Binding<String> {
                    self.textbindings.append( textbinding )
                }
            default:  // unknown
//                print("unknown label: \(child.label)")
                break
            }
        }
    }
}










