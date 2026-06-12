import CoreLocation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PatientLostModeView: View {
    @EnvironmentObject private var appState: CareAppState
    @EnvironmentObject private var locationService: LocationService
    @State private var haptics = GuidanceHapticsService()
    @State private var signalLostReported = false
    @State private var lastDistanceMeters: Double?
    @State private var lastDistanceChangeAt = Date()

    private let instructionService = GuidanceInstructionService()
    private let noMovementThresholdSeconds: TimeInterval = 90
    private let minimumDistanceChangeMeters: Double = 8

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer(minLength: 12)

                Text(titleText)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)

                if session?.status == .active {
                    GuidanceArrowView(relativeAngleDegrees: relativeAngle, isSignalReliable: isSignalReliable)
                        .frame(width: 230, height: 230)
                        .accessibilityLabel("Guidance direction")
                } else {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 96, weight: .bold))
                        .foregroundStyle(AppTheme.warning)
                        .frame(width: 230, height: 230)
                }

                Text(instructionText)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 58)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 10) {
                    Button("Estoy bien") {
                        appState.patientIsOkay()
                    }
                    .buttonStyle(SecondaryLostModeButtonStyle(color: AppTheme.support))

                    Button("Necesito ayuda") {
                        Task {
                            await appState.patientNeedsHelp(location: latestLocationEvent)
                        }
                    }
                    .buttonStyle(SecondaryLostModeButtonStyle(color: .red))
                }
                .padding(.bottom, 18)
            }
            .padding()
        }
        .onAppear {
            locationService.requestPermission()
            locationService.startMonitoring()
            updateGuidanceTelemetry()
        }
        .onDisappear {
            locationService.stopMonitoring()
        }
        .onReceive(locationService.$currentLocation.compactMap { $0 }) { _ in updateGuidanceTelemetry() }
        .onReceive(locationService.$currentHeading.compactMap { $0 }) { _ in updateGuidanceTelemetry() }
        .task(id: isSignalReliable) {
            guard !isSignalReliable, !signalLostReported else { return }
            signalLostReported = true
            await appState.markGuidanceSignalLost()
        }
    }

    private var session: ActiveGuidanceSession? {
        guard
            let session = appState.activeGuidanceSession,
            session.status == .active || session.status == .failed
        else { return nil }
        return session
    }

    private var titleText: String {
        guard let session, session.status == .active else { return "Tu cuidador fue notificado" }
        return "Ve hacia \(session.destinationName)"
    }

    private var isSignalReliable: Bool {
        guard let location = locationService.currentLocation else { return false }
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 120 else { return false }
        guard currentHeadingDegrees != nil else { return false }
        return session != nil
    }

    private var targetBearing: Double? {
        guard let location = locationService.currentLocation?.coordinate, let session else { return nil }
        return DirectionCalculator.bearing(from: location, to: session.destinationCoordinate)
    }

    private var currentHeadingDegrees: Double? {
        guard let heading = locationService.currentHeading else { return nil }
        let value = heading.trueHeading >= 0 && heading.trueHeading.isFinite ? heading.trueHeading : heading.magneticHeading
        return value >= 0 && value.isFinite ? value : nil
    }

    private var relativeAngle: Double? {
        guard let targetBearing, let currentHeadingDegrees else { return nil }
        return DirectionCalculator.relativeAngle(targetBearing: targetBearing, deviceHeading: currentHeadingDegrees)
    }

    private var instructionText: String {
        guard session?.status == .active else {
            return "Quédate en un lugar seguro."
        }
        guard isSignalReliable, let relativeAngle else {
            return instructionService.unreliableSignalInstruction()
        }
        if hasNoRecentMovement {
            return instructionService.noMovementInstruction()
        }
        return instructionService.instruction(for: relativeAngle)
    }

    private var hasNoRecentMovement: Bool {
        Date().timeIntervalSince(lastDistanceChangeAt) >= noMovementThresholdSeconds
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

    private func updateGuidanceTelemetry() {
        guard let session, let location = locationService.currentLocation else { return }
        let distance = DirectionCalculator.distanceMeters(from: location.coordinate, to: session.destinationCoordinate)
        let bearing = DirectionCalculator.bearing(from: location.coordinate, to: session.destinationCoordinate)

        if let lastDistanceMeters, abs(lastDistanceMeters - distance) >= minimumDistanceChangeMeters {
            lastDistanceChangeAt = Date()
        } else if lastDistanceMeters == nil {
            lastDistanceChangeAt = Date()
        }

        lastDistanceMeters = distance
        appState.updateActiveGuidance(distanceMeters: distance, bearingDegrees: bearing)

        guard isSignalReliable, let relativeAngle else { return }
        haptics.playFeedback(for: relativeAngle)
    }
}

struct GuidanceArrowView: View {
    let relativeAngleDegrees: Double?
    let isSignalReliable: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.surface)
                .overlay(Circle().stroke(AppTheme.primary.opacity(0.2), lineWidth: 3))

            if let relativeAngleDegrees, isSignalReliable {
                Image(systemName: "location.north.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(44)
                    .foregroundStyle(AppTheme.primary)
                    .rotationEffect(.degrees(relativeAngleDegrees))
                    .animation(.spring(response: 0.45, dampingFraction: 0.72), value: relativeAngleDegrees)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(62)
                    .foregroundStyle(AppTheme.warning)
            }
        }
    }
}

struct GuidanceInstructionService: Sendable {
    func instruction(for relativeAngle: Double) -> String {
        switch relativeAngle {
        case -15...15:
            return "Sigue avanzando"
        case 15...120:
            return "Gira un poco a la derecha"
        case -120 ..< -15:
            return "Gira un poco a la izquierda"
        default:
            return "Da la vuelta lentamente"
        }
    }

    func noMovementInstruction() -> String {
        Bool.random() ? "Quédate tranquilo. El cuidador fue notificado." : "Espera en un lugar seguro."
    }

    func unreliableSignalInstruction() -> String {
        "Espera. Estamos avisando al cuidador."
    }
}

final class GuidanceHapticsService {
    private var lastFeedbackAt = Date.distantPast
    private let minimumInterval: TimeInterval = 5

    func playFeedback(for relativeAngle: Double) {
        guard Date().timeIntervalSince(lastFeedbackAt) >= minimumInterval else { return }
        lastFeedbackAt = Date()

        #if canImport(UIKit)
        let absoluteAngle = abs(relativeAngle)
        if absoluteAngle <= 15 {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
        } else if absoluteAngle <= 75 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.35)
        } else if absoluteAngle >= 120 {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }
}

private struct SecondaryLostModeButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(color)
            .background(color.opacity(configuration.isPressed ? 0.16 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
