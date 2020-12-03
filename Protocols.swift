//
//  Protocols.swift
//  Record the Road
//
//  Created by 小駒翼 on 2020/08/20.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import UIKit

protocol NotificationProtocol {
    func notification(body: String, timeInterval: Double, title: String)
}

protocol AlertProtocols {
    func showAlert(viewController view: UIViewController, message: String)
    
    func goToSettings(viewController view: UIViewController, message: String)
}

protocol TimeRealtionshipProtocols {
    var dateFormatter: DateFormatter { get }
    
    func dateToString(date: Date) -> String
    
    func stringToDate(stringDate: String) -> Date
    
    func difference(startDate: Date, endDate: Date) -> Int
}
