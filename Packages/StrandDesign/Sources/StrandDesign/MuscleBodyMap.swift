import SwiftUI

/// A muscle region the body map can highlight. Raw values match `WhoopStore.LiftMuscle` exactly, so
/// the app maps a classification onto the map with `BodyMapMuscle(rawValue: muscle.rawValue)` without
/// this design package depending on the store.
public enum BodyMapMuscle: String, CaseIterable, Sendable {
    case chest, frontDelts, sideDelts, rearDelts, triceps
    case lats, upperBack, traps, biceps, forearms
    case quads, hamstrings, glutes, adductors, abductors, calves
    case abs, obliques, lowerBack, neck
}

/// A front-and-back anatomical diagram drawn in the design system's own tokens: the silhouette in the
/// inset surface colour, every muscle region outlined faintly, the exercise's primary movers filled in
/// the tint and its secondary movers in a lighter wash of it. Pure vector, so it follows light / dark
/// mode and the Theme Studio tint, and stays crisp at any size.
public struct MuscleBodyMap: View {
    private let primary: Set<BodyMapMuscle>
    private let secondary: Set<BodyMapMuscle>
    private let tint: Color
    private let showsLabels: Bool

    public init(primary: Set<BodyMapMuscle>, secondary: Set<BodyMapMuscle> = [],
                tint: Color = StrandPalette.effortColor, showsLabels: Bool = true) {
        self.primary = primary
        self.secondary = secondary.subtracting(primary)
        self.tint = tint
        self.showsLabels = showsLabels
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            figure(.front)
            figure(.back)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private func figure(_ side: BodySide) -> some View {
        VStack(spacing: 6) {
            Canvas { context, size in
                let scale = min(size.width / BodyGeometry.width, size.height / BodyGeometry.height)
                let dx = (size.width - BodyGeometry.width * scale) / 2
                context.translateBy(x: dx, y: 0)
                context.scaleBy(x: scale, y: scale)

                for part in BodyGeometry.silhouette {
                    context.fill(part, with: .color(StrandPalette.surfaceInset))
                    context.stroke(part, with: .color(StrandPalette.hairline), lineWidth: 0.6)
                }
                for region in BodyGeometry.regions(side) {
                    if primary.contains(region.muscle) {
                        context.fill(region.path, with: .color(tint))
                    } else if secondary.contains(region.muscle) {
                        context.fill(region.path, with: .color(tint.opacity(0.4)))
                    } else {
                        context.fill(region.path, with: .color(StrandPalette.textTertiary.opacity(0.13)))
                    }
                }
            }
            .aspectRatio(BodyGeometry.width / BodyGeometry.height, contentMode: .fit)
            if showsLabels {
                Text(side == .front ? String(localized: "Front", bundle: .module)
                                    : String(localized: "Back", bundle: .module))
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var accessibilitySummary: String {
        let p = primary.map(\.rawValue).sorted().joined(separator: ", ")
        let s = secondary.map(\.rawValue).sorted().joined(separator: ", ")
        return s.isEmpty ? "Primary: \(p)" : "Primary: \(p). Secondary: \(s)"
    }
}

enum BodySide { case front, back }

/// The diagram's geometry in a 100 × 220 design space. Every shape is a smooth closed curve through a
/// handful of anatomical landmarks (Catmull-Rom, so the points sit ON the outline). Paired muscles are
/// described on the figure's right half and mirrored across x = 50; midline regions are drawn once.
enum BodyGeometry {
    static let width: CGFloat = 100
    static let height: CGFloat = 220

    struct Region {
        let muscle: BodyMapMuscle
        let path: Path
    }

    /// Head plus one continuous body outline (arms held slightly away from the torso).
    static let silhouette: [Path] = {
        let half: [CGPoint] = pts([
            (50, 23), (55, 23.5), (57, 28.5), (65, 30.5), (73, 33), (78.5, 39), (80.5, 52), (81.5, 66),
            (84.5, 84), (86, 104), (85, 117), (80.5, 118.5), (78.5, 106), (75.5, 90), (72.5, 74),
            (70, 60), (68, 72), (66.5, 90), (67.5, 104), (68.5, 122), (67, 148), (64.5, 163),
            (65.5, 182), (63.5, 205), (64.5, 213), (56.5, 214.5), (55, 204), (54, 182), (53, 164),
            (52, 140), (50.5, 121)
        ])
        let outline = half + half.dropFirst().dropLast().reversed().map(mirror)
        return [Path(ellipseIn: CGRect(x: 41, y: 1.5, width: 18, height: 21)), smooth(outline)]
    }()

    static func regions(_ side: BodySide) -> [Region] {
        side == .front ? front : back
    }

    private static let front: [Region] = [
        single(.neck, [(46.5, 22), (53.5, 22), (54.5, 29), (50, 30.5), (45.5, 29)]),
        single(.abs, [(45.5, 56), (54.5, 56), (55.5, 76), (54.5, 97), (50, 102), (45.5, 97), (44.5, 76)]),
    ] + pair(.traps, [(54.5, 26.5), (60, 29), (65.5, 31.2), (57.5, 32)])
      + pair(.frontDelts, [(63.5, 31.5), (70, 32), (73.5, 37), (71.5, 44.5), (66.5, 42), (63, 36.5)])
      + pair(.sideDelts, [(72.5, 33.5), (77.5, 38), (79.5, 46), (75.5, 47.5), (72.5, 41)])
      + pair(.chest, [(52, 35), (61.5, 33), (68.5, 38), (68.5, 46.5), (62, 52.5), (53, 52.5), (51, 45)])
      + pair(.biceps, [(71, 46.5), (76.5, 48.5), (78.5, 58), (76.5, 70), (72.5, 70), (70.5, 58)])
      + pair(.forearms, [(74, 74.5), (80, 76.5), (84, 92), (83.5, 105.5), (79.5, 106), (75.5, 90)])
      + pair(.obliques, [(56.5, 56), (63, 58.5), (66, 72), (65, 90), (58.5, 96), (56.5, 78)])
      + pair(.abductors, [(64.5, 100), (67.5, 104), (68, 116), (65.5, 114)])
      + pair(.quads, [(56.5, 108), (63, 104.5), (67, 118), (66, 145), (62, 160), (56.5, 158), (54.5, 130)])
      + pair(.adductors, [(51.2, 112), (55, 110), (56, 129), (53.5, 140), (51.2, 128)])

    private static let back: [Region] = [
        single(.neck, [(46.5, 22), (53.5, 22), (54, 27), (46, 27)]),
        single(.traps, [(50, 24.5), (57, 27.5), (66, 31.5), (58, 36), (54.5, 47), (50, 58),
                        (45.5, 47), (42, 36), (34, 31.5), (43, 27.5)]),
        single(.lowerBack, [(46, 78), (54, 78), (56, 91), (54.5, 102), (45.5, 102), (44, 91)]),
    ] + pair(.rearDelts, [(65.5, 32), (72, 34), (74, 41), (69, 44.5), (65, 38)])
      + pair(.sideDelts, [(72.5, 33.5), (77.5, 38), (79.5, 46), (75.5, 47.5), (72.5, 41)])
      + pair(.upperBack, [(53, 38.5), (59.5, 37.5), (64, 42.5), (62, 52), (55.5, 54), (52.5, 46)])
      + pair(.lats, [(56, 52.5), (64, 46.5), (69, 56), (67, 72), (60, 84), (55.5, 76)])
      + pair(.triceps, [(71, 44.5), (77, 47.5), (79, 58), (76.5, 70), (72.5, 69), (70.5, 56)])
      + pair(.forearms, [(74, 74.5), (80, 76.5), (84, 92), (83.5, 105.5), (79.5, 106), (75.5, 90)])
      + pair(.glutes, [(51.2, 102.5), (60, 100.5), (67, 106), (67.5, 118), (60, 124), (52, 122)])
      + pair(.hamstrings, [(53, 126.5), (61, 124.5), (66, 132), (65, 152), (60, 162), (55, 158), (53, 140)])
      + pair(.calves, [(55, 168.5), (62, 166.5), (65, 178), (63, 194), (58, 198), (55, 188)])

    // MARK: Helpers

    private static func pts(_ xy: [(CGFloat, CGFloat)]) -> [CGPoint] { xy.map { CGPoint(x: $0.0, y: $0.1) } }

    private static func mirror(_ p: CGPoint) -> CGPoint { CGPoint(x: width - p.x, y: p.y) }

    private static func single(_ muscle: BodyMapMuscle, _ xy: [(CGFloat, CGFloat)]) -> Region {
        Region(muscle: muscle, path: smooth(pts(xy)))
    }

    private static func pair(_ muscle: BodyMapMuscle, _ xy: [(CGFloat, CGFloat)]) -> [Region] {
        let right = pts(xy)
        return [Region(muscle: muscle, path: smooth(right)),
                Region(muscle: muscle, path: smooth(right.map(mirror)))]
    }

    /// A closed Catmull-Rom spline through `points`, converted to cubic Béziers.
    static func smooth(_ points: [CGPoint], tension: CGFloat = 0.5) -> Path {
        var path = Path()
        let n = points.count
        guard n > 2 else { return path }
        path.move(to: points[0])
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n], p1 = points[i]
            let p2 = points[(i + 1) % n], p3 = points[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) * tension / 3, y: p1.y + (p2.y - p0.y) * tension / 3)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) * tension / 3, y: p2.y - (p3.y - p1.y) * tension / 3)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        path.closeSubpath()
        return path
    }
}
