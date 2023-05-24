# example-url-opens-app
How to open an iOS app/record from an external URL and 
how to pass that information to a View.


## About

This project demonstrates two separate concepts:

- How to use a URL to open an installed iOS application. This uses standard methods and is well documented.

- How to show a different record in a view. 

- How to pass a URL's information to a sub-view. This code is tested as being reliable in its currently use-case but may break if used in unintended ways. This is an alternative to using standard SwiftUI .enviroment and .onChange modifiers.


## How to use this example app.


1. Open the app

2. Add multiple new records (+ icon on top left of screen).
    (Delete isn't implemented for MacOS/Catalyst)

3. Select a record (screen background changes color)

4. Click the Copy button 

5. Paste the URL into TextEdit or Notes app (as a link)

6. Select another record (different colour, time)

7. Click the link - the app will open (if necessary) and the linked record will display with its correct time and colour.
   (The wrong record appears to be selected on the left -- this appears to be a well-known limit of SwiftUI -- there are complicated hacks to work around this)



## Doing this in another app project.


### 1. Copy the following files to the project...

    * UnionEvent.swift      -- A more flexible way to share data with SwiftUI than using Environment. 

    * URLHelper.swift       -- Encodes and decodes URLs.

### 2. Copy any desired code from the following files, from the sections marked by 'AK:'...    

    * Application.swift     -- The `.onOpenURL() { url in ... }` modifier method which handles all incoming URL events.
                            -- The `cache` variable, which tracks event registrations.

    * ContentView.swift     -- The code to switch to a new record based on changes to `selectedItem`.
                            -- The `selectedItem` variable, which is an ID matching the current record.
                            -- The `onReceivedData` modifier method and its preceding `id(..)` modifier, which receives data notifications from `onOpenURL()`, and sets `selectedItem` to show a different record.  
                            -- The `theURL(..)` methods, which create a URL from a given record's UUID -- see `Copy` button for an example.

### 3. Register a URL scheme in the project

- Open Project Page (project root node in the Project navigator view)

- Select Target under **Targets** (NOT *Projects*). (In this project the target is called OpenThings)

- Select the **Info** tab at the top.

- Expand URL Types section

- Add a URL Type (+ button). There is no delete here - to delete, go to URL Types in the project's info.plist file, then reopen the project (ancient bug workaround).

    -- Identifier: An arbitrary name of your choice
    -- URL Schemes: andrewkingdom.bizz.page.Examples (IMPORTANT: It is *recommended* to match the app's bundle ID. This is *not* a server address.)
    -- Role: Editor (or Viewer if it opens another app that you don't own)
    -- Icon: (unused)

### 4. Get a url and check that it opens the project.



