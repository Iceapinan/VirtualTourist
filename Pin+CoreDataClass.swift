//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by IceApinan on 26/8/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//

import Foundation
import CoreData

public class Pin: NSManagedObject {
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
        self.init(entity: entity, insertInto: context)
        self.latitude = latitude
        self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
