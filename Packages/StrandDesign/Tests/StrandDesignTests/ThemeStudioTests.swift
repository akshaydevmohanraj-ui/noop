import XCTest
@testable import StrandDesign

/// Pins the Theme Studio codec: overrides and saved themes round-trip through their JSON strings,
/// invalid colours are dropped, and a share code survives a copy/paste with surrounding whitespace.
final class ThemeStudioTests: XCTestCase {

    func testOverridesRoundTrip() {
        let overrides: [ThemeColorSlot: String] = [.charge: "#12AB34", .stress: "#FF0000"]
        let raw = ThemeStudio.encodeOverrides(overrides)
        XCTAssertEqual(ThemeStudio.decodeOverrides(raw), overrides)
    }

    func testEmptyOverridesEncodeToEmptyString() {
        XCTAssertEqual(ThemeStudio.encodeOverrides([:]), "")
        XCTAssertEqual(ThemeStudio.decodeOverrides(""), [:])
    }

    func testDecodeDropsUnknownSlotsAndBadHex() {
        let raw = #"{"charge":"#12ab34","bogus":"#000000","rest":"blue"}"#
        XCTAssertEqual(ThemeStudio.decodeOverrides(raw), [.charge: "#12AB34"])
    }

    func testShareCodeRoundTripResetsId() {
        let theme = CustomTheme(name: "Sunset", colors: ["effort": "#FF8800"],
                                accentHex: "#AA00FF", chartStyle: "classic", cardOpacity: 80)
        let code = "  " + ThemeStudio.shareCode(for: theme) + "\n"
        let parsed = ThemeStudio.theme(fromShareCode: code)
        XCTAssertNotNil(parsed)
        XCTAssertNotEqual(parsed?.id, theme.id)
        XCTAssertEqual(parsed?.name, "Sunset")
        XCTAssertEqual(parsed?.colors, ["effort": "#FF8800"])
        XCTAssertEqual(parsed?.accentHex, "#AA00FF")
        XCTAssertEqual(parsed?.cardOpacity, 80)
    }

    func testShareCodeRejectsGarbage() {
        XCTAssertNil(ThemeStudio.theme(fromShareCode: "hello"))
        XCTAssertNil(ThemeStudio.theme(fromShareCode: "noop-theme:not-base64!!"))
    }

    func testSavedThemesRoundTrip() {
        let themes = [CustomTheme(name: "A"), CustomTheme(name: "B", colors: ["heart": "#FF6B81"])]
        XCTAssertEqual(ThemeStudio.decodeSaved(ThemeStudio.encodeSaved(themes)), themes)
    }

    func testHexValidation() {
        XCTAssertTrue(ThemeStudio.isValidHex("#A1B2C3"))
        XCTAssertTrue(ThemeStudio.isValidHex("a1b2c3"))
        XCTAssertFalse(ThemeStudio.isValidHex("#A1B2C"))
        XCTAssertFalse(ThemeStudio.isValidHex("#GGGGGG"))
    }
}
