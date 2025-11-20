//
//  jokercard.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/20.
//
// JokerCard.swift
import SwiftUI
import Foundation

// JokerCard.swift

struct JokerCard: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let price: Int
    let effect: JokerEffect
    
    // ✨ 新增：這張 Joker 對應的圖片名稱 (請確保 Assets 裡有這些圖片)
    let imageName: String
    
    // 更新範例資料 (這裡假設您會去 Assets 加入對應圖片)
    static func exampleJokers() -> [JokerCard] {
        return [
            JokerCard(
                name: "小丑",
                description: "倍率 +4",
                price: 2,
                effect: .flatMult(4),
                imageName: "joker_base" // 請在 Assets 加入名為 joker_base 的圖
            ),
            JokerCard(
                name: "貪婪小丑",
                description: "每張方塊牌 +4 倍率",
                price: 5,
                effect: .suitBonus(.diamonds, 4, "貪婪小丑"),
                imageName: "joker_greedy" // 請在 Assets 加入名為 joker_greedy 的圖
            ),
            JokerCard(
                name: "憤怒小丑",
                description: "每張黑桃牌 +4 倍率",
                price: 5,
                effect: .suitBonus(.spades, 4, "憤怒小丑"),
                imageName: "joker_wrath"
            ),
            JokerCard(
                name: "特技演員",
                description: "籌碼 +100, 手牌上限 -2", // 負面效果邏輯之後再做
                price: 6,
                effect: .flatChips(100),
                imageName: "joker_stuntman"
            ),
            JokerCard(
                name: "半個小丑",
                description: "打出 3 張或是更少的牌，倍率 +20",
                price: 4,
                effect: .flatMult(20), // 需要特殊邏輯，暫用 flatMult 代替
                imageName: "joker_half"
            ),
             JokerCard(
                name: "基本小丑",
                description: "籌碼 +20",
                price: 2,
                effect: .flatChips(20),
                imageName: "joker_default"
            )
        ]
    }
    
    static func randomJoker() -> JokerCard {
        return exampleJokers().randomElement()!
    }
    
    
    static func == (lhs: JokerCard, rhs: JokerCard) -> Bool {
        return lhs.id == rhs.id
    }
}
