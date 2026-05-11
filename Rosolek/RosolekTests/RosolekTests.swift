//
//  RosolekTests.swift
//  RosolekTests
//
//  Created by Paweł Kociszewski on 27/03/2026.
//

import XCTest
@testable import Rosolek

final class RosolekTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBatchRecordCodableRoundtripWithOverrides() throws {
        let original = BatchRecord(
            createdAt: Date(timeIntervalSince1970: 1_713_000_000),
            styleRawValue: "light",
            modeRawValue: "custom",
            presetRawValue: nil,
            profileRawValue: BrothProfile.cleaner.rawValue,
            brothKindRawValue: BrothKind.ramen.rawValue,
            selectedStyleName: "Tonkotsu",
            clarityModeRawValue: BrothClarityMode.normal.rawValue,
            useVinegar: true,
            totalWeightGrams: 2200,
            selectedIngredientCount: 3,
            waterLiters: 4.2,
            estimatedYieldLiters: 3.4,
            totalMinutes: 360,
            activeCookingMinutes: 350,
            warningCount: 2,
            hasThermometer: true,
            selectedIngredientIDs: ["kura", "szponder", "szyje_kurczaka"],
            selectedIngredientsSnapshot: [
                .init(ingredientID: "kura", ingredientName: "Kura rosołowa", categoryRawValue: IngredientCategory.poultry.rawValue, grams: 1300)
            ],
            meatOverrides: ["kura": 1200],
            vegetableOverrides: ["Cebula": 80, "Marchew": 70],
            spiceOverrides: ["salt_start": 6, "pepper": 12],
            customTitle: "Test batch",
            notes: "override test"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BatchRecord.self, from: data)

        XCTAssertEqual(decoded.meatOverrides?["kura"], 1200)
        XCTAssertEqual(decoded.vegetableOverrides?["Cebula"], 80)
        XCTAssertEqual(decoded.spiceOverrides?["pepper"], 12)
        XCTAssertEqual(decoded.brothKindRawValue, BrothKind.ramen.rawValue)
        XCTAssertEqual(decoded.selectedStyleName, "Tonkotsu")
        XCTAssertTrue(decoded.hasManualOverrides)
        XCTAssertEqual(decoded.customTitle, "Test batch")
    }

    func testBatchRecordCodableRoundtripWithoutOverrides() throws {
        let original = BatchRecord(
            createdAt: Date(timeIntervalSince1970: 1_713_000_123),
            styleRawValue: "intense",
            totalWeightGrams: 1800,
            selectedIngredientCount: 2,
            waterLiters: 3.8,
            estimatedYieldLiters: 3.0,
            totalMinutes: 300,
            warningCount: 0,
            hasThermometer: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BatchRecord.self, from: data)

        XCTAssertNil(decoded.meatOverrides)
        XCTAssertNil(decoded.vegetableOverrides)
        XCTAssertNil(decoded.spiceOverrides)
        XCTAssertFalse(decoded.hasManualOverrides)
    }

    // MARK: - String.extractGrams (regression for S-2)

    func testExtractGramsIntegerValue() {
        XCTAssertEqual("300 g".extractGrams(), 300)
    }

    func testExtractGramsDecimalValueTruncates() {
        // "12.5 g" should yield 12, not 125 (old bug: filter { $0.isNumber })
        XCTAssertEqual("12.5 g".extractGrams(), 12)
    }

    func testExtractGramsCommaDecimalSeparator() {
        XCTAssertEqual("12,5 g".extractGrams(), 12)
    }

    func testExtractGramsNoUnit() {
        XCTAssertEqual("300".extractGrams(), 300)
    }

    func testExtractGramsSpaceThousandsSeparator() {
        XCTAssertEqual("1 000 g".extractGrams(), 1000)
    }

    func testExtractGramsEmpty() {
        XCTAssertEqual("".extractGrams(), 0)
    }

    func testExtractGramsZero() {
        XCTAssertEqual("0 g".extractGrams(), 0)
    }

}
