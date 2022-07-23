//
//  LocationListView.swift
//  arweatherinformation
//
//  Created by Yasuhito Nagatomo on 2022/06/28.
//

import SwiftUI

struct LocationListView: View {
    @ObservedObject var appStateController: AppStateController
    @State private var showingAddLocation = false
    @State private var showingSettings = false
    @State private var showingAbout = false
    #if DEBUG
    @State private var showingDev = false
    #endif

    // Navigation state
    @State private var selectedLocation: Location?

    private var canAdd: Bool {
        appStateController.locations.count < AppConstant.maximulLocationRegistrationCount
    }

//    let hereLocation = Location(name: "HERE", isHere: true)

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedLocation) {
                Section(header: Text("current location")) {
                    NavigationLink(value: appStateController.currentLocation) {
                        LocationView(location: appStateController.currentLocation)
                    }
//                    .disabled(!appStateController.locationServiceSupported)
                }

                Section(header: Text("favorite")) {
                    ForEach(appStateController.locations.filter({
                        $0.favorite
                    })) { location in
                        NavigationLink(value: location) {
                            LocationView(location: location)
                        }
                    }
                }

                Section(header: Text("registered places")) {
                    ForEach(appStateController.locations) { location in
                        NavigationLink(value: location) {
                            LocationView(location: location)
                        }
                    }
                    .onDelete { offsets in
                        if let offset = offsets.first { // single selection
                            removeLocation(at: offset)
                        }
                    }
                }
            }
            .onChange(of: selectedLocation) { newValue in
                debugLog("DEBUG: selectedLocation was changed.")
                if let newValue, newValue.task == nil {
                    let task = Task.detached(priority: .userInitiated) {
                        await appStateController.checkWeather(for: newValue.id)
                        await appStateController.setTask(nil, toID: newValue.id)
                    }
                    appStateController.setTask(task, toID: newValue.id)
                } else {
                    #if DEBUG
                    if newValue != nil {
                        debugLog("DEBUG: since location.task is not nil, new task did not start.")
                    }
                    #endif
                }
            }
            .navigationTitle("LOCATIONS")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    #if DEBUG
                    Button(action: { showingDev = true }, label: {
                        Label("DEV", systemImage: "doc.badge.gearshape")
                    })
                    #endif
                    Button(action: { showingAddLocation = true }, label: {
                        Label("add", systemImage: "plus")
                    })
                    .disabled(!canAdd)
                }
                // On iOS beta 1, .bottomBar does not work correctly.
                // It sometime appears and sometime does not.
                ToolbarItemGroup(placement: .secondaryAction) { // .bottomBar) {
                    Button(action: { showingSettings = true }, label: {
                        Label("SETTINGS", systemImage: "gear")
                    })
                    Button(action: { showingAbout = true }, label: {
                        Label("ABOUT", systemImage: "note.text")
                    })
                }
            }
            .sheet(isPresented: $showingAbout, onDismiss: nil) {
                AboutView()
            }
            // .fullScreenCover(isPresented: $showingSettings, onDismiss: nil) {
            .sheet(isPresented: $showingSettings, onDismiss: nil) {
                SettingsView()
            }
            .sheet(isPresented: $showingAddLocation, onDismiss: nil) {
                AddLocationView(appStateController: appStateController,
                                isNew: true,
                                locationID: nil)
            }
            #if DEBUG
            .sheet(isPresented: $showingDev, onDismiss: nil) {
                DevView(appStateController: appStateController)
            }
            #endif
        } detail: {
            ForecastView(appStateController: appStateController,
                         locationID: selectedLocation?.id)
            .ignoresSafeArea()
        }
    }

    private func removeLocation(at index: Int) {
//        debugLog("DEBUG: removeLocation(at:) was called.")
        appStateController.removeLocation(at: index)
        appStateController.storeLocations() // store them into UserDefaults
    }
}

struct LocationListView_Previews: PreviewProvider {
    static var previews: some View {
        LocationListView(appStateController: AppStateController())
    }
}
