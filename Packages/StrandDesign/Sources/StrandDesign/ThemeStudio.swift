import SwiftUI
import Foundation

/// A data-colour slot the Theme Studio can repaint. Each slot owns one pillar's colour family in
/// `StrandPalette` (the base colour plus its derived deep / bright / glow variants), so a single pick
/// recolours that pillar's rings, charts and accents everywhere it is drawn.
public enum ThemeColorSlot: String, CaseIterable, Identifiable, Codable, Sendable {
    case charge   // recovery
    case effort   // strain
    case rest     // sleep
    case stress
    case heart    // live heart-rate accents

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .charge: return String(localized: "Recovery", bundle: .module)
        case .effort: return String(localized: "Strain", bundle: .module)
        case .rest:   return String(localized: "Sleep", bundle: .module)
        case .stress: return String(localized: "Stress", bundle: .module)
        case .heart:  return String(localized: "Heart rate", bundle: .module)
        }
    }

    public var symbol: String {
        switch self {
        case .charge: return "bolt.heart"
        case .effort: return "flame"
        case .rest:   return "moon.zzz"
        case .stress: return "waveform.path.ecg"
        case .heart:  return "heart"
        }
    }
}

/// A complete, nameable theme: per-slot colour overrides plus the existing appearance prefs it
/// coordinates. Optional fields mean "leave that pref alone" when the theme is applied, so a theme
/// shared from someone else only changes what it actually specifies.
public struct CustomTheme: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var colors: [String: String]   // ThemeColorSlot.rawValue → "#RRGGBB"
    public var accentHex: String?
    public var chartStyle: String?
    public var appearance: String?
    public var cardOpacity: Int?
    public var backdrop: Bool?

    public init(id: UUID = UUID(), name: String, colors: [String: String] = [:],
                accentHex: String? = nil, chartStyle: String? = nil, appearance: String? = nil,
                cardOpacity: Int? = nil, backdrop: Bool? = nil) {
        self.id = id
        self.name = name
        self.colors = colors
        self.accentHex = accentHex
        self.chartStyle = chartStyle
        self.appearance = appearance
        self.cardOpacity = cardOpacity
        self.backdrop = backdrop
    }
}

/// The Theme Studio store: the live per-slot overrides (read by `StrandPalette`) and the user's saved
/// themes. Both persist as JSON strings in `UserDefaults` so `@AppStorage` can observe them.
///
/// Like `StrandPalette.chartStyle` / `accentChoice`, the live overrides are a global set during the
/// app root's body evaluation (`.themeStudio(raw)`), which also keys the content so a change
/// re-renders every visible colour.
public enum ThemeStudio {
    /// `@AppStorage` key for the live overrides: JSON `{ slot: "#RRGGBB" }`. Default `""` (none).
    public static let overridesKey = "theme.studio.overrides"
    /// `@AppStorage` key for the saved theme library: JSON `[CustomTheme]`. Default `""` (empty).
    public static let savedKey = "theme.studio.saved"
    /// Prefix that marks a pasted string as a NOOP theme code.
    public static let sharePrefix = "noop-theme:"

    /// The live overrides, keyed by slot. Set from the app root; empty means "use the stock palette".
    public static var overrides: [ThemeColorSlot: String] = [:]

    /// The override colour for a slot, or nil when the slot follows the stock palette.
    public static func color(_ slot: ThemeColorSlot) -> Color? {
        overrides[slot].map { Color(hex: $0) }
    }

    /// The override's deeper shade (gradient start / pressed state).
    public static func deep(_ slot: ThemeColorSlot) -> Color? {
        overrides[slot].map { shade($0, by: 0.28) }
    }

    /// The override's brighter tint (gradient end / highlights).
    public static func bright(_ slot: ThemeColorSlot) -> Color? {
        overrides[slot].map { tint($0, by: 0.28) }
    }

    // MARK: Codec

