import Foundation
import StrandDesign

/// Carries the user's Theme Studio colours and accent across the process boundary into the widget
/// extension. The app mirrors its `UserDefaults.standard` theme prefs into the App Group (`mirror`);
/// the extension reads them back and installs them into the same `StrandPalette` globals the app root
/// sets (`applyInExtension`), so every widget draws with the user's colours without per-widget wiring.
enum WidgetTheme {
    private static let overridesKey = "noop.widget.theme.overrides"
    private static let accentKey = "noop.widget.theme.accent"
    private static let accentHexKey = "noop.widget.theme.accentHex"

    /// App side: copy the live theme prefs into the App Group. Returns true when anything changed, so
    /// the caller can reload widget timelines only when it matters.
    @discardableResult
    static func mirror(overridesRaw: String, accentRaw: String, accentHex: String) -> Bool {
        guard let group = UserDefaults(suiteName: WidgetSnapshot.suiteName) else { return false }
        let changed = group.string(forKey: overridesKey) != overridesRaw
            || group.string(forKey: accentKey) != accentRaw
            || group.string(forKey: accentHexKey) != accentHex
        guard changed else { return false }
        group.set(overridesRaw, forKey: overridesKey)
        group.set(accentRaw, forKey: accentKey)
        group.set(accentHex, forKey: accentHexKey)
        return true
    }

    /// Extension side: install the mirrored theme into the palette globals. A no-op inside the app
    /// itself, whose root modifiers already own these globals and must not be overwritten by a mirror
    /// that may lag a moment behind.
    static func applyInExtension() {
        guard Bundle.main.bundleURL.pathExtension == "appex",
              let group = UserDefaults(suiteName: WidgetSnapshot.suiteName) else { return }
        ThemeStudio.overrides = ThemeStudio.decodeOverrides(group.string(forKey: overridesKey) ?? "")
        StrandPalette.accentChoice = AccentColor.resolve(group.string(forKey: accentKey) ?? "")
        StrandPalette.customAccentHex = group.string(forKey: accentHexKey) ?? AccentColor.defaultCustomHex
    }
}
