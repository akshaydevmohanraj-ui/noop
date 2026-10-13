import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// The browsable exercise library: gym exercises (with the machine or station to look for) and
/// no-equipment exercises, filterable by muscle and searchable. Tapping an exercise opens a detail
/// sheet with the front / back muscle map.
struct ExerciseLibraryView: View {
    let onClose: () -> Void

    @State private var gym = true
    @State private var muscle: LiftMuscle?
    @State private var search = ""
    @State private var selected: LibrarySelection?

    private var results: [ExerciseLibrary.Entry] {
        ExerciseLibrary.browse(gym: gym, muscle: muscle, search: search)
    }

    /// Results grouped by equipment, in the order the equipment enum declares.
    private var grouped: [EquipmentGroup] {
        let byEquipment = Dictionary(grouping: results, by: \.equipment)
        return ExerciseLibrary.Equipment.allCases.compactMap { eq in
            byEquipment[eq].map { EquipmentGroup(equipment: eq, entries: $0) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(StrandPalette.hairline)
            ScrollView {
                VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                    controls
                    if results.isEmpty {
                        NoopCard {
                            Text("No exercises match. Try another muscle or clear the search.")
                                .font(StrandFont.footnote)
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                    ForEach(grouped) { group in
                        let equipment = group.equipment
                        let entries = group.entries
                        VStack(alignment: .leading, spacing: NoopMetrics.gap) {
                            Label(equipment.displayName, systemImage: equipment.symbol)
                                .font(StrandFont.headline)
                                .foregroundStyle(StrandPalette.textPrimary)
                            NoopCard {
                                VStack(spacing: 0) {
                                    ForEach(Array(entries.enumerated()), id: \.element.name) { index, entry in
                                        if index > 0 { Divider().overlay(StrandPalette.hairline) }
                                        row(entry)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            #if os(iOS)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            #endif
        }
        #if os(macOS)
        .frame(width: 600, height: 720)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .noopSheetPresentation(largeFirst: true)
        #endif
        .background(StrandPalette.surfaceBase)
        .sheet(item: $selected) { selection in
            ExerciseDetailSheet(entry: selection.entry, onClose: { selected = nil })
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("EXERCISE LIBRARY").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textTertiary)
                Text("\(ExerciseLibrary.entries.count) exercises")
                    .font(StrandFont.rounded(26, weight: .bold))
                    .foregroundStyle(StrandPalette.textPrimary)
                Text("What to use, and which muscles it works.").font(StrandFont.caption)
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

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Where", selection: $gym) {
                Text("Gym equipment").tag(true)
                Text("No equipment").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(StrandPalette.textTertiary)
                TextField("Search exercises or machines", text: $search)
                    .textFieldStyle(.plain)
                    .font(StrandFont.body)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(StrandPalette.surfaceRaised)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    chip(title: String(localized: "All muscles"), active: muscle == nil) { muscle = nil }
                    ForEach(LiftMuscle.ordered, id: \.self) { m in
                        chip(title: m.displayName, active: muscle == m) { muscle = (muscle == m) ? nil : m }
                    }
                }
            }
        }
    }

    private func chip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(StrandFont.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(active ? StrandPalette.goldDeepText : StrandPalette.textSecondary)
                .background(Capsule().fill(active ? StrandPalette.accent : StrandPalette.surfaceRaised))
        }
        .buttonStyle(.plain)
    }

    private func row(_ entry: ExerciseLibrary.Entry) -> some View {
        Button { selected = LibrarySelection(entry: entry) } label: {
            HStack(spacing: 12) {
                MuscleBodyMap(primary: entry.primaryMapMuscles, secondary: entry.secondaryMapMuscles,
                              showsLabels: false)
                    .frame(width: 46, height: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(StrandFont.body)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text(entry.subtitle)
                        .font(StrandFont.caption)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Detail for one library exercise: the muscle map large, the movers listed, and the equipment.
struct ExerciseDetailSheet: View {
    let entry: ExerciseLibrary.Entry
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(entry.equipment.displayName, systemImage: entry.equipment.symbol)
                        .font(StrandFont.overline)
                        .foregroundStyle(StrandPalette.textTertiary)
                    Text(entry.name)
                        .font(StrandFont.rounded(24, weight: .bold))
                        .foregroundStyle(StrandPalette.textPrimary)
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
            Divider().overlay(StrandPalette.hairline)
            ScrollView {
                VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                    NoopCard {
                        MuscleBodyMap(primary: entry.primaryMapMuscles, secondary: entry.secondaryMapMuscles)
                            .frame(maxHeight: 320)
                    }
                    NoopCard {
                        VStack(alignment: .leading, spacing: 12) {
                            musclesRow(title: String(localized: "Primary"), muscles: [entry.primary], strong: true)
                            if !entry.secondary.isEmpty {
                                musclesRow(title: String(localized: "Also works"), muscles: entry.secondary, strong: false)
                            }
                        }
                    }
                    NoopCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("What you need")
                                .font(StrandFont.headline)
                                .foregroundStyle(StrandPalette.textPrimary)
                            Label(entry.setup ?? entry.equipment.defaultSetup, systemImage: entry.equipment.symbol)
                                .font(StrandFont.body)
                                .foregroundStyle(StrandPalette.textSecondary)
                            Text(entry.equipment.needsGym ? "Gym equipment" : "Do it anywhere")
                                .font(StrandFont.caption)
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                    }
                }
                .padding(20)
            }
        }
        #if os(macOS)
        .frame(width: 480, height: 680)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .noopSheetPresentation(largeFirst: true)
        #endif
        .background(StrandPalette.surfaceBase)
    }

    private func musclesRow(title: String, muscles: [LiftMuscle], strong: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).strandOverline()
            FlowChips(items: muscles.map(\.displayName), strong: strong)
        }
    }
}

/// Wrapped capsule labels for muscle names.
private struct FlowChips: View {
    let items: [String]
    let strong: Bool

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6, alignment: .leading)],
                  alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { name in
                Text(name)
                    .font(StrandFont.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(strong ? StrandPalette.goldDeepText : StrandPalette.textPrimary)
                    .background(Capsule().fill(strong ? StrandPalette.effortColor
                                                      : StrandPalette.effortColor.opacity(0.22)))
            }
        }
    }
}

private struct EquipmentGroup: Identifiable {
    let equipment: ExerciseLibrary.Equipment
    let entries: [ExerciseLibrary.Entry]
    var id: String { equipment.rawValue }
}

private struct LibrarySelection: Identifiable {
    let entry: ExerciseLibrary.Entry
    var id: String { entry.name }
}

// MARK: - App-layer presentation for library types

extension ExerciseLibrary.Equipment {
    var displayName: String {
        switch self {
        case .machine:    return String(localized: "Machines")
        case .cable:      return String(localized: "Cables")
        case .smith:      return String(localized: "Smith machine")
        case .barbell:    return String(localized: "Barbell")
        case .dumbbell:   return String(localized: "Dumbbells")
        case .kettlebell: return String(localized: "Kettlebell")
        case .band:       return String(localized: "Resistance band")
        case .bodyweight: return String(localized: "Bodyweight")
        case .other:      return String(localized: "Other equipment")
        }
    }

