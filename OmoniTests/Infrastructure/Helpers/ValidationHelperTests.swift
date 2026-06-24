import XCTest
@testable import Omoni

final class ValidationHelperTests: XCTestCase {

    func testSanitizeItemQuantityEditingInput_RemovesNonDigits() {
        let sanitized = ValidationHelper.sanitizeItemQuantityEditingInput("12a-3")

        XCTAssertEqual(sanitized, "123")
    }

    func testSanitizeItemQuantityEditingInput_LimitsToMaximumDigits() {
        let sanitized = ValidationHelper.sanitizeItemQuantityEditingInput("1234567890123")

        XCTAssertEqual(sanitized, "1234567890")
    }

    func testNormalizeItemQuantityAfterEditing_EmptyInputDefaultsToMinimum() {
        let normalized = ValidationHelper.normalizeItemQuantityAfterEditing("")

        XCTAssertEqual(normalized, "1")
    }

    func testNormalizeItemQuantityAfterEditing_ZeroInputDefaultsToMinimum() {
        let normalized = ValidationHelper.normalizeItemQuantityAfterEditing("000")

        XCTAssertEqual(normalized, "1")
    }

    func testItemQuantityValue_RejectsValuesAboveMaximum() {
        let quantity = ValidationHelper.itemQuantityValue(from: "10000000000")

        XCTAssertNil(quantity)
    }
}
