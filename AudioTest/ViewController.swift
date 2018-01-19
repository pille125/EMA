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

extension UIButton {
    func setTitleWithoutAnimation(title: String?) {
        UIView.setAnimationsEnabled(false)
        setTitle(title, for: .normal)
        layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
    }
}

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
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
    let maxEffect = 1.0
    var toneData = [ToneData]()
    var record:Bool = false
    
    var timer: Timer!
    var valX = 0.00
    var valY = 0.00
    var valZ = 0.00
    var maxValX = 0.00
    var maxValY = 0.00
    var maxValZ = 0.00
    
    var wave = AKTable()
    var effect = AKReverb()
    var amp = 0.5
    var freq = 100.0
    var ramp = 0.0
    var eff = 0.0
    
    let effectList = ["Cathedral", "Large Hall", "Large Hall 2",
                   "Large Room", "Large Room 2", "Medium Chamber",
                   "Medium Hall", "Medium Hall 2", "Medium Hall 3",
                   "Medium Room", "Plate", "Small Room"]
    
    var status = Status.Gyroskop
    @IBOutlet weak var effectButton: UIButton!
    @IBOutlet weak var audioPlot: UIView!
    @IBOutlet weak var amplitudeLabel: UILabel!
    @IBOutlet weak var amplitudeSlider: UISlider!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencySlider: UISlider!
    @IBOutlet weak var rampTimeLabel: UILabel!
    @IBOutlet weak var rampTimeSlider: UISlider!
    @IBOutlet weak var effectMixLabel: UILabel!
    @IBOutlet weak var textBoxEffect: UITextField!
    @IBOutlet weak var dropDownEffect: UIPickerView!
    
  
    @IBAction func recordButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
        case "Record":
            record = true
            toneData.removeAll()
            sender.setTitleWithoutAnimation(title: "Stop Record")
            print("started recording")
        case "Stop Record":
            record = false
            sender.setTitleWithoutAnimation(title: "Record")
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
                sender.setTitleWithoutAnimation(title:"Stop")
            }
        
        case "Stop":
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
            sender.setTitleWithoutAnimation(title: "Play")
        default:
            print("unknown")
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        view.endEditing(true)
        return effectList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return effectList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch effectList[row] {
        case "Cathedral":
            effect.loadFactoryPreset(.cathedral)
        case "Large Hall":
            effect.loadFactoryPreset(.largeHall)
        case "Large Hall 2":
            effect.loadFactoryPreset(.largeHall2)
        case "Large Room":
            effect.loadFactoryPreset(.largeRoom)
        case "Large Room 2":
            effect.loadFactoryPreset(.largeRoom2)
        case "Medium Chamber":
            effect.loadFactoryPreset(.mediumChamber)
        case "Medium Hall":
            effect.loadFactoryPreset(.mediumHall)
        case "Medium Hall 2":
            effect.loadFactoryPreset(.mediumHall2)
        case "Medium Hall 3":
            effect.loadFactoryPreset(.mediumHall3)
        case "Medium Room":
            effect.loadFactoryPreset(.mediumRoom)
        case "Plate":
            effect.loadFactoryPreset(.plate)
        case "Small Room":
            effect.loadFactoryPreset(.smallRoom)
        default:
            break
        }
        effectButton.setTitleWithoutAnimation(title: effectList[row])
        dropDownEffect.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField  == textBoxEffect {
            dropDownEffect.isHidden = false
        }
    }
  
    @IBAction func effectButon(_ sender: UIButton) {
        if sender.titleLabel == effectButton.titleLabel {
        dropDownEffect.isHidden = false
        }
    }

    @IBAction func waveformButton(_ sender: UIButton) {
        switch sender.title(for: .normal)! {
        case "Sine":
            sender.setTitleWithoutAnimation(title: "Square")
            loadAudio(square)
            setupPlot()
        case "Square":
            sender.setTitleWithoutAnimation(title: "Triangle")
            loadAudio(triangle)
            setupPlot()
        case "Triangle":
            sender.setTitleWithoutAnimation(title: "Sawtooh")
            loadAudio(sawtooth)
            setupPlot()
        case "Sawtooh":
            sender.setTitleWithoutAnimation( title:"Sine")
            loadAudio(sine)
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
                sender.setTitleWithoutAnimation(title: "Accelerometer")
                motionManager.stopGyroUpdates()
                motionManager.startAccelerometerUpdates()
                status = Status.Accelerometer
                maxValX = 0.00
                maxValY = 0.00
            case "Accelerometer":
                print("accelerometer")
                sender.setTitleWithoutAnimation(title:"Magnetometer")
                motionManager.stopAccelerometerUpdates()
                motionManager.startMagnetometerUpdates()
                status = Status.Magnetometer
                maxValX = 0.00
                maxValY = 0.00
            case "Magnetometer":
                print("Magnetometer")
                sender.setTitleWithoutAnimation(title:"Gyroskop")
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
        effect = AKReverb(oscillator)
        effect.dryWetMix = 0.0
        AudioKit.output = effect
        AudioKit.start()
        oscillator.start()
        changeSoundAmplitude(amplitude: amp)
        changeSoundFrequency(frequency: freq)
        changeSoundRampTime(rampTime: ramp)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        motionManager.startGyroUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        loadAudio(sine)
        setupPlot()
    }
    
    func setupPlot() {
        let plot = AKNodeOutputPlot(oscillator, frame: audioPlot.bounds)
        plot.plotType = .rolling
        plot.shouldCenterYAxis = true
        plot.color = UIColor.blue
        audioPlot.addSubview(plot)
    }
    
    @IBAction func amplitudeValueChange(_ sender: UISlider) {
        let value = Double(sender.value)
        let y = Double(round(100*value)/100)
        amplitudeLabel.text = "Amplitude: \(y)"
        changeSoundAmplitude(amplitude: value)
    }
    
    @IBAction func frequnecyValueChange(_ sender: UISlider) {
        let value = Double(sender.value)
        let y = Double(round(100*value)/100)
        frequencyLabel.text = "Frequency: \(y)"
        changeSoundFrequency(frequency: value)
    }
    
    @IBAction func rampTimeValueChange(_ sender: UISlider) {
        let value = Double(sender.value)
        let y = Double(round(100*value)/100)
        rampTimeLabel.text = "Ramp Time: \(y)"
        changeSoundRampTime(rampTime: value)
        //oscillator.modulationIndex = value
    }
    
    @IBAction func effectMixValueChange(_ sender: UISlider) {
        let value = Double(sender.value)
        let y = Double(round(100*value)/100)
        effectMixLabel.text = "Mix: \(y)"
        changeEffectMix(mix: value)
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
    
    func changeEffectMix(mix: Double) {
        if (mix <= maxEffect) {
            effect.dryWetMix = mix
            eff = mix
        }else {
            print("Effect error")
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
                self.changeSoundRampTime(rampTime: tone.tone.z)
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
                valZ = accelerometerData.acceleration.z
                
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
                if (valZ < 0) {
                    valZ = valZ * -1
                }
                if (maxValZ < valZ) {
                    maxValZ = valZ
                }
                
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(a)")
                changeSoundAmplitude(amplitude: a)
                
                let r = Double(valZ).map(from: 0.0...CGFloat(maxValZ), to: 0.0...CGFloat(maxRampTime))
                print("mapped Ramp Time: \(a)")
                changeSoundRampTime(rampTime: r)
                
                if record == true {
                    toneData.append(ToneData(tone: (x: f, y: a, z: r)))
                }
            }
            
        case Status.Gyroskop:
            if let gyroData = motionManager.gyroData {
                //print("Gyrodata: \(gyroData)")
                valX = gyroData.rotationRate.x
                valY = gyroData.rotationRate.y
                valZ = gyroData.rotationRate.z
                
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
                if (valZ < 0) {
                    valZ = valZ * -1
                }
                if (maxValZ < valZ) {
                    maxValZ = valZ
                }
                
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: f)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(a)")
                changeSoundAmplitude(amplitude: a)
                
                let r = Double(valZ).map(from: 0.0...CGFloat(maxValZ), to: 0.0...CGFloat(maxRampTime))
                print("mapped Ramp Time: \(a)")
                changeSoundRampTime(rampTime: r)
                
                if record == true {
                    let tone = ToneData(tone: (x: f, y: a, z: r))
                    toneData.append(tone)
                    print("\(toneData.count) appended \(tone)")
                }
            }
            
        case Status.Magnetometer:
            if let magnetometerData = motionManager.magnetometerData {
                //print("MagnetoData: \(magnetometerData)")
                valX = magnetometerData.magneticField.x
                valY = magnetometerData.magneticField.y
                valZ = magnetometerData.magneticField.z
                
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
                if (valZ < 0) {
                    valZ = valZ * -1
                }
                if (maxValZ < valZ) {
                    maxValZ = valZ
                }
                
                let f = Double(valX).map(from: 0.0...CGFloat(maxValX), to: 20.0...CGFloat(maxFrequency))
                print("mapped Frequency: \(f)")
                changeSoundFrequency(frequency: valX*10)
                
                let a = Double(valY).map(from: 0.0...CGFloat(maxValY), to: 0.0...CGFloat(maxAmplitude))
                print("mapped Amplitude: \(a)")
                changeSoundAmplitude(amplitude: a)
                
                let r = Double(valZ).map(from: 0.0...CGFloat(maxValZ), to: 0.0...CGFloat(maxRampTime))
                print("mapped Ramp Time: \(a)")
                changeSoundRampTime(rampTime: r)
                
                if record == true {
                    toneData.append(ToneData(tone: (x: f, y: a, z: r)))
                }
            }
        }
    }
}
