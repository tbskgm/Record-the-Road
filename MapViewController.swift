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
import RealmSwift

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeView: UIView!
    @IBOutlet weak var mapTypeSegmentButton: UISegmentedControl!
    
    let locationManager: CLLocationManager = CLLocationManager()
    var moniteringRegion: CLCircularRegion = CLCircularRegion()
    //var recordTheRoad = [[String: Any]]() //位置情報を記録する    /*支障がなければ削除*/
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self //locationManagerを自身で操作できるようにする
        getAuthorizationStatus() //位置情報へのアクセス状態の確認及びそれぞれの場合の処理の実行
        mapTypeView.isHidden = true //mapTypeViewを隠す
        
        // 通知の許可を求める
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("通知許可で出ました")
            } else {
                print("通知許可が出ませんでした")
            }
        }
        
        //通知を飛ばす処理
        let notification = NotificationStruct()
        notification.notification(body: "おはよう", timeInterval: 10, title: "テスト") //テスト用
        
        
        //segmentIndexを取り出す
        let userDefaults: UserDefaults = UserDefaults.standard
        if let storedSegmentIndex = userDefaults.object(forKey: "segmentIndex") as? Int {
            mapTypeSegmentButton.selectedSegmentIndex = storedSegmentIndex //segmentに前回設定された値を入れる
            switch storedSegmentIndex {
            case 0: mapView.mapType = .standard
            case 1: mapView.mapType = .hybrid
            default: fatalError("想定外の値の検出") }
        }
        
        
        //保存された記録を追加する
        let realm = try! Realm()
        let storedData = realm.objects(LocationData.self)
        print("storedData: \(storedData)")
        //recordTheRoad.append(storedData)
        
        
        //ユーザーが位置情報の利用を許可しているか
        guard CLLocationManager.locationServicesEnabled() else {
            let alert = Alert()
            return alert.showAlert(viewController: self, message: "位置情報がオン出ないと位置情報を記録することができません。") //ユーザーに位置情報を利用できるように求める
        }
        
        //ピンの追加
        AboutLocation.getLocationData(mapView: mapView)
        
    }
    
    
    /*特定の場所に移動したら動くまで待機する*/
    /*fileprivate func geofence(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: CLLocationDistance, identifier: String) {
        // 中心位置の設定(緯度・経度)
        let moniteringCordinate = CLLocationCoordinate2DMake(latitude, longitude)
        // モニタリング領域を作成
        moniteringRegion = CLCircularRegion.init(center: moniteringCordinate, radius: radius, identifier: identifier)
        
        // モニタリング開始
        self.locationManager.startMonitoring(for: self.moniteringRegion)

        // モニタリング停止
        //self.locationManager.stopMonitoring(for: self.moniteringRegion)

        // 現在の状態(領域内or領域外)を取得
        self.locationManager.requestState(for: self.moniteringRegion)
    }*/
    
    
    //番号によって地図タイプを変更する
    @IBAction func mapTypeSegumentedButton(_ sender: UISegmentedControl) {
        //print("mapTypeSegumentedButton開始")
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = MKMapType.standard //標準的な地図に変更 /*列挙型が書かれているところから書くのか！初知り*/
            let userDefatuls: UserDefaults = UserDefaults.standard
            let segmentIndex: Int = 0
            userDefatuls.set(segmentIndex, forKey: "segmentIndex") //mapTypeの保存
            //userDefatuls.synchronize()
            
        case 1:
            mapView.mapType = MKMapType.hybrid /*列挙型が書かれているところから書くのか！初知り*/
            let userDefatuls: UserDefaults = UserDefaults.standard
            let segmentIndex: Int = 1
            userDefatuls.set(segmentIndex, forKey: "segmentIndex") //mapTypeの保存
            //userDefatuls.synchronize()
            
        default:
            fatalError("segmentの数が増えているので修正してください")
        }
        UserDefaults.standard.synchronize()
    }
    
    
    //位置情報取得できる時の共通処理
    func getLocation() {
        /*滞在時間が存在しないログを無くすためにChangesをテストしている*/
        //locationManager.startUpdatingLocation() //位置情報取得
        locationManager.startMonitoringSignificantLocationChanges() //大幅な移動があった場合更新する
        mapView.userTrackingMode = MKUserTrackingMode.follow //地図はユーザーの位置を追従する
        locationManager.allowsBackgroundLocationUpdates = true //backgroundでの位置情報更新を可能にする
        let backgroundLocationIndicator = locationManager.showsBackgroundLocationIndicator //background時外観ステータスバーを変更するかどうか
        locationManager.distanceFilter = 500 //更新イベントに必要な最低距離
        print("backgroundLocationIndicator: \(backgroundLocationIndicator)") /*何に使うのか謎*/
        //locationManager.startUpdatingHeading() //方角の取得
        locationManager.pausesLocationUpdatesAutomatically = true //システムが自動で位置情報の取得を一時停止する(消費電力削減のため)
    }
    
    
    //認証状況を確認して、位置情報へのアクセスを許可されてなかった場合は許可を得る
    func getAuthorizationStatus() {
        let status = CLLocationManager.authorizationStatus()
        /*列挙型化したい*/
        switch status {
        case .notDetermined:
            print("notDetermined(未設定)")
            //locationManager.requestWhenInUseAuthorization() //位置情報へのアクセスをユーザーに求める
            locationManager.requestAlwaysAuthorization()
            
        case .denied:
            print("denied(許可していない)")
            let alert: Alert = Alert()
            alert.goToSettings(viewController: self, message: "このサービスを利用するには、端末の位置情報をオンにしてください。")
            
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
    
    
    /*
    func migration() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 1,　// ①
            migrationBlock: { migration, oldSchemaVersion in
                if(oldSchemaVersion < 1) {
                    migration.renameProperty(onType: Cat.className(), from: "name", to: "fullName") //②
                }
           }
        })
    }*/
    func migration() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if(oldSchemaVersion < 1) {
                }
            }
        )
    }
    
    //地図タイプを変更するUIViewを表示するボタン
    @IBAction func changeMKMapTypeButton(_ sender: Any) {
        guard mapTypeView.isHidden == true else {
            return mapTypeView.isHidden = true
        }
        return mapTypeView.isHidden = false
    }
    
    
    //現在の位置に移動するボタン
    @IBAction func moveCurrentPositionButton(_ sender: Any) {
        mapView.userTrackingMode = MKUserTrackingMode.follow //地図はユーザーの位置を追従します
    }
    
    
    //mapTypeViewを隠すボタン
    @IBAction func backButton(_ sender: Any) {
        mapTypeView.isHidden = true
    }
    
    
    /*
    //ピンを立てるボタン
    @IBAction func raisePinButton(_ sender: Any) {
        //geofence(latitude: 35.595497, longitude: 135.337812, radius: 500, identifier: "test")
    }*/
    
    
    
    //設定画面に遷移するボタン
    @IBAction func settingsButton(_ sender: Any) {
        //明示的な画面遷移処理
        guard let settingsViewController = storyboard?.instantiateViewController(withIdentifier: "Settings") as? SettingsViewController else {
            print("SettingsViewControllerが存在しません")
            return
        }
        present(settingsViewController, animated: true, completion: nil)
        
    }
    
}



