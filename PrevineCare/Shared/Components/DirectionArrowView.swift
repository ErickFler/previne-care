import CoreLocation
import SwiftUI

struct DirectionArrowView: View {
    let currentLocation: CLLocation?
    let heading: CLHeading?
    let safePlaces: [SafePlace]

    private var nearest: SafePlace? {
        guard let coordinate = currentLocation?.coordinate else { return nil }
        return DirectionCalculator.nearestSafePlace(to: coordinate, in: safePlaces)
    }

    private var rotationDegrees: Double? {
        guard
            let coordinate = currentLocation?.coordinate,
            let nearest,
            let heading
        else { return nil }

        let headingDegrees = heading.trueHeading >= 0 && heading.trueHeading.isFinite
            ? heading.trueHeading
            : heading.magneticHeading

        guard headingDegrees >= 0 && headingDegrees.isFinite else { return nil }

        return DirectionCalculator.relativeBearingDegrees(
            from: coordinate,
            to: nearest.coordinate,
            headingDegrees: headingDegrees
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            if let nearest, let rotationDegrees {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 104, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .rotationEffect(.degrees(rotationDegrees))
                    .accessibilityLabel("Direction to \(nearest.name)")

                Text("Ve hacia \(nearest.name)")
                    .font(.title3.bold())
            } else {
                Image(systemName: "location.slash")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.secondary)

                Text("No puedo calcular la dirección exacta. Quédate en un lugar seguro y espera ayuda.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
