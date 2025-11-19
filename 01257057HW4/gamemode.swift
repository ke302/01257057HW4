//
//  gamemode.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/19.
//
import Foundation
import SwiftUI
import Combine // 用於 Timer

// MARK: - Balatro 遊戲模型
@Observable
final class BalatroGame {
    
    // MARK: - 遊戲狀態
    var deck: Deck = Deck()
    var playerHand: [Card] = []
    var activeJokers: [JokerCard] = [] // 玩家擁有的特殊小丑牌
    var playedCards: [Card] = [] // 暫存打出的牌，用於計分
    // 追蹤目前被選取準備打出的牌
    var selectedCards: [Card] = []
    // MARK: - 分數與目標
    var chip: Int = 0 // 當前累積的分數
    var multiplier: Int = 1 // 當前倍率
    var blindTarget: Int = 300 // 盲注目標分數
    
    // MARK: - 回合限制
    var handsRemaining: Int = 4 // 剩餘可打出的手數
    var discardsRemaining: Int = 3 // 剩餘可棄牌次數
    var currentBlind: Int = 1 // 當前盲注等級
    
    // MARK: - 遊戲流程
    var gameMessage: String = "歡迎來到 Balatro！"
    var isGameOver: Bool = false
    
    // MARK: - 初始化與重設
    init() {
        // Balatro 通常從 8 張牌開始
        dealInitialCards(numberOfCards: 8)
        // 初始化時，給玩家一張範例小丑牌
        activeJokers.append(JokerCard.simplePlusChipJoker())
    }
    
    func resetGame() {
        deck = Deck()
        playerHand = []
        activeJokers = []
        chip = 0
        multiplier = 1
        blindTarget = 300
        handsRemaining = 4
        discardsRemaining = 3
        currentBlind = 1
        isGameOver = false
        gameMessage = "新遊戲開始！"
        
        dealInitialCards(numberOfCards: 8)
        activeJokers.append(JokerCard.simplePlusChipJoker())
    }
    // 選牌/取消選牌的邏輯
        func toggleSelection(_ card: Card) {
            if selectedCards.contains(card) {
                selectedCards.removeAll { $0.id == card.id }
            } else {
                // 限制最多選 5 張 (Balatro 規則)
                if selectedCards.count < 5 {
                    selectedCards.append(card)
                }
            }
        }
    // MARK: - 核心方法
    
    func playPokerHand(cards: [Card]) {
        // 1. 檢查：確保有選牌
        guard !cards.isEmpty else { return }
        
        // 2. 識別牌型 (使用上一步做的 Evaluator)
        let handType = PokerHandEvaluator.evaluate(cards: cards)
        
        // 3. 計算分數 (使用剛剛做的 Calculator)
        let result = ScoreCalculator.calculate(handType: handType, playedCards: cards)
        
        // 4. 更新遊戲狀態
        self.chip += result.totalScore
        self.handsRemaining -= 1
        
        // 5. 產生訊息回饋
        let feedback = "打出了 \(handType.description)！\n" +
        "籌碼: \(result.chips) x 倍率: \(result.multiplier) = \(result.totalScore)"
        self.gameMessage = feedback
        
        // 6. 檢查盲注目標是否達成
        checkBlindCondition()
        
        // 7. 從手牌中移除打出的牌，並補牌 (這部分邏輯稍後實作)
        removePlayedCards(cards)
        
        // 8. 清空「已選取」的狀態 (這步很重要，不然 UI 會以為牌還被選著)
        selectedCards.removeAll()
            
        // 9. 延遲一下再補牌 (讓視覺上先看到牌消失，再看到新牌進來，體驗較好)
        // 使用 Task + sleep (Swift Concurrency)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 等待 0.5 秒
            
            // 回到主執行緒補牌
            await MainActor.run {
                drawToMaxHandSize()
                    
                // 檢查盲注目標
                checkBlindCondition()
            }
        }
    }
    
    func checkBlindCondition() {
        if chip >= blindTarget {
            gameMessage = "🎉 盲注達成！分數：\(chip)/\(blindTarget)"
            // 這裡可以觸發過關邏輯 (例如進入商店)
        } else if handsRemaining == 0 {
            isGameOver = true
            gameMessage = "💔 遊戲結束。分數未達標。"
        }
    }
    
    // 簡單的移除卡牌邏輯
    func removePlayedCards(_ cardsToRemove: [Card]) {
        withAnimation { // 加入動畫讓移除過程更平滑
            playerHand.removeAll { card in
                // 因為 Card 有 ID 且遵循 Equatable，這裡可以直接判斷是否包含
                cardsToRemove.contains(card)
            }
        }
    }
    func drawToMaxHandSize() {
        let maxHandSize = 8
        let cardsNeeded = maxHandSize - playerHand.count
        
        if cardsNeeded > 0 {
                var newCards: [Card] = []
                
                // 使用迴圈，呼叫您原本就有的單張 draw() 方法
                for _ in 0..<cardsNeeded {
                    if let card = deck.draw() {
                        newCards.append(card)
                    } else {
                        // 如果牌組沒牌了，就停止抽取
                        break
                    }
                }
                
                // 更新 UI
                withAnimation {
                    playerHand.append(contentsOf: newCards)
                    // 自動理牌
                    playerHand.sort { $0.rank.pokerValue < $1.rank.pokerValue }
                }
            }
    }
    // 請加入到 BalatroGame 類別
    func discardSelectedCards() {
        // 檢查是否還有棄牌次數
        guard discardsRemaining > 0 else {
            gameMessage = "沒有棄牌次數了！"
            return
        }
        
        guard !selectedCards.isEmpty else { return }
        
        // 1. 扣除次數
        discardsRemaining -= 1
        
        // 2. 移除選取的牌
        let cardsToDiscard = selectedCards
        removePlayedCards(cardsToDiscard)
        
        // 3. 清空選擇
        selectedCards.removeAll()
        
        // 4. 補滿手牌
        drawToMaxHandSize()
        
        gameMessage = "棄掉了 \(cardsToDiscard.count) 張牌。"
    }
    
    // MARK: - 小丑牌模型
    struct JokerCard: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let description: String
        // 儲存實際的加成邏輯
        let chipBonus: Int
        let multiplierBonus: Int
        
        // 範例：一張簡單加分的 Joker
        static func simplePlusChipJoker() -> JokerCard {
            return JokerCard(name: "紅臉小丑",
                             description: "打出任何牌組時，總 Chip +20",
                             chipBonus: 20,
                             multiplierBonus: 0)
        }
        
        // 在 Balatro 中，Joker 的邏輯遠比這複雜得多，但這是起點。
    }
    
    // 請加入到 BalatroGame 類別中
    func dealInitialCards(numberOfCards: Int) {
        for _ in 0..<numberOfCards {
            if let card = deck.draw() {
                playerHand.append(card)
            }
        }
        
        // 自動理牌
        playerHand.sort { $0.rank.pokerValue < $1.rank.pokerValue }
    }
    
    
}
