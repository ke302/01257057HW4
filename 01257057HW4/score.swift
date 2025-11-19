//
//  score.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/19.
//

import Foundation

struct ScoreCalculator {
    
    // 定義一個回傳結果的結構，方便我們在 UI 上分開顯示籌碼和倍率
    struct ScoreResult {
        var chips: Int
        var multiplier: Int
        var totalScore: Int {
            return chips * multiplier
        }
    }

    /// 根據牌型和打出的牌，計算分數
    static func calculate(handType: PokerHandType, playedCards: [Card]) -> ScoreResult {
        
        // 1. 取得該牌型的基礎分數 (Base Chips) 和 基礎倍率 (Base Mult)
        // 這裡使用 Balatro 的預設 Level 1 數值
        var (currentChips, currentMult) = getBaseStats(for: handType)
        
        // 2. 加上卡牌本身的籌碼 (Card Chips)
        // 注意：在嚴格的 Balatro 規則中，只有「計分卡牌」才加分 (例如兩對時，第5張雜牌不算分)
        // 但為了簡化，我們先將打出的所有牌都加總。
        for card in playedCards {
            currentChips += card.rank.chipValue
        }
        
        // 3. (未來擴充) 在這裡應用小丑牌 (Joker) 的加成
        // applyJokerEffects(...)
        
        return ScoreResult(chips: currentChips, multiplier: currentMult)
    }
    
    /// 查表：取得各種牌型的初始數值 (Level 1)
    private static func getBaseStats(for type: PokerHandType) -> (chips: Int, mult: Int) {
        switch type {
        case .highCard:      return (5, 1)
        case .pair:          return (10, 2)
        case .twoPair:       return (20, 2)
        case .threeOfAKind:  return (30, 3)
        case .straight:      return (30, 4)
        case .flush:         return (35, 4)
        case .fullHouse:     return (40, 4)
        case .fourOfAKind:   return (60, 7)
        case .straightFlush: return (100, 8)
        }
    }
}
