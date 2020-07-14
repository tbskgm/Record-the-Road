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

class MapViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager: CLLocationManager = CLLocationManager()
    
    
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
        
        locationManager.pausesLocationUpdatesAutomatically = true //システムが自動で位置情報の取得を一時停止する(消費電力削減のため)
        
        mapView.showsCompass = true //コンパスを表示する
        mapView.showsUserLocation = true //ユーザーの位置を表示する
        /*列挙型が書かれているところから書くのか！初知り*/
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading //地図はユーザーの位置を追従し、見出しが変わると回転します。
        
        locationManager.allowsBackgroundLocationUpdates = true //backgroundでの位置情報更新を可能にする
        
        print("デバイスの位置が表示可能か: \(mapView.isUserLocationVisible)") //これが何の機能なのかイマイチわからない。
        
        
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
            print("restricted(機能が制限されている)")
            let alert: Alert = Alert()
            alert.showAlert(viewController: self, message: "アプリ起動中かつ許可がある時のみ記録できます")
            //locationManager.startUpdatingLocation() //精度が高いが、消費電力が多い
            locationManager.startMonitoringVisits() //位置情報を取得する
            
        case .authorizedWhenInUse:
            print("authorizedWhenInUse(このAppの使用中のみ許可)")
            let alert: Alert = Alert()
            alert.showAlert(viewController: self, message: "アプリが起動していない時に位置情報を記録できません")
            //locationManager.startUpdatingLocation() //精度が高いが、消費電力が多い
            locationManager.startMonitoringVisits() //位置情報を取得する
            
        case .authorizedAlways:
            print("authorizedAlways(常に許可)")
            //locationManager.startUpdatingLocation() //精度が高いが、消費電力が多い
            locationManager.startMonitoringVisits() //位置情報を取得する
            
        @unknown default:
            fatalError("想定外のケースを検出したのでアプリを終了します")
        }
    }
    
    
    //現在の位置に移動するボタン
    @IBAction func moveCurrentPositionButton(_ sender: Any) {
        /*列挙型が書かれているところから書くのか！初知り*/
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading //地図はユーザーの位置を追従し、見出しが変わると回転します。
        
    }
    
    
    //地図のタイプの変更
    @IBAction func changeMKMapTypeButton(_ sender: Any) {
        self.mapView.mapType = MKMapType.satellite //航空写真
        
    }
    
    
    
    
}


















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
