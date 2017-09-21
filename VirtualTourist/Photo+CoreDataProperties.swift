//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by IceApinan on 19/9/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var pageNumber: Int32
    @NSManaged public var photo: NSData?
    @NSManaged public var url: String

}
