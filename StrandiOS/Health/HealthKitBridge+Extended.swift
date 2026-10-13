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

    /// One daily category aggregate. `mode` picks summed minutes, an event count, or a 0/1 flag for
    /// "this happened today"; `countedValues`, when set, keeps only samples with one of those values
    /// (e.g. only hours actually stood, only symptoms actually present).
    struct ExtendedCategorySpec {
        enum Mode { case minutes, count, flag }
        let id: HKCategoryTypeIdentifier
        let key: String
        let mode: Mode
        var countedValues: Set<Int>? = nil
    }

    /// Every read type the extended path needs, for the authorization request.
    static var extendedReadTypes: Set<HKObjectType> {
        var s = Set<HKObjectType>()
        for spec in extendedQuantitySpecs {
            if let t = HKObjectType.quantityType(forIdentifier: spec.id) { s.insert(t) }
        }
        for spec in extendedCategorySpecs {
            if let t = HKObjectType.categoryType(forIdentifier: spec.id) { s.insert(t) }
        }
        if #available(iOS 18.0, *) { s.insert(HKObjectType.stateOfMindType()) }
        return s
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
            ExtendedQuantitySpec(id: .height, key: "height_cm", unit: .meterUnit(with: .centi), op: .discreteMostRecent),
            ExtendedQuantitySpec(id: .basalBodyTemperature, key: "basal_body_temp", unit: .degreeCelsius(), op: .discreteAverage),
            // Activity extras
            ExtendedQuantitySpec(id: .appleMoveTime, key: "move_min", unit: .minute(), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .distanceCycling, key: "cycling_km", unit: .meterUnit(with: .kilo), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .cyclingSpeed, key: "cycling_speed", unit: metersPerSecond, op: .discreteAverage, scale: 3.6),
            ExtendedQuantitySpec(id: .cyclingPower, key: "cycling_power", unit: .watt(), op: .discreteAverage),
            ExtendedQuantitySpec(id: .cyclingCadence, key: "cycling_cadence", unit: perMinute, op: .discreteAverage),
            ExtendedQuantitySpec(id: .distanceSwimming, key: "swim_m", unit: .meter(), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .swimmingStrokeCount, key: "swim_strokes", unit: .count(), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .numberOfTimesFallen, key: "falls", unit: .count(), op: .cumulativeSum),
            ExtendedQuantitySpec(id: .uvExposure, key: "uv_index", unit: .count(), op: .discreteMax),
            // Vitals from other devices or manual entry
            ExtendedQuantitySpec(id: .bloodPressureSystolic, key: "bp_systolic", unit: .millimeterOfMercury(), op: .discreteAverage),
            ExtendedQuantitySpec(id: .bloodPressureDiastolic, key: "bp_diastolic", unit: .millimeterOfMercury(), op: .discreteAverage),
            ExtendedQuantitySpec(id: .bloodGlucose, key: "blood_glucose", unit: HKUnit(from: "mg/dL"), op: .discreteAverage),
            ExtendedQuantitySpec(id: .peakExpiratoryFlowRate, key: "peak_flow", unit: HKUnit.liter().unitDivided(by: .minute()), op: .discreteAverage),
            ExtendedQuantitySpec(id: .forcedExpiratoryVolume1, key: "fev1", unit: .liter(), op: .discreteAverage),
            ExtendedQuantitySpec(id: .numberOfAlcoholicBeverages, key: "alcohol_drinks", unit: .count(), op: .cumulativeSum),
        ]
    }()

    static let extendedCategorySpecs: [ExtendedCategorySpec] = {
        // Symptom severities other than "not present" mean the symptom was logged as happening.
        let present: Set<Int> = [HKCategoryValueSeverity.unspecified.rawValue, HKCategoryValueSeverity.mild.rawValue,
                                 HKCategoryValueSeverity.moderate.rawValue, HKCategoryValueSeverity.severe.rawValue]
        // Menstrual flow values unspecified / light / medium / heavy (1…4); 5 is "none". Raw values because
        // the iOS 18 `HKCategoryValueVaginalBleeding` rename is unavailable at the iOS 17 deployment target.
        let flow: Set<Int> = [1, 2, 3, 4]
        return [
            ExtendedCategorySpec(id: .mindfulSession, key: "mindful_min", mode: .minutes),
            ExtendedCategorySpec(id: .highHeartRateEvent, key: "high_hr_events", mode: .count),
            ExtendedCategorySpec(id: .lowHeartRateEvent, key: "low_hr_events", mode: .count),
            ExtendedCategorySpec(id: .irregularHeartRhythmEvent, key: "irregular_rhythm_events", mode: .count),
            ExtendedCategorySpec(id: .appleStandHour, key: "stand_hours", mode: .count,
                                 countedValues: [HKCategoryValueAppleStandHour.stood.rawValue]),
            ExtendedCategorySpec(id: .handwashingEvent, key: "handwashing", mode: .count),
            ExtendedCategorySpec(id: .toothbrushingEvent, key: "toothbrushing", mode: .count),
            ExtendedCategorySpec(id: .menstrualFlow, key: "period_day", mode: .flag, countedValues: flow),
            ExtendedCategorySpec(id: .headache, key: "symptom_headache", mode: .flag, countedValues: present),
            ExtendedCategorySpec(id: .fatigue, key: "symptom_fatigue", mode: .flag, countedValues: present),
            ExtendedCategorySpec(id: .nausea, key: "symptom_nausea", mode: .flag, countedValues: present),
            ExtendedCategorySpec(id: .coughing, key: "symptom_cough", mode: .flag, countedValues: present),
            ExtendedCategorySpec(id: .fever, key: "symptom_fever", mode: .flag, countedValues: present),
            ExtendedCategorySpec(id: .soreThroat, key: "symptom_sore_throat", mode: .flag, countedValues: present),
            ExtendedCategorySpec(id: .sleepChanges, key: "symptom_sleep_changes", mode: .flag, countedValues: present),
            ExtendedCategorySpec(id: .moodChanges, key: "symptom_mood_changes", mode: .flag, countedValues: present),
        ]
    }()

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
        if #available(iOS 18.0, *), let mood = await collectStateOfMindDaily(start: start, end: end) {
            points.append(contentsOf: mood.map { MetricPoint(day: $0.key, key: "state_of_mind", value: $0.value) })
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
                    if let allowed = spec.countedValues,
                       let value = (sample as? HKCategorySample)?.value, !allowed.contains(value) { continue }
                    let day = HealthKitBridge.dayString(sample.startDate)
                    switch spec.mode {
                    case .minutes: byDay[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate) / 60
                    case .count:   byDay[day, default: 0] += 1
                    case .flag:    byDay[day] = 1
                    }
                }
                cont.resume(returning: byDay)
            }
            store.execute(q)
        }
    }

    /// Daily average State of Mind valence (-1 very unpleasant … +1 very pleasant), from moods and
    /// emotions logged in the Health or Mindfulness apps (iOS 18+). Nil when the query fails.
    @available(iOS 18.0, *)
    private func collectStateOfMindDaily(start: Date, end: Date) async -> [String: Double]? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let store = HKHealthStore()
        return await withCheckedContinuation { (cont: CheckedContinuation<[String: Double]?, Never>) in
            let q = HKSampleQuery(sampleType: HKObjectType.stateOfMindType(), predicate: predicate,
                                  limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard error == nil, let samples else { cont.resume(returning: nil); return }
                var sum: [String: Double] = [:], count: [String: Double] = [:]
                for case let mood as HKStateOfMind in samples {
                    let day = HealthKitBridge.dayString(mood.startDate)
                    sum[day, default: 0] += mood.valence
                    count[day, default: 0] += 1
                }
                cont.resume(returning: sum.reduce(into: [:]) { out, kv in out[kv.key] = kv.value / (count[kv.key] ?? 1) })
            }
            store.execute(q)
        }
    }
}
#endif
