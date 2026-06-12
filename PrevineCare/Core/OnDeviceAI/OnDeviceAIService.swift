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
            return "Respira profundo conmigo."
        case .medium:
            return "Quédate donde estás. Tu cuidador será notificado."
        case .high:
            return "Tranquilo, te vamos a ayudar. Quédate en un lugar seguro."
        }
    }

    public var allMessages: [String] {
        [
            "Respira profundo conmigo.",
            "Inhala lentamente.",
            "Exhala despacio.",
            "Quédate donde estás.",
            "Tu cuidador será notificado."
        ]
    }
}

public struct PatientPromptGenerator: Sendable {
    public init() {}

    public func lostPatientPrompts() -> [String] {
        [
            "Tranquilo, te vamos a ayudar.",
            "Quédate donde estás.",
            "Busca un lugar seguro y visible.",
            "Presiona Necesito ayuda si no sabes dónde estás."
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
