//
//  ATSignal.swift
//  Pods
//
//  Created by Tuan Phung on 1/10/16.
//
//

import Foundation

open class ATSignal {
    open var identifier: String
    open var associatedObject: Any?
    
    init(identifider: String, associatedObject: Any?) {
        self.identifier = identifider
        self.associatedObject = associatedObject
    }
}
