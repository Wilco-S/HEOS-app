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
            Image(systemName: menuBarIcon)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environmentObject(model)
        }
    }

    private var menuBarIcon: String {
        model.connectionState == .connected ? "hifispeaker.2.fill" : "hifispeaker.2"
    }
}
