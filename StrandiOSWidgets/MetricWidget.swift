import WidgetKit
import SwiftUI
import AppIntents
import StrandDesign

// MARK: - Configuration

/// The score a configurable Metric widget shows. Each case reads one field of the shared
/// `WidgetSnapshot`, so adding a case only needs a snapshot field and a colour.
enum WidgetMetricChoice: String, AppEnum {
    case recovery, strain, sleep, hrv, restingHr, heartRate

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Metric"
    static var caseDisplayRepresentations: [WidgetMetricChoice: DisplayRepresentation] = [
        .recovery: "Recovery",
        .strain: "Strain",
        .sleep: "Sleep",
        .hrv: "HRV",
        .restingHr: "Resting heart rate",
        .heartRate: "Heart rate",
    ]
}

/// How the Metric widget draws its value.
enum WidgetStyleChoice: String, AppEnum {
    case ring, number, bar

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
    static var caseDisplayRepresentations: [WidgetStyleChoice: DisplayRepresentation] = [
        .ring: "Ring",
        .number: "Big number",
        .bar: "Bar",
    ]
}

/// The widget's background treatment.
enum WidgetBackgroundChoice: String, AppEnum {
    case theme, tinted, clear

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Background"
    static var caseDisplayRepresentations: [WidgetBackgroundChoice: DisplayRepresentation] = [
        .theme: "Theme",
        .tinted: "Tinted",
        .clear: "Minimal",
    ]
}

struct MetricWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose metric"
    static var description = IntentDescription("Pick the score, style and background for this widget.")

    @Parameter(title: "Metric", default: .recovery)
    var metric: WidgetMetricChoice

    @Parameter(title: "Style", default: .ring)
    var style: WidgetStyleChoice

    @Parameter(title: "Background", default: .theme)
    var background: WidgetBackgroundChoice

    @Parameter(title: "Show label", default: true)
    var showLabel: Bool
}

// MARK: - Timeline

struct MetricEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let config: MetricWidgetIntent
}

struct MetricProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MetricEntry {
        MetricEntry(date: Date(), snapshot: .placeholder, config: MetricWidgetIntent())
    }

    func snapshot(for configuration: MetricWidgetIntent, in context: Context) async -> MetricEntry {
        WidgetTheme.applyInExtension()
        let snap = WidgetSnapshot.load() ?? (context.isPreview ? .placeholder : .unavailable)
        return MetricEntry(date: Date(), snapshot: snap, config: configuration)
    }

    func timeline(for configuration: MetricWidgetIntent, in context: Context) async -> Timeline<MetricEntry> {
        WidgetTheme.applyInExtension()
        let entry = MetricEntry(date: Date(), snapshot: WidgetSnapshot.load() ?? .unavailable,
                                config: configuration)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
            ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(next))
    }
}

// MARK: - Resolved value

/// One metric resolved against a snapshot: display text, ring fill (0…1, nil when unscored), label,
/// unit and colour.
private struct ResolvedMetric {
    let text: String?
    let fraction: Double?
    let label: String
    let unit: String
    let color: Color
    let symbol: String

    init(_ choice: WidgetMetricChoice, snap: WidgetSnapshot) {
        switch choice {
        case .recovery:
            text = snap.recovery.map(String.init)
            fraction = snap.recovery.map { Double($0) / 100 }
            label = String(localized: "Recovery"); unit = "%"
            color = StrandPalette.chargeColor; symbol = "bolt.heart"
        case .strain:
            text = snap.effortDisplay ?? snap.effort.map(String.init)
            fraction = snap.effort.map { Double($0) / 100 }
            label = String(localized: "Strain"); unit = ""
            color = StrandPalette.effortColor; symbol = "flame"
        case .sleep:
            text = snap.rest.map(String.init)
            fraction = snap.rest.map { Double($0) / 100 }
            label = String(localized: "Sleep"); unit = "%"
            color = StrandPalette.restColor; symbol = "moon.zzz"
        case .hrv:
            text = snap.hrv.map(String.init)
            fraction = snap.hrv.map { min(1, Double($0) / 120) }
            label = String(localized: "HRV"); unit = "ms"
            color = StrandPalette.chargeColor; symbol = "waveform.path.ecg"
        case .restingHr:
            text = snap.restingHr.map(String.init)
            fraction = snap.restingHr.map { min(1, max(0, (90 - Double($0)) / 50)) }
            label = String(localized: "Resting HR"); unit = "bpm"
            color = StrandPalette.liquidHeart; symbol = "heart"
        case .heartRate:
            text = snap.bpm.map(String.init)
            fraction = snap.bpm.map { min(1, Double($0) / 200) }
            label = String(localized: "Heart rate"); unit = "bpm"
            color = StrandPalette.liquidHeart; symbol = "heart.fill"
        }
    }
}

