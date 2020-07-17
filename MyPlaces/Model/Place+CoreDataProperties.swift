//
//  Place+CoreDataProperties.swift
//  MyPlaces
//
//  Created by Данила on 10.04.2020.
//  Copyright © 2020 Данила. All rights reserved.
//
//

import Foundation
import CoreData


extension Place {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        return NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var rating: Double
    @NSManaged public var location: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var date: Date?

    convenience init(name:String, location:String?, imageData:Data?, type:String?, rating:Double){
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
}


