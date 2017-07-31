//
//  VoiceCalculation.swift
//  Voice Calculator
//
//  Created by Олег on 31.07.17.
//  Copyright © 2017 Oleg Dreyman. All rights reserved.
//

import Foundation
import Speech

final class VoiceCalculation : NSObject {
    
    enum Availability {
        case available
        case notAvailable
    }
    
    var availability: Availability = .notAvailable {
        didSet {
            self.delegate?.voiceCalculation(self, availabilityDidChange: self.availability)
        }
    }
    
    let speechRecognition: SpeechRecognition
    let makeExpression: (String) throws -> Expression
    let formatter: NumberFormatter
    
    weak var delegate: VoiceCalculationDelegate?

    init(speechRecognition: SpeechRecognition = VoiceCalculation.default(),
         formatter: NumberFormatter = VoiceCalculation.default(),
         makeExpression: @escaping (String) throws -> Expression = VoiceCalculation.default()) {
        self.speechRecognition = speechRecognition
        self.makeExpression = makeExpression
        self.formatter = formatter
        super.init()
        speechRecognition.availabilityDelegate = self
        main()
    }
    
    func main() {
        speechRecognition.authorization.authorize { (status) in
            switch status {
            case .authorized:
                self.availability = self.speechRecognition.isAvailable ? .available : .notAvailable
            default:
                self.availability = .notAvailable
            }
        }
    }

    private let evaluationQueue = DispatchQueue.global(qos: .userInitiated)
        
    func startRecognition() {
        speechRecognition.start { (result) in
            switch result {
            case .failure(let error):
                self.delegate?.voiceCalculation(self, didFailWith: error)
            case .recognized(let string):
                self.speechRecognitionDidRecognizeString(string)
            }
        }
    }
    
    func stopRecognition() {
        speechRecognition.stop()
    }
    
    enum Error : Swift.Error {
        case invalidNumber(Double)
    }
    
    private func speechRecognitionDidRecognizeString(_ string: String) {
        print("recognized:", string)
        evaluationQueue.async {
            do {
                let expression = try self.makeExpression(string)
                self.didRecognize(expression)
                let result = expression.evaluate()
                try self.didEvaluate(result: result)
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.voiceCalculation(self, didFailWith: error)
                }
            }
        }
    }
    
    private func didRecognize(_ expression: Expression) {
        let string = expression.rightmostNode.fullString()
        DispatchQueue.main.async {
            self.delegate?.voiceCalculation(self, didRecognize: string)
        }
    }
    
    private func didEvaluate(result: Double) throws {
        guard let resultString = self.formatter.string(from: result as NSNumber) else {
            throw Error.invalidNumber(result)
        }
        DispatchQueue.main.async {
            self.delegate?.voiceCalculation(self, didEvaluateWithResult: resultString)
        }
    }
    
}

protocol VoiceCalculationDelegate : class {
    
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, availabilityDidChange availability: VoiceCalculation.Availability)
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, didRecognize expression: String)
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, didEvaluateWithResult result: String)
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, didFailWith error: Error)
}

extension VoiceCalculation : SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.availability = available ? .available : .notAvailable
        }
    }
    
}

extension VoiceCalculation {
    
    static func `default`() -> (String) throws -> Expression {
        return { try Expression(from: $0) }
    }
    
    static func `default`() -> SpeechRecognition {
        return SpeechRecognition()
    }
    
    static func `default`() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.en_US
        formatter.numberStyle = .decimal
        return formatter
    }
    
}
