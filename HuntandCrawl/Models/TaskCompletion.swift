import Foundation
import SwiftData

@Model
final class TaskCompletion {
    var id: String
    var userId: String
    var completedAt: Date?
    var verificationMethod: VerificationMethod
    var evidenceData: Data?
    var answer: String?
    var isVerified: Bool
    var verifiedAt: Date?
    var verifiedBy: String?
    
    @Relationship(deleteRule: .noAction)
    var task: Task?
    
    @Relationship(deleteRule: .noAction)
    var user: User?
    
    init(
        id: String = UUID().uuidString,
        task: Task? = nil,
        user: User? = nil,
        userId: String = "",
        completedAt: Date? = nil,
        verificationMethod: VerificationMethod = .manual,
        evidenceData: Data? = nil,
        answer: String? = nil,
        isVerified: Bool = false,
        verifiedAt: Date? = nil,
        verifiedBy: String? = nil
    ) {
        self.id = id
        self.task = task
        self.user = user
        self.userId = user?.id ?? userId
        self.completedAt = completedAt
        self.verificationMethod = verificationMethod
        self.evidenceData = evidenceData
        self.answer = answer
        self.isVerified = isVerified
        self.verifiedAt = verifiedAt
        self.verifiedBy = verifiedBy
    }
} 