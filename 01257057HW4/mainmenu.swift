//
//  mainmenu.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/19.
//
import SwiftUI
struct MainMenuView: View {
    // 控制 Sheet 顯示的狀態
    @State private var showSettings = false
    @State private var showAbout = false
    
    var body: some View {
        ZStack {
            // A. 背景 (簡單的遊戲風格漸層)
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // B. 遊戲標題
                VStack(spacing: 10) {
                    Text("Joker")
                        .font(.system(size: 60, weight: .heavy, design: .serif))
                        .foregroundColor(.white)
                    Text("Balatro Clone")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // C. 選單按鈕區
                VStack(spacing: 20) {
                    
                    // 1. 開始遊戲 (跳轉到新頁面)
                    NavigationLink(destination: GameView()) {
                        MenuButtonLabel(title: "開始遊戲", icon: "play.fill", color: .green)
                    }
                    
                    // 2. 設定 (跳出 Sheet)
                    Button {
                        showSettings = true
                    } label: {
                        MenuButtonLabel(title: "遊戲設定", icon: "gear", color: .orange)
                    }
                    
                    // 3. 關於 (跳出 Sheet)
                    Button {
                        showAbout = true
                    } label: {
                        MenuButtonLabel(title: "關於開發者", icon: "person.fill", color: .blue)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Text("Ver 1.0.0")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        // 設定頁面的 Sheet
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        // 關於頁面的 Sheet
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}

// 抽取出來的按鈕樣式組件 (讓程式碼更整潔)
struct MenuButtonLabel: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
struct AboutView: View {
    // 用來關閉當前頁面 (Sheet)
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 頂部把手 (提示這是可以向下滑動關閉的 sheet)
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 6)
                    .padding(.top, 10)
                
                Spacer()
                
                // LOGO 或 圖示
                Image(systemName: "suit.spade.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Circle().fill(Color.white).shadow(radius: 5))
                
                // 標題
                VStack(spacing: 8) {
                    Text("Joker Balatro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 內容說明
                VStack(alignment: .leading, spacing: 16) {
                    Text("關於這個遊戲")
                        .font(.headline)
                    
                    Text("這是一個使用 SwiftUI 與 iOS 17+ Observation 框架構建的卡牌遊戲練習專案，致敬了知名遊戲 Balatro 的核心機制。")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        Text("開發者")
                        Spacer()
                        Text("您的名字") // 記得改成您的名字
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("開發工具")
                        Spacer()
                        Text("SwiftUI & Xcode")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // 關閉按鈕
                Button {
                    dismiss()
                } label: {
                    Text("關閉")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

struct SettingsView: View {
    // 用來關閉 Sheet
    @Environment(\.dismiss) var dismiss
    
    // 暫存的設定狀態 (未來可以存入 UserDefaults)
    @AppStorage("isMusicOn") private var isMusicOn = true
    @AppStorage("isSoundEffectOn") private var isSoundEffectOn = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("音效設定")) {
                    Toggle("背景音樂", isOn: $isMusicOn)
                    Toggle("遊戲音效", isOn: $isSoundEffectOn)
                }
                
                Section(header: Text("遊戲難度")) {
                    Text("目前鎖定為：標準模式")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GameView: View {
    @Environment(BalatroGame.self) private var game
    
    var body: some View {
        ZStack {
            // 背景色 (深綠色桌布感覺)
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.3, green: 0.1, blue: 0.1)]),
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                 .ignoresSafeArea()
          
            VStack {
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
                        Button(action: { game.discardSelectedCards() }) {
                            Text("棄牌 (\(game.discardsRemaining))")
                                    // ... 樣式 ...
                        }
                        .disabled(game.selectedCards.isEmpty || game.discardsRemaining <= 0)
                            
                        Button(action: { game.playPokerHand(cards: game.selectedCards) }) {
                        Text("出牌 (\(game.handsRemaining))")
                                    // ... 樣式 ...
                        }
                        .disabled(game.selectedCards.isEmpty || game.handsRemaining <= 0)
                        }
                        
                case .roundWon:
                    VStack(spacing: 10) {
                        Text("🎉 過關！")
                            .font(.title)
                            .foregroundColor(.yellow)
                            
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
                }
            }
            
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
            MainMenuView()
        }
        // 2. 注入環境物件，否則跳轉到 GameView 時會崩潰
        .environment(BalatroGame())
}
