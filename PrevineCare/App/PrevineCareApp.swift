import SwiftUI

@main
struct PrevineCareApp: App {
    @StateObject private var appState = CareAppState()
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(appState)
                .environmentObject(locationService)
                .tint(AppTheme.primary)
                .task {
                    appState.seedDemoIfNeeded()
                    locationService.requestPermission()
                }
        }
    }
}
