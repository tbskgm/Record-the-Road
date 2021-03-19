//
//  DataStruct.swift
//  Record the Road
//
//  Created by 小駒翼 on 2021/01/15.
//  Copyright © 2021 Tsubasa Kogoma. All rights reserved.
//


import MapKit
import RealmSwift


// ピンの情報を格納する
class Spot: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}


// Realmの情報を格納する
class LocationData: Object {
    @objc dynamic var longitude = 0.0
    @objc dynamic var latitude = 0.0
    @objc dynamic var timestamp = Date()
}


