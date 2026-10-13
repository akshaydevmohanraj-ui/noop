import Foundation

/// Energy Bank: a single "how much is left in the tank right now" number for the day.
///
/// The morning balance is the day's recovery (0–100). Through the day it is drawn down by
/// cardiovascular strain (a maximal 100/100 strain day spends `strainDrainAtMax` points) and by time
/// spent in high physiological stress while not moving (`highStressMinutesPerPoint` minutes cost one
/// point, capped at `stressDrainCap`). It never refills during the day; sleep refills it as the next
/// morning's recovery.
///
/// This is NOOP's own transparent heuristic, not a reproduction of any other app's score: the
/// constants are round numbers chosen so a hard training day with a stressful afternoon can empty a
/// middling morning, and the app shows the drivers next to the number.
public enum EnergyBank {

    public static let strainDrainAtMax: Double = 45
    public static let highStressMinutesPerPoint: Double = 8
    public static let stressDrainCap: Double = 25

    public struct Reading: Equatable, Sendable {
        public let energy: Int
        public let morning: Int
        public let strainDrain: Double
        public let stressDrain: Double
    }

    /// Nil without a recovery score, since there is no honest starting balance.
    public static func reading(recovery: Double?, strain: Double?, highStressMinutes: Double) -> Reading? {
        guard let recovery else { return nil }
        let morning = min(100, max(0, recovery))
        let strainDrain = min(100, max(0, strain ?? 0)) / 100 * strainDrainAtMax
        let stressDrain = min(stressDrainCap, max(0, highStressMinutes) / highStressMinutesPerPoint)
        let energy = min(100, max(0, morning - strainDrain - stressDrain))
        return Reading(energy: Int(energy.rounded()), morning: Int(morning.rounded()),
                       strainDrain: strainDrain, stressDrain: stressDrain)
    }

    /// Minutes of a stress timeline at or above `floor` while not moving, given each bucket's length.
    public static func highStressMinutes(levels: [(level: Double?, moving: Bool)], bucketMinutes: Double,
                                         floor: Double) -> Double {
        Double(levels.filter { !$0.moving && ($0.level ?? -1) >= floor }.count) * bucketMinutes
    }
}
