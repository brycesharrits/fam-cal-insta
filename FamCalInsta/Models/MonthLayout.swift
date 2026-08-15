import Foundation

enum MonthLayout: String, CaseIterable, Codable {
    case single
    case double
    case grid

    /// Total photo slots including the required AI slot.
    var slotCount: Int {
        switch self {
        case .single:  return 1
        case .double:  return 2
        case .grid:    return 4
        }
    }

    var userSlotCount: Int { slotCount - 1 }

    var displayName: String {
        switch self {
        case .single:  return "Single"
        case .double:  return "Double"
        case .grid:    return "Grid"
        }
    }

    /// Aspect ratio (width / height) of the printed photo area. 4:3 landscape
    /// matches a typical wall-calendar image plate. When a print partner is
    /// wired up, this should move onto the project so it can vary per product.
    static let pageAspect: CGFloat = 4.0 / 3.0
}

extension MonthLayout {
    /// 12-month distribution weighted toward simpler layouts:
    /// 6 singles, 4 doubles, 2 grids — 10 user photos total.
    /// Shuffled deterministically by seed.
    static func distribute(seed: Int) -> [MonthLayout] {
        var base: [MonthLayout] =
            Array(repeating: .single, count: 6) +
            Array(repeating: .double, count: 4) +
            Array(repeating: .grid,   count: 2)
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(seed)))
        base.shuffle(using: &rng)
        return base
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }
}
