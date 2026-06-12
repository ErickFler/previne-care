# Privacy And On-Device Processing

PrevineCare is designed for sensitive caregiver and patient contexts.

## Current Guarantees

- No external API calls.
- No backend requirement.
- No cloud AI services.
- No location upload.
- No remote processing of reminders, routines, patient notes, or caregiver data.
- Local notifications use `UserNotifications`.
- Location checks use `CoreLocation` on device.

## Local Alert Limitation

In this initial version, caregiver alerts are local to the device running the app. Real alerts between a patient's device and a caregiver's device require a future secure synchronization layer with consent, encryption, authentication, and clear privacy controls.

## Future AI Boundary

The `OnDeviceAI` module is intentionally abstract. It can later be connected to Apple-compatible on-device model runtimes, but it must not send sensitive prompts, patient notes, locations, or routines to cloud services.
