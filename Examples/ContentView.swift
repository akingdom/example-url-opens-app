//
//  ContentView.swift
//  Examples
//
//  Created by Andrew on 11/5/23.
//

import SwiftUI
import CoreData

struct ContentView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @State public var selectedItem: UUID? = nil  // AK: Address ID of the selected row
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                ForEach(items, id:\.uuid) { item in
                    NavigationLink(tag: item.uuid!, selection: $selectedItem) {
                        
                        VStack {
                            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                                .font(.system(size: 36))
                                .padding()
                            
                            /* AK: */
                            Text("URL Link:")
                                .padding()
                            Divider()
                            Text("\(theURL(uuid: item.uuid))").italic()
                                .padding()
                            Divider()
                            Button("Copy") { let pasteboard = UIPasteboard.general
                                pasteboard.string = "\(theURL(uuid: item.uuid))"
                            }
                            .padding()
                            .background(Color(red: 0.5, green: 0.5, blue: 1.0))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .frame(
                              minWidth: 0,
                              maxWidth: .infinity,
                              minHeight: 0,
                              maxHeight: .infinity,
                              alignment: .topLeading
                            )
                        .background(Color(UIColor(ciColor: CIColor(string: item.color ?? "1.0 1.0 1.0 1.0"))))
                    
                    } label: {
                        Text(item.timestamp!, formatter: itemFormatter)
                            .listRowBackground((self.selectedItem ?? UUID.zero) == item.uuid ? Color.red : Color.yellow)//Color(UIColor.systemGroupedBackground))
//                            .listRowBackground(
//                                Text("ABCD")
////                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                    .background(Color.yellow)
////                                    .foregroundColor(.purple)
////                                    .opacity(0.5)
//                                )
                    }
                    
//                    .listRowBackground(
//                        //                        View()
//                        .background(Color(UIColor.systemYellow))//systemBackground systemYellow
//                    )
                }
                
                .onDelete(perform: deleteItems)
            
            }
            
            // AK: This is put outside the list, otherwise it will be called once per list row.
            .id("#selectedIndex")   // AK: Required ID to identify the event target
            .onReceivedData {event in  // AK: The event target
                
                guard let id = event.ids.last as? String,  // get the above ID
                      let selectedUuid = event.data["uuid"] as? UUID  // get the sent value
                else { return }
                print("\(id) received value \(selectedUuid)")
                self.selectedItem = selectedUuid  // update the bound Text display string with the new value
            }
        
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.uuid = UUID()  // AK: unique id
            newItem.color = CIColor(color: UIColor.lightRandom()).stringRepresentation
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // AK: get URL for a UUID (a better ID than an Integer index as it doesn't change when you delete something)
    private func theURL(uuid:UUID?) -> String {
        guard (uuid != nil) else {return ""}
        return theURL(id: uuid!.uuidString)
    }
    
    // AK: get URL for a String
    private func theURL(id:String) -> String {
        guard let url = URL(string: URLHelper.urlBuilder(
            bundleId: Bundle.main.bundleIdentifier!,  // like url ip-name
            pathItems: ["Children"],  // like url port
            keyValues: ["index" : "\(id)"]  // like url query
        )) else { return "" }
        return url.absoluteString
    }
    
    
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()


extension UIColor {
    public static func lightRandom() -> UIColor {
        return UIColor(
            red:   .random(in: 0.75...1.0),
           green: .random(in: 0.75...1.0),
           blue:  .random(in: 0.75...1.0),
           alpha: 1.0
        )
    }
}

extension UILabel {
    func setSizeFont (sizeFont: Double) {
        self.font =  UIFont(name: self.font.fontName, size: sizeFont)!
        self.sizeToFit()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
