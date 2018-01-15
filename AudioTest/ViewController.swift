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
    
    var oscillator = AKOscillator()
    //let oscillator = AKFMOscillator()
    
    let triangle = AKTable(.triangle, count: 256)
    let square = AKTable(.square, count: 256)
    let sawtooth = AKTable(.sawtooth, count: 256)
    let sine = AKTable(.sine, count: 256)
    
    let motionManager = CMMotionManager()
    let maxFrequency = 2000.0
    let maxAmplitude = 1.0
    let maxRampTime = 5.0
    var toneData = [ToneData]()
    var record:Bool = false
    
    var timer: Timer!
    var valX = 0.00
    var valY = 0.00
    var maxValX = 0.00
    var maxValY = 0.00
    
    var wave = AKTable()
    
    var amp = 0.5
    var freq = 100.0
    var ramp = 0.0
    
    var status = Status.Gyroskop
    
    @IBOutlet weak var audioPlot: UIView!
    @IBOutlet weak var amplitudeLabel: UILabel!
    @IBOutlet weak var amplitudeSlider: UISlider!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencySlider: UISlider!
    @IBOutlet weak var rampTimeLabel: UILabel!
    @IBOutlet weak var rampTimeSlider: UISlider!
    
    @IBAction func recordButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
        case "Record":
            record = true
            toneData.removeAll()
            sender.setTitle("Stop Record", for: .normal)
            print("started recording")
        case "Stop Record":
            record = false
            sender.setTitle("Record", for: .normal)
            print("Stopped recording, record time: \(toneData.count * 0.5) seconds")
        default:
            print("Unknown")
        }
    }
    
    @IBAction func playButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
        case "Play":
            if record == false && toneData.count > 0 {
                timer.invalidate()
                playRecord()
                sender.setTitle("Stop", for: .normal)
            }
        
        case "Stop":
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
            sender.setTitle("Play", for: .normal)
        default:
            print("unknown")
        }
    }
    
    @IBAction func waveformButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
        case "Sine":
            loadAudio(sine)
            sender.setTitle("Square", for: .normal)
            print("Sine")
            setupPlot()
        case "Square":
            loadAudio(square)
            sender.setTitle("Triangle", for: .normal)
            print("Square")
            setupPlot()
        case "Triangle":
            loadAudio(triangle)
            sender.setTitle("Sawtooh", for: .normal)
            print("Triangle")
            setupPlot()
        case "Sawtooh":
            loadAudio(sawtooth)
            sender.setTitle("Sine", for: .normal)
            print("Sawtooh")
            setupPlot()
        default:
            print("No waveforms!")
        }
    }
  
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
    
    
    func loadAudio(_ wave: AKTable) {
        oscillator.stop()
        AudioKit.stop()
        oscillator = AKOscillator(waveform: wave)
        AudioKit.output = oscillator
        AudioKit.start()
        oscillator.start()
        changeSoundAmplitude(amplitude: amp)
        changeSoundFrequency(frequency: freq)
        changeSoundRampTime(rampTime: ramp)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        //oscillator = AKOscillator(waveform: square)
        //loadAudio(sine)
        
        //motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        setupPlot()
    }
    
    func setupPlot() {
        let plot = AKNodeOutputPlot(oscillator, frame:  CGRect(x: 0, y: 0, width: 280, height: 200))
        plot.plotType = .rolling
        //plot.shouldFill = true
        //plot.shouldMirror = true
        plot.shouldCenterYAxis = true
        plot.color = UIColor.blue
        audioPlot.addSubview(plot)
    }
    

    @IBAction func amplitudeValueChange(_ sender: UISlider) {
        let value = Double(sender.value)
        amplitudeLabel.text = "\(value)"
        changeSoundAmplitude(amplitude: value)
    }
    
   
    @IBAction func frequnecyValueChange(_ sender: UISlider) {
        let value = Double(sender.value)
        frequencyLabel.text = "\(value)"
        changeSoundFrequency(frequency: value)
    }
    
  
    @IBAction func rampTimeValueChange(_ sender: UISlider) {
        let value = Double(sender.value)
        rampTimeLabel.text = "\(value)"
        changeSoundRampTime(rampTime: value)
        //oscillator.modulationIndex = value
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeSoundFrequency(frequency: Double) {
        if (frequency <= maxFrequency) {
            oscillator.frequency = frequency
             freq = frequency
            //oscillator.baseFrequency = frequency
        }else {
            print("Frequency to High")
        }
    }
    
    func changeSoundAmplitude(amplitude: Double) {
        if (amplitude <= maxAmplitude) {
            oscillator.amplitude = amplitude
            amp = amplitude
        }else {
            print("Amplitude to High")
        }
        
    }
    
    func changeSoundRampTime(rampTime: Double) {
        if (rampTime <= maxRampTime) {
            oscillator.rampTime = rampTime
            ramp = rampTime
        }else {
            print("Ramp Time to High")
        }
    }

    func playRecord() {
        var time = 0.0
        for tone in toneData {
            let when = DispatchTime.now() + time
            time += 0.5
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.changeSoundFrequency(frequency: tone.tone.x)
                self.changeSoundAmplitude(amplitude: tone.tone.y)
            }
        }
    }
    
    @objc
    func update() {
        switch status {
        case Status.Accelerometer:
            if let accelerometerData = motionManager.accelerometerData {
                //print("AccelorometerData: \(accelerometerData)")
                valX = accelerometerData.acceleration.x
                valY = accelerometerData.acceleration.y
                
                if (valX < 0) {
                    valX = valX * -1
                }
                if (maxValX < valX) {
                    maxValX = valX
                }
                if (valY < 0) {
                    valY = valY * -1
                }
                if (maxValY < valY) {
                    maxValY = valY
                }
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(a)")
                changeSoundAmplitude(amplitude: a)
                
                if record == true {
                    toneData.append(ToneData(tone: (x: f, y: a, z: 0.0)))
                }
                
            }
        case Status.Gyroskop:
            if let gyroData = motionManager.gyroData {
                //print("Gyrodata: \(gyroData)")
                valX = gyroData.rotationRate.x
                valY = gyroData.rotationRate.y
                
                if (valX < 0) {
                    valX = valX * -1
                }
                if (maxValX < valX) {
                    maxValX = valX
                }
                if (valY < 0) {
                    valY = valY * -1
                }
                if (maxValY < valY) {
                    maxValY = valY
                }
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(a)")
                changeSoundAmplitude(amplitude: a)
                
                if record == true {
                    toneData.append(ToneData(tone: (x: f, y: a, z: 0.0)))
                }
            }
        case Status.Magnetometer:
            if let magnetometerData = motionManager.magnetometerData {
                //print("MagnetoData: \(magnetometerData)")
                valX = magnetometerData.magneticField.x
                valY = magnetometerData.magneticField.y
                
                if (valX < 0) {
                    valX = valX * -1
                }
                if (maxValX < valX) {
                    maxValX = valX
                }
                if (valY < 0) {
                    valY = valY * -1
                }
                if (maxValY < valY) {
                    maxValY = valY
                }
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: valX*10)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(a)")
                changeSoundAmplitude(amplitude: a)
                
                if record == true {
                    toneData.append(ToneData(tone: (x: f, y: a, z: 0.0)))
                }
            }
        }
    }
}
