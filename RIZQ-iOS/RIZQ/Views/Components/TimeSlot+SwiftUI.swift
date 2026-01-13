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
    case .morning: return Color("timeSlotMorningBg", bundle: .main)
    case .anytime: return Color("timeSlotAnytimeBg", bundle: .main)
    case .evening: return Color("timeSlotEveningBg", bundle: .main)
    }
  }
}

// Color.init(hex:) is defined in RIZQKit/Design/Colors.swift





