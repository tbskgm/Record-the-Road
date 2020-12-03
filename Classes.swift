//
//  Classes.swift
//  Record the Road
//
//  Created by 小駒翼 on 2020/08/19.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import MapKit


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
        let intervalStayTime = endDate.timeIntervalSince(startDate)
        var intStayTime: Int { Int(intervalStayTime) }
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


//
class A: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }
    
    var longitude: CLLocationDegrees!
    
    var latitude: CLLocationDegrees!
    
    var timestamp: Date!
    
    var stayTime: Int?
    
    override init() {}
    
    func encode(with decoder: NSCoder) {
        longitude = (decoder.decodeObject(forKey: "longitude") as! CLLocationDegrees)
        latitude = (decoder.decodeObject(forKey: "latitude") as! CLLocationDegrees)
        timestamp = (decoder.decodeObject(forKey: "timestamp") as! Date)
        stayTime = decoder.decodeObject(forKey: "stayTime") as? Int
    }
    
    required init(coder: NSCoder) {
        coder.encode(longitude, forKey: "longitude")
        coder.encode(latitude, forKey: "latitude")
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(stayTime, forKey: "stayTime")
    }
    
    
}
/*
 class TableViewList: NSObject, NSSecureCoding {
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    var title: String = ""
    
    var time: Int = 0
    
    override init() {}
    
    required init(coder decoder: NSCoder) {
        title = decoder.decodeObject(forKey: "targetTitle") as! String
        //time = decoder.decodeObject(forKey: "targetTime")
        time = decoder.decodeInteger(forKey: "targetTime")
        
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(title, forKey: "targetTitle")
        coder.encode(time, forKey: "targetTime")
    }
}*/


class AboutLocation {
    func getLocationData() -> [[String: Any]]? {
        let userDefaults: UserDefaults = UserDefaults.standard
        guard let storedCollectedInfomations = userDefaults.object(forKey: "collectedInfomation") as? [[String: Any]] else {
            print("collectedInfomationの値が存在しませんでした")
            return nil
        }
        
        let storedCollectedInfomationsCount = storedCollectedInfomations.count
        var count = 0
        var collectedInfomations: [[String: Any]] = []
        
        for storedCollectedInfomation in storedCollectedInfomations {
            //経度、緯度の取得
            let latitude = storedCollectedInfomation["latitude"] as! CLLocationDegrees //経度の取得
            let longitude = storedCollectedInfomation["longitude"] as! CLLocationDegrees //緯度の取得
            
            //タイトルの取得
            let date = storedCollectedInfomation["timestamp"] as! Date
            
            //サブタイトルの取得
            guard storedCollectedInfomationsCount > 2 else { //配列の数が足らない時
                print("storedCollectedInfomationの数が足りません")
                return nil
            }
            
            //到着時間の取得
            let arrival = storedCollectedInfomations[count]
            let arrivalTime = arrival["timestamp"] as! Date
            
            //出発時間の取得
            count += 1
            /*guard (storedCollectedInfomationsCount - 1) != count else { //すべての配列を記録した後に配列外を参照しないため
             //終了処理
             //continue
             break /*関数自体から抜けてしまう場合はcotinueにする*/
             }*/
            let timestamp: Date!
            if (storedCollectedInfomationsCount - 1) == count || (storedCollectedInfomationsCount - 1) < count {
                let nowDate = Date()
                timestamp = nowDate
            } else {
                let departure = storedCollectedInfomations[count]
                timestamp = (departure["timestamp"] as! Date)
            }
            let departureTime: Date = timestamp
            print("departureTime: \(departureTime)")
            //滞在時間の取得
            var stayTime: Int { Int(departureTime.timeIntervalSince(arrivalTime)) } //出発時間から到着時間を引く
            if stayTime < 600 { //滞在時間が指定時間以下だった時は次の処理に移行する
                continue
            }
            print("class.stayTime: \(stayTime)")
            /*ここから下がreturnするもの*/
            let collectedInfomation: [String: Any] = ["longitude": longitude, "latitude": latitude, "timestamp": date, "stayTime": stayTime] //情報をまとめる
            collectedInfomations.append(collectedInfomation) //位置情報を記録する
            
        }
        //print("全ての滞在時間を算出しました")
        //let userDefaults: UserDefaults = UserDefaults.standard
        //userDefaults.set(collectedInfomations, forKey: "collectedInfomation")
        return collectedInfomations
    }
}
