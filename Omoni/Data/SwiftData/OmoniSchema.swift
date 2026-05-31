import Foundation
import SwiftData

/// Baseline production schema.
/// When a persisted model changes, add a new schema version and migration stage
/// instead of bypassing this file from `ModelContainer`.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SDUser.self,
            SDGroup.self,
            SDUserGroup.self,
            SDCategory.self,
            SDPaymentMethod.self,
            SDItemList.self,
            SDItem.self
        ]
    }
}

enum OmoniMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

typealias OmoniSchema = SchemaV1