extension MapViewController: MKMapViewDelegate {
}



extension MapViewController: CLLocationManagerDelegate{
    //位置情報を取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.startUpdatingLocation() //高精度位置情報取得を開始する
        //print("@x.更新しました")
        //取得したlocationの情報を代入する
        guard let location = locations.last else { print("returnされました"); return }
        
        //経度、緯度の取得
        let latlng = location.coordinate //緯度、経度の取得
        let latitude = latlng.latitude //経度の取得
        let longitude = latlng.longitude //緯度の取得
        print("経度: \(String(describing: latitude))経度: \(String(describing: longitude))") //出力
        //時間の取得
        let timestamp = location.timestamp
        
        //値を代入
        let locationData = LocationData()
        locationData.longitude = longitude
        locationData.latitude = latitude
        locationData.timestamp = timestamp
        
        //保存
        let realm = try! Realm()
        try! realm.write { realm.add(locationData) }
        let lastLocation = realm.objects(LocationData.self).last
        print("realm: \(String(describing: lastLocation))")
        
        //大幅な動きがあった時に検出する
        locationManager.stopUpdatingLocation() //高精度の位置情報取得を停止
        locationManager.startMonitoringSignificantLocationChanges() //大幅な移動があった場合更新する
    }
    
    
    //位置情報の取得に失敗すると呼ばれる
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("位置情報の更新を失敗しました。")
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
    
    //一時停止された時に呼び出される
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        locationManager.stopUpdatingLocation() //高精度の位置情報取得を停止
        locationManager.startMonitoringSignificantLocationChanges() //大幅な移動があった場合更新する
    }
    
    //visitの呼び出し処理
    /*
    //位置情報が取得されると呼ばれる
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        let arrivalDate = visit.arrivalDate
        let departureDate = visit.departureDate
        let location = visit.coordinate
        print("arrivalDate: \(arrivalDate)")
        print("departureDate: \(departureDate)")
        print("location: \(location)")
        
        locationManager処理()
    }*/

    // 位置情報取得認可
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("ユーザー認証未選択")
            //break
        case .restricted:
            print("位置情報サービス未許可")
            //break
        case .denied:
            print("位置情報取得を拒否、もしくは本体設定で拒否")
            //break
        case .authorizedAlways:
            print("アプリは常時、位置情報取得を許可")
            //break
        case .authorizedWhenInUse:
            print("アプリ起動時のみ、位置情報取得を許可")
            //break
        @unknown default:
            fatalError()
        }
    }

    // モニタリング開始成功時に呼ばれる
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("モニタリング開始")
    }

    // モニタリングに失敗時に呼ばれる
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("モニタリング失敗")
    }

    // ジオフェンス領域侵入時に呼ばれる
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("ジオフェンス侵入")
    }

    // ジオフェンス領域離脱時に呼ばれる
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("ジオフェンス離脱")
    }

    // requestStateが呼ばれた時に呼ばれる
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside {
            print("領域内です。")
        } else {
            print("領域外です。")
        }
    }
    
}



