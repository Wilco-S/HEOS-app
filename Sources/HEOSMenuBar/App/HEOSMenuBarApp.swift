import SwiftUI

@main
struct HEOSMenuBarApp: App {
    @StateObject private var model = HEOSAppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(model)
                .task { model.start() }
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environmentObject(model)
        }
    }

}
