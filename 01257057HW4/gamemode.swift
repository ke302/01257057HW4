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
    var handLevels: [PokerHandType: Int] = [
        .highCard: 1,
        .pair: 1,
        .twoPair: 1,
        .threeOfAKind: 1,
        .straight: 1,
        .flush: 1,
        .fullHouse: 1,
        .fourOfAKind: 1,
        .straightFlush: 1
    ]
    // MARK: - 分數與目標
    var chip: Int = 0 // 當前累積的分數
    var multiplier: Int = 1 // 當前倍率
    var blindTarget: Int = 300 // 盲注目標分數
    // 讀取最高分
    var highScore: Int {
        UserDefaults.standard.integer(forKey: "HighScore")
    }

    // 更新最高分的方法
    func saveHighScore() {
        if chip > highScore {
            UserDefaults.standard.set(chip, forKey: "HighScore")
        }
    }
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
        // 👇 切斷上一局的失敗/勝利音效
        AudioManager.shared.stopAllSFX()
        AudioManager.shared.playBGM() // 確保 BGM 回歸
        
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
        handLevels = [
                .highCard: 1, .pair: 1, .twoPair: 1, .threeOfAKind: 1,
                .straight: 1, .flush: 1, .fullHouse: 1, .fourOfAKind: 1, .straightFlush: 1
            ]
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
            AudioManager.shared.playSound(named: "error") // 錯誤音效
            gameMessage = "沒有出手次數了！"
            return
        }
        // 1. 檢查：確保有選牌
        guard !cards.isEmpty else { return }
        // 播放出牌音效 🎵
        AudioManager.shared.playSound(named: "card_fan")
        // 2. 識別牌型 (使用上一步做的 Evaluator)
        let handType = PokerHandEvaluator.evaluate(cards: cards)
        
        // 3. 計算分數 (使用剛剛做的 Calculator)
        let result = ScoreCalculator.calculate(
                handType: handType,
                playedCards: cards,
                activeJokers: self.activeJokers,
                handLevels: self.handLevels
            )
        // 在計分完成後，如果有得分，可以播個籌碼聲
        AudioManager.shared.playSound(named: "chips_count")
        
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
        // 👇 切斷上一局的勝利音效
        AudioManager.shared.stopAllSFX()
        AudioManager.shared.playBGM() // 確保 BGM 回歸
        
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
            AudioManager.shared.playSound(named: "victory")
            calculateRoundRewards()
            gameMessage = "你可真厲害啊"
        } else if handsRemaining <= 0 {
            // 輸了！次數用完且分數不夠
            gameState = .gameOver
            saveHighScore()
            AudioManager.shared.playSound(named: "defeat")
            gameMessage = "啊啊啊啊啊啊啊啊啊啊啊啊"
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
        // 播放棄牌音效 🎵
        AudioManager.shared.playSound(named: "card_fan")
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
        AudioManager.shared.playSound(named: "card_fan")
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
        let baseReward = 4 + (currentBlind * 2)
        
        // 2. 剩餘手數獎勵 ($1/手)
        let handsReward = handsRemaining
        
        // 3. 利息 (每 $5 給 $1，上限通常是 $5，也就是存款 $25)
        let interest = min(5, money / 5)
        
        let totalReward = baseReward + handsReward + interest
        
        // 發錢
        self.money += totalReward
        
        // 更新訊息 (讓玩家知道錢怎麼來的)
        self.gameMessage = "過關！獎勵 $\(totalReward)\n(底薪\(baseReward) + 手數\(handsReward) + 利息\(interest))"
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
                AudioManager.shared.playSound(named: "chips_count") // 購買成功的錢聲
            } else {
                AudioManager.shared.playSound(named: "error") // 錢不夠
                gameMessage = "小丑牌欄位已滿！"
            }
        } else {
            AudioManager.shared.playSound(named: "error") // 錢不夠
            gameMessage = "金錢不足！"
        }
    }
    func sellJoker(_ joker: JokerCard) {
        // 找到這張牌並移除
        if let index = activeJokers.firstIndex(where: { $0.id == joker.id }) {
            activeJokers.remove(at: index)
            money += joker.sellValue // 加錢
            gameMessage = "賣出了 \(joker.name)，獲得 $\(joker.sellValue)"
        }
    }
    func goToShop() {
        // 先補貨
        generateShop()
        // 切換狀態到商店
        gameState = .shopping
        gameMessage = "歡迎來到商店！請選購。"
    }
    func levelUpHand(_ type: PokerHandType) {
        if let currentLevel = handLevels[type] {
            handLevels[type] = currentLevel + 1
            gameMessage = "\(type.description) 升級到了 Lv.\(currentLevel + 1)！"
        }
    }
    
}
