//
//  LocationData.swift
//  Record the Road
//
//  Created by 小駒翼 on 2021/03/29.
//  Copyright © 2021 Tsubasa Kogoma. All rights reserved.
//

import RealmSwift

// Realmの情報を格納する
class LocationData: Object {
    @objc dynamic var longitude = 0.0
    @objc dynamic var latitude = 0.0
    @objc dynamic var timestamp = Date()
}
