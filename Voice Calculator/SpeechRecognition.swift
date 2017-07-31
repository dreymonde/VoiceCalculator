//
//  SpeechRecognition.swift
//  Voice Calculator
//
//  Created by Олег on 30.07.17.
//  Copyright © 2017 Oleg Dreyman. All rights reserved.
//

import Foundation
import Speech

final class SpeechRecognition {
    
    var availabilityDelegate: SFSpeechRecognizerDelegate? {
        get {
            return recognizer.delegate
        }
        set {
            recognizer.delegate = newValue
        }
    }
    
    var isAvailable: Bool {
        return recognizer.isAvailable
    }
    
    private let recognizer = SFSpeechRecognizer(locale: .en_US)!
    private let audioEngine = AVAudioEngine()
    
    let authorization: Authorization
    
    init(authorization: Authorization = Authorization.application.mainThread()) {
        self.authorization = authorization
    }
    
    var currentSession: SpeechRecognitionSession?
    
    enum Error : Swift.Error, LocalizedError {
        case recognizerIsNotAvailable
        case alreadyRunning
        
        var errorDescription: String? {
            switch self {
            case .recognizerIsNotAvailable:
                return "Not available"
            case .alreadyRunning:
                return "Already running"
            }
        }
    }
    
    func start(completion: @escaping (SpeechRecognitionSession.Result) -> ()) {
        do {
            guard currentSession == nil else {
                throw Error.alreadyRunning
            }
            guard recognizer.isAvailable else {
                throw Error.recognizerIsNotAvailable
            }
            let newSession = try SpeechRecognitionSession(recognizer: recognizer,
                                                          audioSession: .sharedInstance(),
                                                          audioEngine: audioEngine)
            currentSession = newSession
            newSession.handler = { result in
                self.currentSession = nil
                completion(result)
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func stop() {
        currentSession?.stop()
    }
    
}

extension Locale {
    
    static var en_US: Locale {
        return Locale(identifier: "en-US")
    }
    
}

final class SpeechRecognitionSession : Hashable {
    
    enum Result {
        case recognized(String)
        case failure(Swift.Error)
    }
    
    enum Error : Swift.Error, LocalizedError {
        case noInputNode(AVAudioEngine)
        case noResult
        
        var errorDescription: String? {
            switch self {
            case .noInputNode:
                return "Something is severely wrong"
            case .noResult:
                return "Failed to recognize"
            }
        }
    }
    
    var handler: (Result) -> () = { _ in }
    
    init(recognizer: SFSpeechRecognizer,
         audioSession: AVAudioSession,
         audioEngine: AVAudioEngine) throws {
        self.audioSession = audioSession
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        self.audioEngine = audioEngine
        self.request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            throw Error.noInputNode(audioEngine)
        }
        request.shouldReportPartialResults = false
        
        self.task = recognizer.recognitionTask(with: request, resultHandler: { result, error in
            defer {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
            if let error = error {
                self.handler(.failure(error))
                return
            }
            guard let result = result else {
                self.handler(.failure(Error.noResult))
                return
            }
            let recognized = Result.recognized(result.bestTranscription.formattedString)
            self.handler(recognized)
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stop() {
        audioEngine.stop()
        request.endAudio()
    }
    
    let request: SFSpeechAudioBufferRecognitionRequest
    var task: SFSpeechRecognitionTask!
    let audioEngine: AVAudioEngine
    let audioSession: AVAudioSession
    
    static func == (lhs: SpeechRecognitionSession, rhs: SpeechRecognitionSession) -> Bool {
        return lhs === rhs
    }
    
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
}

extension SpeechRecognition {
    
    final class Authorization {
        
        private let _authorize: (_ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> ()) -> ()
        
        init(authorize: @escaping (_ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> ()) -> ()) {
            self._authorize = authorize
        }
        
        func mainThread() -> Authorization {
            return Authorization(authorize: { (handler) in
                self.authorize(handler: { (status) in
                    DispatchQueue.main.async {
                        handler(status)
                    }
                })
            })
        }
        
        func authorize(handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> ()) {
            _authorize(handler)
        }
        
        static var application: Authorization {
            return Authorization(authorize: SFSpeechRecognizer.requestAuthorization)
        }
        
        static func always(_ status: SFSpeechRecognizerAuthorizationStatus) -> Authorization {
            return Authorization(authorize: { handler in handler(status) })
        }
        
    }
    
}
