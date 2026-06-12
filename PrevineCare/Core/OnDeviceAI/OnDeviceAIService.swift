import Foundation

public protocol OnDeviceAIServiceProtocol: Sendable {
    func calmingMessage(for riskLevel: RiskLevel) -> String
    func patientLostInstructions() -> [String]
    func caregiverSummary(patient: PatientProfile, reminders: [Reminder], latestRisk: RiskEvent?) -> String
}

public struct LocalAssistantService: OnDeviceAIServiceProtocol {
    private let calmingGuidance = CalmingGuidanceService()
    private let patientPromptGenerator = PatientPromptGenerator()
    private let caregiverSummaryGenerator = CaregiverSummaryGenerator()

    public init() {}

    public func calmingMessage(for riskLevel: RiskLevel) -> String {
        calmingGuidance.message(for: riskLevel)
    }

    public func patientLostInstructions() -> [String] {
        patientPromptGenerator.lostPatientPrompts()
    }

    public func caregiverSummary(patient: PatientProfile, reminders: [Reminder], latestRisk: RiskEvent?) -> String {
        caregiverSummaryGenerator.summary(patient: patient, reminders: reminders, latestRisk: latestRisk)
    }
}

public struct CalmingGuidanceService: Sendable {
    public init() {}

    public func message(for riskLevel: RiskLevel = .low) -> String {
        switch riskLevel {
        case .low:
            return "Take a deep breath with me."
        case .medium:
            return "Stay where you are. Your caregiver will be notified."
        case .high:
            return "Stay calm, we are going to help you. Stay in a safe place."
        }
    }

    public var allMessages: [String] {
        [
            "Take a deep breath with me.",
            "Breathe in slowly.",
            "Breathe out slowly.",
            "Stay where you are.",
            "Your caregiver will be notified."
        ]
    }
}

public struct PatientPromptGenerator: Sendable {
    public init() {}

    public func lostPatientPrompts() -> [String] {
        [
            "Stay calm, we are going to help you.",
            "Stay where you are.",
            "Find a safe and visible place.",
            "Press I need help if you don't know where you are."
        ]
    }
}

public struct CaregiverSummaryGenerator: Sendable {
    public init() {}

    public func summary(patient: PatientProfile, reminders: [Reminder], latestRisk: RiskEvent?) -> String {
        let completed = reminders.filter { $0.status == .completed }.count
        let total = reminders.count
        let riskText = latestRisk.map { "Latest risk level is \($0.riskLevel.rawValue)." } ?? "No risk event is open."
        return "\(patient.name) completed \(completed) of \(total) reminders today. \(riskText)"
    }
}
