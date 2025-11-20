//
//  gamemode.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/19.
//
import Foundation
import SwiftUI
import Combine // 用於 Timer

enum GameState {
    case playing    // 正在玩
    case roundWon   // 盲注達成（等待進入下一關）
    case shopping // 顯示商店畫面
    case gameOver   // 遊戲結束（輸了）
}

// MARK: - Balatro 遊戲模型
@Observable
final class BalatroGame {
    
    // MARK: - 遊戲狀態
    var deck: Deck = Deck()
    var playerHand: [Card] = []
    var activeJokers: [JokerCard] = [] // 玩家擁有的特殊小丑牌
    var playedCards: [Card] = [] // 暫存打出的牌，用於計分
    var gameState: GameState = .playing
    var money: Int = 4 // 初始金錢
    var shopJokers: [JokerCard] = []
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
    
    // MARK: - 初始化與重設
    init() {
        resetGame()
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
        gameState = .playing
        gameMessage = "新遊戲開始！"
        
        dealInitialCards(numberOfCards: 8)
        
        activeJokers.append(JokerCard.randomJoker())
        
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
        // 🛡️ 防護盾 1：如果遊戲不是「進行中」，不準出牌
        guard gameState == .playing else { return }
            
        // 🛡️ 防護盾 2：確保手數大於 0 (防止變成 -1)
        guard handsRemaining > 0 else {
            gameMessage = "沒有出手次數了！"
            return
        }
        // 1. 檢查：確保有選牌
        guard !cards.isEmpty else { return }
        
        // 2. 識別牌型 (使用上一步做的 Evaluator)
        let handType = PokerHandEvaluator.evaluate(cards: cards)
        
        // 3. 計算分數 (使用剛剛做的 Calculator)
        let result = ScoreCalculator.calculate(
                handType: handType,
                playedCards: cards,
                activeJokers: self.activeJokers
            )
        
        // 4. 更新遊戲狀態
        self.chip += result.totalScore
        self.handsRemaining -= 1
        
        // 5. 產生訊息回饋
        self.gameMessage = "打出了 \(handType.description)！得 \(result.totalScore) 分"
        
        // 6. 檢查盲注目標是否達成
        checkBlindCondition()
        
        // A. 無論輸贏，打出的牌都應該先移除
        removePlayedCards(cards)
        selectedCards.removeAll()
        // B. 根據狀態決定後續動作
        if gameState == .playing {
                
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    drawToMaxHandSize()
                }
            }
        }
    }
    func startNextRound() {
        // 1. 提升難度 (簡單的倍率成長)
        currentBlind += 1
        blindTarget = Int(Double(blindTarget) * 1.5) // 目標分數變 1.5 倍
        
        // 2. 重置遊戲資源
        chip = 0
        handsRemaining = 4
        discardsRemaining = 3
        
        // 3. 重置牌組 (把棄牌堆和手牌全部洗回牌組)
        // 簡單做法：直接生成新的一副牌 (但保留玩家的 Joker，如果有做 Joker 系統的話)
        // 這裡我們先簡單地重置牌組
        deck = Deck()
        playerHand = []
        selectedCards = []
        
        // 4. 發新牌
        dealInitialCards(numberOfCards: 8)
        
        // 5. 切換回「遊玩中」狀態
        gameState = .playing
        gameMessage = "第 \(currentBlind) 關開始！目標：\(blindTarget)"
    }
    
    func checkBlindCondition() {
        if chip >= blindTarget {
            // 贏了！切換狀態
            gameState = .roundWon
            calculateRoundRewards()
            gameMessage = "🎉 盲注達成！請準備進入下一關。"
        } else if handsRemaining <= 0 {
            // 輸了！次數用完且分數不夠
            gameState = .gameOver
            gameMessage = "💔 遊戲結束。手數耗盡且分數未達標。"
        }
        // 如果還沒贏也還沒輸，狀態保持 .playing，繼續遊戲
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
    
    
    func dealInitialCards(numberOfCards: Int) {
        for _ in 0..<numberOfCards {
            if let card = deck.draw() {
                playerHand.append(card)
            }
        }
        
        // 自動理牌
        playerHand.sort { $0.rank.pokerValue < $1.rank.pokerValue }
    }
    
    //結算發錢
    func calculateRoundRewards() {
        // 1. 過關基礎獎勵
        let baseReward = 5
        
        // 2. 剩餘手數獎勵 ($1/手)
        let handsReward = handsRemaining
        
        // 3. 利息 (每 $5 給 $1，上限通常是 $5，也就是存款 $25)
        let interest = min(5, money / 5)
        
        let totalReward = baseReward + handsReward + interest
        
        // 發錢
        self.money += totalReward
        self.gameMessage = "過關！獎勵 $\(totalReward) (底薪\(baseReward) + 手數\(handsReward) + 利息\(interest))"
    }
    // 產生新商店內容
    func generateShop() {
        shopJokers = []
        // 隨機產生 3 張小丑牌上架
        for _ in 0..<3 {
            shopJokers.append(JokerCard.randomJoker())
        }
    }
    // 購買邏輯
    func buyJoker(_ joker: JokerCard) {
        if money >= joker.price {
            if activeJokers.count < 5 { // 檢查欄位是否滿了
                money -= joker.price
                activeJokers.append(joker)
                // 從商店移除已買的牌
                shopJokers.removeAll { $0.id == joker.id }
            } else {
                gameMessage = "小丑牌欄位已滿！"
            }
        } else {
            gameMessage = "金錢不足！"
        }
    }
    func goToShop() {
        // 先補貨
        generateShop()
        // 切換狀態到商店
        gameState = .shopping
        gameMessage = "歡迎來到商店！請選購。"
    }
}
