import XCTest
@testable import Rosolek

final class UltraSpecVariantMappingTests: XCTestCase {
    func testRamenTonkotsuMapping() {
        let variant = UltraSpecVariantResolver.resolve(kind: .ramen, styleKey: "ramen_tonkotsu")
        XCTAssertEqual(variant, .ramenTonkotsu)
    }

    func testStyleNameResolver() {
        XCTAssertEqual(UltraSpecStyleKeyResolver.resolve(kind: .ramen, styleName: "Tonkotsu"), "ramen_tonkotsu")
        XCTAssertEqual(UltraSpecStyleKeyResolver.resolve(kind: .fish, styleName: "Intensywny"), "fish_intense")
        XCTAssertEqual(UltraSpecStyleKeyResolver.resolve(kind: .rosol, styleName: nil), "rosol_light")
    }

    func testBridgeAcceptsStyleName() throws {
        let result = try UltraSpecBridge.calculateFromCurrentFlow(
            kind: .ramen,
            styleName: "Tonkotsu",
            potCapacityL: 7,
            selections: [.init(ingredientID: "kosci_wieprzowe", ingredientName: "Kości", category: .pork, grams: 2000)],
            clarityMode: .normal
        )

        XCTAssertGreaterThan(result.waterStartL, 0)
    }

    func testRequestBuilderMapsIngredientIDs() {
        let request = UltraSpecRequestBuilder.build(
            kind: .rosol,
            styleKey: "rosol_light",
            potCapacityL: 7,
            selections: [
                .init(ingredientID: "kura", ingredientName: "Kura", category: .poultry, grams: 1200),
                .init(ingredientID: "szponder", ingredientName: "Szponder", category: .beef, grams: 400)
            ],
            clarityMode: .normal
        )

        XCTAssertEqual(request.variant, .rosolLekki)
        XCTAssertEqual(request.items.first?.ingredientID, "POULTRY_OLD_HEN")
        XCTAssertEqual(request.items.last?.ingredientID, "BEEF_SHORT_RIB")
    }

    func testRequestBuilderMapsVegetableAndFishAliases() {
        let request = UltraSpecRequestBuilder.build(
            kind: .fish,
            styleKey: "fish_delicate",
            potCapacityL: 7,
            selections: [
                .init(ingredientID: "seler_baza", ingredientName: "Seler", category: .veggies, grams: 150),
                .init(ingredientID: "por_baza", ingredientName: "Por", category: .veggies, grams: 100),
                .init(ingredientID: "glowy_rybne", ingredientName: "Głowy", category: .fish, grams: 900)
            ],
            clarityMode: .normal
        )

        XCTAssertEqual(request.items.map(\.ingredientID), ["VEG_CELERIAC", "VEG_LEEK", "FISH_WHITE_BONES"])
    }
}
