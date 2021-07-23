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
    
    // MARK: - Properity
    
    // Locale 설정
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko_KR"))
    
    // 음성인식 요청 처리
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // 음성인식 결과 제공
    var recognitionTask: SFSpeechRecognitionTask?
    
    // 소리를 인식하는 오디오 엔진
    let audioEngine = AVAudioEngine()

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
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
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
            var isFinal = false
            
            if result != nil {
                print(result?.bestTranscription.formattedString)
                
                isFinal = (result?.isFinal)!
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

}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "", for: indexPath) as! MyTableViewCell
        
        return cell
    }
}

