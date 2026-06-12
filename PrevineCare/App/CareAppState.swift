import Foundation

@MainActor
final class CareAppState: ObservableObject {
    @Published var activeMode: CareMode = .caregiver {
        didSet { save() }
    }

    @Published var patient = PatientProfile(name: "Javier", emergencyNotes: "Prefiere instrucciones cortas y calmadas.") {
        didSet { save() }
    }

    @Published var caregiver = CaregiverProfile(
        name: "Erick Flores",
        phone: "3232323232",
        relationship: "Father",
        emergencyPhone: "911",
        caregiverPIN: "1234"
    ) {
        didSet { save() }
    }

    @Published var reminders: [Reminder] = [] {
        didSet { save() }
    }

    @Published var safePlaces: [SafePlace] = [] {
        didSet { save() }
    }

    @Published var riskEvents: [RiskEvent] = [] {
        didSet { save() }
    }

    @Published var lastPatientCheckIn: Date? {
        didSet { save() }
    }

    @Published var activeGuidanceSession: ActiveGuidanceSession? {
        didSet { save() }
    }

    private let riskEngine = RiskEngine()
    private let lostDetector = LostPatientDetector()
    private let storageKey = "previnecare.app-state.v1"

    init() {
        let snapshot = LocalJSONStore.load(AppSnapshot.self, key: storageKey, fallback: .empty)
        if let snapshotPatient = snapshot.patient {
            patient = snapshotPatient
            caregiver = snapshot.caregiver
            reminders = snapshot.reminders
            safePlaces = snapshot.safePlaces
            riskEvents = snapshot.riskEvents
            lastPatientCheckIn = snapshot.lastPatientCheckIn
            activeMode = snapshot.activeMode
            activeGuidanceSession = snapshot.activeGuidanceSession
        }
    }

    var openRiskEvents: [RiskEvent] {
        riskEvents.filter { $0.status == .open }.sorted { $0.timestamp > $1.timestamp }
    }

    var latestOpenRiskEvent: RiskEvent? {
        openRiskEvents.first
    }

    var todayReminders: [Reminder] {
        reminders.sorted { $0.scheduleDate < $1.scheduleDate }
    }

    var nextReminder: Reminder? {
        todayReminders.first { $0.status == .pending }
    }

    func seedDemoIfNeeded() {
        guard reminders.isEmpty && safePlaces.isEmpty else { return }
        let calendar = Calendar.current
        let now = Date()
        reminders = [
            Reminder(
                title: "Take morning medicine",
                type: .medication,
                scheduleDate: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
                instructions: "Take the pills with water.",
                requiresConfirmation: true,
                isCritical: true
            ),
            Reminder(
                title: "Eat breakfast",
                type: .meal,
                scheduleDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                instructions: "Sit at the table and eat something light."
            ),
            Reminder(
                title: "Short walk",
                type: .movement,
                scheduleDate: calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now) ?? now,
                instructions: "Walk only near home."
            )
        ]

