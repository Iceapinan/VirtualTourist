//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by IceApinan on 26/8/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public class Photo: NSManagedObject {
 
    convenience init(pin: Pin, url: URL, pageNumber: Int32, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.url = url.absoluteString
            self.pageNumber = pageNumber
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    convenience init(photo: NSData, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.photo = photo
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
}
