
import Speech

protocol SpeechRecognitionEngine {
    
    associatedtype Session : SpeechRecognitionSession
    
    func start() throws -> Session
    
}

final class LiveSpeechEngine : SpeechRecognitionEngine {
    
    typealias Session = LiveSpeechRecognitionSession
    
    init(recognizer: SFSpeechRecognizer = LiveSpeechEngine.default(),
         audioEngine: AVAudioEngine = LiveSpeechEngine.default() ) {
        self.recognizer = recognizer
        self.audioEngine = audioEngine
    }
    
    let recognizer: SFSpeechRecognizer
    let audioEngine: AVAudioEngine
    
    func start() throws -> LiveSpeechRecognitionSession {
        guard recognizer.isAvailable else {
            throw Error.recognizerIsNotAvailable
        }
        let newSession = try Session(recognizer: recognizer,
                                     audioSession: .sharedInstance(),
                                     audioEngine: audioEngine)
        return newSession
    }
    
}

extension LiveSpeechEngine {
    
    static func `default`() -> SFSpeechRecognizer {
        return SFSpeechRecognizer(locale: .en_US)!
    }
    
    static func `default`() -> AVAudioEngine {
        return AVAudioEngine()
    }
    
    enum Error : Swift.Error, LocalizedError {
        case recognizerIsNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .recognizerIsNotAvailable:
                return "Not available"
            }
        }
    }
    
}

extension Locale {
    
    static var en_US: Locale {
        return Locale(identifier: "en-US")
    }
    
}
