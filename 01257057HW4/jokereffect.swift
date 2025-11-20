//
//  jokereffect.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/20.
//
import SwiftUI

// JokerEffect.swift
import Foundation

enum JokerEffect: Equatable { // 讓效果可以比較，方便管理
    case flatMult(Int)       // 純粹增加倍率 (+Mult)
    case flatChips(Int)      // 純粹增加籌碼 (+Chip)
    case xMult(Double)       // 乘以倍率 (xMult)
    case suitBonus(Suit, Int, String) // 特定花色每張牌額外增加倍率 (例如：每張紅心 +2 倍率)
    case handTypeBonus(PokerHandType, Int) // 特定牌型額外增加倍率 (例如：順子 +8 倍率)
    case firstPlayedCardBonus(Int) // 第一次打出的牌增加籌碼
    case cardRankBonus(Rank, Int) // 特定點數牌增加倍率
    
    // 方便 UI 顯示的描述
    var description: String {
        switch self {
        case .flatMult(let amount): return "倍率 +\(amount)"
        case .flatChips(let amount): return "籌碼 +\(amount)"
        case .xMult(let amount): return "總倍率 x\(String(format: "%.1f", amount))"
        case .suitBonus(let suit, let amount, _): return "每張 \(suit.symbol) 牌倍率 +\(amount)"
        case .handTypeBonus(let type, let amount): return "\(type.description) 倍率 +\(amount)"
        case .firstPlayedCardBonus(let amount): return "第一張打出的牌籌碼 +\(amount)"
        case .cardRankBonus(let rank, let amount): return "每張 \(rank.label) 牌倍率 +\(amount)"
        }
    }
}
