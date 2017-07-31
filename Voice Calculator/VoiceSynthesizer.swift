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
    
    init() { }
    
    let synthes = AVSpeechSynthesizer()
    let voice = AVSpeechSynthesisVoice(language: "en-US")!
    
    func synthesize(_ text: String) {
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        synthes.speak(utterance)
    }
    
}
