import XCTest
@testable import Rosolek

final class CookingPhaseBuilderTests: XCTestCase {

    // MARK: - Fixtures

    private static let minimalResult = BrothCalculationResult(
        waterLiters: 4.0,
        temperatureMin: 88,
        temperatureMax: 90,
        totalMinutes: 180,
        estimatedYieldLiters: 3.0,
        startSaltGrams: 4.0,
        finalSaltGrams: 8.0,
        appleCiderVinegarMl: 0,
        peppercornCount: 5,
        allspiceCount: 4,
        bayLeafCount: 2,
        vegetables: [],
        meatParts: [],
        timeline: [],
        warnings: [],
        structuredWarnings: [],
        validationFailure: nil,
        scoring: nil,
        recommendedMeatRange: nil,
        clarityMode: .normal,
        useVinegar: false,
        targetYieldLiters: nil,
        vegetableBreakdown: nil,
        spiceBreakdown: nil,
        microMode: false,
        waterWasReducedToFit: false
    )

    private static let poultrySnapshot = BatchIngredientSnapshot(
        ingredientID: "POULTRY_OLD_HEN",
        ingredientName: "Kura stara",
        categoryRawValue: IngredientCategory.poultry.rawValue,
        grams: 1000
    )

    private static let beefSnapshot = BatchIngredientSnapshot(
        ingredientID: "BEEF_SHANK",
        ingredientName: "Pręga wołowa",
        categoryRawValue: IngredientCategory.beef.rawValue,
        grams: 600
    )

    private static let fishSnapshot = BatchIngredientSnapshot(
        ingredientID: "FISH_WHITE_BONES",
        ingredientName: "Kręgosłup rybny",
        categoryRawValue: IngredientCategory.fish.rawValue,
        grams: 500
    )

    private func makeBatch(
        modeRawValue: String = "custom",
        brothKindRawValue: String? = nil,
        selectedStyleName: String? = nil,
        presetRawValue: String? = nil,
        snapshots: [BatchIngredientSnapshot] = []
    ) -> BatchRecord {
        BatchRecord(
            createdAt: Date(),
            styleRawValue: "light",
            modeRawValue: modeRawValue,
            presetRawValue: presetRawValue,
            brothKindRawValue: brothKindRawValue,
            selectedStyleName: selectedStyleName,
            totalWeightGrams: snapshots.reduce(0) { $0 + $1.grams },
            selectedIngredientCount: snapshots.count,
            waterLiters: 4.0,
            estimatedYieldLiters: 3.0,
            totalMinutes: 180,
            warningCount: 0,
            hasThermometer: false,
            selectedIngredientsSnapshot: snapshots.isEmpty ? nil : snapshots
        )
    }

    private func builder(batch: BatchRecord, hasThermometer: Bool = false) -> CookingPhaseBuilder {
        CookingPhaseBuilder(batch: batch, result: Self.minimalResult, hasThermometer: hasThermometer)
    }

    // MARK: - All UltraSpec variants produce non-empty phases

    func testAllUltraSpecVariantsProduce2OrMorePhases() {
        let cases: [(kind: String, style: String, snapshots: [BatchIngredientSnapshot])] = [
            ("rosol",    "Lekki",      [Self.poultrySnapshot]),
            ("rosol",    "Bogaty",     [Self.poultrySnapshot]),
            ("ramen",    "Shio",       [Self.poultrySnapshot]),
            ("ramen",    "Tonkotsu",   [Self.poultrySnapshot]),
            ("wolowy",   "Czysty",     [Self.beefSnapshot]),
            ("wolowy",   "Mocny",      [Self.beefSnapshot]),
            ("warzywny", "Jasny",      []),
            ("warzywny", "Umami",      []),
            ("rybny",    "Delikatny",  [Self.fishSnapshot]),
            ("rybny",    "Intensywny", [Self.fishSnapshot]),
        ]
        for c in cases {
            let batch = makeBatch(brothKindRawValue: c.kind, selectedStyleName: c.style, snapshots: c.snapshots)
            let b = builder(batch: batch)
            XCTAssertNotNil(b.activeUltraVariant,
                "Expected non-nil activeUltraVariant for kind=\(c.kind) style=\(c.style)")
            let phases = b.buildPhases()
            XCTAssertGreaterThan(phases.count, 1,
                "Expected > 1 phases for kind=\(c.kind) style=\(c.style), got \(phases.count)")
        }
    }

    // MARK: - Variant routing correctness

    func testActiveUltraVariantResolvesCorrectly() {
        let expectations: [(String, String, UltraSpecVariantID)] = [
            ("rosol",    "Lekki",      .rosolLekki),
            ("rosol",    "Bogaty",     .rosolBogaty),
            ("ramen",    "Shio",       .ramenShio),
            ("ramen",    "Tonkotsu",   .ramenTonkotsu),
            ("wolowy",   "Czysty",     .wolowyCzysty),
            ("wolowy",   "Mocny",      .wolowyMocny),
            ("warzywny", "Jasny",      .warzywnyJasny),
            ("warzywny", "Umami",      .warzywnyUmami),
            ("rybny",    "Delikatny",  .rybnyDelikatny),
            ("rybny",    "Intensywny", .rybnyIntensywny),
        ]
        for (kind, style, expected) in expectations {
            let batch = makeBatch(brothKindRawValue: kind, selectedStyleName: style)
            let resolved = builder(batch: batch).activeUltraVariant
            XCTAssertEqual(resolved, expected, "kind=\(kind) style=\(style)")
        }
    }

    // MARK: - First phase is always manual (prep step)

