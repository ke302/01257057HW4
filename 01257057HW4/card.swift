//
//  card.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/19.
//
import Foundation
import SwiftUI
// 1. 卡牌花色
enum Suit: CaseIterable {
    case spades, hearts, diamonds, clubs
    var symbol: String {
            switch self {
            case .spades: return "♠️"
            case .hearts: return "♥️"
            case .diamonds: return "♦️"
            case .clubs: return "♣️"
            }
        }
        
        var color: Color {
            switch self {
            case .spades, .clubs: return .black
            case .hearts, .diamonds: return .red
            }
        }
}

// 2. 卡牌點數/等級 (包含 Joker)
enum Rank: CaseIterable {
    case two, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace
    case joker // 小丑牌
    var label: String {
            switch self {
            case .ace: return "A"
            case .jack: return "J"
            case .queen: return "Q"
            case .king: return "K"
            case .joker: return "JOKER"
            default: return String(pokerValue) // 使用之前定義的 value 或 rawValue
            }
        }
    var pokerValue: Int {
        switch self {
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten: return 10
        case .jack: return 11
        case .queen: return 12
        case .king: return 13
        case .ace: return 14 // 用於排序時，A 通常算最大
        case .joker: return 15 // Joker 排序時放最右邊
        }
    }
    
    var chipValue: Int {
            switch self {
            case .two: return 2
            case .three: return 3
            case .four: return 4
            case .five: return 5
            case .six: return 6
            case .seven: return 7
            case .eight: return 8
            case .nine: return 9
            case .ten, .jack, .queen, .king: return 10 // 人頭牌都算 10
            case .ace: return 11 // A 算 11
            case .joker: return 0 // Joker 牌本身通常不計入基礎籌碼
            }
        }
}

// 3. 單張卡牌結構
struct Card: Identifiable, Hashable {
    let id = UUID()
    let suit: Suit? // 小丑牌可能沒有花色，所以使用 optional
    let rank: Rank
    
    // 靜態方法來建立一個完整的小丑牌
    static func makeJoker() -> Card {
        return Card(suit: nil, rank: .joker)
    }
}

struct Deck {
    private var cards: [Card] = []

