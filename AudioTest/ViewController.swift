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

class ViewController: UIViewController {
    let oscillator = AKOscillator()
    let motionManager = CMMotionManager()
    
    var timer: Timer!
    var x = 0.00;
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        AudioKit.output = oscillator
        AudioKit.start()
        oscillator.start()
        oscillator.rampTime = 0.2
        
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        update()
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeSoundFrequency(frequency: Double) {
        if (frequency < 15000) {
            oscillator.frequency = frequency
            print(frequency)
        }else {
            print("Frequency to High")
        }
    }
    
    func changeSoundAmplitude(amplitude: Double) {
        oscillator.amplitude = amplitude
    }
    
    
    @objc func update() {
        if let accelerometerData = motionManager.accelerometerData {
            print("AccelorometerData: \(accelerometerData)")
            x = accelerometerData.acceleration.x
            if (x < 0) {
                x = x * -1
                print(x*1000)
            }
            changeSoundFrequency(frequency: x*1000)//accelerometerData.acceleration.x * 10
            
        }
        if let gyroData = motionManager.gyroData {
            //print("Gyrodata: \(gyroData)")
        }
        if let magnetometerData = motionManager.magnetometerData {
            //print("MagnetoData: \(magnetometerData)")
        }
    }
    


}

