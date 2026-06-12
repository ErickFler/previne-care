# Architecture

PrevineCare uses a simple SwiftUI MVVM-style architecture.

## Layers

- `App`: app entry point and high-level routing.
- `Core/Models`: domain models shared by views, services, and tests.
- `Core/Storage`: local persistence adapters and SwiftData-ready models.
- `Core/Location`: CoreLocation service and local geospatial calculations.
- `Core/Notifications`: UserNotifications scheduling.
- `Core/RiskEngine`: explainable rule-based risk evaluation.
- `Core/OnDeviceAI`: local assistant protocols and predefined guidance.
- `Features`: SwiftUI screens and feature view models.
- `Shared`: reusable views, theme, and small utilities.

## Data Flow

Views call feature view models or local app state. Feature state calls services from `Core`. `RiskEngine` is deterministic and testable; it receives a `RiskAssessmentContext` and returns a `RiskAssessmentResult`.

## No External Services

The initial version has no HTTP client, backend SDK, public API dependency, or cloud AI integration. Real cross-device caregiver notifications will require a future secure sync layer, documented separately.

## Safe Places

Safe Places are evaluated on-device with CoreLocation distance calculations. The current MVP stores each safe zone as a circular area with a center coordinate and radius in meters. `SafeZoneShape` includes a future `polygon` case so map-drawn zones can be added later without changing the high-level domain model, but only circular zones are implemented now.

Caregiver-facing "blocks" are approximate labels derived from radius size. They intentionally avoid claiming street-level precision because block length varies by city and neighborhood.

Address search, exact street matching, and geocoding are outside the MVP because they would introduce network or external service dependencies. Caregivers can use current location or pick a point directly on the MapKit map.

## Apple Watch Preparation

The domain models are value types and Codable where possible so they can later be shared with a Watch target. The patient actions are intentionally small commands: check in, request help, view next reminder, and show guidance.
