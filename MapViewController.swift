//
//  ViewController.swift
//  Record the Road
//
//  Created by 小駒翼 on 2020/06/30.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeView: UIView!
    @IBOutlet weak var mapTypeSegmentButton: UISegmentedControl!
    
    let locationManager: CLLocationManager = CLLocationManager()
    var recordTheRoad = [[String: Any]]() //位置情報を記録する
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self //locationManagerを自身で操作できるようにする
        
        // 通知の許可を求める
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
        }
        
        //通知を飛ばす処理
        let notification = NotificationStruct()
        notification.notification(body: "おはよう", timeInterval: 10, title: "テスト") //テスト用
        
        getAuthorizationStatus() //位置情報へのアクセス状態の確認及びそれぞれの場合の処理の実行
        
        mapTypeView.isHidden = true //mapTypeViewを隠す
        
        //segmentIndexを取り出す
        let userDefaults: UserDefaults = UserDefaults.standard
        if let storedSegmentIndex = userDefaults.object(forKey: "segmentIndex") as? Int {
            mapTypeSegmentButton.selectedSegmentIndex = storedSegmentIndex //segmentに前回設定された値を入れる
            switch storedSegmentIndex {
            case 0:
                mapView.mapType = .standard
            case 1:
                mapView.mapType = .hybrid
            default:
                fatalError("想定外の値の検出")
            }
            
            
        }
        
        //保存された記録を追加する
        if let storedCollectedInfomations = userDefaults.object(forKey: "collectedInfomation") as? [[String: Any]] {
           for storedCollectedInfomation in storedCollectedInfomations {
                recordTheRoad.append(storedCollectedInfomation)
            }
            print(recordTheRoad.count)
            print(recordTheRoad)
        } else {
            print("else!!")
        }
        
        
        //print("viewDidLoad終了")
    }
    
    
    //位置情報の取得に失敗すると呼ばれる
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("@x.更新を失敗しました。")
        if let clError = error as? CLError {
            switch clError {
            case CLError.locationUnknown:
                print("location unknown")
            case CLError.denied:
                print("denied")
            default:
                print("other Core Location error")
            }
        } else {
            print("other error:", error.localizedDescription)
        }
    }
    
    //位置情報が取得されると呼ばれる
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        print("@x.更新を成功しました。")
        locationManager処理()
        
    }
    
    
    func locationManager処理() {
        print("@x.location: \(String(describing: locationManager.location))")
        print("@x.haeding: \(String(describing: locationManager.heading))")
        //経度、緯度の取得
        let location = locationManager.location
        guard let latlng = location?.coordinate else {
            print("returnされました")
            return
        }
        let latitude = latlng.latitude
        let longitude = latlng.longitude
        print("現在地: \n経度: \(String(describing: latitude))\n経度: \(String(describing: longitude))")
        //時間の取得
        let timeRelationship = TimeRelationship()
        let date: Date = timeRelationship.getNowTime
        print(String(describing: date))
        //保存処理
        let collectedInfomation: [String: Any] = ["latitude": latitude, "longitude": longitude, "date": date]
        recordTheRoad.append(collectedInfomation)
        print("array: \(recordTheRoad)")
        let userDefaults: UserDefaults = UserDefaults.standard
        userDefaults.set(recordTheRoad, forKey: "collectedInfomation")
        userDefaults.synchronize()
        
    }
    
    
    //地図タイプを変更するUIViewを表示するボタン
    @IBAction func changeMKMapTypeButton(_ sender: Any) {
        
        guard mapTypeView.isHidden == true else {
            return mapTypeView.isHidden = true
        }
        return mapTypeView.isHidden = false
    }
    
    
    
    //番号によって地図タイプを変更する
    @IBAction func mapTypeSegumentedButton(_ sender: UISegmentedControl) {
        //print("mapTypeSegumentedButton開始")
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = MKMapType.standard //標準的な地図に変更 /*列挙型が書かれているところから書くのか！初知り*/
            //mapTypeの保存
            let userDefatuls: UserDefaults = UserDefaults.standard
            let segmentIndex: Int = 0
            userDefatuls.set(segmentIndex, forKey: "segmentIndex")
            userDefatuls.synchronize()
            
        case 1:
            mapView.mapType = MKMapType.hybrid /*列挙型が書かれているところから書くのか！初知り*/
            //mapTypeの保存
            let userDefatuls: UserDefaults = UserDefaults.standard
            let segmentIndex: Int = 1
            userDefatuls.set(segmentIndex, forKey: "segmentIndex")
            userDefatuls.synchronize()
            
        default:
            fatalError("segmentの数が増えているので修正してください")
        }
    }
    
    //位置情報取得できる時の共通処理
    func getLocation() {
        locationManager.startMonitoringVisits() //位置情報を取得する
        //locationManager.startUpdatingLocation()
        //locationManager.startMonitoringSignificantLocationChanges() //位置情報取得
        mapView.userTrackingMode = MKUserTrackingMode.follow //地図はユーザーの位置を追従し、見出しが変わると回転します。
        locationManager.allowsBackgroundLocationUpdates = true //backgroundでの位置情報更新を可能にする
        locationManager.startUpdatingHeading() //方角の取得
        /*位置情報の取得を邪魔しなければtrueにする*/
        //locationManager.pausesLocationUpdatesAutomatically = true //システムが自動で位置情報の取得を一時停止する(消費電力削減のため)
        
    }
    
    //認証状況を確認して、位置情報へのアクセスを許可されてなかった場合は許可を得る
    func getAuthorizationStatus() {
        let status = CLLocationManager.authorizationStatus()
        /*列挙型化したい*/
        switch status {
        case .notDetermined:
            print("notDetermined(未設定)")
            locationManager.requestWhenInUseAuthorization() //位置情報へのアクセスをユーザーに求める
            
        case .denied:
            print("denied(許可していない)")
            let alert: Alert = Alert()
            alert.showAlert(viewController: self, message: "位置情報へのアクセスが許可されていません！") //許可されてないことを伝える
            
        case .restricted:
            print("restricted(一度だけ許可)")
            let alert: Alert = Alert()
            alert.showAlert(viewController: self, message: "アプリ起動中かつ許可がある時のみ記録できます")
            getLocation()
            
        case .authorizedWhenInUse:
            print("authorizedWhenInUse(このAppの使用中のみ許可)")
            let alert: Alert = Alert()
            alert.showAlert(viewController: self, message: "アプリが起動していない時に位置情報を記録できません")
            getLocation()
            
        case .authorizedAlways:
            print("authorizedAlways(常に許可)")
            getLocation()
            
        @unknown default:
            fatalError("想定外のケースを検出したのでアプリを終了します")
        }
    }
    
    
    //現在の位置に移動するボタン
    @IBAction func moveCurrentPositionButton(_ sender: Any) {
        mapView.userTrackingMode = MKUserTrackingMode.follow //地図はユーザーの位置を追従します
        
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        mapTypeView.isHidden = true
    }
    
    
    @IBAction func button(_ sender: Any) {
        print(recordTheRoad)
        print(recordTheRoad.count)
        
    }
    
    
    @IBAction func settingsButton(_ sender: Any) {
        locationManager処理()
    }
    
    
}

