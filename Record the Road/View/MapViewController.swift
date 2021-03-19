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
import Dispatch
import FSCalendar
import CalculateCalendarLogic
import KeychainAccess
import RxSwift


class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeView: UIView!
    @IBOutlet weak var mapTypeSegmentButton: UISegmentedControl!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var messageLabel: UILabel!
    
    
    let locationManager: CLLocationManager = CLLocationManager()
    var moniteringRegion: CLCircularRegion = CLCircularRegion()
    let disposeBag = DisposeBag()
    
    let locationViewModel: LocationViewModelProtocol = LocationViewModel()
    let realmViewModel: RealmViewModelProtocol = RealmViewModel()
    let calendarViewModel: CalendarViewModelProtocol = CalendarViewModel()
    let alertViewModel: AlertViewModelProtocol = AlertViewModel()
    let notificationViewModel: NotificationViewModelProtocol = NotificationViewModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global(qos: .background).async {
            // 記録した位置情報からデータをfilterする
            let deleteTime = 120
            self.realmViewModel.organizeData(deleteTime: deleteTime).subscribe(
                onSuccess: { _ in
                    
                }, onError: { error in
                    // crashlyticsに連絡
                })
                .dispose()
        }
        
        mapTypeView.isHidden = true //mapTypeViewを隠す
        locationManager.delegate = self //locationManagerを自身で操作できるようにする
        self.calendarView.dataSource = self //カレンダーのdataSourceの紐付け
        self.calendarView.delegate = self //カレンダーのdelegateの紐付け
        
        
        // 位置情報へのアクセス状態の確認及びそれぞれの場合の処理の実行
        checkLocationStatus()
        
        // 通知へのアクセス状態を確認する
        notificationViewModel.askNotificationPermission()
        
        
        // 通知を飛ばす処理
        let notificationViewModel: NotificationViewModelProtocol = NotificationViewModel()
        notificationViewModel.notification(body: "おはよう", timeInterval: 1, title: "テスト")
        
        // segmentIndexを取り出す
        let userDefaults: UserDefaults = UserDefaults.standard
        if let storedSegmentIndex = userDefaults.object(forKey: "segmentIndex") as? Int {
            mapTypeSegmentButton.selectedSegmentIndex = storedSegmentIndex //segmentに前回設定された値を入れる
            switch storedSegmentIndex {
            case 0:
                mapView.mapType = .standard
            case 1:
                mapView.mapType = .hybrid
            default:
                fatalError("想定外の値の検出") }
        }
        
        // ピンを立てる処理
        let deleteTime = 120
        locationViewModel.getPinDatas(startDate: Date(), deleteTime: deleteTime).subscribe(
            onSuccess: { spots in
                self.mapView.addAnnotations(spots)
            }, onError: { error in
                let alert = self.alertViewModel.showAlert(message: "\(error.localizedDescription)")
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    
    // labelのアラートを出す
    func labelAlert(text: String) {
        messageLabel.isHidden = false
        messageLabel.text = text
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: .now() + 2) {
            self.messageLabel.isHidden = true
        }
    }
    
    
    //位置情報取得できる時の共通処理
    func getLocation() {
        /*滞在時間が存在しないログを無くすためにChangesをテストしている*/
        //locationManager.startUpdatingLocation() //位置情報取得
        locationManager.startMonitoringSignificantLocationChanges() //大幅な移動があった場合更新する
        mapView.userTrackingMode = MKUserTrackingMode.follow //地図はユーザーの位置を追従する
        locationManager.allowsBackgroundLocationUpdates = true //backgroundでの位置情報更新を可能にする
        //let backgroundLocationIndicator = locationManager.showsBackgroundLocationIndicator //background時外観ステータスバーを変更するかどうか
        locationManager.distanceFilter = 500 //更新イベントに必要な最低距離
        locationManager.pausesLocationUpdatesAutomatically = true //システムが自動で位置情報の取得を一時停止する(消費電力削減のため)
    }
    
    
    // 位置情報へのアクセス状態を確認する
    func checkLocationStatus() {
        locationViewModel.getAuthorizationStatus().subscribe(
            onSuccess: { result in
                switch result {
                case .notDetermined:
                    self.locationManager.requestAlwaysAuthorization() // 位置情報へのアクセスをユーザーに求める
                case .denied:
                    let message = "このサービスを利用するには、端末の位置情報をオンにしてください。"
                    let alert = self.alertViewModel.goToSettings(message: message)
                    self.present(alert, animated: true, completion: nil)
                    
                case .restricted:
                    let message = "アプリ起動中かつ許可がある時のみ記録できます"
                    self.labelAlert(text: message)
                    self.getLocation()
                    
                case .authorizedWhenInUse:
                    let message = "アプリの起動中のみ位置情報を記録します"
                    self.labelAlert(text: message)
                    self.getLocation()
                    
                case .authorizedAlways:
                    let message = "常に許可されています"
                    self.labelAlert(text: message)
                    self.getLocation()
                @unknown default:
                    assertionFailure()
                }
            }, onError: { error in
                fatalError("想定外の値の検出")
            })
            .disposed(by: disposeBag)
    }
    
    
    //番号によって地図タイプを変更する
    @IBAction func mapTypeSegumentedButton(_ sender: UISegmentedControl) {
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
    
    
    //地図タイプを変更するUIViewを表示するボタン
    @IBAction func changeMKMapTypeButton(_ sender: Any) {
        guard mapTypeView.isHidden == true else {
            return mapTypeView.isHidden = true
        }
        return mapTypeView.isHidden = false
    }
    
    
    // 現在の位置に移動するボタン
    @IBAction func moveCurrentPositionButton(_ sender: Any) {
        mapView.userTrackingMode = MKUserTrackingMode.follow //地図はユーザーの位置を追従します
    }
    
    
    // mapTypeViewを隠すボタン
    @IBAction func backButton(_ sender: Any) {
        mapTypeView.isHidden = true
    }
    
    
    // カレンダーを表示するボタン
    @IBAction func calendarButton(_ sender: Any) {
        guard calendarView.isHidden == true else {
            return calendarView.isHidden = true
        }
        return calendarView.isHidden = false
    }
    
}



extension MapViewController: MKMapViewDelegate {
}


extension MapViewController: CLLocationManagerDelegate{
    // 位置情報を取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.startUpdatingLocation() //高精度位置情報取得を開始する
        
        // 取得したlocationの情報を取得する
        guard let location = locations.last else {
            return
        }
        
        // 経度、緯度、時間のの取得
        let coordinate = location.coordinate //緯度、経度の取得
        let latitude = coordinate.latitude //経度の取得
        let longitude = coordinate.longitude //緯度の取得
        let timestamp = location.timestamp
        
        // Realmにデータを保存
        realmViewModel.saveData(longitude: longitude, latitude: latitude, timestamp: timestamp).subscribe(
            onSuccess: { _ in},
            onError: { _ in})
            .disposed(by: disposeBag)
        
        // 大幅な動きがあった時に検出する
        locationManager.stopUpdatingLocation() //高精度の位置情報取得を停止
        locationManager.startMonitoringSignificantLocationChanges() //大幅な移動があった場合更新する
    }
    
    
    // 位置情報の取得に失敗すると呼ばれる
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError {
            case CLError.locationUnknown:
                break
            case CLError.denied:
                break
            default:
                break
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
    
    
    /*特定の場所に移動したら動くまで待機する*/
    fileprivate func geofence(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: CLLocationDistance, identifier: String) {
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


extension MapViewController: FSCalendarDelegate, FSCalendarDataSource {
    // 土日や祝日の日の文字色を変える
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        //祝日判定をする（祝日は赤色で表示する）
        if calendarViewModel.judgeHoliday(date) {
            return UIColor.red
        }
        
        //土日の判定を行う（土曜日は青色、日曜日は赤色で表示する）
        let weekday = calendarViewModel.getWeekId(date)
        if weekday == 1 {   //日曜日
            return UIColor.red
        }
        else if weekday == 7 {  //土曜日
            return UIColor.blue
        }
        
        return nil
    }
    
    //タップされた日付を取得する
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // ピンの削除
        locationViewModel.removePins().subscribe(
            onSuccess: { spots in
                self.mapView.removeAnnotations(spots)
            }, onError: { error in
                fatalError("\(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
        
        // ピンを立てる処理
        let deleteTime = 120 // 除外される時間の指定
        let startDate = date
        locationViewModel.getPinDatas(startDate: startDate, deleteTime: deleteTime).subscribe(
            onSuccess: { spots in
                self.mapView.addAnnotations(spots)
            }, onError: { error in
                fatalError("error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}


extension MapViewController: FSCalendarDelegateAppearance {
}