    func testFirstUltraSpecPhaseIsManuaForEveryVariant() {
        let cases: [(String, String)] = [
            ("rosol", "Lekki"), ("rosol", "Bogaty"), ("ramen", "Shio"), ("ramen", "Tonkotsu"),
            ("wolowy", "Czysty"), ("wolowy", "Mocny"), ("warzywny", "Jasny"), ("warzywny", "Umami"),
            ("rybny", "Delikatny"), ("rybny", "Intensywny"),
        ]
        for (kind, style) in cases {
            let batch = makeBatch(brothKindRawValue: kind, selectedStyleName: style)
            let phases = builder(batch: batch).buildPhases()
            XCTAssertNil(phases.first?.durationSeconds,
                "First phase must be manual for kind=\(kind) style=\(style)")
        }
    }

    // MARK: - rosolBogaty sub-paths

    func testBogatyPoultryOnlyUsesLekkiSteps() {
        // hasBeef=false → CookingPhaseBuilder falls back to rosolLekki steps
        let bogatyBatch = makeBatch(brothKindRawValue: "rosol", selectedStyleName: "Bogaty",
                                    snapshots: [Self.poultrySnapshot])
        let lekkiBatch  = makeBatch(brothKindRawValue: "rosol", selectedStyleName: "Lekki",
                                    snapshots: [Self.poultrySnapshot])
        let bogatyPhases = builder(batch: bogatyBatch).buildPhases()
        let lekkiPhases  = builder(batch: lekkiBatch).buildPhases()
        XCTAssertEqual(bogatyPhases.count, lekkiPhases.count,
            "Bogaty with no beef falls back to Lekki step count")
    }

    func testBogatyWithBeefAndPoultryProducesPhases() {
        let batch = makeBatch(brothKindRawValue: "rosol", selectedStyleName: "Bogaty",
                              snapshots: [Self.poultrySnapshot, Self.beefSnapshot])
        let phases = builder(batch: batch).buildPhases()
        XCTAssertGreaterThan(phases.count, 1)
    }

    func testBogatyBeefOnlyProducesPhases() {
        let batch = makeBatch(brothKindRawValue: "rosol", selectedStyleName: "Bogaty",
                              snapshots: [Self.beefSnapshot])
        let phases = builder(batch: batch).buildPhases()
        XCTAssertGreaterThan(phases.count, 1)
    }

    // MARK: - UltraSpec phase step IDs are set and non-empty

    func testAllUltraSpecPhasesHaveNonEmptyStepIDs() {
        let batch = makeBatch(brothKindRawValue: "rosol", selectedStyleName: "Lekki",
                              snapshots: [Self.poultrySnapshot])
        let phases = builder(batch: batch).buildPhases()
        for phase in phases {
            XCTAssertNotNil(phase.stepID, "Every UltraSpec phase must have a stepID")
            XCTAssertFalse(phase.stepID?.isEmpty ?? true, "UltraSpec phase stepID must not be empty")
        }
    }

    // MARK: - Preset paths

    func testFishPresetReturnsRybnyDelikatnyPhases() {
        let batch = makeBatch(modeRawValue: "preset", presetRawValue: "fishReady",
                              snapshots: [Self.fishSnapshot])
        let b = builder(batch: batch)
        XCTAssertEqual(b.activeUltraVariant, .rybnyDelikatny)
        XCTAssertGreaterThan(b.buildPhases().count, 1)
    }

    func testGrandmaPresetRoutesToGrandmaPhases() {
        let batch = makeBatch(modeRawValue: "preset", presetRawValue: "grandmaReady",
                              snapshots: [Self.poultrySnapshot])
        let b = builder(batch: batch)
        XCTAssertNil(b.activeUltraVariant, "Grandma preset must not activate UltraSpec path")
        XCTAssertTrue(b.isGrandmaPreset)
        XCTAssertGreaterThan(b.buildPhases().count, 1)
    }

    func testCollagenPresetRoutesToCollagenPhases() {
        let batch = makeBatch(modeRawValue: "preset", presetRawValue: "collagenPoultryReady",
                              snapshots: [Self.poultrySnapshot])
        let b = builder(batch: batch)
        XCTAssertNil(b.activeUltraVariant, "Collagen preset must not activate UltraSpec path")
        XCTAssertTrue(b.isCollagenPoultryPreset)
        XCTAssertGreaterThan(b.buildPhases().count, 1)
    }

    func testStandardLegacyPathProducesPhases() {
        let batch = makeBatch(modeRawValue: "legacy", snapshots: [Self.poultrySnapshot])
        let b = builder(batch: batch)
        XCTAssertNil(b.activeUltraVariant)
        XCTAssertFalse(b.isGrandmaPreset)
        XCTAssertFalse(b.isCollagenPoultryPreset)
        XCTAssertGreaterThan(b.buildPhases().count, 1)
    }

    // MARK: - Non-negative timed phase durations

    func testAllTimedPhaseDurationsArePositive() {
        let cases: [(String, String, [BatchIngredientSnapshot])] = [
            ("rosol", "Lekki", [Self.poultrySnapshot]),
            ("ramen", "Tonkotsu", [Self.poultrySnapshot]),
            ("warzywny", "Jasny", []),
            ("rybny", "Delikatny", [Self.fishSnapshot]),
        ]
        for (kind, style, snapshots) in cases {
            let batch = makeBatch(brothKindRawValue: kind, selectedStyleName: style, snapshots: snapshots)
            let phases = builder(batch: batch).buildPhases()
            for phase in phases {
                if let d = phase.durationSeconds {
                    XCTAssertGreaterThan(d, 0,
                        "durationSeconds must be > 0 for timed phases in kind=\(kind) style=\(style), got \(d) for '\(phase.title)'")
                }
            }
        }
    }
}
