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

## Apple Watch Preparation

The domain models are value types and Codable where possible so they can later be shared with a Watch target. The patient actions are intentionally small commands: check in, request help, view next reminder, and show guidance.
