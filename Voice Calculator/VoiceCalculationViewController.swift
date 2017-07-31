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
            stateIndicatorLabel.text = VoiceCalculation.processing
            stateIndicatorLabel.textColor = .black
            startStopButton.setTitle(VoiceCalculation.listen, for: .normal)
            startStopButton.isEnabled = true
            isListening = false
        } else {
            voiceCalculation.startRecognition()
            stateIndicatorLabel.pushTransition(.fromBottom)
            stateIndicatorLabel.text = VoiceCalculation.listening
            stateIndicatorLabel.textColor = .listening
            startStopButton.setTitle(VoiceCalculation.stop, for: .normal)
            startStopButton.isEnabled = true
            isListening = true
        }
    }
    
    func updateStartStopButton(with availability: VoiceCalculation.Availability) {
        switch availability {
        case .available:
            startStopButton.isEnabled = true
            startStopButton.setTitle(VoiceCalculation.listen, for: .normal)
        case .notAvailable:
            startStopButton.isEnabled = false
            startStopButton.setTitle(VoiceCalculation.unavailable, for: .disabled)
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
        stateIndicatorLabel.text = VoiceCalculation.empty
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

fileprivate extension VoiceCalculation {
    
    static let listen = "Listen"
    static let stop = "Stop"
    static let unavailable = "Unavailable"
    
    static let listening = "Listening..."
    static let processing = "Processing..."
    
    static let empty = " "
    
}

extension UIView {
    
    enum TransitionPushDirection {
        case fromBottom
        case fromLeft
        case fromRight
        case fromTop
        
        var coreAnimationConstant: String {
            switch self {
            case .fromBottom:
                return kCATransitionFromBottom
            case .fromTop:
                return kCATransitionFromTop
            case .fromLeft:
                return kCATransitionFromLeft
            case .fromRight:
                return kCATransitionFromRight
            }
        }
    }
    
    func pushTransition(_ direction: TransitionPushDirection, duration: TimeInterval = 0.2) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = kCATransitionPush
        transition.subtype = direction.coreAnimationConstant
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        layer.add(transition, forKey: nil)
    }
    
}
