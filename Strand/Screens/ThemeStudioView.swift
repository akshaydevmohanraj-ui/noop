import SwiftUI
import StrandDesign
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Theme Studio: per-pillar colour overrides on top of the theme presets, a library of named saved
/// themes, and copy/paste theme codes for sharing. Every edit writes straight to `@AppStorage`, and the
/// app root's `.themeStudio(...)` re-renders the whole UI live, so this sheet doubles as its own preview.
struct ThemeStudioView: View {
    let onClose: () -> Void

    @AppStorage(ThemeStudio.overridesKey) private var overridesRaw = ""
    @AppStorage(ThemeStudio.savedKey) private var savedRaw = ""
    @AppStorage(AccentColor.storageKey) private var accentRaw = AccentColor.mint.rawValue
    @AppStorage(AccentColor.customHexKey) private var accentCustomHex = AccentColor.defaultCustomHex
    @AppStorage(ChartStyle.storageKey) private var chartStyleRaw = ChartStyle.titanium.rawValue
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(CardAppearancePrefs.opacityKey) private var cardOpacityPercent = CardAppearancePrefs.defaultPercent
    @AppStorage(SceneBackgroundPrefs.enabledKey) private var showDayCycleBackground = true

    @State private var newThemeName = ""
    @State private var importCode = ""
    @State private var statusMessage: String?

