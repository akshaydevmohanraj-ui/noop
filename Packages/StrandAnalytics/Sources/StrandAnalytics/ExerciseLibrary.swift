import Foundation
import WhoopStore

/// A built-in library of common exercises, each pre-classified onto the canonical `LiftMuscle`
/// vocabulary with the same direct / indirect split the set counter credits (direct 1.0, indirect
/// 0.5), the equipment it needs, and (where it matters) the specific machine or station to find.
/// It seeds the exercise pickers so a typical exercise is one tap with its muscles filled in, and
/// backs the browsable Exercise Library screen. The user can still type anything, and an exercise
/// they classify themselves always wins over the library entry of the same name.
///
/// Classifications follow the usual prime-mover / synergist reading of each lift (the movers EMG and
/// hypertrophy studies attribute the exercise to). Stabilisers that do no meaningful shortening are
/// left out, because counting them would inflate weekly sets for muscles that were not trained.
public enum ExerciseLibrary {

    /// What an exercise is performed with. Display names and icons live in the app layer.
    public enum Equipment: String, CaseIterable, Sendable {
        case machine, cable, smith, barbell, dumbbell, kettlebell, band, bodyweight, other

        /// True when the exercise needs a gym (a machine, cable stack, rack or loaded bar). Bands and
        /// bodyweight work anywhere. Dumbbells and kettlebells count as gym kit, since most people
        /// do not own a full rack of them.
        public var needsGym: Bool {
            switch self {
            case .band, .bodyweight: return false
            default:                 return true
            }
        }
    }

    public struct Entry: Equatable, Sendable {
        public let name: String
        public let primary: LiftMuscle
        public let secondary: [LiftMuscle]
        public let equipment: Equipment
        /// The machine, station or accessory to look for, e.g. "45° leg press machine". Nil when the
        /// equipment category says it all (a pair of dumbbells, bodyweight on the floor).
        public let setup: String?

        public init(name: String, primary: LiftMuscle, secondary: [LiftMuscle],
                    equipment: Equipment, setup: String? = nil) {
            self.name = name
            self.primary = primary
            self.secondary = secondary
            self.equipment = equipment
            self.setup = setup
        }

        /// Every muscle the exercise trains, primary first.
        public var allMuscles: [LiftMuscle] { [primary] + secondary }
    }

