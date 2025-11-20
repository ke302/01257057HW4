//
//  gameview.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/20.
//
import SwiftUI
import UIKit
struct GameView: View {
    @Environment(BalatroGame.self) private var game
    
    var body: some View {
        ZStack {
            // 背景色 (深綠色桌布感覺)
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.3, green: 0.1, blue: 0.1)]),
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                 .ignoresSafeArea()
          
            VStack {
                // 在 GameView 的 body 內，頂部資訊區的上方加入這個 Joker 儀表板
                
                // Joker 牌展示區 (Joker Dashboard)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(game.activeJokers) { joker in
                            ZStack {
                                // 1. 卡牌底圖 (或背景色)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                                    .shadow(radius: 2)
                                
                                // 2. 顯示該 Joker 獨特的圖片
                                // ⚠️ 如果 Assets 找不到圖片，這裡會顯示空白，建議加個預設圖
                                if let _ = UIImage(named: joker.imageName) {
                                    Image(joker.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    // 備案：如果找不到圖，顯示文字
                                    VStack(spacing: 2) {
                                        Text("🤡")
                                            .font(.largeTitle)
                                        Text(joker.name)
                                            .font(.system(size: 10))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(4)
                                }
                            }
                            // Joker 卡牌尺寸 (比手牌小一點)
                            .frame(width: 70, height: 135)
                            // 點擊可以顯示詳細資訊 (Tooltip)
                            .onTapGesture {
                                game.gameMessage = "\(joker.name): \(joker.description)"
                            }
                        }
                        
                        // 佔位符：顯示剩餘的 Joker 空位 (Balatro 預設 5 格)
                        ForEach(0..<(5 - game.activeJokers.count), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2) // 虛線框效果
                                .background(Color.black.opacity(0.2))
                                .frame(width: 70, height: 100)
                                .overlay(Text("空").font(.caption).foregroundColor(.gray))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10) // 留點頂部空間
                }
                .frame(height: 100)
                // 1. 頂部資訊區 (暫時)
                HStack(alignment: .top) { // 將 alignment 改為 .top
                    // 左側：分數與目標
                    VStack(alignment: .leading, spacing: 5) {
                        Text("分數")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(game.chip)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .id(game.chip) // ✅ 使用 id 觸發數字變動動畫
                            .animation(.easeInOut(duration: 0.5), value: game.chip) // 分數變動動畫
                        
                        Text("目標: \(game.blindTarget)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(15)
                    
                    Spacer()
                    
                    VStack(spacing: 5) {
                        Text("金錢")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$\(game.money)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.orange) // 金錢用橘色或金色
                            .id(game.money)
                            .animation(.default, value: game.money)
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(15)
                    
                    Spacer()
                    
                    // 右側：手數與棄牌次數
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("次數")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(game.handsRemaining)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(game.handsRemaining <= 1 ? .red : .white)
                            .id(game.handsRemaining) // ✅ 觸發變動動畫
                            .animation(.easeInOut(duration: 0.3), value: game.handsRemaining)
                        
                        Text("棄牌: \(game.discardsRemaining)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(15)
                    
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 2. 訊息區
                Text(game.gameMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.6))
                            .shadow(color: .white.opacity(0.2), radius: 3)
                    )
                    .padding(.top, 5)
                    .id(game.gameMessage) // ✅ 訊息改變時，可以增加動畫效果
                    .transition(.opacity.animation(.easeInOut)) // 訊息變動時淡入淡出
                
                Spacer()
                
                // 3. 出牌區域 (顯示選了什麼牌型)
                if !game.selectedCards.isEmpty {
                    let handType = PokerHandEvaluator.evaluate(cards: game.selectedCards)
                    Text("準備打出: \(handType.description)")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .padding(.bottom, 5)
                }
                
                // 4. 手牌區 (我們剛做好的組件)
                HandView()
                
                // 5. 底部操作按鈕
                switch game.gameState {
                case .playing:
                    HStack(spacing: 20) {
                        Button(action: {
                            game.discardSelectedCards()
                        }) {
                            Text("棄牌 (\(game.discardsRemaining))")
                                .font(.headline)
                                .frame(width: 120, height: 50)
                                .background(Color.red.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .disabled(game.selectedCards.isEmpty || game.discardsRemaining <= 0)
                        
                        Button(action: {
                            game.playPokerHand(cards: game.selectedCards)
                            // selectedCards 在 playPokerHand 裡已經清空了
                        }) {
                            Text("出牌")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(width: 160, height: 60)
                                .background(game.selectedCards.isEmpty ? Color.gray.opacity(0.5) : Color.yellow.opacity(0.8)) // ✅ 根據是否有選牌改變顏色
                                .foregroundColor(.black) // 黑色文字在黃色背景上更明顯
                                .cornerRadius(20)
                                .shadow(radius: 7)
                        }
                    }
                    .padding(.bottom, 20)
                    .animation(.default, value: game.selectedCards.isEmpty) // 按鈕禁用狀態的動畫
                    
                case .roundWon:
                    VStack(spacing: 10) {
                        Text("🎉 過關！")
                            .font(.title)
                            .foregroundColor(.yellow)
                        
                        Button(action: {
                            withAnimation {
                            
                            game.goToShop()
                            }
                        }) {
                            Text("進入商店") // 文字也可以改一下
                                .font(.title2)
                                .padding()
                                .background(Color.orange) // 改成橘色更有商店感
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        
                        Button(action: {
                            withAnimation {
                                game.startNextRound()
                            }
                        }) {
                            Text("進入下一關")
                                .font(.title2)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                    }
                    .padding()
                    .background(Color.black.opacity(0.8)) //稍微遮擋一下手牌區
                    .cornerRadius(15)
                    
                case .gameOver:
                    VStack(spacing: 10) {
                        Text("💀 失敗")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Button(action: {
                            withAnimation {
                                game.resetGame()
                            }
                        }) {
                            Text("重新開始")
                                .font(.title2)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                case .shopping:
                    VStack(spacing: 20) {
                        Text("🛒 商店")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text("持有金錢: $\(game.money)")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        // 顯示商品列表
                        HStack(spacing: 15) {
                            ForEach(game.shopJokers) { joker in
                                VStack {
                                    // 顯示 Joker 圖片或圖示 (與 CardView 類似邏輯)
                                    if let _ = UIImage(named: joker.imageName) {
                                        Image(joker.imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 100)
                                            .cornerRadius(8)
                                    } else {
                                        Text("🤡")
                                            .font(.largeTitle)
                                    }
                                    
                                    Text(joker.name)
                                        .fontWeight(.bold)
                                        .font(.caption)
                                    
                                    Text(joker.description)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .frame(height: 30) // 固定高度避免跳動
                                    
                                    Button("$\(joker.price)") {
                                        game.buyJoker(joker)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                                }
                                .padding()
                                .frame(width: 120, height: 220)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                            }
                        }
                        
                        Divider().background(Color.white)
                        
                        Button(action: {
                            game.startNextRound() // 離開商店，開始下一關
                        }) {
                            Text("下一回合")
                                .font(.title2)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 50)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.95))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}



