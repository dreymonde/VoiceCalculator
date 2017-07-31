//
//  VoiceSynthesizer.swift
//  Voice Calculator
//
//  Created by Олег on 31.07.17.
//  Copyright © 2017 Oleg Dreyman. All rights reserved.
//

import Foundation
import AVFoundation

final class VoiceSynthesizer {
    
    let session = AVAudioSession.sharedInstance()
    
    init(speechSynthesizer: AVSpeechSynthesizer = VoiceSynthesizer.default(),
         voice: AVSpeechSynthesisVoice = VoiceSynthesizer.default()) {
        self.synthes = speechSynthesizer
        self.voice = voice
    }
    
    let synthes: AVSpeechSynthesizer
    let voice: AVSpeechSynthesisVoice
    
    func synthesize(_ text: String) {
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        synthes.speak(utterance)
    }
    
}

extension VoiceSynthesizer {
    
    static func `default`() -> AVSpeechSynthesizer {
        return AVSpeechSynthesizer()
    }
    
    static func `default`() -> AVSpeechSynthesisVoice {
        return AVSpeechSynthesisVoice(language: "en-US")!
    }
    
}