    var symbol: String {
        switch self {
        case .machine:    return "gearshape.2"
        case .cable:      return "arrow.down.to.line"
        case .smith:      return "square.split.1x2"
        case .barbell:    return "figure.strengthtraining.traditional"
        case .dumbbell:   return "dumbbell"
        case .kettlebell: return "figure.strengthtraining.functional"
        case .band:       return "lasso"
        case .bodyweight: return "figure.core.training"
        case .other:      return "wrench.and.screwdriver"
        }
    }

    /// Shown when an entry has no specific `setup`.
    var defaultSetup: String {
        switch self {
        case .dumbbell:   return String(localized: "A pair of dumbbells")
        case .kettlebell: return String(localized: "One kettlebell")
        case .barbell:    return String(localized: "Barbell and plates")
        case .band:       return String(localized: "A resistance band")
        case .bodyweight: return String(localized: "Just your bodyweight and some floor space")
        default:          return displayName
        }
    }
}

extension ExerciseLibrary.Entry {
    var primaryMapMuscles: Set<BodyMapMuscle> {
        Set([primary].compactMap { BodyMapMuscle(rawValue: $0.rawValue) })
    }

    var secondaryMapMuscles: Set<BodyMapMuscle> {
        Set(secondary.compactMap { BodyMapMuscle(rawValue: $0.rawValue) })
    }

    /// "45° leg press machine · Quads" or "Bodyweight · Chest".
    var subtitle: String {
        "\(setup ?? equipment.displayName) · \(primary.displayName)"
    }
}
