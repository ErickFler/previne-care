# PrevineCare

PrevineCare is a clean, local-first SwiftUI app foundation for caregiver and patient support.

It is intentionally separate from the original `Previne.swiftpm` Playground codebase so this folder can become a new repository.

## Scope

PrevineCare focuses only on:

- Caregiver mode.
- Patient mode.
- Daily reminders and routines.
- Safe places.
- On-device location checks.
- Explainable risk rules.
- Local notifications.
- Preparation for Apple Watch and on-device AI.

It intentionally does not include Vision Pro, Create ML as a central dependency, external APIs, public web services, Firebase, Supabase, Google Maps, OpenAI, Gemini, Claude, or a required backend.

## How To Open

This folder includes a Swift Package so the core logic can be opened and tested directly in Xcode:

1. Open `PrevineCare/Package.swift` in Xcode.
2. Run the `RiskEngineTests` and `LocationLogicTests` test targets.
3. To create the iOS app target, create a new SwiftUI iOS app in Xcode named `PrevineCare`, then add the `PrevineCare/PrevineCare` folder to the target.

The SwiftUI app entry point is `PrevineCare/App/PrevineCareApp.swift`.

## Current Implementation

- `Core/Models` contains patient, caregiver, reminder, safe place, location, risk, and alert models.
- `Core/RiskEngine` contains rule-based risk scoring and lost-patient detection.
- `Core/Location` contains CoreLocation integration and local bearing/distance calculations.
- `Core/Notifications` contains local notification scheduling.
- `Core/OnDeviceAI` contains a safe local assistant abstraction with predefined responses.
- `Features` contains caregiver, patient, reminders, safe places, alerts, and settings SwiftUI screens.

## Privacy

All sensitive processing is designed to happen on device. No HTTP clients, API keys, cloud SDKs, or remote processing are included.