    init() {
        // 創建標準的 52 張牌
        for suit in Suit.allCases {
            for rank in Rank.allCases where rank != .joker {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
        
        // 根據您遊戲的規則加入小丑牌 (通常是 2 張)
        cards.append(Card.makeJoker())
        cards.append(Card.makeJoker())
        
        // 初始時洗牌
        shuffle()
    }

    // 洗牌功能
    mutating func shuffle() {
        cards.shuffle()
    }
    
    // 發牌功能
    mutating func draw() -> Card? {
        // 移除並回傳牌組中的最後一張牌
        return cards.popLast()
    }
    
    // 牌組剩餘的牌數
    var count: Int {
        return cards.count
    }
}

// MARK: - 撲克牌型
enum PokerHandType: Int, Comparable, CaseIterable {
    case highCard = 1
    case pair = 2
    case twoPair = 3
    case threeOfAKind = 4
    case straight = 5
    case flush = 6
    case fullHouse = 7
    case fourOfAKind = 8
    case straightFlush = 9
    case fiveOfAKind = 10 // ✨ 新增：五條 (有 Joker 才有可能)
    
    static func < (lhs: PokerHandType, rhs: PokerHandType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var description: String {
        switch self {
        case .highCard: return "高牌"
        case .pair: return "一對"
        case .twoPair: return "兩對"
        case .threeOfAKind: return "三條"
        case .straight: return "順子"
        case .flush: return "同花"
        case .fullHouse: return "葫蘆"
        case .fourOfAKind: return "四條"
        case .straightFlush: return "同花順"
        case .fiveOfAKind: return "五條"
        }
    }
}

struct PokerHandEvaluator {
    
    static func evaluate(cards: [Card]) -> PokerHandType {
        guard !cards.isEmpty else { return .highCard }
        
        // 1. 分離 Joker 和普通牌
        let jokers = cards.filter { $0.rank == .joker }
        let regularCards = cards.filter { $0.rank != .joker }
        let jokerCount = jokers.count
        let totalCards = cards.count
        
        // 特殊情況：如果全部都是 Joker
        if regularCards.isEmpty {
            if totalCards >= 5 { return .fiveOfAKind }
            if totalCards == 4 { return .fourOfAKind }
            if totalCards == 3 { return .threeOfAKind }
            if totalCards == 2 { return .pair }
            return .highCard
        }
        
        // --- 分析普通牌 ---
        
        // A. 點數頻率統計 (例如: [K:2, Q:1])
        var rankCounts: [Rank: Int] = [:]
        for card in regularCards {
            rankCounts[card.rank, default: 0] += 1
        }
        // 排序頻率 (例如 Full House 會是 [3, 2])
        var sortedCounts = rankCounts.values.sorted(by: >)
        
        // B. 花色統計 (忽略 Joker 的 nil 花色)
        var suitCounts: [Suit: Int] = [:]
        for card in regularCards {
            if let suit = card.suit {
                suitCounts[suit, default: 0] += 1
            }
        }
        let maxSuitCount = suitCounts.values.max() ?? 0
        
        // C. 排序後的點數值 (去重)
        let sortedUniqueValues = Array(Set(regularCards.map { $0.rank.pokerValue })).sorted()
        
        // --- 結合 Joker 進行判定 ---
        
        // 1. 判定同花 (Flush)
        // 邏輯：最多的一種花色數量 + Joker 數量 >= 5
        // Balatro 規則：只要能湊成同花就算，不一定要 5 張打滿。但標準撲克要 5 張。
        // 這裡採用標準規則：總張數 >= 5 且 (某花色數量 + Joker數量 >= 5)
        let canMakeFlush = (totalCards >= 5) && (maxSuitCount + jokerCount >= 5)
        
        // 2. 判定順子 (Straight)
        // 邏輯較複雜，檢查是否有機會用 Joker 填補空缺形成 5 張連續
        let canMakeStraight = (totalCards >= 5) && checkStraightWithWildcards(sortedUniqueValues: sortedUniqueValues, jokerCount: jokerCount)
        
        // --- 最終判定 ---
        
        if canMakeFlush && canMakeStraight {
            return .straightFlush
        }
        
        // 利用 Joker 強化點數組合 (將 Joker 加到最多的那一組上)
        // 例如：有兩張 7，一張 Joker -> 變成三條 (count: 2 + 1 = 3)
        let bestCount = (sortedCounts.first ?? 0) + jokerCount
        
        if bestCount >= 5 { return .fiveOfAKind }
        if bestCount == 4 { return .fourOfAKind }
        
        // 葫蘆判定：(最多張數 + Joker >= 3) 且 (第二多張數 >= 2)
        // 注意 Joker 只能用一次，這裡簡化判定，假設 Joker 優先湊三條
        if sortedCounts.count >= 2 {
             if (sortedCounts[0] + jokerCount >= 3) && sortedCounts[1] >= 2 {
                 return .fullHouse
             }
            // 特殊葫蘆：兩對 + 1張 Joker (例如：2,2,3,3,Joker -> 2,2,2,3,3)
            if sortedCounts[0] == 2 && sortedCounts[1] == 2 && jokerCount >= 1 {
                return .fullHouse
            }
        }
        
        if canMakeFlush { return .flush }
        if canMakeStraight { return .straight }
        
        if bestCount == 3 { return .threeOfAKind }
        
        // 兩對判定
        if sortedCounts.count >= 2 && sortedCounts[0] == 2 && sortedCounts[1] == 2 {
            // Joker 沒用上，原本就是兩對
            return .twoPair
        }
        // 特殊兩對：一對 + 單張 + Joker (例如 2,2,3,Joker -> 2,2,3,3)
        if sortedCounts.count >= 2 && sortedCounts[0] == 2 && sortedCounts[1] == 1 && jokerCount >= 1 {
            return .twoPair
        }
        
        if bestCount == 2 { return .pair }
        
        return .highCard
    }
    
    // 輔助方法：檢查百搭順子
    private static func checkStraightWithWildcards(sortedUniqueValues: [Int], jokerCount: Int) -> Bool {
        if sortedUniqueValues.isEmpty { return jokerCount >= 5 }
        
        // 處理 A 的特殊情況 (可以當 14 也可以當 1)
        var valuesToCheck = [sortedUniqueValues]
        if sortedUniqueValues.contains(14) { // 如果有 A
            var lowAceValues = sortedUniqueValues.filter { $0 != 14 }
            lowAceValues.insert(1, at: 0) // 加入 1
            valuesToCheck.append(lowAceValues)
        }
        
        for values in valuesToCheck {
            // 滑動視窗檢查，視窗大小隨著 Joker 數量變化
            // 我們需要找到一個區間，區間內的 (最大值 - 最小值) < 5，且缺少的牌數 <= jokerCount
            for i in 0..<values.count {
                for j in i..<values.count {
                    let min = values[i]
                    let max = values[j]
                    
                    // 如果跨度已經超過 4 (例如 2 和 7)，不可能組成 5 張順子，跳過
                    if (max - min) >= 5 { continue }
                    
                    let cardsInBetween = j - i + 1
                    let cardsNeeded = 5 - cardsInBetween
                    
                    // 如果需要的卡牌數可以用 Joker 填補，就是順子
                    if cardsNeeded <= jokerCount {
                        return true
                    }
                }
            }
        }
        return false
    }
}

struct CardView: View {
    let card: Card
    let isSelected: Bool // 傳入選取狀態
    
    var body: some View {
        ZStack {
            // 1. 卡牌背景
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(radius: 2)
            
            // 2. 選取時的邊框高亮 (Balatro 風格可以使用紅色或橘色邊框)
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.orange : Color.black, lineWidth: isSelected ? 3 : 1)
            
            // 3. 卡牌內容
            if card.rank == .joker {
                // 小丑牌特殊設計
                
                Image("joker")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
                
            } else {
                // 普通牌設計
                VStack {
                    // 左上角：點數 + 花色
                    HStack {
                        VStack(spacing: 0) {
                            Text(card.rank.label)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(card.suit?.symbol ?? "")
                                .font(.subheadline)
                        }
                        .foregroundColor(card.suit?.color ?? .black)
                        Spacer()
                    }
                    .padding(4)
                    
                    Spacer()
                    
                    // 中間大花色
                    Text(card.suit?.symbol ?? "")
                        .font(.system(size: 30))
                        .foregroundColor(card.suit?.color ?? .black)
                        .opacity(0.3) // 讓中間稍微淡一點
                    
                    Spacer()
                    
                    // 右下角：倒轉的點數 (可選，增加擬真度)
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            Text(card.rank.label)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(card.suit?.symbol ?? "")
                                .font(.subheadline)
                        }
                        .foregroundColor(card.suit?.color ?? .black)
                        .rotationEffect(.degrees(180))
                    }
                    .padding(4)
                }
                .frame(width: 70, height: 130)
            }
        }
        .frame(width: 70, height: 140) // 固定卡牌大小
        // 關鍵動畫：選取時往上浮動
        .offset(y: isSelected ? -20 : 0)
        // 增加彈性動畫效果
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct HandView: View {
    @Environment(BalatroGame.self) private var game
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -20) { // 負間距創造重疊效果
                ForEach(game.playerHand) { card in
                    CardView(
                        card: card,
                        isSelected: game.selectedCards.contains(card)
                    )
                    .onTapGesture {
                        // 播放音效 🎵
                            AudioManager.shared.playSound(named: "card_select")
                        // 點擊觸發震動回饋 (Haptic Feedback)
                        let impactHeavy = UIImpactFeedbackGenerator(style: .light)
                        impactHeavy.impactOccurred()
                        
                        // 切換選取狀態
                        game.toggleSelection(card)
                    }
                    // 讓選取時的卡牌圖層順序在最上面 (可選，視效果而定)
                    .zIndex(game.selectedCards.contains(card) ? 1 : 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30) // 預留上方空間給卡牌彈起
            .padding(.bottom, 20)
        }
        // 確保卡牌區域有固定高度
        .frame(height: 150)
    }
}
