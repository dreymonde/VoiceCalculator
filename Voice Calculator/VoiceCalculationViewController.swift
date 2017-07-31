//
//  VoiceCalculationViewController.swift
//  Voice Calculator
//
//  Created by Олег on 31.07.17.
//  Copyright © 2017 Oleg Dreyman. All rights reserved.
//

import UIKit

class VoiceCalculationViewController: UIViewController {
    
    let voiceCalculation: VoiceCalculation = VoiceCalculation()
    let voiceSynthesizer: VoiceSynthesizer = VoiceSynthesizer()
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var stateIndicatorLabel: UILabel!
    @IBOutlet weak var expressionLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        voiceCalculation.delegate = self
    }
    
    var isListening = false
    
    @IBAction func didPressStartStopButton(_ sender: UIButton) {
        if isListening {
            voiceCalculation.stopRecognition()
            stateIndicatorLabel.pushTransition(.fromBottom)
            stateIndicatorLabel.text = Strings.processing
            stateIndicatorLabel.textColor = .black
            startStopButton.setTitle(Strings.listen, for: .normal)
            startStopButton.isEnabled = true
            isListening = false
        } else {
            voiceCalculation.startRecognition()
            stateIndicatorLabel.pushTransition(.fromBottom)
            stateIndicatorLabel.text = Strings.listening
            stateIndicatorLabel.textColor = .listening
            startStopButton.setTitle(Strings.stop, for: .normal)
            startStopButton.isEnabled = true
            isListening = true
        }
    }
    
    func updateStartStopButton(with availability: VoiceCalculation.Availability) {
        switch availability {
        case .available:
            startStopButton.isEnabled = true
            startStopButton.setTitle(Strings.listen, for: .normal)
        case .notAvailable:
            startStopButton.isEnabled = false
            startStopButton.setTitle(Strings.unavailable, for: .disabled)
        }
    }
    
}

extension VoiceCalculationViewController : VoiceCalculationDelegate {
    
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, availabilityDidChange availability: VoiceCalculation.Availability) {
        print(#function)
        assert(Thread.isMainThread)
        updateStartStopButton(with: availability)
    }
    
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, didFailWith error: Error) {
        print(#function)
        stateIndicatorLabel.pushTransition(.fromBottom)
        stateIndicatorLabel.text = error.localizedDescription
        stateIndicatorLabel.textColor = .error
    }
    
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, didRecognize expression: String) {
        print(#function)
        stateIndicatorLabel.pushTransition(.fromBottom)
        stateIndicatorLabel.text = Strings.empty
        stateIndicatorLabel.textColor = .black
        
        expressionLabel.pushTransition(.fromBottom)
        expressionLabel.text = expression
    }
    
    func voiceCalculation(_ voiceCalculation: VoiceCalculation, didEvaluateWithResult result: String) {
        print(#function)
        resultLabel.pushTransition(.fromBottom)
        resultLabel.text = result
        voiceSynthesizer.synthesize(result)
    }
    
}

extension VoiceCalculationViewController {
    
    fileprivate enum Strings {
        
        static let listen = "Listen"
        static let stop = "Stop"
        static let unavailable = "Unavailable"
        
        static let listening = "Listening..."
        static let processing = "Processing..."
        
        static let empty = " "
        
    }
    
}
