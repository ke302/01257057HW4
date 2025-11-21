//
//  AudioManager.swift
//  01257057HW4
//
//  Created by user05 on 2025/11/21.
//
import Foundation
import AVFoundation

class AudioManager: NSObject, AVAudioPlayerDelegate{
    // 1. 建立單例，方便在任何地方呼叫 (AudioManager.shared)
    static let shared = AudioManager()
    
    // 2. 音樂播放器實例
    private var bgmPlayer: AVAudioPlayer?
    
    // 用一個 Set 來儲存正在播放的音效，防止被記憶體回收
    private var sfxPlayers: Set<AVAudioPlayer> = []
        
    // 音效開關 (預設開啟)
    var isSoundEffectOn: Bool = true
        
    private override init() {}
    
    // MARK: - 背景音樂 (BGM)
    
    func playBGM() {
        // 防止重複播放
        if bgmPlayer != nil && bgmPlayer!.isPlaying {
            return
        }
        
        // 1. 獲取檔案路徑 (請確保檔名與副檔名正確)
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else {
            print("❌ 找不到 bgm.mp3 檔案")
            return
        }
        
        do {
            // 2. 設定播放器
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // 🔥 設定為 -1 代表無限循環播放
            bgmPlayer?.volume = 0.5 // 設定音量 (0.0 ~ 1.0)
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
            print("🎵 開始播放 BGM")
        } catch {
            print("❌ BGM 播放失敗: \(error.localizedDescription)")
        }
    }
    
    func stopBGM() {
        bgmPlayer?.stop()
        print("🛑 停止播放 BGM")
    }
    
    // 用來回應設定開關的變化
    func updateMusicState(isMusicOn: Bool) {
        if isMusicOn {
            playBGM()
        } else {
            stopBGM()
        }
    }
    /// 播放指定名稱的音效檔案
        func playSound(named soundName: String) {
            // 1. 檢查開關
            guard isSoundEffectOn else { return }
            
            // 2. 找檔案 (支援 mp3 或 wav)
            let url: URL?
            if let mp3Url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
                url = mp3Url
            } else if let wavUrl = Bundle.main.url(forResource: soundName, withExtension: "wav") {
                url = wavUrl
            } else {
                print("❌ 找不到音效檔案: \(soundName)")
                return
            }
            
            do {
                // 3. 建立新的播放器 (因為音效可能重疊播放，所以每次都 new 一個)
                let player = try AVAudioPlayer(contentsOf: url!)
                player.delegate = self // 設定代理，以便播放完後移除
                player.volume = 0.2  // 音效音量
                player.prepareToPlay()
                player.play()
                
                // 4. 加入集合中保存，不然函數結束 player 就會被釋放導致沒聲音
                sfxPlayers.insert(player)
                
            } catch {
                print("❌ 音效播放失敗: \(error.localizedDescription)")
            }
        }
        /// 強制停止所有目前的短音效 (適用於切換場景或重新開始時)
        func stopAllSFX() {
            for player in sfxPlayers {
                player.stop()
            }
            sfxPlayers.removeAll()
            print("🤫 已停止所有音效")
        }
        // MARK: - AVAudioPlayerDelegate
        
        // 當音效播放完畢時，從集合中移除，釋放記憶體
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            sfxPlayers.remove(player)
        }
}