// MARK: - Views

struct MetricWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: MetricEntry

    private var metric: ResolvedMetric { ResolvedMetric(entry.config.metric, snap: entry.snapshot) }
    private var tint: Color { renderingMode == .fullColor ? metric.color : .primary }

    var body: some View {
        switch family {
        case .accessoryInline:
            Label {
                Text("\(metric.label) \(metric.text ?? "–")\(metric.unit)")
            } icon: {
                Image(systemName: metric.symbol)
            }
        case .accessoryCircular:
            Gauge(value: metric.fraction ?? 0) {
                Image(systemName: metric.symbol)
            } currentValueLabel: {
                Text(metric.text ?? "–").monospacedDigit()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(tint)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label(metric.label, systemImage: metric.symbol)
                    .font(.caption)
                Text(metric.text.map { "\($0) \(metric.unit)" } ?? "–")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Gauge(value: metric.fraction ?? 0) { EmptyView() }
                    .gaugeStyle(.accessoryLinearCapacity)
                    .tint(tint)
            }
        default:
            homeScreen
        }
    }

    @ViewBuilder
    private var homeScreen: some View {
        VStack(spacing: 6) {
            switch entry.config.style {
            case .ring:   ring
            case .number: bigNumber
            case .bar:    bar
            }
            if entry.config.showLabel {
                Text(metric.label)
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(metric.color.opacity(0.18), lineWidth: 10)
            if let fraction = metric.fraction {
                Circle()
                    .trim(from: 0, to: max(0.0001, min(1, fraction)))
                    .stroke(metric.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            valueText(size: 30)
        }
        .padding(6)
    }

    private var bigNumber: some View {
        VStack(spacing: 2) {
            Image(systemName: metric.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(metric.color)
            valueText(size: 44)
            if !metric.unit.isEmpty {
                Text(metric.unit)
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
            }
        }
    }

    private var bar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: metric.symbol).foregroundStyle(metric.color)
                Spacer()
                valueText(size: 32)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(metric.color.opacity(0.18))
                    Capsule().fill(metric.color)
                        .frame(width: geo.size.width * CGFloat(min(1, max(0, metric.fraction ?? 0))))
                }
            }
            .frame(height: 10)
        }
        .padding(.horizontal, 4)
    }

    private func valueText(size: CGFloat) -> some View {
        Text(metric.text ?? "–")
            .font(StrandFont.rounded(size, weight: .bold))
            .foregroundStyle(metric.text == nil ? StrandPalette.textTertiary : StrandPalette.textPrimary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

/// Background for the configured treatment: the theme surface, a wash of the metric's own colour, or
/// nothing beyond the system's.
private struct MetricWidgetBackground: View {
    let entry: MetricEntry

    var body: some View {
        let color = ResolvedMetric(entry.config.metric, snap: entry.snapshot).color
        switch entry.config.background {
        case .theme:  StrandPalette.surfaceBase
        case .tinted: LinearGradient(colors: [color.opacity(0.35), StrandPalette.surfaceBase],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
        case .clear:  Color.clear
        }
    }
}

struct MetricWidget: Widget {
    static let kind = "NOOPMetricWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: MetricWidgetIntent.self,
                               provider: MetricProvider()) { entry in
            MetricWidgetView(entry: entry)
                .containerBackground(for: .widget) { MetricWidgetBackground(entry: entry) }
        }
        .configurationDisplayName("Any Metric")
        .description("Choose any score, then pick a ring, big number or bar. Follows your Theme Studio colours.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}
