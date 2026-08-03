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
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environmentObject(model)
        }
    }

}
