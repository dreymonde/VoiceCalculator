
import Speech

protocol SpeechRecognitionEngine {
    
    associatedtype Session : SpeechRecognitionSession
    
    func start() throws -> Session
    
}

extension SFSpeechRecognizer : SpeechRecognitionEngine {
    
    enum Error : Swift.Error, LocalizedError {
        case recognizerIsNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .recognizerIsNotAvailable:
                return "Not available"
            }
        }
    }
    
    typealias Session = SFSpeechRecognitionTaskRecognitionSession
    
    func start() throws -> Session {
        guard self.isAvailable else {
            throw Error.recognizerIsNotAvailable
        }
        let newSession = try Session(recognizer: self,
                                     audioSession: .sharedInstance())
        return newSession
    }
    
}

extension Locale {
    
    static var en_US: Locale {
        return Locale(identifier: "en-US")
    }
    
}
