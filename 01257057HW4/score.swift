//
//  score.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/19.
//

import Foundation

struct ScoreCalculator {
    
    struct ScoreResult {
        var chips: Int
        var multiplier: Int
        var totalScore: Int {
            return chips * multiplier
        }
    }

    /// 計算分數
    static func calculate(
        handType: PokerHandType,
        playedCards: [Card],
        activeJokers: [JokerCard],
        handLevels: [PokerHandType: Int]
    ) -> ScoreResult {
        let level = handLevels[handType] ?? 1
        // 1. 取得基礎分數 (呼叫下面的 getBaseStats)
        var (currentChips, currentMult) = getBaseStats(for: handType, level: level)
        
        // 2. 加上卡牌分數
        for card in playedCards {
            currentChips += card.rank.chipValue
        }
        
        // 3. 應用 Joker 效果
        // 3a. 加減型
        for joker in activeJokers {
            switch joker.effect {
            case .flatChips(let amount):
                currentChips += amount
            case .flatMult(let amount):
                currentMult += amount
            case .suitBonus(let suit, let mult, _):
                let count = playedCards.filter { $0.suit == suit }.count
                currentMult += (count * mult)
            case .handTypeBonus(let type, let amount):
                if handType == type {
                    currentMult += amount
                }
            case .cardRankBonus(let rank, let amount):
                let count = playedCards.filter { $0.rank == rank }.count
                currentMult += (count * amount)
            case .firstPlayedCardBonus(let amount):
                 if !playedCards.isEmpty { currentChips += amount }
            default:
                break
            }
        }
        
        // 3b. 乘法型
        for joker in activeJokers {
            if case .xMult(let amount) = joker.effect {
                currentMult = Int(Double(currentMult) * amount)
            }
        }
        
        return ScoreResult(chips: currentChips, multiplier: max(1, currentMult))
    }
    
    static func getBaseStats(for type: PokerHandType, level: Int) -> (chips: Int, mult: Int) {
            // 成長幅度：每升 1 級，籌碼 +10~30，倍率 +1~4 (依牌型強弱而定)
            // 這裡用一個簡單的通用公式：
            // 基礎籌碼 = 原始籌碼 + (等級-1) * 20
            // 基礎倍率 = 原始倍率 + (等級-1) * 2
            
            let levelBonusChips = (level - 1) * 20
            let levelBonusMult = (level - 1) * 2
            
            switch type {
            case .highCard:      return (5 + levelBonusChips, 1 + levelBonusMult)
            case .pair:          return (10 + levelBonusChips, 2 + levelBonusMult)
            case .twoPair:       return (20 + levelBonusChips, 2 + levelBonusMult)
            case .threeOfAKind:  return (30 + levelBonusChips, 3 + levelBonusMult)
            case .straight:      return (30 + levelBonusChips, 4 + levelBonusMult)
            case .flush:         return (35 + levelBonusChips, 4 + levelBonusMult)
            case .fullHouse:     return (40 + levelBonusChips, 4 + levelBonusMult)
            case .fourOfAKind:   return (60 + levelBonusChips, 7 + levelBonusMult)
            case .straightFlush: return (100 + levelBonusChips, 8 + levelBonusMult)
            case .fiveOfAKind:   return (120 + levelBonusChips, 8 + levelBonusMult)
            }
        }
}
