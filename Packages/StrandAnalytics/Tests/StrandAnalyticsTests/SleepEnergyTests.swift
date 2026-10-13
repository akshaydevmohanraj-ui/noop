import XCTest
@testable import StrandAnalytics

final class SleepEnergyTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }()
    private lazy var fmt: DateFormatter = {
        let f = DateFormatter(); f.timeZone = cal.timeZone; f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private func t(_ d: Int, _ h: Int, _ m: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 10, day: d, hour: h, minute: m))!
    }
    private typealias I = SleepSessionSummary.Interval

    func testNightWithLatencyAwakeningAndNap() {
        let intervals: [I] = [
            I(start: t(12, 23), end: t(12, 23, 20), stage: .inBed),
            I(start: t(12, 23, 20), end: t(13, 2), stage: .asleep),
            I(start: t(13, 2), end: t(13, 2, 10), stage: .awake),
            I(start: t(13, 2, 10), end: t(13, 6, 30), stage: .asleep),
            I(start: t(13, 6, 30), end: t(13, 6, 40), stage: .awake),
            I(start: t(13, 14), end: t(13, 14, 40), stage: .asleep),
        ]
        let r = SleepSessionSummary.summarize(intervals, calendar: cal) { self.fmt.string(from: $0) }
        let d = r["2026-10-13"]!
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(d.latencyMin, 20)
        XCTAssertEqual(d.awakenings, 1)
        XCTAssertEqual(d.efficiencyPct!, 100.0 * 420 / 460, accuracy: 0.01)
        XCTAssertEqual(d.naps, 1)
        XCTAssertEqual(d.napMin, 40)
    }

    func testSessionOpeningAsleepHasUnknownLatency() {
        let r = SleepSessionSummary.summarize([I(start: t(12, 23), end: t(13, 7), stage: .asleep)],
                                              calendar: cal) { self.fmt.string(from: $0) }
        XCTAssertNil(r["2026-10-13"]!.latencyMin)
    }

    func testTinyDaytimeSleepIsNotANap() {
        let r = SleepSessionSummary.summarize([I(start: t(13, 13), end: t(13, 13, 5), stage: .asleep)],
                                              calendar: cal) { self.fmt.string(from: $0) }
        XCTAssertEqual(r["2026-10-13"]!.naps, 0)
    }

    func testEnergyBankDrainsAndFloors() {
        let e = EnergyBank.reading(recovery: 80, strain: 50, highStressMinutes: 80)!
        XCTAssertEqual(e.morning, 80)
        XCTAssertEqual(e.energy, 48)   // 80 − 22.5 − 10 = 47.5
        XCTAssertNil(EnergyBank.reading(recovery: nil, strain: 50, highStressMinutes: 0))
        XCTAssertEqual(EnergyBank.reading(recovery: 20, strain: 100, highStressMinutes: 999)!.energy, 0)
    }

    func testHighStressMinutesSkipsMovementAndLowLevels() {
        let m = EnergyBank.highStressMinutes(
            levels: [(2.5, false), (2.0, false), (3, true), (1, false), (nil, false)],
            bucketMinutes: 15, floor: 2)
        XCTAssertEqual(m, 30)
    }
}
