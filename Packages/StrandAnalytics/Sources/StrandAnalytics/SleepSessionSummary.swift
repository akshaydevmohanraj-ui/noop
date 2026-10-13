import Foundation

/// Turns a night's raw sleep-stage intervals (as Apple Health stores them) into the session-level
/// numbers the stage totals cannot express: how long it took to fall asleep, how many times sleep
/// broke, efficiency over the whole session, and naps.
///
/// Intervals are grouped into sessions wherever the gap between one interval's end and the next one's
/// start exceeds `sessionGapMin`. A session is a NAP when it is short (`asleep < napMaxAsleepMin`) and
/// starts in the daytime (`napStartHours`); everything else is a main sleep. Each session is
/// attributed to the local day it ENDS on, matching how the rest of NOOP labels a night by wake day.
public enum SleepSessionSummary {

    public enum Stage: Sendable { case inBed, awake, asleep }

    public struct Interval: Sendable {
        public let start: Date
        public let end: Date
        public let stage: Stage
        public init(start: Date, end: Date, stage: Stage) {
            self.start = start; self.end = end; self.stage = stage
        }
    }

    public struct Day: Equatable, Sendable {
        /// Minutes from the session's first record to the first asleep record, when the session opens
        /// with in-bed or awake time (nil when it opens asleep, so latency is unknown, not zero).
        public var latencyMin: Double?
        /// Awake intervals of at least `minAwakeningMin` between the first and last asleep interval.
        public var awakenings: Int?
        /// Asleep minutes / session span, as a percentage, for the main sleep.
        public var efficiencyPct: Double?
        public var napMin: Double = 0
        public var naps: Int = 0
    }

    public static let sessionGapMin: Double = 60
    public static let napMaxAsleepMin: Double = 180
    public static let napMinAsleepMin: Double = 10
    public static let napStartHours = 9..<19
    public static let minAwakeningMin: Double = 1

    /// Per-day summaries keyed by `dayKey(sessionEnd)`.
    public static func summarize(_ intervals: [Interval], calendar: Calendar = .current,
                                 dayKey: (Date) -> String) -> [String: Day] {
        let sorted = intervals.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        var sessions: [[Interval]] = []
        var currentEnd: Date?
        for iv in sorted {
            if let e = currentEnd, iv.start.timeIntervalSince(e) <= sessionGapMin * 60 {
                sessions[sessions.count - 1].append(iv)
                currentEnd = max(e, iv.end)
            } else {
                sessions.append([iv])
                currentEnd = iv.end
            }
        }

        var out: [String: Day] = [:]
        for session in sessions {
            let asleep = session.filter { $0.stage == .asleep }
            guard let firstAsleep = asleep.first, let lastAsleep = asleep.max(by: { $0.end < $1.end }) else { continue }
            let asleepMin = asleep.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) / 60 }
            let start = session.map(\.start).min()!
            let end = session.map(\.end).max()!
            let key = dayKey(end)
            var day = out[key] ?? Day()

            let startHour = calendar.component(.hour, from: start)
            let isNap = asleepMin < napMaxAsleepMin && napStartHours.contains(startHour)
            if isNap {
                if asleepMin >= napMinAsleepMin {
                    day.napMin += asleepMin
                    day.naps += 1
                }
            } else if day.efficiencyPct == nil {
                // The first main sleep ending on this day wins; a second one is rare and ambiguous.
                let opensAwake = session.first.map { $0.stage != .asleep } ?? false
                day.latencyMin = opensAwake ? max(0, firstAsleep.start.timeIntervalSince(start) / 60) : nil
                day.awakenings = session.filter {
                    $0.stage == .awake && $0.start >= firstAsleep.end && $0.end <= lastAsleep.start
                        && $0.end.timeIntervalSince($0.start) >= minAwakeningMin * 60
                }.count
                let span = end.timeIntervalSince(start) / 60
                day.efficiencyPct = span > 0 ? min(100, 100 * asleepMin / span) : nil
            }
            out[key] = day
        }
        return out
    }
}
