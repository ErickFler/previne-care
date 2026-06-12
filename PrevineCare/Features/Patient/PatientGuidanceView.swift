import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PatientGuidanceView: View {
    @EnvironmentObject private var appState: CareAppState
    @EnvironmentObject private var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    private let guidance = CalmingGuidanceService()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Tranquilo, te vamos a ayudar")
                    .font(.system(size: 38, weight: .bold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)

                Text("Quédate donde estás")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.primary)

                DirectionArrowView(
                    currentLocation: locationService.currentLocation,
                    heading: locationService.currentHeading,
                    safePlaces: appState.safePlaces
                )

                VStack(spacing: 10) {
                    ForEach(guidance.allMessages, id: \.self) { message in
                        Text(message)
                            .font(.title3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Estoy bien") {
                    appState.patientIsOkay()
                    dismiss()
                }
                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.support))

                Button("Necesito ayuda") {
                    Task {
                        await appState.patientNeedsHelp(location: latestLocationEvent)
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle(color: .red))

                Button("Llamar a mi cuidador") {
                    call(appState.caregiver.phone)
                }
                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.primary))
            }
            .padding()
        }
        .onAppear {
            locationService.startMonitoring()
        }
    }

    private var latestLocationEvent: LocationEvent? {
        locationService.currentLocation.map {
            LocationEvent(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                accuracy: $0.horizontalAccuracy,
                timestamp: $0.timestamp
            )
        }
    }

    private func call(_ phone: String?) {
        #if canImport(UIKit)
        guard
            let phone,
            let url = URL(string: "tel://\(phone.filter(\.isNumber))")
        else { return }
        UIApplication.shared.open(url)
        #endif
    }
}
