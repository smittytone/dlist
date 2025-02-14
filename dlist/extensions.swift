//
//  Extensions.swift
//  dlist
//
//  Created by Tony Smith on 13/02/2025.
//

import Foundation


extension NSDictionary {
    
    // Create a Swift Dictionary based on the instance's keys and valus
    var swiftDictionary: Dictionary<String, Any> {
        var swiftDictionary = Dictionary<String, Any>()

        for key : Any in self.allKeys {
            let stringKey = key as! String
            if let keyValue = self.value(forKey: stringKey){
                swiftDictionary[stringKey] = keyValue
            }
        }

        return swiftDictionary
    }
}
