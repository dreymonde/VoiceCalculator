//
//  SpeechRecognition.swift
//  Voice Calculator
//
//  Created by Олег on 30.07.17.
//  Copyright © 2017 Oleg Dreyman. All rights reserved.
//

import Foundation
import Speech

final class SpeechRecognition<Engine : SpeechRecognitionEngine> {
    
    let engine: Engine
    
    let authorization: Authorization
    
    init(engine: Engine, authorization: Authorization = Authorization.application.mainThread()) {
        self.engine = engine
        self.authorization = authorization
    }
    
    var currentSession: Engine.Session?
    
    enum Error : LocalizedError {
        case alreadyRunning

        var errorDescription: String? {
            switch self {
            case .alreadyRunning:
                return "Already running"
            }
        }
    }
    
    func start(completion: @escaping (SpeechRecognitionResult) -> ()) {
        do {
            guard currentSession == nil else {
                throw Error.alreadyRunning
            }
            var newSession = try engine.start()
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