    private var overrides: [ThemeColorSlot: String] { ThemeStudio.decodeOverrides(overridesRaw) }
    private var savedThemes: [CustomTheme] { ThemeStudio.decodeSaved(savedRaw) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(StrandPalette.hairline)
            ScrollView {
                VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                    previewCard
                    colorsCard
                    saveCard
                    libraryCard
                    importCard
                }
                .padding(20)
            }
            #if os(iOS)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            #endif
        }
        #if os(macOS)
        .frame(width: 560, height: 680)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .noopSheetPresentation(largeFirst: true)
        #endif
        .background(StrandPalette.surfaceBase)
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THEME STUDIO").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textTertiary)
                Text("Make it yours")
                    .font(StrandFont.rounded(26, weight: .bold))
                    .foregroundStyle(StrandPalette.textPrimary)
                Text("Changes apply instantly across the app.").font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(20)
    }

    private var previewCard: some View {
        studioCard(title: "Preview") {
            HStack(spacing: 0) {
                ForEach(ThemeColorSlot.allCases) { slot in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(previewColor(slot).opacity(0.25), lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: 0.72)
                                .stroke(previewColor(slot), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Image(systemName: slot.symbol)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(previewColor(slot))
                        }
                        .frame(width: 48, height: 48)
                        Text(slot.label)
                            .font(StrandFont.caption)
                            .foregroundStyle(StrandPalette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var colorsCard: some View {
        studioCard(title: "Colours") {
            VStack(spacing: 12) {
                ForEach(ThemeColorSlot.allCases) { slot in
                    HStack(spacing: 12) {
                        Image(systemName: slot.symbol)
                            .frame(width: 22)
                            .foregroundStyle(previewColor(slot))
                        Text(slot.label)
                            .font(StrandFont.body)
                            .foregroundStyle(StrandPalette.textPrimary)
                        Spacer()
                        if overrides[slot] != nil {
                            Button("Reset") { setOverride(slot, hex: nil) }
                                .buttonStyle(.plain)
                                .font(StrandFont.caption)
                                .foregroundStyle(StrandPalette.accent)
                        }
                        ColorPicker(slot.label, selection: binding(for: slot), supportsOpacity: false)
                            .labelsHidden()
                            .accessibilityLabel(Text(slot.label))
                    }
                }
                Divider().overlay(StrandPalette.hairline)
                HStack(spacing: 12) {
                    Image(systemName: "paintbrush.pointed")
                        .frame(width: 22)
                        .foregroundStyle(StrandPalette.accent)
                    Text("Accent")
                        .font(StrandFont.body)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Spacer()
                    ColorPicker("Accent", selection: accentBinding, supportsOpacity: false)
                        .labelsHidden()
                        .accessibilityLabel("Accent colour")
                }
                if !overrides.isEmpty {
                    NoopButton("Reset all colours", systemImage: "arrow.counterclockwise", kind: .tertiary) {
                        overridesRaw = ""
                    }
                }
            }
        }
    }

    private var saveCard: some View {
        studioCard(title: "Save this look") {
            HStack(spacing: 10) {
                TextField("Theme name", text: $newThemeName)
                    .textFieldStyle(.roundedBorder)
                NoopButton("Save", systemImage: "square.and.arrow.down", kind: .primary) {
                    saveCurrent()
                }
                .disabled(newThemeName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var libraryCard: some View {
        studioCard(title: "My themes") {
            if savedThemes.isEmpty {
                Text("Saved themes appear here. Tap one to apply it.")
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(savedThemes) { theme in
                        themeRow(theme)
                    }
                }
            }
        }
    }

    private var importCard: some View {
        studioCard(title: "Import a theme code") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Paste a noop-theme: code", text: $importCode)
                    .textFieldStyle(.roundedBorder)
                    .font(StrandFont.mono)
                HStack {
                    NoopButton("Import", systemImage: "square.and.arrow.down.on.square", kind: .secondary) {
                        importTheme()
                    }
                    .disabled(importCode.isEmpty)
                    Spacer()
                    if let statusMessage {
                        Text(statusMessage)
                            .font(StrandFont.caption)
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                }
            }
        }
    }

    private func themeRow(_ theme: CustomTheme) -> some View {
        HStack(spacing: 10) {
            Button { apply(theme) } label: {
                HStack(spacing: 10) {
                    HStack(spacing: -6) {
                        ForEach(ThemeColorSlot.allCases) { slot in
                            Circle()
                                .fill(theme.colors[slot.rawValue].map { Color(hex: $0) } ?? StrandPalette.surfaceInset)
                                .overlay(Circle().stroke(StrandPalette.surfaceRaised, lineWidth: 2))
                                .frame(width: 20, height: 20)
                        }
                    }
                    Text(theme.name)
                        .font(StrandFont.body)
                        .foregroundStyle(StrandPalette.textPrimary)
                        .lineLimit(1)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Apply \(theme.name)"))
            Button { copyShareCode(theme) } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(StrandPalette.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Copy code for \(theme.name)"))
            Button { delete(theme) } label: {
                Image(systemName: "trash")
                    .foregroundStyle(StrandPalette.statusCritical)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Delete \(theme.name)"))
        }
    }

    private func studioCard<Content: View>(title: LocalizedStringKey,
                                           @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(StrandFont.headline)
                .foregroundStyle(StrandPalette.textPrimary)
            content()
        }
        .padding(NoopMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous)
                .fill(StrandPalette.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous)
                .stroke(StrandPalette.hairline, lineWidth: 1)
        )
    }

    // MARK: Colour plumbing

    private func previewColor(_ slot: ThemeColorSlot) -> Color {
        if let hex = overrides[slot] { return Color(hex: hex) }
        switch slot {
        case .charge: return StrandPalette.chargeColor
        case .effort: return StrandPalette.effortColor
        case .rest:   return StrandPalette.restColor
        case .stress: return StrandPalette.stressColor
        case .heart:  return StrandPalette.liquidHeart
        }
    }

    private func binding(for slot: ThemeColorSlot) -> Binding<Color> {
        Binding(
            get: { previewColor(slot) },
            set: { setOverride(slot, hex: $0.themeStudioHex) }
        )
    }

    private var accentBinding: Binding<Color> {
        Binding(
            get: { StrandPalette.accent },
            set: { color in
                guard let hex = color.themeStudioHex else { return }
                accentCustomHex = hex
                accentRaw = AccentColor.custom.rawValue
            }
        )
    }

    private func setOverride(_ slot: ThemeColorSlot, hex: String?) {
        var next = overrides
        next[slot] = hex
        overridesRaw = ThemeStudio.encodeOverrides(next)
    }

    // MARK: Library actions

    private func currentTheme(named name: String) -> CustomTheme {
        CustomTheme(
            name: name,
            colors: Dictionary(uniqueKeysWithValues: overrides.map { ($0.key.rawValue, $0.value) }),
            accentHex: AccentColor.resolve(accentRaw) == .custom ? accentCustomHex : nil,
            chartStyle: chartStyleRaw,
            appearance: appearanceRaw,
            cardOpacity: cardOpacityPercent,
            backdrop: showDayCycleBackground
        )
    }

    private func saveCurrent() {
        let name = newThemeName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        var list = savedThemes
        if let i = list.firstIndex(where: { $0.name == name }) {
            let id = list[i].id
            list[i] = currentTheme(named: name)
            list[i].id = id
        } else {
            list.append(currentTheme(named: name))
        }
        savedRaw = ThemeStudio.encodeSaved(list)
        newThemeName = ""
        statusMessage = nil
    }

    private func apply(_ theme: CustomTheme) {
        var next: [ThemeColorSlot: String] = [:]
        for (k, v) in theme.colors { if let slot = ThemeColorSlot(rawValue: k) { next[slot] = v } }
        overridesRaw = ThemeStudio.encodeOverrides(next)
        if let hex = theme.accentHex {
            accentCustomHex = hex
            accentRaw = AccentColor.custom.rawValue
        }
        if let chart = theme.chartStyle { chartStyleRaw = ChartStyle.resolve(chart).rawValue }
        if let mode = theme.appearance { appearanceRaw = AppearanceMode.resolve(mode).rawValue }
        if let opacity = theme.cardOpacity { cardOpacityPercent = opacity }
        if let backdrop = theme.backdrop { showDayCycleBackground = backdrop }
    }

    private func delete(_ theme: CustomTheme) {
        savedRaw = ThemeStudio.encodeSaved(savedThemes.filter { $0.id != theme.id })
    }

    private func copyShareCode(_ theme: CustomTheme) {
        let code = ThemeStudio.shareCode(for: theme)
        #if os(iOS)
        UIPasteboard.general.string = code
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif
        statusMessage = String(localized: "Code copied")
    }

    private func importTheme() {
        guard let theme = ThemeStudio.theme(fromShareCode: importCode) else {
            statusMessage = String(localized: "That isn't a valid theme code")
            return
        }
        savedRaw = ThemeStudio.encodeSaved(savedThemes + [theme])
        apply(theme)
        importCode = ""
        statusMessage = String(localized: "Imported \(theme.name)")
    }
}

private extension Color {
    /// sRGB hex (`#RRGGBB`) for persisting a `ColorPicker` selection; nil if it can't resolve to sRGB.
    var themeStudioHex: String? {
        #if os(iOS)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        #elseif os(macOS)
        guard let ns = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = ns.redComponent, g = ns.greenComponent, b = ns.blueComponent
        #endif
        func clamp(_ x: CGFloat) -> Int { Int((min(1, max(0, x)) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", clamp(r), clamp(g), clamp(b))
    }
}
