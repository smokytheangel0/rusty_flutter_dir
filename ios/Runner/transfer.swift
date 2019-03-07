//
//  transfer.swift
//  Runner
//
//  Created by Jesse Abell on 05/03/2019.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Foundation

func transfer_to_rust(call_method: String, call_arguments: String) -> String {
    let function = call_method.cString(using: .utf8)
    let argument = call_arguments.cString(using: .utf8)
    //doesnt work here, we probably need to link the library somehow
    let result = rusted(function, argument)!
    let output = String(cString: result)
    return output
}
