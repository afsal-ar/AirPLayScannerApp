//
//  AirplayDevice+CoreDataProperties.swift
//  IPListApp
//
//  Created by Afsal  on 27/08/24.
//
//

import Foundation
import CoreData


extension AirplayDevice {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AirplayDevice> {
        return NSFetchRequest<AirplayDevice>(entityName: "AirplayDevice")
    }

    @NSManaged public var deviceName: String?
    @NSManaged public var ipAddress: String?
    @NSManaged public var status: String?

}

extension AirplayDevice : Identifiable {

}
