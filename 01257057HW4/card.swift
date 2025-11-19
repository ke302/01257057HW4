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
    // 數值越大代表牌型越強 (這是 Balatro 的基本順序)
    case highCard = 1       // 高牌 (單張)
    case pair = 2           // 一對
    case twoPair = 3        // 兩對
    case threeOfAKind = 4   // 三條
    case straight = 5       // 順子
    case flush = 6          // 同花
    case fullHouse = 7      // 葫蘆
    case fourOfAKind = 8    // 四條
    case straightFlush = 9  // 同花順
    // case fiveOfAKind // 五條 (需要特殊牌或隱藏牌型，暫不列入)
    
    // 實作 Comparable 所需的小於運算
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
        }
    }
}

struct PokerHandEvaluator {
    
    /// 輸入一組牌 (通常 1~5 張)，回傳最佳牌型
    static func evaluate(cards: [Card]) -> PokerHandType {
        // 如果沒有牌，預設回傳高牌 (或處理錯誤)
        guard !cards.isEmpty else { return .highCard }
        
        // 1. 整理資料：將牌按點數排序
        let sortedCards = cards.sorted { $0.rank.pokerValue < $1.rank.pokerValue }
        
        // 2. 統計點數頻率 (例如：有幾張 2，有幾張 K)
        var rankCounts: [Rank: Int] = [:]
        for card in cards {
            rankCounts[card.rank, default: 0] += 1
        }
        // 將頻率轉為陣列並排序 (例如 Full House 會是 [3, 2]，四條會是 [4, 1])
        let counts = rankCounts.values.sorted(by: >)
        
        // 3. 檢查是否為同花 (Flush)
        // 條件：牌數 >= 5 且所有花色相同 (Balatro 規則通常要求 5 張才算同花，除非有特殊 Joker)
        // 這裡我們先假設必須滿 5 張才算同花/順子，若只要有同花特徵就算，可移除 count >= 5
        let isFlush = (cards.count >= 5) && (Set(cards.map { $0.suit }).count == 1)
        
        // 4. 檢查是否為順子 (Straight)
        let isStraight = checkStraight(sortedCards: sortedCards)
        
        // --- 判定邏輯 ---
        
        // 同花順 (Straight Flush)
        if isFlush && isStraight {
            return .straightFlush
        }
        
        // 四條 (Four of a Kind)
        if counts.first == 4 {
            return .fourOfAKind
        }
        
        // 葫蘆 (Full House) - 3張一樣 + 2張一樣
        if counts.count >= 2 && counts[0] == 3 && counts[1] == 2 {
            return .fullHouse
        }
        
        // 同花 (Flush)
        if isFlush {
            return .flush
        }
        
        // 順子 (Straight)
        if isStraight {
            return .straight
        }
        
        // 三條 (Three of a Kind)
        if counts.first == 3 {
            return .threeOfAKind
        }
        
        // 兩對 (Two Pair) - [2, 2, 1]
        if counts.count >= 2 && counts[0] == 2 && counts[1] == 2 {
            return .twoPair
        }
        
        // 一對 (Pair)
        if counts.first == 2 {
            return .pair
        }
        
        // 什麼都不是，就是高牌
        return .highCard
    }
    
    // 輔助方法：檢查順子
    private static func checkStraight(sortedCards: [Card]) -> Bool {
        // 順子通常需要至少 5 張牌
        guard sortedCards.count >= 5 else { return false }
        
        // 取得所有不重複的點數值
        let uniqueValues = Array(Set(sortedCards.map { $0.rank.pokerValue })).sorted()
        
        // 如果不重複的牌不夠 5 張，不可能是順子
        if uniqueValues.count < 5 { return false }
        
        // 檢查連續性 (取最後 5 張最大的來檢查)
        // 這裡簡化邏輯：只要有連續 5 張就算
        // 實際 Balatro 可能只打 5 張，所以直接檢查這 5 張即可
        
        // 處理特殊情況：A, 2, 3, 4, 5 (A=14, 但這裡要當 1)
        // 檢查是否包含 A(14), 2, 3, 4, 5
        let isLowAceStraight = uniqueValues.contains(14) && uniqueValues.contains(2) && uniqueValues.contains(3) && uniqueValues.contains(4) && uniqueValues.contains(5)
        if isLowAceStraight { return true }
        
        // 一般情況檢查
        // 滑動視窗檢查是否有連續 5 個數字
        for i in 0...(uniqueValues.count - 5) {
            let subset = uniqueValues[i..<(i+5)]
            if let min = subset.first, let max = subset.last {
                if max - min == 4 {
                    return true
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
                VStack {
                    Text("🤡")
                        .font(.largeTitle)
                    Text("JOKER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
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
            }
        }
        .frame(width: 70, height: 100) // 固定卡牌大小
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
