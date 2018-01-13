//
//  ToneData.swift
//  AudioTest
//
//  Created by Marcel Pillich on 13.01.18.
//  Copyright © 2018 Marcel Pillich. All rights reserved.
//

import Foundation

class ToneData {
    var tone:(x: Double, y: Double, z: Double)
    
    init(tone:(x: Double, y: Double, z: Double)) {
        self.tone = tone
        print("\(tone) initialisiert")
    }
}
