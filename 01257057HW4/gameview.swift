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
    @Environment(\.dismiss) var dismiss
    @State private var showHandRank = false
    var body: some View {
        ZStack {
            // ------------------------------------------------
            // Layer 0: 底層遊戲畫面
            // ------------------------------------------------
            ZStack {
                // 背景色
                LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.3, green: 0.1, blue: 0.1)]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack {
                    // 1. Joker 儀表板 (這段是您新加的，放最上面)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(game.activeJokers) { joker in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                                        .shadow(radius: 2)
                                    if let _ = UIImage(named: joker.imageName) {
                                        Image(joker.imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 70, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        VStack(spacing: 2) {
                                            Text("🤡").font(.largeTitle)
                                            Text(joker.name).font(.system(size: 10)).fontWeight(.bold).foregroundColor(.white).multilineTextAlignment(.center)
                                        }.padding(4)
                                    }
                                }
                                .frame(width: 70, height: 100)
                                .onTapGesture { game.gameMessage = "\(joker.name): \(joker.description)" }
                            }
                            // 空位
                            ForEach(0..<(5 - game.activeJokers.count), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    .background(Color.black.opacity(0.2))
                                    .frame(width: 70, height: 100)
                                    .overlay(Text("空").font(.caption).foregroundColor(.gray))
                            }
                        }
                        .padding(.horizontal).padding(.top, 10)
                    }
                    .frame(height: 100)
                    
                    // 2. 頂部資訊區
                    HStack(alignment: .top) {
                        // 分數
                        VStack(alignment: .leading, spacing: 5) {
                            Text("分數").font(.caption).foregroundColor(.gray)
                            Text("\(game.chip)").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundColor(.yellow)
                                .id(game.chip).animation(.easeInOut(duration: 0.5), value: game.chip)
                            Text("目標: \(game.blindTarget)").font(.headline).foregroundColor(.white.opacity(0.8))
                        }
                        .padding().background(Color.black.opacity(0.4)).cornerRadius(15)
                        
                        Spacer()
                        
                        // 金錢
                        VStack(spacing: 10) {
                            // 金錢 (原本的)
                            VStack(spacing: 5) {
                                Text("金錢").font(.caption).foregroundColor(.gray)
                                Text("$\(game.money)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.4)).cornerRadius(15)
                            
                            // 新增：等級按鈕
                            Button(action: {
                                showHandRank = true
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "list.bullet.clipboard")
                                    Text("牌型")
                                }
                                .font(.caption).bold()
                                .padding(8)
                                .background(Color.purple.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        Spacer()
                        
                        // 次數
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("次數").font(.caption).foregroundColor(.gray)
                            Text("\(game.handsRemaining)").font(.title).fontWeight(.bold).foregroundColor(game.handsRemaining <= 1 ? .red : .white)
                                .id(game.handsRemaining).animation(.easeInOut(duration: 0.3), value: game.handsRemaining)
                            Text("棄牌: \(game.discardsRemaining)").font(.subheadline).foregroundColor(.white.opacity(0.8))
                        }
                        .padding().background(Color.black.opacity(0.4)).cornerRadius(15)
                    }
                    .padding(.horizontal).padding(.top, 10)
                    
                    // 3. 訊息區
                    Text(game.gameMessage)
                        .font(.subheadline).foregroundColor(.white).padding(.vertical, 8).padding(.horizontal, 15)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.6)).shadow(color: .white.opacity(0.2), radius: 3))
                        .padding(.top, 5).id(game.gameMessage).transition(.opacity.animation(.easeInOut))
                    
                    Spacer()
                    
                    // 4. 出牌預覽
                    if !game.selectedCards.isEmpty {
                        let handType = PokerHandEvaluator.evaluate(cards: game.selectedCards)
                        Text("準備打出: \(handType.description)").font(.headline).foregroundColor(.yellow).padding(.bottom, 5)
                    }
                    
                    // 5. 手牌區
                    HandView()
                    
                    // 6. 底部按鈕區
                    switch game.gameState {
                    case .playing:
                        HStack(spacing: 20) {
                            Button(action: { game.discardSelectedCards() }) {
                                Text("棄牌 (\(game.discardsRemaining))").font(.headline).frame(width: 120, height: 50)
                                    .background(Color.red.opacity(0.7)).foregroundColor(.white).cornerRadius(15).shadow(radius: 5)
                            }
                            .disabled(game.selectedCards.isEmpty || game.discardsRemaining <= 0)
                            
                            Button(action: { game.playPokerHand(cards: game.selectedCards) }) {
                                Text("出牌").font(.title2).fontWeight(.bold).frame(width: 160, height: 60)
                                    .background(game.selectedCards.isEmpty ? Color.gray.opacity(0.5) : Color.yellow.opacity(0.8))
                                    .foregroundColor(.black).cornerRadius(20).shadow(radius: 7)
                            }
                        }
                        .padding(.bottom, 20).animation(.default, value: game.selectedCards.isEmpty)
                        
                    case .roundWon:
                        VStack(spacing: 10) {
                            Text("🎉 過關！").font(.title).foregroundColor(.yellow)
                            Button(action: { withAnimation { game.goToShop() } }) {
                                Text("進入商店").font(.title2).padding().background(Color.orange).foregroundColor(.white).cornerRadius(12)
                            }
                            Button(action: { withAnimation { game.startNextRound() } } ) {
                                Text("下一關").font(.title2).padding().background(Color.green).foregroundColor(.white).cornerRadius(12)
                            }
                        }
                        .padding().background(Color.black.opacity(0.8)).cornerRadius(15).padding(.bottom, 20)
                        
                    case .gameOver:
                        VStack(spacing: 10) {
                            Text("💀 失敗").font(.title).foregroundColor(.red)
                            Button(action: { withAnimation { game.resetGame() } }) {
                                Text("重新開始").font(.title2).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
                            }
                        }
                        .padding().background(Color.black.opacity(0.8)).cornerRadius(15).padding(.bottom, 20)
                        
                    case .shopping:
                        // 這裡留空，因為商店會顯示在 Layer 1
                        EmptyView()
                    }
                }
            }
            // 當商店開啟時，讓底下的遊戲介面模糊一點
            .blur(radius: game.gameState == .shopping ? 5 : 0)
            
            // ------------------------------------------------
            // Layer 1: 全螢幕商店覆蓋層
            // ------------------------------------------------
            if game.gameState == .shopping {
                VStack(spacing: 0) {
                    // --- 頂部區域 ---
                    VStack(spacing: 10) {
                        Text("🛒 商店").font(.largeTitle).bold().foregroundColor(.white)
                        Text("持有金錢: $\(game.money)").font(.title2).foregroundColor(.orange)
                    }
                    .padding(.top, 50).padding(.bottom, 20)
                    
                    // --- 中間區域 (可捲動) ---
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 30) { // 增加間距讓分區更明顯
                            
                            Spacer(minLength: 10)
                            
                            // 🔥🔥🔥 新增區塊：玩家目前擁有的 Joker (賣出區) 🔥🔥🔥
                            if !game.activeJokers.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("我的收藏 (點擊賣出)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(game.activeJokers) { joker in
                                                VStack {
                                                    // 圖片區
                                                    ZStack(alignment: .topTrailing) {
                                                        if let _ = UIImage(named: joker.imageName) {
                                                            Image(joker.imageName).resizable().scaledToFit().frame(height: 80).cornerRadius(8)
                                                        } else {
                                                            Text("🤡").font(.system(size: 50))
                                                        }
                                                        
                                                        // 顯示 "賣" 的標籤
                                                        Text("出售")
                                                            .font(.caption2).bold()
                                                            .padding(4)
                                                            .background(Color.red)
                                                            .foregroundColor(.white)
                                                            .cornerRadius(4)
                                                            .offset(x: 5, y: -5)
                                                    }
                                                    
                                                    Text(joker.name).font(.caption).fontWeight(.bold).foregroundColor(.black)
                                                    
                                                    // 賣出按鈕
                                                    Button(action: {
                                                        withAnimation {
                                                            game.sellJoker(joker)
                                                        }
                                                    }) {
                                                        Text("+$\(joker.sellValue)")
                                                            .font(.caption).bold()
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 5)
                                                            .background(Color.green)
                                                            .foregroundColor(.white)
                                                            .cornerRadius(8)
                                                    }
                                                }
                                                .padding()
                                                .frame(width: 120, height: 180) // 比商品小一點
                                                .background(Color.white.opacity(0.9))
                                                .cornerRadius(12)
                                                .shadow(radius: 3)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                
                                Divider().background(Color.white.opacity(0.3))
                            }
                            VStack {
                                Spacer(minLength: 20)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(game.shopJokers) { joker in
                                            VStack {
                                                if let _ = UIImage(named: joker.imageName) {
                                                    Image(joker.imageName).resizable().scaledToFit().frame(height: 100).cornerRadius(8)
                                                } else { Text("🤡").font(.largeTitle) }
                                                Text(joker.name).fontWeight(.bold).font(.caption).foregroundColor(.black)
                                                Text(joker.description).font(.caption2).foregroundColor(.gray).multilineTextAlignment(.center).frame(height: 40)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                Button("$\(joker.price)") { game.buyJoker(joker) }
                                                    .buttonStyle(.borderedProminent).tint(.orange)
                                            }
                                            .padding().frame(width: 140, height: 240)
                                            .background(Color.white.opacity(0.95)).cornerRadius(12).shadow(radius: 5)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                Spacer(minLength: 20)
                            }
                            VStack {
                                    Text("🪐")
                                        .font(.system(size: 60))
                                    
                                    Text("隨機升級")
                                        .fontWeight(.bold)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Text("隨機提升一種\n牌型的等級")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .frame(height: 40)
                                    
                                    Button("$5 購買") {
                                        // 購買邏輯
                                        if game.money >= 5 {
                                            game.money -= 5
                                            // 隨機選一個牌型升級
                                            if let randomType = PokerHandType.allCases.randomElement() {
                                                game.levelUpHand(randomType)
                                            }
                                            AudioManager.shared.playSound(named: "chips_count") // 播放音效
                                        } else {
                                            AudioManager.shared.playSound(named: "error")
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.purple) // 用紫色代表星球/升級
                                    .padding(.top, 5)
                                }
                                .padding()
                                .frame(width: 140, height: 240)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                    }
                    // --- 底部區域 (固定在畫面最下方) ---
                    VStack(spacing: 20) {
                        Divider().background(Color.white)
                        Button(action: { game.startNextRound() }) {
                            Text("下一回合").font(.title2).bold().padding().frame(maxWidth: .infinity)
                                .background(Color.red).foregroundColor(.white).cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 30)
                    .background(Color.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.95).ignoresSafeArea())
                .transition(.move(edge: .bottom)) // 從下往上滑出的動畫
                .zIndex(2) // 確保在最上層
            }
        }
        .sheet(isPresented: $showHandRank) {
            HandRankView()
                .presentationDetents([.medium, .large]) // 允許半開或全開
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 1. 隱藏系統原本 "沒有功能" 的返回鍵
        .toolbar { // 2. 放上我們 "有功能" 的返回鍵
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // 這裡執行您的邏輯
                    game.saveHighScore()
                    game.resetGame() // 重置遊戲
                    dismiss()        // 回到上一頁
                }) {
                    // 這裡設計按鈕長相，讓它看起來像系統原本的
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("主選單")
                    }
                    .foregroundColor(.white) // 確保在深色背景看得到
                }
            }
        }
    }
}
struct HandRankView: View {
    @Environment(BalatroGame.self) private var game
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 標題
                Text("牌型等級")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // 列表
                ScrollView {
                    VStack(spacing: 12) {
                        // 遍歷所有牌型
                        ForEach(PokerHandType.allCases, id: \.self) { type in
                            HStack {
                                // 1. 牌型名稱與等級
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.description)
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.white)
                                    
                                    Text("Lv.\(game.handLevels[type] ?? 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .cornerRadius(5)
                                }
                                
                                Spacer()
                                
                                // 2. 數值顯示 (籌碼 x 倍率)
                                let level = game.handLevels[type] ?? 1
                                let stats = ScoreCalculator.getBaseStats(for: type, level: level)
                                
                                HStack(spacing: 2) {
                                    Text("\(stats.chips)")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text("X")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(stats.mult)")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                
                // 關閉按鈕
                Button(action: {
                    dismiss()
                }) {
                    Text("關閉")
                        .font(.headline)
                        .padding() // 1. 增加文字周圍的空間
                        .frame(maxWidth: .infinity) // 2. 讓點擊區域撐滿整個寬度
                        .background(Color.gray.opacity(0.3)) // 3. 背景色現在是按鈕內容的一部分
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
}
