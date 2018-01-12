//
//  ViewController.swift
//  AudioTest
//
//  Created by Marcel Pillich on 19.10.17.
//  Copyright © 2017 Marcel Pillich. All rights reserved.
//

import UIKit

import AudioKit
import CoreMotion
import AudioKitUI


extension CGFloat {
    func map(from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> CGFloat {
        let result = ((self - from.lowerBound) / (from.upperBound - from.lowerBound)) * (to.upperBound - to.lowerBound) + to.lowerBound
        return result
    }
}

extension Double {
    func map(from: ClosedRange<CGFloat>, to: ClosedRange<CGFloat>) -> Double {
        return Double(CGFloat(self).map(from: from, to: to))
    }
}

class ViewController: UIViewController {
    
    enum Status: String {
        case Gyroskop = "Gyroskop"
        case Accelerometer = "Accelerometer"
        case Magnetometer = "Magnetometer"
    }
    
    let oscillator = AKOscillator()
    let motionManager = CMMotionManager()
    let maxFrequency = 2000.0
    
    var timer: Timer!
    var val = 0.00
    var maxVal = 0.00
    var status = Status.Gyroskop
    
    var delay: AKVariableDelay!
    var delayMixer: AKDryWetMixer!
    var reverb: AKCostelloReverb!
    var reverbMixer: AKDryWetMixer!
    var booster: AKBooster!
    
    let input = AKStereoInput()
    
    //Loop through the different sensors bei pressing the button
    @IBAction func modeButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
            case "Gyroskop":
                print("gyro")
                sender.setTitle("Accelerometer", for: .normal)
                motionManager.stopGyroUpdates()
                motionManager.startAccelerometerUpdates()
                status = Status.Accelerometer
                maxVal = 0.00
            case "Accelerometer":
                print("accelerometer")
                sender.setTitle("Magnetometer", for: .normal)
                motionManager.stopAccelerometerUpdates()
                motionManager.startMagnetometerUpdates()
                status = Status.Magnetometer
                maxVal = 0.00
            case "Magnetometer":
                print("Magnetometer")
                sender.setTitle("Gyroskop", for: .normal)
                motionManager.stopMagnetometerUpdates()
                motionManager.startGyroUpdates()
                status = Status.Gyroskop
                maxVal = 0.00
            default:
                print("Unknown")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        AudioKit.output = oscillator
        AudioKit.start()
        oscillator.start()
        oscillator.rampTime = 0.2
        
        //motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()

        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        
        delay = AKVariableDelay(input)
        delay.rampTime = 0.5 // Allows for some cool effects
        delayMixer = AKDryWetMixer(input, delay)
        
        reverb = AKCostelloReverb(delayMixer)
        reverbMixer = AKDryWetMixer(delayMixer, reverb)
        
        booster = AKBooster(reverbMixer)
        
        AudioKit.output = booster
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeSoundFrequency(frequency: Double) {
        if (frequency < maxFrequency) {
            oscillator.frequency = frequency
            print(frequency)
        }else {
            print("Frequency to High")
        }
    }
    
    func changeSoundAmplitude(amplitude: Double) {
        oscillator.amplitude = amplitude
    }
    
    @objc
    func update() {
        switch status {
        case Status.Accelerometer:
            if let accelerometerData = motionManager.accelerometerData {
                print("AccelorometerData: \(accelerometerData)")
                val = accelerometerData.acceleration.x + accelerometerData.acceleration.y + accelerometerData.acceleration.z
                if (val < 0) {
                    val = val * -1
                }
                if (maxVal < val) {
                    maxVal = val
                }
                print("This is the Max for accelerometer: \(maxVal)")
                let f = Double(val).map(from: 0.0...CGFloat(maxVal), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)//accelerometerData.acceleration.x * 10
            }
        case Status.Gyroskop:
            if let gyroData = motionManager.gyroData {
                print("Gyrodata: \(gyroData)")
                val = gyroData.rotationRate.x + gyroData.rotationRate.y + gyroData.rotationRate.z
                if (val < 0) {
                    val = val * -1
                }
                if (maxVal < val) {
                    maxVal = val
                }
                print("This is the Max for Gyroskop: \(maxVal)")
                let f = Double(val).map(from: 0.0...CGFloat(maxVal), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)
            }
        case Status.Magnetometer:
            if let magnetometerData = motionManager.magnetometerData {
                print("MagnetoData: \(magnetometerData)")
                val = magnetometerData.magneticField.x + magnetometerData.magneticField.y + magnetometerData.magneticField.z
                if (val < 0) {
                    val = val * -1
                }
                if (maxVal < val) {
                    maxVal = val
                }
                print("This is the Max for Magnetormeter: \(maxVal)")
                let f = Double(val).map(from: 0.0...CGFloat(maxVal), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: val*10)
            }

        }
    }
    func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 5
        
        stackView.addArrangedSubview(AKSlider(
            property: "Delay Time",
            value: self.delay.time,
            format: "%0.2f s") { sliderValue in
                self.delay.time = sliderValue
        })
        
        stackView.addArrangedSubview(AKSlider(
            property: "Delay Feedback",
            value: self.delay.feedback,
            range: 0 ... 0.99,
            format: "%0.2f") { sliderValue in
                self.delay.feedback = sliderValue
        })
        
        stackView.addArrangedSubview(AKSlider(
            property: "Delay Mix",
            value: self.delayMixer.balance,
            format: "%0.2f") { sliderValue in
                self.delayMixer.balance = sliderValue
        })
        /*
        stackView.addArrangedSubview(AKSlider(
            property: "Reverb Feedback",
            value: self.reverb.feedback,
            range: 0 ... 0.99,
            format: "%0.2f") { sliderValue in
                self.reverb.feedback = sliderValue
        })
        
        stackView.addArrangedSubview(AKSlider(
            property: "Reverb Mix",
            value: self.reverbMixer.balance,
            format: "%0.2f") { sliderValue in
                self.reverbMixer.balance = sliderValue
        })
        
        stackView.addArrangedSubview(AKSlider(
            property: "Output Volume",
            value: self.booster.gain,
            range: 0 ... 2,
            format: "%0.2f") { sliderValue in
                self.booster.gain = sliderValue
        })
        */
        view.addSubview(stackView)
        
        stackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9).isActive = true
        stackView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.4).isActive = true
        
        stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
    
}
