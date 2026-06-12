# Migration Notes From Previne

The original Previne Playground contains useful pieces but also broader app flows that are outside PrevineCare's scope.

## Recreated

- Patient profile.
- Caregiver profile.
- Reminder list, editing, recurrence, occurrence completion, and calendar.
- Caregiver dashboard.
- Patient dashboard.
- Caregiver PIN gate for patient mode.
- Safe places with create/edit/delete and MapKit selection.
- Local notification manager.
- CoreLocation manager.

## Not Migrated

- General personal mode.
- Demo authentication and broad onboarding.
- Vision Pro references.
- Non-caregiver/patient features.
- Any future cloud, backend, or public API dependency.

## Changed

- Risk logic is now explicit and isolated in `RiskEngine`.
- Lost-patient detection is a first-class local rule service.
- On-device AI is represented by protocols and local responses, not by external APIs.
- Help/Lost Mode state is explicit and does not activate from demo seed data.
- Tests cover risk, direction, safe-place checks, and reminder recurrence.

## Pending Migration Work

- Replace the MVP local JSON persistence with SwiftData if the app needs richer queries or multi-device sync.
- Add secure caregiver/patient synchronization for `ActiveGuidanceSession`.
- Expand reminder occurrence history if long-term analytics are needed.
