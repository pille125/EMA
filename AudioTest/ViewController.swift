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
    
    enum Status: String {
        case Gyroskop = "Gyroskop"
        case Accelerometer = "Accelerometer"
        case Magnetometer = "Magnetometer"
    }
    
    let oscillator = AKOscillator()
    let motionManager = CMMotionManager()
    
    var timer: Timer!
    var x = 0.00;
    var status = Status.Gyroskop
    
    //Loop through the different sensors bei pressing the button
    @IBAction func modeButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
            case "Gyroskop":
                print("gyro")
                sender.setTitle("Accelerometer", for: .normal)
                motionManager.stopGyroUpdates()
                motionManager.startAccelerometerUpdates()
                status = Status.Accelerometer
            case "Accelerometer":
                print("accelerometer")
                sender.setTitle("Magnetometer", for: .normal)
                motionManager.stopAccelerometerUpdates()
                motionManager.startMagnetometerUpdates()
                status = Status.Magnetometer
            case "Magnetometer":
                print("Magnetometer")
                sender.setTitle("Gyroskop", for: .normal)
                motionManager.stopMagnetometerUpdates()
                motionManager.startGyroUpdates()
                status = Status.Gyroskop
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
        switch status {
        case Status.Accelerometer:
            if let accelerometerData = motionManager.accelerometerData {
                print("AccelorometerData: \(accelerometerData)")
                x = accelerometerData.acceleration.x
                if (x < 0) {
                    x = x * -1
                    print(x*1000)
                }
                changeSoundFrequency(frequency: x*1000)//accelerometerData.acceleration.x * 10
            }
        case Status.Gyroskop:
            if let gyroData = motionManager.gyroData {
                print("Gyrodata: \(gyroData)")
                x = gyroData.rotationRate.x
                if (x < 0) {
                    x = x * -1
                    print(x*100)
                }
                changeSoundFrequency(frequency: x*100)
            }
        case Status.Magnetometer:
            if let magnetometerData = motionManager.magnetometerData {
                print("MagnetoData: \(magnetometerData)")
                x = magnetometerData.magneticField.x
                if (x < 0) {
                    x = x * -1
                    print(x*10)
                }
                changeSoundFrequency(frequency: x*10)
            }

        }
    }
}
