//
//  RegexHelpers.swift
//  DartsScoreVoice
//
//  Created by Bogdan Sukonnov on 2/22/20.
//  Copyright © 2020 Evermind. All rights reserved.
//

import Foundation

extension NSRegularExpression {
  
  convenience init?(options: SearchOptions) throws {
    let searchString = options.searchString
    let isCaseSensitive = options.matchCase
    let isWholeWords = options.wholeWords
    
    let regexOption: NSRegularExpression.Options = isCaseSensitive ? [] : .caseInsensitive
    
    let pattern = isWholeWords ? "\\b\(searchString)\\b" : searchString
    
    try self.init(pattern: pattern, options: regexOption)
  }
}
