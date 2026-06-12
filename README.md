# PrevineCare

PrevineCare is a clean, local-first SwiftUI app foundation for caregiver and patient support.

It is intentionally separate from the original `Previne.swiftpm` Playground codebase so this folder can become a new repository.

## Scope

PrevineCare focuses only on:

- Caregiver mode.
- Patient mode.
- Editable reminders, routines, recurrence, and a simple day calendar.
- Editable safe places with current location or MapKit point selection.
- On-device location checks.
- Explainable risk rules.
- Local notifications.
- Local/demo Help Mode and Lost Mode guidance.
- Preparation for future Apple Watch and on-device AI.

It intentionally does not include Vision Pro, Create ML as a central dependency, external APIs, public web services, Firebase, Supabase, Google Maps, OpenAI, Gemini, Claude, or a required backend.

## How To Open

This folder includes both a Swift Package for testable core logic and an Xcode iOS app project.

1. Open `PrevineCare.xcodeproj` in Xcode.
2. Select the `PrevineCare` scheme.
3. Pick an iPhone simulator.
4. Press Run.

Core tests can also be run with `swift test`.

The SwiftUI app entry point is `PrevineCare/App/PrevineCareApp.swift`.

## Current Implementation

- `Core/Models` contains patient, caregiver, reminder, safe place, location, risk, and alert models.
- `Core/RiskEngine` contains rule-based risk scoring and lost-patient detection.
- `Core/Location` contains CoreLocation integration and local bearing/distance calculations.
- `Core/Notifications` contains local notification scheduling.
- `Core/OnDeviceAI` contains a safe local assistant abstraction with predefined responses.
- `Shared/Theme` contains the app theme, card styles, spacing, radius, and button styles.
- `Features` contains caregiver, patient, reminders, safe places, alerts, and settings SwiftUI screens.

Help Mode and Lost Mode are local MVP flows. The patient can request help, the caregiver can choose a safe place destination, and the patient sees a simple non-map guidance screen. Production cross-device sync is not included.

Reminders use a base `Reminder` definition plus local `ReminderOccurrence` records so completing today's occurrence does not complete future recurring occurrences.

## Privacy

All sensitive processing is designed to happen on device. No HTTP clients, API keys, cloud SDKs, or remote processing are included.
