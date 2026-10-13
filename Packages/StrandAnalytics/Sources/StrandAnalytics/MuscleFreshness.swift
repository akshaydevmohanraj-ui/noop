import Foundation
import WhoopStore

/// Per-muscle freshness: how much recent training load each muscle is still carrying.
///
/// Each performed working set contributes its fractional credit (direct 1.0, indirect 0.5, the same
/// credit `LiftMetrics.muscleCounts` uses) and that contribution decays exponentially with the time
/// since the session ended. Freshness is the remaining decayed load mapped onto 0–100, where 100 is
/// "nothing left over" and 0 is at or beyond `fatigueAtZero` decayed sets.
///
/// This is an ESTIMATE built on two round-number constants, not a measurement: muscle recovery
/// varies with the person, the exercise, proximity to failure and sleep. The half-life sits in the
/// 24–72 h window that soreness and force-recovery studies broadly report, and the app presents the
/// result with that caveat rather than as a prescription.
public enum MuscleFreshness {

    /// Hours for a set's leftover load to halve.
    public static let halfLifeHours: Double = 36
    /// Decayed fractional sets at which freshness reads 0.
    public static let fatigueAtZero: Double = 10
    /// Sessions older than this contribute too little to matter and are ignored.
    public static let lookbackHours: Double = 7 * 24

    public struct Reading: Equatable, Sendable {
        public let muscle: LiftMuscle
        /// 0 (heavily loaded) … 100 (fully fresh).
        public let freshnessPct: Int
        /// Decayed fractional sets still attributed to this muscle.
        public let residualSets: Double
        /// Unix seconds of the most recent session that trained this muscle, if any.
        public let lastTrainedTs: Int?

        public init(muscle: LiftMuscle, freshnessPct: Int, residualSets: Double, lastTrainedTs: Int?) {
            self.muscle = muscle
            self.freshnessPct = freshnessPct
            self.residualSets = residualSets
            self.lastTrainedTs = lastTrainedTs
        }
    }

    /// One finished session: when it ended and the sets it logged.
    public struct Session: Sendable {
        public let endTs: Int
        public let sets: [LiftSetRow]
        public init(endTs: Int, sets: [LiftSetRow]) {
            self.endTs = endTs
            self.sets = sets
        }
    }

    /// A reading for every muscle in `LiftMuscle.ordered`; untrained muscles read 100.
    public static func readings(_ sessions: [Session], now: Int) -> [Reading] {
        var residual: [LiftMuscle: Double] = [:]
        var last: [LiftMuscle: Int] = [:]
        for session in sessions {
            let hours = Double(now - session.endTs) / 3600
            guard hours >= 0, hours <= lookbackHours else { continue }
            let decay = pow(0.5, hours / halfLifeHours)
            let counts = LiftMetrics.muscleCounts(session.sets).fractional
            for (muscle, sets) in counts where sets > 0 {
                residual[muscle, default: 0] += sets * decay
                last[muscle] = max(last[muscle] ?? 0, session.endTs)
            }
        }
        return LiftMuscle.ordered.map { muscle in
            let r = residual[muscle] ?? 0
            let pct = Int((100 * (1 - min(1, r / fatigueAtZero))).rounded())
            return Reading(muscle: muscle, freshnessPct: pct, residualSets: r, lastTrainedTs: last[muscle])
        }
    }
}
