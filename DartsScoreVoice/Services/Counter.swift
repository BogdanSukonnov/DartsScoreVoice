//
//  Counter.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/16/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import Foundation

class Counter: ObservableObject {
    
    @Published var count = "initial count"
    
    init() {
        
    }
    
    func add(text: String) {
        self.count = self.count + "; " + text;
        print("COUNT: " + self.count)
    }
}
