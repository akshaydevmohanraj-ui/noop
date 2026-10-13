import XCTest
import WhoopStore
@testable import StrandAnalytics

final class TrainingLibraryTests: XCTestCase {

    // MARK: ExerciseLibrary

    func testLibraryNamesAreUniqueCaseInsensitively() {
        let names = ExerciseLibrary.entries.map { $0.name.lowercased() }
        XCTAssertEqual(names.count, Set(names).count)
    }

    func testSecondariesNeverRepeatThePrimary() {
        for e in ExerciseLibrary.entries {
            XCTAssertFalse(e.secondary.contains(e.primary), e.name)
            XCTAssertEqual(e.secondary.count, Set(e.secondary).count, e.name)
        }
    }

    func testMatchesPreferPrefixAndHonourExclusions() {
        let m = ExerciseLibrary.matches("curl")
        XCTAssertFalse(m.isEmpty)
        XCTAssertTrue(m.allSatisfy { $0.name.lowercased().contains("curl") })
        let excluded = ExerciseLibrary.matches("bench", excluding: ["Barbell Bench Press"], limit: 50)
        XCTAssertFalse(excluded.contains { $0.name == "Barbell Bench Press" })
        XCTAssertEqual(ExerciseLibrary.matches("Pull").first?.name.hasPrefix("Pull"), true)
        XCTAssertTrue(ExerciseLibrary.matches("   ").isEmpty)
    }

    func testEntryLookupIsCaseInsensitive() {
        XCTAssertEqual(ExerciseLibrary.entry(named: "back squat")?.primary, .quads)
        XCTAssertNil(ExerciseLibrary.entry(named: "not an exercise"))
    }

    // MARK: MuscleFreshness

    private func set(_ primary: LiftMuscle?, _ secondary: [LiftMuscle] = [], reps: Int? = 8,
                     warmup: Bool = false) -> LiftSetRow {
        LiftSetRow(id: UUID().uuidString, deviceId: "d", sessionId: "s", ord: 0, exercise: "x",
                   primaryMuscle: primary, secondaryMuscles: secondary, setIndex: 0,
                   weightKg: 60, reps: reps, rpe: nil, isWarmup: warmup, startTs: nil, endTs: nil,
                   restSec: nil, note: nil)
    }

    func testUntrainedMusclesAreFullyFresh() {
        let r = MuscleFreshness.readings([], now: 1_000_000)
        XCTAssertEqual(r.count, LiftMuscle.ordered.count)
        XCTAssertTrue(r.allSatisfy { $0.freshnessPct == 100 && $0.lastTrainedTs == nil })
    }

    func testFreshSessionLowersFreshnessAndDecaysOverTime() {
        let now = 10_000_000
        let sets = Array(repeating: set(.chest, [.triceps]), count: 5)
        let justNow = MuscleFreshness.readings([.init(endTs: now, sets: sets)], now: now)
        let chest = justNow.first { $0.muscle == .chest }!
        let triceps = justNow.first { $0.muscle == .triceps }!
        XCTAssertEqual(chest.residualSets, 5, accuracy: 1e-9)
        XCTAssertEqual(chest.freshnessPct, 50)
        XCTAssertEqual(triceps.residualSets, 2.5, accuracy: 1e-9)
        XCTAssertEqual(chest.lastTrainedTs, now)

        let halfLife = Int(MuscleFreshness.halfLifeHours * 3600)
        let later = MuscleFreshness.readings([.init(endTs: now, sets: sets)], now: now + halfLife)
        XCTAssertEqual(later.first { $0.muscle == .chest }!.residualSets, 2.5, accuracy: 1e-9)
    }

    func testWarmupsUnperformedAndOldSessionsAreIgnored() {
        let now = 10_000_000
        let old = now - Int((MuscleFreshness.lookbackHours + 1) * 3600)
        let r = MuscleFreshness.readings([
            .init(endTs: now, sets: [set(.quads, warmup: true), set(.quads, reps: 0)]),
            .init(endTs: old, sets: [set(.quads)]),
        ], now: now)
        XCTAssertEqual(r.first { $0.muscle == .quads }!.freshnessPct, 100)
    }

    func testFreshnessFloorsAtZero() {
        let now = 10_000_000
        let sets = Array(repeating: set(.lats), count: 30)
        let r = MuscleFreshness.readings([.init(endTs: now, sets: sets)], now: now)
        XCTAssertEqual(r.first { $0.muscle == .lats }!.freshnessPct, 0)
    }
}