/*
class RecordLocation: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool {
        return true
    }
    
    var locations: [CLLocation]? //
    
    override init() {}
    
    required init?(coder Decoder: NSCoder) {
        locations = Decoder.decodeObject(forKey: "recordTheRoad") as? [CLLocation]
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(locations, forKey: "recordTheRoad")
    }
    
}*/


protocol NotificationProtocol {
    func notification(body: String, timeInterval: Double, title: String)
}


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

class Alert {
    //通常バージョン
    func showAlert(viewController view: UIViewController, message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        alert.addAction(close)
        view.present(alert, animated: true, completion: nil)
    }
}
class TimeRelationship {
    var dateFormatter: DateFormatter = DateFormatter()
    //時差を加算
    var getNowTime: Date{
        let date : Date = Date()
        print("date: \(date)")
        //let dateFormatter: DateFormatter = DateFormatter()
        //dateFormatter.locale = Locale(identifier: "ja_JP") //表示方法のカスタマイズ
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: Int(TimeZone.current.secondsFromGMT()))
        //dateFormatter.timeZone = TimeZone.current
        let q = dateFormatter.string(from: date)
        print("date.string: \(dateFormatter.string(from: date))")
        print("date.date: \(dateFormatter.date(from: q)!)")
        return dateFormatter.date(from: q)!
        
    }
    
}
