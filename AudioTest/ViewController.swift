//
//  ViewController.swift
//  AudioTest
//
//  Created by Marcel Pillich on 19.10.17.
//  Copyright © 2017 Marcel Pillich. All rights reserved.
//

import UIKit

import AudioKit
import AudioKitUI
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
    let maxAmplitude = 10.0
    
    var timer: Timer!
    var valX = 0.00
    var valY = 0.00
    var maxValX = 0.00
    var maxValY = 0.00
    
    var status = Status.Gyroskop
    
    @IBOutlet weak var audioPlot: UIView!
    
    
    //Loop through the different sensors bei pressing the button
    @IBAction func modeButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
            case "Gyroskop":
                print("gyro")
                sender.setTitle("Accelerometer", for: .normal)
                motionManager.stopGyroUpdates()
                motionManager.startAccelerometerUpdates()
                status = Status.Accelerometer
                maxValX = 0.00
                maxValY = 0.00
            case "Accelerometer":
                print("accelerometer")
                sender.setTitle("Magnetometer", for: .normal)
                motionManager.stopAccelerometerUpdates()
                motionManager.startMagnetometerUpdates()
                status = Status.Magnetometer
                maxValX = 0.00
                maxValY = 0.00
            case "Magnetometer":
                print("Magnetometer")
                sender.setTitle("Gyroskop", for: .normal)
                motionManager.stopMagnetometerUpdates()
                motionManager.startGyroUpdates()
                status = Status.Gyroskop
                maxValX = 0.00
                maxValY = 0.00
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
        setupPlot()
        
        delay = AKVariableDelay(input)
        delay.rampTime = 0.5 // Allows for some cool effects
        delayMixer = AKDryWetMixer(input, delay)
        
        reverb = AKCostelloReverb(delayMixer)
        reverbMixer = AKDryWetMixer(delayMixer, reverb)
        
        booster = AKBooster(reverbMixer)
        
        AudioKit.output = booster
        setupUI()
    }
    
    func setupPlot() {
        let plot = AKNodeOutputPlot(oscillator, frame:  CGRect(x: 0, y: 0, width: 440, height: 300))
        plot.plotType = .rolling
        //plot.shouldFill = true
        //plot.shouldMirror = true
        plot.shouldCenterYAxis = true
        plot.color = UIColor.blue
        audioPlot.addSubview(plot)
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
        if (amplitude < maxAmplitude) {
            oscillator.amplitude = amplitude
        }
    }
    
    @objc
    func update() {
        switch status {
        case Status.Accelerometer:
            if let accelerometerData = motionManager.accelerometerData {
                print("AccelorometerData: \(accelerometerData)")
                valX = accelerometerData.acceleration.x
                valY = accelerometerData.acceleration.y
                
                if (valX < 0) {
                    valX = valX * -1
                }
                if (maxValX < valX) {
                    maxValX = valX
                }
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(a)")
                changeSoundAmplitude(amplitude: a)
            }
        case Status.Gyroskop:
            if let gyroData = motionManager.gyroData {
                print("Gyrodata: \(gyroData)")
                valX = gyroData.rotationRate.x
                if (valX < 0) {
                    valX = valX * -1
                }
                if (maxValX < valX) {
                    maxValX = valX
                }
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(f)")
                changeSoundAmplitude(amplitude: a)
            }
        case Status.Magnetometer:
            if let magnetometerData = motionManager.magnetometerData {
                print("MagnetoData: \(magnetometerData)")
                valX = magnetometerData.magneticField.x
                
                if (valX < 0) {
                    valX = valX * -1
                }
                if (maxValX < valX) {
                    maxValX = valX
                }
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: valX*10)
            }
        }
    }
}
