//
//  ContentView.swift
//  TonetimePermission_Example
//
//  Created by George on 10/18/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import SwiftUI
import TonetimePermission

struct ContentView: View {
    
    @State var permissionsGranted = false
    var body: some View {
        if permissionsGranted == false {
            return AnyView(TonetimePermissionsCheck("Tonetime", [.camera,.microphone,.library], $permissionsGranted))
        }
        else {
            return AnyView(Text("You have authorized! Yay!"))
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
