import SwiftUI

enum CareMode: String, Codable {
    case caregiver
    case patient
}

struct AppRouter: View {
    @EnvironmentObject private var appState: CareAppState

    var body: some View {
        Group {
            switch appState.activeMode {
            case .caregiver:
                CaregiverDashboardView()
            case .patient:
                PatientHomeView()
            }
        }
    }
}
