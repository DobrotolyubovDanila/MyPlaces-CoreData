//
//  LocationDescription.swift
//  MyPlaces
//
//  Created by Данила on 10.04.2020.
//  Copyright © 2020 Данила. All rights reserved.
//

import Foundation

class LocationDescription {
    var name:String = ""
    var type:String?
    var location:String?
    var imageData: Data?
    
    convenience init(name: String, type: String?, location: String?, imageData: Data?) {
        self.init()
        self.name = name
        self.type = type
        self.location = location
        self.imageData = imageData
    }
}