    public static func decodeOverrides(_ raw: String) -> [ThemeColorSlot: String] {
        guard let data = raw.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        var out: [ThemeColorSlot: String] = [:]
        for (k, v) in dict {
            if let slot = ThemeColorSlot(rawValue: k), isValidHex(v) { out[slot] = v.uppercased() }
        }
        return out
    }

    public static func encodeOverrides(_ overrides: [ThemeColorSlot: String]) -> String {
        guard !overrides.isEmpty else { return "" }
        let dict = Dictionary(uniqueKeysWithValues: overrides.map { ($0.key.rawValue, $0.value) })
        return encodeJSON(dict) ?? ""
    }

    public static func decodeSaved(_ raw: String) -> [CustomTheme] {
        guard let data = raw.data(using: .utf8),
              let list = try? JSONDecoder().decode([CustomTheme].self, from: data) else { return [] }
        return list
    }

    public static func encodeSaved(_ themes: [CustomTheme]) -> String {
        guard !themes.isEmpty else { return "" }
        return encodeJSON(themes) ?? ""
    }

    /// A copy-pasteable code for one theme: `noop-theme:` + base64(JSON). The id is reset on import,
    /// so pasting the same code twice yields two independent saved themes.
    public static func shareCode(for theme: CustomTheme) -> String {
        guard let json = encodeJSON(theme), let data = json.data(using: .utf8) else { return "" }
        return sharePrefix + data.base64EncodedString()
    }

    /// Parse a theme code (tolerant of surrounding whitespace). Returns nil for anything that is not a
    /// valid code; invalid colour entries inside an otherwise valid code are dropped.
    public static func theme(fromShareCode code: String) -> CustomTheme? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(sharePrefix),
              let data = Data(base64Encoded: String(trimmed.dropFirst(sharePrefix.count))),
              var theme = try? JSONDecoder().decode(CustomTheme.self, from: data) else { return nil }
        theme.id = UUID()
        theme.colors = theme.colors.filter { ThemeColorSlot(rawValue: $0.key) != nil && isValidHex($0.value) }
        if let a = theme.accentHex, !isValidHex(a) { theme.accentHex = nil }
        if let o = theme.cardOpacity { theme.cardOpacity = min(100, max(0, o)) }
        return theme
    }

    public static func isValidHex(_ s: String) -> Bool {
        let body = s.hasPrefix("#") ? s.dropFirst() : Substring(s)
        return body.count == 6 && body.allSatisfy(\.isHexDigit)
    }

    // MARK: Colour math

    /// Blend an sRGB hex toward white by `amount` (0…1).
    static func tint(_ hex: String, by amount: Double) -> Color {
        let c = Color.sRGBComponents(hex: hex)
        func up(_ x: Double) -> Double { min(1, x + (1 - x) * amount) }
        return Color(.sRGB, red: up(c.r), green: up(c.g), blue: up(c.b), opacity: 1)
    }

    /// Blend an sRGB hex toward black by `amount` (0…1).
    static func shade(_ hex: String, by amount: Double) -> Color {
        let c = Color.sRGBComponents(hex: hex)
        func down(_ x: Double) -> Double { max(0, x * (1 - amount)) }
        return Color(.sRGB, red: down(c.r), green: down(c.g), blue: down(c.b), opacity: 1)
    }

    private static func encodeJSON<T: Encodable>(_ value: T) -> String? {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        guard let data = try? enc.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// Applies the Theme Studio overrides: sets `ThemeStudio.overrides` (read by the pillar accessors in
/// `StrandPalette`) and keys the content so an edit re-renders live. Apply at each app root next to
/// `.chartStyle(...)`: `.themeStudio(themeOverridesRaw)`.
public extension View {
    func themeStudio(_ raw: String) -> some View {
        ThemeStudio.overrides = ThemeStudio.decodeOverrides(raw)
        return self.id("noop.themeStudio.\(raw)")
    }
}
