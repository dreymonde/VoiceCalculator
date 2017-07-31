
import Speech

enum SpeechRecognitionResult {
    case recognized(String)
    case failure(Swift.Error)
}

protocol SpeechRecognitionSession {
    
    func stop()
    
    var handler: (SpeechRecognitionResult) -> () { get set }
    
}

final class SFSpeechRecognitionTaskRecognitionSession : SpeechRecognitionSession {
    
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
    
    var handler: (SpeechRecognitionResult) -> () = { _ in }
    
    init(recognizer: SFSpeechRecognizer,
         audioSession: AVAudioSession) throws {
        self.audioSession = audioSession
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        let audioEngine = AVAudioEngine.shared
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
            let recognized = SpeechRecognitionResult.recognized(result.bestTranscription.formattedString)
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
    
}

extension AVAudioEngine {
    
    fileprivate static let shared = AVAudioEngine()
    
}
