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
}
