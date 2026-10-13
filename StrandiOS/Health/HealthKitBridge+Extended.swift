#if os(iOS)
import Foundation
import HealthKit
import WhoopStore

/// Extended Apple Health read path: mobility, running form, activity-ring minutes, daylight, audio
/// exposure, walking heart rate, one-minute heart-rate recovery, mindful minutes and heart events.
///
/// Every metric lands in `metricSeries` under the apple-health source with its own key, so it shows
/// up in Explore, Compare and the correlation scan through `MetricCatalog` with no extra plumbing.
/// Unlike the core aggregates in `sync`, each metric is independent: a failed read skips only that
/// metric, and nothing here can hold back or overwrite the core rows.
extension HealthKitBridge {

    /// One daily quantity aggregate: the HealthKit type, the metricSeries key it writes, the unit it
    /// is read in, the per-day statistic, and a multiplier applied to the value before storing.
    struct ExtendedQuantitySpec {
        let id: HKQuantityTypeIdentifier
        let key: String
        let unit: HKUnit
        let op: HKStatisticsOptions
        var scale: Double = 1
    }

    /// One daily category aggregate: either summed minutes (`minutes == true`) or an event count.
    struct ExtendedCategorySpec {
        let id: HKCategoryTypeIdentifier
        let key: String
        let minutes: Bool
    }

    static let extendedQuantitySpecs: [ExtendedQuantitySpec] = {
        let perMinute = HKUnit.count().unitDivided(by: .minute())
        let metersPerSecond = HKUnit.meter().unitDivided(by: .second())
        let dBA = HKUnit.decibelAWeightedSoundPressureLevel()
        return [
            // Activity rings and movement
            ExtendedQuantitySpec(id: .appleExerciseTime, key: "exercise_min", unit: .minute(), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .appleStandTime, key: "stand_min", unit: .minute(), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .flightsClimbed, key: "flights", unit: .count(), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .distanceWalkingRunning, key: "walk_run_km", unit: .meterUnit(with: .kilo), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .timeInDaylight, key: "daylight_min", unit: .minute(), op: .cumulativeSum),
            // Heart
            ExtendedQuantitySpec(id: .walkingHeartRateAverage, key: "walking_hr", unit: perMinute, op: .discreteAverage),
            ExtendedQuantitySpec(id: .heartRateRecoveryOneMinute, key: "hr_recovery_1min", unit: perMinute, op: .discreteAverage),
            // Mobility (walking)
            ExtendedQuantitySpec(id: .walkingSpeed, key: "walking_speed", unit: metersPerSecond, op: .discreteAverage, scale: 3.6),
            ExtendedQuantitySpec(id: .walkingStepLength, key: "walking_step_length", unit: .meterUnit(with: .centi), op: .discreteAverage),
            ExtendedQuantitySpec(id: .walkingAsymmetryPercentage, key: "walking_asymmetry", unit: .percent(), op: .discreteAverage, scale: 100),
            ExtendedQuantitySpec(id: .walkingDoubleSupportPercentage, key: "walking_double_support", unit: .percent(), op: .discreteAverage, scale: 100),
            ExtendedQuantitySpec(id: .appleWalkingSteadiness, key: "walking_steadiness", unit: .percent(), op: .discreteMostRecent, scale: 100),
            ExtendedQuantitySpec(id: .sixMinuteWalkTestDistance, key: "six_min_walk", unit: .meter(), op: .discreteMostRecent),
            ExtendedQuantitySpec(id: .stairAscentSpeed, key: "stair_ascent_speed", unit: metersPerSecond, op: .discreteAverage),
            ExtendedQuantitySpec(id: .stairDescentSpeed, key: "stair_descent_speed", unit: metersPerSecond, op: .discreteAverage),
            // Running form
            ExtendedQuantitySpec(id: .runningSpeed, key: "running_speed", unit: metersPerSecond, op: .discreteAverage, scale: 3.6),
            ExtendedQuantitySpec(id: .runningPower, key: "running_power", unit: .watt(), op: .discreteAverage),
            ExtendedQuantitySpec(id: .runningStrideLength, key: "running_stride", unit: .meter(), op: .discreteAverage),
            ExtendedQuantitySpec(id: .runningGroundContactTime, key: "running_ground_contact", unit: .secondUnit(with: .milli), op: .discreteAverage),
            ExtendedQuantitySpec(id: .runningVerticalOscillation, key: "running_vertical_osc", unit: .meterUnit(with: .centi), op: .discreteAverage),
            // Hearing
            ExtendedQuantitySpec(id: .environmentalAudioExposure, key: "env_audio_db", unit: dBA, op: .discreteAverage),
            ExtendedQuantitySpec(id: .headphoneAudioExposure, key: "headphone_audio_db", unit: dBA, op: .discreteAverage),
            // Body
            ExtendedQuantitySpec(id: .waistCircumference, key: "waist_cm", unit: .meterUnit(with: .centi), op: .discreteMostRecent),
        ]
    }()

    static let extendedCategorySpecs: [ExtendedCategorySpec] = [
        ExtendedCategorySpec(id: .mindfulSession, key: "mindful_min", minutes: true),
        ExtendedCategorySpec(id: .highHeartRateEvent, key: "high_hr_events", minutes: false),
        ExtendedCategorySpec(id: .lowHeartRateEvent, key: "low_hr_events", minutes: false),
        ExtendedCategorySpec(id: .irregularHeartRhythmEvent, key: "irregular_rhythm_events", minutes: false),
    ]

    /// Read every extended metric for [start, end] and upsert the points. Best-effort per metric.
    func syncExtended(store: WhoopStore, start: Date, end: Date) async {
        var points: [MetricPoint] = []
        for spec in Self.extendedQuantitySpecs {
            var specPoints: [MetricPoint] = []
            let outcome = await collect(spec.id, unit: spec.unit, start: start, end: end, op: spec.op) { day, v in
                specPoints.append(MetricPoint(day: day, key: spec.key, value: v * spec.scale))
            }
            if outcome == .read { points.append(contentsOf: specPoints) }
        }
        for spec in Self.extendedCategorySpecs {
            if let daily = await collectCategoryDaily(spec, start: start, end: end) {
                points.append(contentsOf: daily.map { MetricPoint(day: $0.key, key: spec.key, value: $0.value) })
            }
        }
        guard !points.isEmpty else { return }
        try? await store.upsertMetricSeries(points, deviceId: appleDeviceId)
    }

    /// Per-day minutes (or event counts) for one category type, attributed to the sample's start day.
    /// Returns nil when the query fails, so a failure never writes zeros over stored days.
    private func collectCategoryDaily(_ spec: ExtendedCategorySpec, start: Date,
                                      end: Date) async -> [String: Double]? {
        guard let type = HKObjectType.categoryType(forIdentifier: spec.id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let store = HKHealthStore()
        return await withCheckedContinuation { (cont: CheckedContinuation<[String: Double]?, Never>) in
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, error in
                guard error == nil, let samples else { cont.resume(returning: nil); return }
                var byDay: [String: Double] = [:]
                for sample in samples {
                    let day = HealthKitBridge.dayString(sample.startDate)
                    let amount = spec.minutes ? sample.endDate.timeIntervalSince(sample.startDate) / 60 : 1
                    byDay[day, default: 0] += amount
                }
                cont.resume(returning: byDay)
            }
            store.execute(q)
        }
    }
}
#endif
