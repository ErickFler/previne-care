# Migration Notes From Previne

The original Previne Playground contains useful pieces but also broader app flows that are outside PrevineCare's scope.

## Recreated

- Patient profile.
- Caregiver profile.
- Reminder list and daily completion.
- Caregiver dashboard.
- Patient dashboard.
- Caregiver PIN gate for patient mode.
- Safe places.
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
- Tests cover risk and direction calculations.
