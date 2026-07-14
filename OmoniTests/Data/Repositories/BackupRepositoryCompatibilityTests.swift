import XCTest
import SwiftData
@testable import Omoni

@MainActor
final class BackupRepositoryCompatibilityTests: XCTestCase {
    private var swiftData: SwiftDataTestContainer!
    private var repository: BackupRepository!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        repository = swiftData.makeBackupRepository()
    }

    override func tearDown() {
        repository = nil
        swiftData = nil
    }

    func testDecodeLegacyBackupJSON_WithoutGroupKind_Succeeds() throws {
        let backup = try decodeLegacyBackupWithoutGroupKind()

        XCTAssertEqual(backup.schemaVersion, 2)
        XCTAssertNil(backup.groups.first?.groupKind)
    }

    func testImportLegacyBackup_WithoutGroupKind_PersistsNilAndResolvesExpense() async throws {
        let backup = try decodeLegacyBackupWithoutGroupKind()

        try await repository.replaceAllData(with: backup)

        let groups = try swiftData.context.fetch(FetchDescriptor<SDGroup>())
        XCTAssertEqual(groups.count, 1)
        XCTAssertNil(groups[0].groupKind)
        XCTAssertEqual(groups[0].resolvedGroupKind, .expense)
    }

    func testMakeBackup_NormalizesNilGroupKindToExpense() async throws {
        let user = try swiftData.insertUser()
        let group = try swiftData.insertGroup(name: "Casa", currency: "EUR")
        _ = try swiftData.insertUserGroup(user: user, group: group)

        XCTAssertNil(group.groupKind)

        let backup = try await repository.makeBackup(
            appName: "OMONI",
            bundleIdentifier: "com.omo.Omoni",
            appVersion: "1.0",
            exportedAt: Date()
        )

        XCTAssertEqual(backup.schemaVersion, OMOBackupEnvelope.currentSchemaVersion)
        XCTAssertEqual(backup.groups.count, 1)
        XCTAssertEqual(backup.groups[0].groupKind, SDGroupKind.expense.rawValue)
    }

    private func decodeLegacyBackupWithoutGroupKind() throws -> OMOBackupEnvelope {
        let userID = UUID()
        let groupID = UUID()
        let userGroupID = UUID()

        let json = """
        {
          "appName": "OMONI",
          "appVersion": "0.9",
          "bundleIdentifier": "com.omo.Omoni",
          "categories": [],
          "exportedAt": "2026-06-10T12:00:00Z",
          "groups": [
            {
              "createdAt": "2026-06-09T12:00:00Z",
              "currency": "EUR",
              "id": "\(groupID.uuidString)",
              "lastModifiedAt": null,
              "name": "Casa"
            }
          ],
          "itemLists": [],
          "items": [],
          "paymentMethods": [],
          "schemaVersion": 2,
          "statistics": {
            "categories": 0,
            "groups": 1,
            "itemLists": 0,
            "items": 0,
            "paymentMethods": 0,
            "userGroups": 1,
            "users": 1
          },
          "userGroups": [
            {
              "groupID": "\(groupID.uuidString)",
              "id": "\(userGroupID.uuidString)",
              "joinedAt": "2026-06-09T12:00:00Z",
              "role": "owner",
              "userID": "\(userID.uuidString)"
            }
          ],
          "users": [
            {
              "createdAt": "2026-06-09T12:00:00Z",
              "email": "dennis@example.com",
              "id": "\(userID.uuidString)",
              "lastModifiedAt": null,
              "name": "Dennis"
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(OMOBackupEnvelope.self, from: Data(json.utf8))
    }
}
