# Product Scope

## Included

- Caregiver mode for setup, review, reminders, safe places, and alerts.
- Patient mode with a simple next-action interface.
- Caregiver PIN to exit patient mode or edit sensitive settings.
- Editable reminders and routines with one-time, daily, weekly, monthly, and selected-weekday recurrence.
- Simple reminder calendar for past, current, and future days.
- "I am okay" and "I need help" patient actions.
- Safe place management with create, edit, and delete.
- Safe place creation with current location, MapKit map selection, circular radius, and approximate block labels.
- Local risk evaluation based on location, time, reminder status, and patient response.
- Local notifications.
- A patient guidance screen for possible lost-patient situations.
- Lost Mode demo with caregiver-selected destination, large compass arrow, local haptics, and short patient instructions.
- On-device assistant interfaces backed by local rules and predefined messages.

## Excluded

- Personal productivity mode.
- Vision Pro features.
- Create ML as the main dependency.
- Public external APIs.
- Backend as a requirement.
- Cloud AI services.
- Remote sensitive processing.
- Internet-required functionality.
- Address search, exact street matching, and external geocoding for safe places.
- Polygon or quadrant safe zones.
- Automatic calls to authorities or real emergency dispatch.
- Apple Watch Lost Mode.

## Future, Not Implemented Yet

- Secure cross-device caregiver alerts.
- Apple Watch companion target.
- HealthKit integration.
- On-device model runtime integration when Apple platform support is appropriate.
- Polygon or quadrant safe zones drawn on a map.
- Secure cross-device synchronization for ActiveGuidanceSession.
- Migration from JSON/UserDefaults-style local storage to SwiftData when persistence needs grow.
