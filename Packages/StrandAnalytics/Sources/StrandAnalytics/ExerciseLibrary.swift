import Foundation
import WhoopStore

/// A built-in library of common gym exercises, each pre-classified onto the canonical `LiftMuscle`
/// vocabulary with the same direct / indirect split the set counter credits (direct 1.0, indirect
/// 0.5). It seeds the exercise pickers so a typical exercise is one tap with its muscles filled in;
/// the user can still type anything, and an exercise they classify themselves always wins over the
/// library entry of the same name.
///
/// Classifications follow the usual prime-mover / synergist reading of each lift (the movers EMG and
/// hypertrophy studies attribute the exercise to). Stabilisers that do no meaningful shortening are
/// left out, because counting them would inflate weekly sets for muscles that were not trained.
public enum ExerciseLibrary {

    public struct Entry: Equatable, Sendable {
        public let name: String
        public let primary: LiftMuscle
        public let secondary: [LiftMuscle]

        public init(name: String, primary: LiftMuscle, secondary: [LiftMuscle]) {
            self.name = name
            self.primary = primary
            self.secondary = secondary
        }
    }

    public static let entries: [Entry] = [
        Entry(name: "Barbell Bench Press", primary: .chest, secondary: [.frontDelts, .triceps]),
        Entry(name: "Incline Barbell Bench Press", primary: .chest, secondary: [.frontDelts, .triceps]),
        Entry(name: "Decline Barbell Bench Press", primary: .chest, secondary: [.triceps, .frontDelts]),
        Entry(name: "Dumbbell Bench Press", primary: .chest, secondary: [.frontDelts, .triceps]),
        Entry(name: "Incline Dumbbell Press", primary: .chest, secondary: [.frontDelts, .triceps]),
        Entry(name: "Dumbbell Fly", primary: .chest, secondary: [.frontDelts]),
        Entry(name: "Cable Fly", primary: .chest, secondary: [.frontDelts]),
        Entry(name: "Pec Deck", primary: .chest, secondary: [.frontDelts]),
        Entry(name: "Push-Up", primary: .chest, secondary: [.triceps, .frontDelts, .abs]),
        Entry(name: "Chest Dip", primary: .chest, secondary: [.triceps, .frontDelts]),
        Entry(name: "Machine Chest Press", primary: .chest, secondary: [.triceps, .frontDelts]),
        Entry(name: "Overhead Press", primary: .frontDelts, secondary: [.sideDelts, .triceps, .upperBack]),
        Entry(name: "Seated Dumbbell Shoulder Press", primary: .frontDelts, secondary: [.sideDelts, .triceps]),
        Entry(name: "Arnold Press", primary: .frontDelts, secondary: [.sideDelts, .triceps]),
        Entry(name: "Machine Shoulder Press", primary: .frontDelts, secondary: [.sideDelts, .triceps]),
        Entry(name: "Push Press", primary: .frontDelts, secondary: [.triceps, .quads, .glutes]),
        Entry(name: "Lateral Raise", primary: .sideDelts, secondary: [.traps]),
        Entry(name: "Cable Lateral Raise", primary: .sideDelts, secondary: [.traps]),
        Entry(name: "Front Raise", primary: .frontDelts, secondary: [.sideDelts]),
        Entry(name: "Rear Delt Fly", primary: .rearDelts, secondary: [.upperBack]),
        Entry(name: "Face Pull", primary: .rearDelts, secondary: [.upperBack, .traps]),
        Entry(name: "Reverse Pec Deck", primary: .rearDelts, secondary: [.upperBack]),
        Entry(name: "Upright Row", primary: .sideDelts, secondary: [.traps, .biceps]),
        Entry(name: "Close-Grip Bench Press", primary: .triceps, secondary: [.chest, .frontDelts]),
        Entry(name: "Triceps Pushdown", primary: .triceps, secondary: []),
        Entry(name: "Overhead Triceps Extension", primary: .triceps, secondary: []),
        Entry(name: "Skull Crusher", primary: .triceps, secondary: []),
        Entry(name: "Triceps Dip", primary: .triceps, secondary: [.chest, .frontDelts]),
        Entry(name: "Diamond Push-Up", primary: .triceps, secondary: [.chest, .frontDelts]),
        Entry(name: "Triceps Kickback", primary: .triceps, secondary: []),
        Entry(name: "Pull-Up", primary: .lats, secondary: [.biceps, .upperBack, .forearms]),
        Entry(name: "Chin-Up", primary: .lats, secondary: [.biceps, .upperBack]),
        Entry(name: "Lat Pulldown", primary: .lats, secondary: [.biceps, .upperBack]),
        Entry(name: "Close-Grip Lat Pulldown", primary: .lats, secondary: [.biceps, .upperBack]),
        Entry(name: "Straight-Arm Pulldown", primary: .lats, secondary: [.triceps]),
        Entry(name: "Barbell Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps, .lowerBack]),
        Entry(name: "Pendlay Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps, .lowerBack]),
        Entry(name: "Dumbbell Row", primary: .lats, secondary: [.upperBack, .rearDelts, .biceps]),
        Entry(name: "Seated Cable Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps]),
        Entry(name: "T-Bar Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps]),
        Entry(name: "Chest-Supported Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps]),
        Entry(name: "Machine Row", primary: .upperBack, secondary: [.lats, .biceps]),
        Entry(name: "Inverted Row", primary: .upperBack, secondary: [.lats, .biceps, .rearDelts]),
        Entry(name: "Barbell Shrug", primary: .traps, secondary: [.forearms]),
        Entry(name: "Dumbbell Shrug", primary: .traps, secondary: [.forearms]),
        Entry(name: "Barbell Curl", primary: .biceps, secondary: [.forearms]),
        Entry(name: "Dumbbell Curl", primary: .biceps, secondary: [.forearms]),
        Entry(name: "Hammer Curl", primary: .biceps, secondary: [.forearms]),
        Entry(name: "Incline Dumbbell Curl", primary: .biceps, secondary: []),
        Entry(name: "Preacher Curl", primary: .biceps, secondary: []),
        Entry(name: "Cable Curl", primary: .biceps, secondary: [.forearms]),
        Entry(name: "Concentration Curl", primary: .biceps, secondary: []),
        Entry(name: "EZ-Bar Curl", primary: .biceps, secondary: [.forearms]),
        Entry(name: "Reverse Curl", primary: .forearms, secondary: [.biceps]),
        Entry(name: "Wrist Curl", primary: .forearms, secondary: []),
        Entry(name: "Reverse Wrist Curl", primary: .forearms, secondary: []),
        Entry(name: "Farmer's Carry", primary: .forearms, secondary: [.traps, .abs, .obliques]),
        Entry(name: "Back Squat", primary: .quads, secondary: [.glutes, .adductors, .lowerBack]),
        Entry(name: "Front Squat", primary: .quads, secondary: [.glutes, .abs, .upperBack]),
        Entry(name: "Goblet Squat", primary: .quads, secondary: [.glutes, .adductors]),
        Entry(name: "Hack Squat", primary: .quads, secondary: [.glutes]),
        Entry(name: "Leg Press", primary: .quads, secondary: [.glutes, .adductors]),
        Entry(name: "Bulgarian Split Squat", primary: .quads, secondary: [.glutes, .adductors]),
        Entry(name: "Walking Lunge", primary: .quads, secondary: [.glutes, .adductors]),
        Entry(name: "Reverse Lunge", primary: .quads, secondary: [.glutes]),
        Entry(name: "Step-Up", primary: .quads, secondary: [.glutes]),
        Entry(name: "Leg Extension", primary: .quads, secondary: []),
        Entry(name: "Sissy Squat", primary: .quads, secondary: []),
        Entry(name: "Box Jump", primary: .quads, secondary: [.glutes, .calves]),
        Entry(name: "Conventional Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack, .upperBack, .traps, .forearms, .quads]),
        Entry(name: "Sumo Deadlift", primary: .glutes, secondary: [.quads, .adductors, .hamstrings, .lowerBack, .traps]),
        Entry(name: "Romanian Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack]),
        Entry(name: "Stiff-Leg Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack]),
        Entry(name: "Trap Bar Deadlift", primary: .quads, secondary: [.glutes, .hamstrings, .lowerBack, .traps]),
        Entry(name: "Good Morning", primary: .hamstrings, secondary: [.lowerBack, .glutes]),
        Entry(name: "Lying Leg Curl", primary: .hamstrings, secondary: [.calves]),
        Entry(name: "Seated Leg Curl", primary: .hamstrings, secondary: []),
        Entry(name: "Nordic Curl", primary: .hamstrings, secondary: []),
        Entry(name: "Glute-Ham Raise", primary: .hamstrings, secondary: [.glutes, .calves]),
        Entry(name: "Hip Thrust", primary: .glutes, secondary: [.hamstrings]),
        Entry(name: "Glute Bridge", primary: .glutes, secondary: [.hamstrings]),
        Entry(name: "Cable Pull-Through", primary: .glutes, secondary: [.hamstrings]),
        Entry(name: "Kettlebell Swing", primary: .glutes, secondary: [.hamstrings, .lowerBack, .frontDelts]),
        Entry(name: "Cable Kickback", primary: .glutes, secondary: [.hamstrings]),
        Entry(name: "Hip Abduction Machine", primary: .abductors, secondary: [.glutes]),
        Entry(name: "Hip Adduction Machine", primary: .adductors, secondary: []),
        Entry(name: "Copenhagen Plank", primary: .adductors, secondary: [.obliques]),
        Entry(name: "Standing Calf Raise", primary: .calves, secondary: []),
        Entry(name: "Seated Calf Raise", primary: .calves, secondary: []),
        Entry(name: "Leg Press Calf Raise", primary: .calves, secondary: []),
        Entry(name: "Back Extension", primary: .lowerBack, secondary: [.glutes, .hamstrings]),
        Entry(name: "Superman", primary: .lowerBack, secondary: [.glutes]),
        Entry(name: "Plank", primary: .abs, secondary: [.obliques]),
        Entry(name: "Side Plank", primary: .obliques, secondary: [.abs]),
        Entry(name: "Crunch", primary: .abs, secondary: []),
        Entry(name: "Cable Crunch", primary: .abs, secondary: [.obliques]),
        Entry(name: "Hanging Leg Raise", primary: .abs, secondary: [.obliques, .forearms]),
        Entry(name: "Lying Leg Raise", primary: .abs, secondary: []),
        Entry(name: "Ab Wheel Rollout", primary: .abs, secondary: [.obliques, .lats]),
        Entry(name: "Russian Twist", primary: .obliques, secondary: [.abs]),
        Entry(name: "Pallof Press", primary: .obliques, secondary: [.abs]),
        Entry(name: "Woodchopper", primary: .obliques, secondary: [.abs]),
        Entry(name: "Dead Bug", primary: .abs, secondary: [.obliques]),
        Entry(name: "Mountain Climber", primary: .abs, secondary: [.frontDelts, .quads]),
        Entry(name: "Neck Flexion", primary: .neck, secondary: []),
        Entry(name: "Neck Extension", primary: .neck, secondary: [.traps]),
        Entry(name: "Power Clean", primary: .quads, secondary: [.glutes, .hamstrings, .traps, .upperBack, .calves]),
        Entry(name: "Hang Clean", primary: .traps, secondary: [.quads, .glutes, .hamstrings, .upperBack]),
        Entry(name: "Snatch", primary: .quads, secondary: [.glutes, .hamstrings, .traps, .frontDelts, .upperBack]),
        Entry(name: "Clean and Jerk", primary: .quads, secondary: [.glutes, .frontDelts, .triceps, .traps, .upperBack]),
        Entry(name: "Thruster", primary: .quads, secondary: [.frontDelts, .triceps, .glutes]),
        Entry(name: "Burpee", primary: .quads, secondary: [.chest, .frontDelts, .triceps, .abs]),
        Entry(name: "Turkish Get-Up", primary: .abs, secondary: [.frontDelts, .glutes, .obliques]),
        Entry(name: "Sled Push", primary: .quads, secondary: [.glutes, .calves]),
        Entry(name: "Battle Ropes", primary: .frontDelts, secondary: [.abs, .forearms]),
        Entry(name: "Muscle-Up", primary: .lats, secondary: [.chest, .triceps, .biceps]),
        Entry(name: "Landmine Press", primary: .frontDelts, secondary: [.chest, .triceps]),
        Entry(name: "Dumbbell Pullover", primary: .lats, secondary: [.chest, .triceps]),
    ]

    /// Library entries whose name contains `query` (case-insensitive), excluding any name in
    /// `excluding` (compared case-insensitively). Prefix matches sort first, then alphabetical.
    public static func matches(_ query: String, excluding: Set<String> = [], limit: Int = 6) -> [Entry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let skip = Set(excluding.map { $0.lowercased() })
        return entries
            .filter { e in
                let n = e.name.lowercased()
                return n.contains(q) && n != q && !skip.contains(n)
            }
            .sorted { a, b in
                let ap = a.name.lowercased().hasPrefix(q), bp = b.name.lowercased().hasPrefix(q)
                return ap != bp ? ap : a.name < b.name
            }
            .prefix(limit)
            .map { $0 }
    }

    /// The library entry with exactly this name (case-insensitive), if any.
    public static func entry(named name: String) -> Entry? {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries.first { $0.name.lowercased() == n }
    }
}