        safePlaces = [
            SafePlace(name: "Home", type: .home, latitude: 25.6516, longitude: -100.2897, radiusMeters: 180),
            SafePlace(name: "Clinic", type: .clinic, latitude: 25.6490, longitude: -100.2920, radiusMeters: 120)
        ]
    }

    func enterPatientMode(pin: String) -> Bool {
        guard verifyPIN(pin) else { return false }
        activeMode = .patient
        return true
    }

    func exitPatientMode(pin: String) -> Bool {
        guard verifyPIN(pin) else { return false }
        activeMode = .caregiver
        return true
    }

    func verifyPIN(_ pin: String) -> Bool {
        pin.filter(\.isNumber) == caregiver.caregiverPIN.filter(\.isNumber)
    }

    func complete(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].status = .completed
        lastPatientCheckIn = Date()
    }

    func patientIsOkay() {
        lastPatientCheckIn = Date()
        completeActiveGuidanceSession()
    }

    func patientNeedsHelp(location: LocationEvent?) async {
        let event = RiskEvent(
            patientID: patient.id,
            riskScore: 90,
            riskLevel: .high,
            reasons: ["Patient pressed Need help."],
            lastLocation: location
        )
        riskEvents.insert(event, at: 0)
        await LocalNotificationService.shared.notifyCaregiver(riskEvent: event, patientName: patient.name)
    }

    func startGuidance(to safePlace: SafePlace) {
        activeGuidanceSession = ActiveGuidanceSession(
            patientId: patient.id,
            destinationSafePlaceId: safePlace.id,
            destinationName: safePlace.name,
            destinationLatitude: safePlace.latitude,
            destinationLongitude: safePlace.longitude
        )
        activeMode = .patient
    }

    func updateActiveGuidance(distanceMeters: Double?, bearingDegrees: Double?) {
        guard var session = activeGuidanceSession, session.status == .active else { return }
        session.lastKnownDistanceMeters = distanceMeters
        session.lastKnownBearingDegrees = bearingDegrees
        activeGuidanceSession = session
    }

    func completeActiveGuidanceSession() {
        updateGuidanceStatus(.completed)
    }

    func cancelActiveGuidanceSession() {
        updateGuidanceStatus(.cancelled)
    }

    func markGuidanceSignalLost() async {
        updateGuidanceStatus(.failed)
        let event = RiskEvent(
            patientID: patient.id,
            riskScore: 70,
            riskLevel: .high,
            reasons: ["GuidanceSignalLostEvent", "Location or compass signal is not reliable."],
            lastLocation: nil
        )
        riskEvents.insert(event, at: 0)
        await LocalNotificationService.shared.notifyCaregiver(riskEvent: event, patientName: patient.name)
    }

    func evaluateRisk(currentLocation: LocationEvent?, recentLocations: [LocationEvent] = []) async {
        let context = RiskAssessmentContext(
            patient: patient,
            currentLocation: currentLocation,
            recentLocationEvents: recentLocations,
            safePlaces: safePlaces,
            reminders: reminders,
            now: Date(),
            lastPatientCheckIn: lastPatientCheckIn,
            minutesAwayFromHome: nil,
            minutesSinceLastResponse: minutesSinceLastResponse()
        )
        let result = riskEngine.evaluate(context)
        let lostResult = lostDetector.evaluate(context)

        guard result.shouldAlertCaregiver || lostResult.isPossiblyLost else { return }

        var event = riskEngine.makeRiskEvent(from: result, context: context)
        if lostResult.isPossiblyLost {
            event.reasons.append(contentsOf: lostResult.reasons)
            event.riskScore = max(event.riskScore, lostResult.confidenceLevel == .high ? 80 : 50)
            event.riskLevel = RiskEngine.level(for: event.riskScore)
        }

        riskEvents.insert(event, at: 0)
        await LocalNotificationService.shared.notifyCaregiver(riskEvent: event, patientName: patient.name)
    }

    func markAlertResolved(_ event: RiskEvent) {
        guard let index = riskEvents.firstIndex(where: { $0.id == event.id }) else { return }
        riskEvents[index].status = .resolved
    }

    private func minutesSinceLastResponse() -> Int? {
        guard let lastPatientCheckIn else { return nil }
        return Calendar.current.dateComponents([.minute], from: lastPatientCheckIn, to: Date()).minute
    }

    private func updateGuidanceStatus(_ status: GuidanceSessionStatus) {
        guard var session = activeGuidanceSession else { return }
        session.status = status
        activeGuidanceSession = session
    }

    private func save() {
        let snapshot = AppSnapshot(
            patient: patient,
            caregiver: caregiver,
            reminders: reminders,
            safePlaces: safePlaces,
            riskEvents: riskEvents,
            lastPatientCheckIn: lastPatientCheckIn,
            activeMode: activeMode,
            activeGuidanceSession: activeGuidanceSession
        )
        LocalJSONStore.save(snapshot, key: storageKey)
    }
}

private struct AppSnapshot: Codable {
    var patient: PatientProfile?
    var caregiver: CaregiverProfile
    var reminders: [Reminder]
    var safePlaces: [SafePlace]
    var riskEvents: [RiskEvent]
    var lastPatientCheckIn: Date?
    var activeMode: CareMode
    var activeGuidanceSession: ActiveGuidanceSession?

    init(
        patient: PatientProfile?,
        caregiver: CaregiverProfile,
        reminders: [Reminder],
        safePlaces: [SafePlace],
        riskEvents: [RiskEvent],
        lastPatientCheckIn: Date?,
        activeMode: CareMode,
        activeGuidanceSession: ActiveGuidanceSession?
    ) {
        self.patient = patient
        self.caregiver = caregiver
        self.reminders = reminders
        self.safePlaces = safePlaces
        self.riskEvents = riskEvents
        self.lastPatientCheckIn = lastPatientCheckIn
        self.activeMode = activeMode
        self.activeGuidanceSession = activeGuidanceSession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patient = try container.decodeIfPresent(PatientProfile.self, forKey: .patient)
        caregiver = try container.decode(CaregiverProfile.self, forKey: .caregiver)
        reminders = try container.decode([Reminder].self, forKey: .reminders)
        safePlaces = try container.decode([SafePlace].self, forKey: .safePlaces)
        riskEvents = try container.decode([RiskEvent].self, forKey: .riskEvents)
        lastPatientCheckIn = try container.decodeIfPresent(Date.self, forKey: .lastPatientCheckIn)
        activeMode = try container.decode(CareMode.self, forKey: .activeMode)
        activeGuidanceSession = try container.decodeIfPresent(ActiveGuidanceSession.self, forKey: .activeGuidanceSession)
    }

    static let empty = AppSnapshot(
        patient: nil,
        caregiver: CaregiverProfile(),
        reminders: [],
        safePlaces: [],
        riskEvents: [],
        lastPatientCheckIn: nil,
        activeMode: .caregiver,
        activeGuidanceSession: nil
    )
}
