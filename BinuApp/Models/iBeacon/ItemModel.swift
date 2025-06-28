//
//  ItemModel.swift
//  BinuApp
//
//  Created by Ryan on 27/6/25.
//

enum Item: UInt8, CaseIterable, Identifiable {
    case sanitaryPad = 0
    case tissues
    case tampons
    case morningAfterPill
    case contraceptive
    case walkingBuddy
    
    var id: UInt8 { rawValue }
    
    var description: String {
        switch self {
        case .sanitaryPad: return "Sanitary Pad"
        case .tissues: return "Tissues"
        case .tampons: return "Tampons"
        case .morningAfterPill: return "Morning After Pill"
        case .contraceptive: return "Contraceptive"
        case .walkingBuddy: return "Walking Buddy"
        }
    }
}
