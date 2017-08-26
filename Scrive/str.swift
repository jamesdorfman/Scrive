//
//  str.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-07-24.
//  Copyright © 2017 James Dorfman. All rights reserved.
//

import Foundation

extension String {
    var lines: [String] {
        var result: [String] = []
        enumerateLines { line, _ in result.append(line) }
        return result
    }
}
