//
//  ViewController.swift
//  SpeechToTextTest
//
//  Created by Byungwook Jeong on 2021/07/23.
//

import UIKit
import Speech
import AVKit

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: - IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Property
    
    // Locale 설정
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko_KR"))
    
    // 음성인식 요청 처리
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // 음성인식 결과 제공
    var recognitionTask: SFSpeechRecognitionTask?
    
    // 소리를 인식하는 오디오 엔진
    let audioEngine = AVAudioEngine()
    
    let contextualStrings: [String] = [
        "탑", "정글", "미드", "원딜", "서폿",
        "점멸", "점화", "탈진", "텔", "유체화", "정화", "베리어"
    ]
    
    var spellCheckArr: [String] = []

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        speechRecognizer?.delegate = self
    }
    
    // MARK: - IBAction
    
    @IBAction func tapAction(_ sender: Any) {
        speechRecognizerRequestAuthorization {
            if self.audioEngine.isRunning {
                print("stop recording")
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
            } else {
                print("start recording")
                self.startRecording()
            }
        }
    }
    
    // MARK: - Method
    
    func speechRecognizerRequestAuthorization(completion: @escaping () -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                print("authorized")
                completion()
            default:
                print("denied, notDetermined, restricted")
            }
        }
    }
    
    func startRecording() {
        // 이전 task가 있을 경우 task 초기화
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 음성을 녹음하기 위한 오디오 세션 인스턴스 생성
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // contextualStrings
        // - 네트워크가 연결된 상태에서만 정상적으로 동작
        recognitionRequest.contextualStrings = contextualStrings
        
        // Error Domain=kAFAssistantErrorDomain Code=203 "Retry"
        // - speechRecognizer에서 recognitionTask를 완료하거나 취소할 때 결과를 감지할 수 없을 때() 발생함!
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let formattedString = result.bestTranscription.formattedString
                
                print("formattedString: \(formattedString)")
                
                if let position = self.checkEachPosition(formattedString: formattedString) {
                    if let spell = self.checkEachSpell(formattedString: formattedString) {
                        self.spellCheckArr.append("\(position) 노\(spell)")
                        print(self.spellCheckArr)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        
                        self.recognitionTask?.cancel()
                    }
                }
                
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                print("Final!")
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error")
        }
    }
    
    func checkEachPosition(formattedString: String) -> String? {
        if formattedString.isContainTopPostion() {
            return "탑"
        } else if formattedString.isContainJunglePostion() {
            return "정글"
        } else if formattedString.isContainMidPostion() {
            return "미드"
        } else if formattedString.isContainADPostion() {
            return "원딜"
        } else if formattedString.isContainSupportPostion() {
            return "서폿"
        }
        
        return nil
    }
    
    func checkEachSpell(formattedString: String) -> String? {
        if formattedString.isContainHealSpell() {
            return "회복"
        } else if formattedString.isContainFlashSpell() {
            return "점멸"
        } else if formattedString.isContainGhostSpell() {
            return "유체화"
        } else if formattedString.isContainIgniteSpell() {
            return "점화"
        } else if formattedString.isContainBarrierSpell() {
            return "방어막"
        } else if formattedString.isContainExhaustSpell() {
            return "탈진"
        } else if formattedString.isContainCleanseSpell() {
            return "정화"
        } else if formattedString.isContainTeleportSpell() {
            return "텔레포트"
        }
        
        return nil
    }
}

// MARK: String Extension

extension String {
    // Position
    func isContainTopPostion() -> Bool {
        if self.contains("탑") {
            return true
        }
        
        return false
    }
    
    func isContainJunglePostion() -> Bool {
        if self.contains("정글") {
            return true
        }
        
        return false
    }
    
    func isContainMidPostion() -> Bool {
        if self.contains("미드") {
            return true
        }
        
        return false
    }
    
    func isContainADPostion() -> Bool {
        if self.contains("원딜") || self.contains("먼길") {
            return true
        }
        
        return false
    }
    
    func isContainSupportPostion() -> Bool {
        if self.lowercased().contains("support") || self.contains("써포트") || self.contains("소폭") || self.contains("소포") {
            return true
        }
        
        return false
    }
    
    // Spell
    func isContainFlashSpell() -> Bool {
        if self.contains("점멸") || self.contains("전멸") || self.contains("전면") {
            return true
        }
        
        return false
    }
    
    func isContainIgniteSpell() -> Bool {
        if self.contains("점화") || self.contains("전화") {
            return true
        }
        
        return false
    }
    
    func isContainExhaustSpell() -> Bool {
        if self.contains("탈진") {
            return true
        }
        
        return false
    }
    
    func isContainGhostSpell() -> Bool {
        if self.contains("유체화") || self.contains("고스트") {
            return true
        }
        
        return false
    }
    
    func isContainCleanseSpell() -> Bool {
        if self.contains("정화") || self.contains("클린지") {
            return true
        }
        
        return false
    }
    
    func isContainBarrierSpell() -> Bool {
        if self.contains("방어막") || self.contains("보호막") || self.contains("베리어") {
            return true
        }
        
        return false
    }
    
    func isContainTeleportSpell() -> Bool {
        if self.contains("텔") || self.contains("텔포") || self.contains("텔레포트") {
            return true
        }
        
        return false
    }
    
    func isContainHealSpell() -> Bool {
        if self.contains("힐") || self.contains("회복") {
            return true
        }
        
        return false
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        spellCheckArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myTableViewCell", for: indexPath) as! MyTableViewCell
        
        cell.myLabel.text = spellCheckArr[indexPath.row]
        
        return cell
    }
}