    public static let entries: [Entry] = [
        Entry(name: "Barbell Bench Press", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .barbell, setup: "Flat bench + barbell rack"),
        Entry(name: "Incline Barbell Bench Press", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .barbell, setup: "Incline bench + barbell rack"),
        Entry(name: "Decline Barbell Bench Press", primary: .chest, secondary: [.triceps, .frontDelts], equipment: .barbell, setup: "Decline bench + barbell rack"),
        Entry(name: "Dumbbell Bench Press", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .dumbbell, setup: "Flat bench"),
        Entry(name: "Incline Dumbbell Press", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .dumbbell, setup: "Adjustable bench (30-45°)"),
        Entry(name: "Dumbbell Fly", primary: .chest, secondary: [.frontDelts], equipment: .dumbbell, setup: "Flat bench"),
        Entry(name: "Cable Fly", primary: .chest, secondary: [.frontDelts], equipment: .cable, setup: "Cable crossover station"),
        Entry(name: "Low-to-High Cable Fly", primary: .chest, secondary: [.frontDelts], equipment: .cable, setup: "Cable crossover station"),
        Entry(name: "Pec Deck", primary: .chest, secondary: [.frontDelts], equipment: .machine, setup: "Pec deck / rear delt fly machine"),
        Entry(name: "Machine Chest Press", primary: .chest, secondary: [.triceps, .frontDelts], equipment: .machine, setup: "Seated chest press machine"),
        Entry(name: "Incline Machine Press", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .machine, setup: "Incline chest press machine"),
        Entry(name: "Smith Machine Bench Press", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .smith, setup: "Smith machine + flat bench"),
        Entry(name: "Chest Dip", primary: .chest, secondary: [.triceps, .frontDelts], equipment: .bodyweight, setup: "Dip station"),
        Entry(name: "Push-Up", primary: .chest, secondary: [.triceps, .frontDelts, .abs], equipment: .bodyweight, setup: nil),
        Entry(name: "Wide Push-Up", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .bodyweight, setup: nil),
        Entry(name: "Decline Push-Up", primary: .chest, secondary: [.frontDelts, .triceps], equipment: .bodyweight, setup: nil),
        Entry(name: "Overhead Press", primary: .frontDelts, secondary: [.sideDelts, .triceps, .upperBack], equipment: .barbell, setup: "Squat rack"),
        Entry(name: "Seated Dumbbell Shoulder Press", primary: .frontDelts, secondary: [.sideDelts, .triceps], equipment: .dumbbell, setup: "Adjustable bench (upright)"),
        Entry(name: "Arnold Press", primary: .frontDelts, secondary: [.sideDelts, .triceps], equipment: .dumbbell, setup: "Adjustable bench (upright)"),
        Entry(name: "Machine Shoulder Press", primary: .frontDelts, secondary: [.sideDelts, .triceps], equipment: .machine, setup: "Shoulder press machine"),
        Entry(name: "Smith Machine Shoulder Press", primary: .frontDelts, secondary: [.sideDelts, .triceps], equipment: .smith, setup: "Smith machine + upright bench"),
        Entry(name: "Push Press", primary: .frontDelts, secondary: [.triceps, .quads, .glutes], equipment: .barbell, setup: "Squat rack"),
        Entry(name: "Landmine Press", primary: .frontDelts, secondary: [.chest, .triceps], equipment: .barbell, setup: "Landmine attachment"),
        Entry(name: "Pike Push-Up", primary: .frontDelts, secondary: [.triceps, .upperBack], equipment: .bodyweight, setup: nil),
        Entry(name: "Handstand Push-Up", primary: .frontDelts, secondary: [.triceps, .traps], equipment: .bodyweight, setup: nil),
        Entry(name: "Lateral Raise", primary: .sideDelts, secondary: [.traps], equipment: .dumbbell, setup: nil),
        Entry(name: "Cable Lateral Raise", primary: .sideDelts, secondary: [.traps], equipment: .cable, setup: "Single cable stack (low pulley)"),
        Entry(name: "Machine Lateral Raise", primary: .sideDelts, secondary: [.traps], equipment: .machine, setup: "Lateral raise machine"),
        Entry(name: "Front Raise", primary: .frontDelts, secondary: [.sideDelts], equipment: .dumbbell, setup: nil),
        Entry(name: "Rear Delt Fly", primary: .rearDelts, secondary: [.upperBack], equipment: .dumbbell, setup: nil),
        Entry(name: "Face Pull", primary: .rearDelts, secondary: [.upperBack, .traps], equipment: .cable, setup: "Cable stack + rope attachment"),
        Entry(name: "Reverse Pec Deck", primary: .rearDelts, secondary: [.upperBack], equipment: .machine, setup: "Pec deck / rear delt fly machine"),
        Entry(name: "Band Pull-Apart", primary: .rearDelts, secondary: [.upperBack], equipment: .band, setup: nil),
        Entry(name: "Upright Row", primary: .sideDelts, secondary: [.traps, .biceps], equipment: .barbell, setup: nil),
        Entry(name: "Close-Grip Bench Press", primary: .triceps, secondary: [.chest, .frontDelts], equipment: .barbell, setup: "Flat bench + barbell rack"),
        Entry(name: "Triceps Pushdown", primary: .triceps, secondary: [], equipment: .cable, setup: "Cable stack + straight bar or rope"),
        Entry(name: "Overhead Triceps Extension", primary: .triceps, secondary: [], equipment: .cable, setup: "Cable stack + rope attachment"),
        Entry(name: "Skull Crusher", primary: .triceps, secondary: [], equipment: .barbell, setup: "Flat bench + EZ bar"),
        Entry(name: "Assisted Dip Machine", primary: .triceps, secondary: [.chest, .frontDelts], equipment: .machine, setup: "Assisted dip / pull-up machine"),
        Entry(name: "Machine Triceps Extension", primary: .triceps, secondary: [], equipment: .machine, setup: "Triceps extension machine"),
        Entry(name: "Bench Dip", primary: .triceps, secondary: [.chest, .frontDelts], equipment: .bodyweight, setup: nil),
        Entry(name: "Diamond Push-Up", primary: .triceps, secondary: [.chest, .frontDelts], equipment: .bodyweight, setup: nil),
        Entry(name: "Triceps Kickback", primary: .triceps, secondary: [], equipment: .dumbbell, setup: nil),
        Entry(name: "Pull-Up", primary: .lats, secondary: [.biceps, .upperBack, .forearms], equipment: .bodyweight, setup: "Pull-up bar"),
        Entry(name: "Chin-Up", primary: .lats, secondary: [.biceps, .upperBack], equipment: .bodyweight, setup: "Pull-up bar"),
        Entry(name: "Assisted Pull-Up", primary: .lats, secondary: [.biceps, .upperBack], equipment: .machine, setup: "Assisted dip / pull-up machine"),
        Entry(name: "Lat Pulldown", primary: .lats, secondary: [.biceps, .upperBack], equipment: .machine, setup: "Lat pulldown machine"),
        Entry(name: "Close-Grip Lat Pulldown", primary: .lats, secondary: [.biceps, .upperBack], equipment: .machine, setup: "Lat pulldown machine + V-handle"),
        Entry(name: "Straight-Arm Pulldown", primary: .lats, secondary: [.triceps], equipment: .cable, setup: "Cable stack + straight bar"),
        Entry(name: "Barbell Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps, .lowerBack], equipment: .barbell, setup: nil),
        Entry(name: "Pendlay Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps, .lowerBack], equipment: .barbell, setup: nil),
        Entry(name: "Dumbbell Row", primary: .lats, secondary: [.upperBack, .rearDelts, .biceps], equipment: .dumbbell, setup: "Flat bench"),
        Entry(name: "Seated Cable Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps], equipment: .cable, setup: "Seated cable row station"),
        Entry(name: "T-Bar Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps], equipment: .machine, setup: "T-bar row machine"),
        Entry(name: "Chest-Supported Row", primary: .upperBack, secondary: [.lats, .rearDelts, .biceps], equipment: .machine, setup: "Chest-supported row machine"),
        Entry(name: "Machine Row", primary: .upperBack, secondary: [.lats, .biceps], equipment: .machine, setup: "Seated row machine"),
        Entry(name: "Inverted Row", primary: .upperBack, secondary: [.lats, .biceps, .rearDelts], equipment: .bodyweight, setup: "Smith machine bar or rings"),
        Entry(name: "Superman", primary: .lowerBack, secondary: [.glutes], equipment: .bodyweight, setup: nil),
        Entry(name: "Barbell Shrug", primary: .traps, secondary: [.forearms], equipment: .barbell, setup: nil),
        Entry(name: "Dumbbell Shrug", primary: .traps, secondary: [.forearms], equipment: .dumbbell, setup: nil),
        Entry(name: "Barbell Curl", primary: .biceps, secondary: [.forearms], equipment: .barbell, setup: nil),
        Entry(name: "Dumbbell Curl", primary: .biceps, secondary: [.forearms], equipment: .dumbbell, setup: nil),
        Entry(name: "Hammer Curl", primary: .biceps, secondary: [.forearms], equipment: .dumbbell, setup: nil),
        Entry(name: "Incline Dumbbell Curl", primary: .biceps, secondary: [], equipment: .dumbbell, setup: "Adjustable bench (45°)"),
        Entry(name: "Preacher Curl", primary: .biceps, secondary: [], equipment: .machine, setup: "Preacher curl bench"),
        Entry(name: "Cable Curl", primary: .biceps, secondary: [.forearms], equipment: .cable, setup: "Cable stack (low pulley)"),
        Entry(name: "Concentration Curl", primary: .biceps, secondary: [], equipment: .dumbbell, setup: nil),
        Entry(name: "EZ-Bar Curl", primary: .biceps, secondary: [.forearms], equipment: .barbell, setup: "EZ bar"),
        Entry(name: "Band Curl", primary: .biceps, secondary: [.forearms], equipment: .band, setup: nil),
        Entry(name: "Reverse Curl", primary: .forearms, secondary: [.biceps], equipment: .barbell, setup: "EZ bar"),
        Entry(name: "Wrist Curl", primary: .forearms, secondary: [], equipment: .dumbbell, setup: nil),
        Entry(name: "Reverse Wrist Curl", primary: .forearms, secondary: [], equipment: .dumbbell, setup: nil),
        Entry(name: "Farmer's Carry", primary: .forearms, secondary: [.traps, .abs, .obliques], equipment: .dumbbell, setup: nil),
        Entry(name: "Dead Hang", primary: .forearms, secondary: [.lats], equipment: .bodyweight, setup: "Pull-up bar"),
        Entry(name: "Back Squat", primary: .quads, secondary: [.glutes, .adductors, .lowerBack], equipment: .barbell, setup: "Squat rack"),
        Entry(name: "Front Squat", primary: .quads, secondary: [.glutes, .abs, .upperBack], equipment: .barbell, setup: "Squat rack"),
        Entry(name: "Goblet Squat", primary: .quads, secondary: [.glutes, .adductors], equipment: .dumbbell, setup: nil),
        Entry(name: "Smith Machine Squat", primary: .quads, secondary: [.glutes, .adductors], equipment: .smith, setup: "Smith machine"),
        Entry(name: "Hack Squat", primary: .quads, secondary: [.glutes], equipment: .machine, setup: "Hack squat machine"),
        Entry(name: "Pendulum Squat", primary: .quads, secondary: [.glutes], equipment: .machine, setup: "Pendulum squat machine"),
        Entry(name: "Belt Squat", primary: .quads, secondary: [.glutes, .adductors], equipment: .machine, setup: "Belt squat machine"),
        Entry(name: "Leg Press", primary: .quads, secondary: [.glutes, .adductors], equipment: .machine, setup: "45° leg press machine"),
        Entry(name: "Leg Extension", primary: .quads, secondary: [], equipment: .machine, setup: "Leg extension machine"),
        Entry(name: "Bulgarian Split Squat", primary: .quads, secondary: [.glutes, .adductors], equipment: .dumbbell, setup: "Flat bench"),
        Entry(name: "Walking Lunge", primary: .quads, secondary: [.glutes, .adductors], equipment: .dumbbell, setup: nil),
        Entry(name: "Reverse Lunge", primary: .quads, secondary: [.glutes], equipment: .dumbbell, setup: nil),
        Entry(name: "Step-Up", primary: .quads, secondary: [.glutes], equipment: .dumbbell, setup: "Plyo box or bench"),
        Entry(name: "Bodyweight Squat", primary: .quads, secondary: [.glutes, .adductors], equipment: .bodyweight, setup: nil),
        Entry(name: "Jump Squat", primary: .quads, secondary: [.glutes, .calves], equipment: .bodyweight, setup: nil),
        Entry(name: "Pistol Squat", primary: .quads, secondary: [.glutes, .adductors], equipment: .bodyweight, setup: nil),
        Entry(name: "Wall Sit", primary: .quads, secondary: [.glutes], equipment: .bodyweight, setup: nil),
        Entry(name: "Sissy Squat", primary: .quads, secondary: [], equipment: .bodyweight, setup: nil),
        Entry(name: "Bodyweight Lunge", primary: .quads, secondary: [.glutes, .adductors], equipment: .bodyweight, setup: nil),
        Entry(name: "Box Jump", primary: .quads, secondary: [.glutes, .calves], equipment: .bodyweight, setup: "Plyo box"),
        Entry(name: "Conventional Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack, .upperBack, .traps, .forearms, .quads], equipment: .barbell, setup: nil),
        Entry(name: "Sumo Deadlift", primary: .glutes, secondary: [.quads, .adductors, .hamstrings, .lowerBack, .traps], equipment: .barbell, setup: nil),
        Entry(name: "Romanian Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack], equipment: .barbell, setup: nil),
        Entry(name: "Dumbbell Romanian Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack], equipment: .dumbbell, setup: nil),
        Entry(name: "Stiff-Leg Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack], equipment: .barbell, setup: nil),
        Entry(name: "Trap Bar Deadlift", primary: .quads, secondary: [.glutes, .hamstrings, .lowerBack, .traps], equipment: .barbell, setup: "Trap (hex) bar"),
        Entry(name: "Good Morning", primary: .hamstrings, secondary: [.lowerBack, .glutes], equipment: .barbell, setup: "Squat rack"),
        Entry(name: "Lying Leg Curl", primary: .hamstrings, secondary: [.calves], equipment: .machine, setup: "Lying leg curl machine"),
        Entry(name: "Seated Leg Curl", primary: .hamstrings, secondary: [], equipment: .machine, setup: "Seated leg curl machine"),
        Entry(name: "Nordic Curl", primary: .hamstrings, secondary: [], equipment: .bodyweight, setup: "Anchor pad or partner"),
        Entry(name: "Single-Leg Romanian Deadlift", primary: .hamstrings, secondary: [.glutes, .lowerBack], equipment: .bodyweight, setup: nil),
        Entry(name: "Glute-Ham Raise", primary: .hamstrings, secondary: [.glutes, .calves], equipment: .machine, setup: "GHD (glute-ham developer)"),
        Entry(name: "Hip Thrust", primary: .glutes, secondary: [.hamstrings], equipment: .barbell, setup: "Flat bench or hip thrust machine"),
        Entry(name: "Machine Hip Thrust", primary: .glutes, secondary: [.hamstrings], equipment: .machine, setup: "Hip thrust machine"),
        Entry(name: "Glute Bridge", primary: .glutes, secondary: [.hamstrings], equipment: .bodyweight, setup: nil),
        Entry(name: "Single-Leg Glute Bridge", primary: .glutes, secondary: [.hamstrings], equipment: .bodyweight, setup: nil),
        Entry(name: "Cable Pull-Through", primary: .glutes, secondary: [.hamstrings], equipment: .cable, setup: "Cable stack + rope attachment"),
        Entry(name: "Kettlebell Swing", primary: .glutes, secondary: [.hamstrings, .lowerBack, .frontDelts], equipment: .kettlebell, setup: nil),
        Entry(name: "Cable Kickback", primary: .glutes, secondary: [.hamstrings], equipment: .cable, setup: "Cable stack + ankle strap"),
        Entry(name: "Glute Kickback Machine", primary: .glutes, secondary: [.hamstrings], equipment: .machine, setup: "Glute kickback machine"),
        Entry(name: "Hip Abduction Machine", primary: .abductors, secondary: [.glutes], equipment: .machine, setup: "Hip abduction machine"),
        Entry(name: "Band Lateral Walk", primary: .abductors, secondary: [.glutes], equipment: .band, setup: nil),
        Entry(name: "Hip Adduction Machine", primary: .adductors, secondary: [], equipment: .machine, setup: "Hip adduction machine"),
        Entry(name: "Copenhagen Plank", primary: .adductors, secondary: [.obliques], equipment: .bodyweight, setup: "Bench"),
        Entry(name: "Standing Calf Raise", primary: .calves, secondary: [], equipment: .machine, setup: "Standing calf raise machine"),
        Entry(name: "Seated Calf Raise", primary: .calves, secondary: [], equipment: .machine, setup: "Seated calf raise machine"),
        Entry(name: "Leg Press Calf Raise", primary: .calves, secondary: [], equipment: .machine, setup: "45° leg press machine"),
        Entry(name: "Bodyweight Calf Raise", primary: .calves, secondary: [], equipment: .bodyweight, setup: "Step or stair edge"),
        Entry(name: "Back Extension", primary: .lowerBack, secondary: [.glutes, .hamstrings], equipment: .machine, setup: "45° back extension bench"),
        Entry(name: "Bird Dog", primary: .lowerBack, secondary: [.abs, .glutes], equipment: .bodyweight, setup: nil),
        Entry(name: "Plank", primary: .abs, secondary: [.obliques], equipment: .bodyweight, setup: nil),
        Entry(name: "Side Plank", primary: .obliques, secondary: [.abs], equipment: .bodyweight, setup: nil),
        Entry(name: "Crunch", primary: .abs, secondary: [], equipment: .bodyweight, setup: nil),
        Entry(name: "Bicycle Crunch", primary: .abs, secondary: [.obliques], equipment: .bodyweight, setup: nil),
        Entry(name: "V-Up", primary: .abs, secondary: [], equipment: .bodyweight, setup: nil),
        Entry(name: "Hollow Hold", primary: .abs, secondary: [], equipment: .bodyweight, setup: nil),
        Entry(name: "Cable Crunch", primary: .abs, secondary: [.obliques], equipment: .cable, setup: "Cable stack + rope attachment"),
        Entry(name: "Ab Crunch Machine", primary: .abs, secondary: [], equipment: .machine, setup: "Ab crunch machine"),
        Entry(name: "Hanging Leg Raise", primary: .abs, secondary: [.obliques, .forearms], equipment: .bodyweight, setup: "Pull-up bar"),
        Entry(name: "Captain's Chair Leg Raise", primary: .abs, secondary: [.obliques], equipment: .machine, setup: "Captain's chair / vertical knee raise"),
        Entry(name: "Lying Leg Raise", primary: .abs, secondary: [], equipment: .bodyweight, setup: nil),
        Entry(name: "Ab Wheel Rollout", primary: .abs, secondary: [.obliques, .lats], equipment: .other, setup: "Ab wheel"),
        Entry(name: "Russian Twist", primary: .obliques, secondary: [.abs], equipment: .bodyweight, setup: nil),
        Entry(name: "Pallof Press", primary: .obliques, secondary: [.abs], equipment: .cable, setup: "Cable stack (chest height)"),
        Entry(name: "Woodchopper", primary: .obliques, secondary: [.abs], equipment: .cable, setup: "Cable stack (high pulley)"),
        Entry(name: "Rotary Torso Machine", primary: .obliques, secondary: [.abs], equipment: .machine, setup: "Rotary torso machine"),
        Entry(name: "Dead Bug", primary: .abs, secondary: [.obliques], equipment: .bodyweight, setup: nil),
        Entry(name: "Mountain Climber", primary: .abs, secondary: [.frontDelts, .quads], equipment: .bodyweight, setup: nil),
        Entry(name: "Neck Flexion", primary: .neck, secondary: [], equipment: .other, setup: "Neck harness or plate"),
        Entry(name: "Neck Extension", primary: .neck, secondary: [.traps], equipment: .other, setup: "Neck harness or plate"),
        Entry(name: "Power Clean", primary: .quads, secondary: [.glutes, .hamstrings, .traps, .upperBack, .calves], equipment: .barbell, setup: "Lifting platform"),
        Entry(name: "Hang Clean", primary: .traps, secondary: [.quads, .glutes, .hamstrings, .upperBack], equipment: .barbell, setup: "Lifting platform"),
        Entry(name: "Snatch", primary: .quads, secondary: [.glutes, .hamstrings, .traps, .frontDelts, .upperBack], equipment: .barbell, setup: "Lifting platform"),
        Entry(name: "Clean and Jerk", primary: .quads, secondary: [.glutes, .frontDelts, .triceps, .traps, .upperBack], equipment: .barbell, setup: "Lifting platform"),
        Entry(name: "Thruster", primary: .quads, secondary: [.frontDelts, .triceps, .glutes], equipment: .barbell, setup: nil),
        Entry(name: "Burpee", primary: .quads, secondary: [.chest, .frontDelts, .triceps, .abs], equipment: .bodyweight, setup: nil),
        Entry(name: "Turkish Get-Up", primary: .abs, secondary: [.frontDelts, .glutes, .obliques], equipment: .kettlebell, setup: nil),
        Entry(name: "Sled Push", primary: .quads, secondary: [.glutes, .calves], equipment: .other, setup: "Weight sled + turf lane"),
        Entry(name: "Battle Ropes", primary: .frontDelts, secondary: [.abs, .forearms], equipment: .other, setup: "Battle ropes"),
        Entry(name: "Muscle-Up", primary: .lats, secondary: [.chest, .triceps, .biceps], equipment: .bodyweight, setup: "Pull-up bar or rings"),
        Entry(name: "Dumbbell Pullover", primary: .lats, secondary: [.chest, .triceps], equipment: .dumbbell, setup: "Flat bench"),
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

    /// Entries for the browse screen: gym or no-equipment, optionally only those training `muscle`
    /// (as primary or secondary), optionally filtered by a search string, sorted by name.
    public static func browse(gym: Bool, muscle: LiftMuscle? = nil, search: String = "") -> [Entry] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries
            .filter { $0.equipment.needsGym == gym }
            .filter { muscle == nil || $0.allMuscles.contains(muscle!) }
            .filter { q.isEmpty || $0.name.lowercased().contains(q) || ($0.setup?.lowercased().contains(q) ?? false) }
            .sorted { $0.name < $1.name }
    }
}
