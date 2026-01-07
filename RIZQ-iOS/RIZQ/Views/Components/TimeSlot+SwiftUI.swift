import SwiftUI
import RIZQKit

extension TimeSlot {
  var color: Color {
    switch self {
    case .morning: return .badgeMorning
    case .anytime: return .tealMuted
    case .evening: return .badgeEvening
    }
  }

  var backgroundColor: Color {
    switch self {
    case .morning: return Color(hex: "FEF3C7") // amber-100
    case .anytime: return Color(hex: "DBEAFE") // blue-100
    case .evening: return Color(hex: "E0E7FF") // indigo-100
    }
  }
}

// Color.init(hex:) is defined in RIZQKit/Design/Colors.swift


