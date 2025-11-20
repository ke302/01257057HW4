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
        activeJokers: [JokerCard]
    ) -> ScoreResult {
        
        // 1. 取得基礎分數 (呼叫下面的 getBaseStats)
        var (currentChips, currentMult) = getBaseStats(for: handType)
        
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
