//
//  Classes.swift
//  Record the Road
//
//  Created by 小駒翼 on 2020/08/19.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import MapKit
import RealmSwift

//通知関係の構造体
class NotificationStruct: NotificationProtocol {
    func notification(body: String, timeInterval: Double, title: String){
        let content = UNMutableNotificationContent()
        //通知メッセージ
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        //通知リクエストを作成して登録する
        let request = UNNotificationRequest(identifier: title, content: content, trigger: trigger)
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                print("error: \(error!)")
                // Handle any errors.
            }
        }
    }
}



class Alert: AlertProtocols {
    //通常バージョン
    func showAlert(viewController view: UIViewController, message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        alert.addAction(close)
        view.present(alert, animated: true, completion: nil)
    }
    
    
    //アクセス許可が降りていない時に設定画面へ飛ぶ処理
    func goToSettings(viewController view: UIViewController, message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        let close = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        let goToSettings = UIAlertAction(title: "設定へ移動", style: UIAlertAction.Style.default) { (UIAlertAction) in
            print("handler入りました")
            let url = URL(string:UIApplication.openSettingsURLString)! //URL取得
            UIApplication.shared.open(url, options: [:], completionHandler: nil) //URLを開く処理
        }
        alert.addAction(close)
        alert.addAction(goToSettings)
        view.present(alert, animated: true, completion: nil)
    }
}



class TimeRelationship {
    private var dateFormatter: DateFormatter = DateFormatter()
    
    func dateToString(date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    func stringToDate(stringDate: String) -> Date {
        let date = dateFormatter.date(from: stringDate)!
        return date
    }
    
    func difference(startDate: Date, endDate: Date) -> Int {
        //差分を出す
        let stayTime = endDate.timeIntervalSince(startDate)
        var intStayTime: Int { Int(stayTime) }
        return intStayTime
    }
}


//ピンの情報を格納する
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


class LocationData: Object {
    @objc dynamic var longitude = 0.0
    @objc dynamic var latitude = 0.0
    @objc dynamic var timestamp = Date()
}


class AboutLocation {
    //ピンを立てる
    static func raisePins(mapView: MKMapView, locationDatas: Results<LocationData>) {
        print("locationDatas: \(locationDatas)")
        let locationDatasCount = locationDatas.count
        var count = 0
        
        for locationData in locationDatas {
            //経度、緯度の取得
            //let latitude = locationData.latitude
            //let longitude = locationData.longitude
            //タイトルの取得
            //let timestamp = locationData.timestamp
//サブタイトルの取得
            guard locationDatasCount > 2 else { return print("dayLocationの数が足りません") } //配列の数が足らない時
            //到着時間の取得
            let arrival = locationDatas[count]
            let arrivalTime = arrival.timestamp
            //出発時間の取得
            count += 1
            let departureTime: Date!
            if (locationDatasCount - 1) <= count {
                departureTime = Date()
            } else {
                let departure = locationDatas[count]
                departureTime = departure.timestamp
            }
            
            //滞在時間の取得
            var stayTime: Int { Int(departureTime.timeIntervalSince(arrivalTime)) } //出発時間から到着時間を引く
            if stayTime < 300 { continue } //滞在時間が指定時間以下だった時は次の処理に移行する
            //ピンの追加
            var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: locationData.latitude, longitude: locationData.longitude) }//経度、緯度の取得
            let timeRelationship = TimeRelationship()
            var title: String { timeRelationship.dateToString(date: locationData.timestamp) }
            var subtitle: String { String(stayTime) }
            let spot = Spot(coordinate: coordinate, title: title, subtitle: subtitle)
            mapView.addAnnotation(spot)
            mapView.selectAnnotation(spot, animated: true)
        }
    }
    
    
}
