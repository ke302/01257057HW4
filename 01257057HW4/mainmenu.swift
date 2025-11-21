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
    @AppStorage("HighScore") private var highScore: Int = 0
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
                    Image("sea")
                        .resizable()
                        .scaledToFit()
                    Text("最高紀錄: \(UserDefaults.standard.integer(forKey: "HighScore"))")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .padding(.bottom, 10)
                    
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
                        MenuButtonLabel(title: "關於", icon: "person.fill", color: .blue)
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
                        .foregroundColor(.black)
                    Text("這是一個使用 SwiftUI 與 iOS 17+ Observation 框架構建的卡牌遊戲練習專案，致敬了知名遊戲 Balatro 的核心機制。")
                        .font(.body)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                    Divider()
                    
                    Image("Image")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 200)
                    
                    Divider()
                    
                    
                    HStack {
                        Text("開發工具")
                        Spacer()
                        Text("SwiftUI & Xcode")
                            .foregroundColor(.black)
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

#Preview {
    NavigationStack {
            MainMenuView()
        }
        // 2. 注入環境物件，否則跳轉到 GameView 時會崩潰
        .environment(BalatroGame())
}
