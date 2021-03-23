//
//  Model.swift
//  Record the Road
//
//  Created by 小駒翼 on 2021/01/12.
//  Copyright © 2021 Tsubasa Kogoma. All rights reserved.
//

import RxSwift
import RxCocoa
import RealmSwift
import MapKit


protocol LocationViewModelProtocol {
    func getPinDatas(startValue: Int, deleteTime: Int) -> Single<[Spot]>
    
    func getPinDatas(startDate: Date, deleteTime: Int) -> Single<[Spot]>
    
    func removePins() -> Single<[Spot]>
    
    func getAuthorizationStatus() -> Single<CLAuthorizationStatus>
}
class LocationViewModel: LocationViewModelProtocol {
    let locationRepository: LocationRepositoryProtocol = LocationRepository()
    // 地図に立てられているピンを保存する
    private var previousDatas = [Spot]()
    
    // ピンを追加する
    func getPinDatas(startValue: Int, deleteTime: Int) -> Single<[Spot]> {
        let realmViewModel: RealmViewModelProtocol = RealmViewModel()
        var locationDatas: [LocationData]!
        realmViewModel.getOneDayData(startValue: startValue).subscribe(
            onSuccess: { result in
                locationDatas = result
            }, onError: { error in
                fatalError("想定外のエラーです")
            })
            .dispose()
        
        
        return self.locationRepository.getPinDatas(locationDatas: locationDatas).map { spots -> [Spot] in
            var spotArray = [Spot]()
            for spot in spots {
                let intSubtitle = spot.subtitle
                guard intSubtitle > deleteTime else {
                    continue
                }
                // 値の整形
                let coordinate = spot.coordinate
                let timeViewModel: TimeViewModelProtocol = TimeViewModel()
                let title = timeViewModel.dateToString(date: spot.title)
                let subtitle = timeViewModel.timeConversion(secondTime: intSubtitle)
                // Spotの作成、追加
                let returnSpot = Spot(coordinate: coordinate, title: title, subtitle: subtitle)
                spotArray.append(returnSpot)
            }
            // 立てられつピンの情報を保存
            self.previousDatas = spotArray
            return spotArray
        }
    }
    func getPinDatas(startDate: Date, deleteTime: Int) -> Single<[Spot]> {
        let realmViewModel: RealmViewModelProtocol = RealmViewModel()
        var locationDatas: [LocationData]!
        
        realmViewModel.getOneDayData(startDate: startDate).subscribe(
            onSuccess: { result in
                locationDatas = result
            }, onError: { error in
                fatalError("想定外のエラーです")
            })
            .dispose()
        
        return self.locationRepository.getPinDatas(locationDatas: locationDatas).map { spots -> [Spot] in
            var spotArray = [Spot]()
            for spot in spots {
                let intSubtitle = spot.subtitle
                guard intSubtitle > deleteTime else {
                    continue
                }
                // 値の整形
                let coordinate = spot.coordinate
                let timeViewModel: TimeViewModelProtocol = TimeViewModel()
                let title = timeViewModel.dateToString(date: spot.title)
                let subtitle = timeViewModel.timeConversion(secondTime: intSubtitle)
                // Spotの作成、追加
                let returnSpot = Spot(coordinate: coordinate, title: title, subtitle: subtitle)
                spotArray.append(returnSpot)
            }
            // 立てられるピンの情報を保存
            self.previousDatas = spotArray
            return spotArray
        }
    }
    
    // ピンを削除する
    func removePins() -> Single<[Spot]> {
        return self.locationRepository.removePins(previousDatas: previousDatas).map { spots -> [Spot] in
            self.previousDatas = []
            return spots
        }
    }
    
    // 位置情報のアクセスレべルを取得
    func getAuthorizationStatus() -> Single<CLAuthorizationStatus> {
        if #available(iOS 14.0, *) {
            let  clLocationManager = CLLocationManager()
            let status = clLocationManager.authorizationStatus
            return locationRepository.getAuthorizationStatus(status: status)
        } else {
            let status = CLLocationManager.authorizationStatus()
            return locationRepository.getAuthorizationStatus(status: status)
        }
    }
}


protocol RealmViewModelProtocol {
    func saveData(longitude: Double, latitude: Double, timestamp: Date) -> Single<Void>
    
    func getOneDayData(startValue: Int) -> Single<[LocationData]>
    
    func getOneDayData(startDate: Date) -> Single<[LocationData]>
    
    func organizeData(deleteTime: Int) -> Single<Void>
    
    func deleteData(locationData: LocationData) -> Single<Void>
}
class RealmViewModel: RealmViewModelProtocol {
    private let realmRepository: RealmRepositoryProtocol = RealmRepository()
    
    func saveData(longitude: Double, latitude: Double, timestamp: Date) -> Single<Void> {
        // 引数の整形
        let locationData = LocationData()
        locationData.longitude = longitude
        locationData.latitude = latitude
        locationData.timestamp = timestamp
        
        // realmに保存する
        return self.realmRepository.saveData(locationData: locationData)
    }
    
    func getOneDayData(startValue: Int) -> Single<[LocationData]> {
        let timeViewModel: TimeViewModelProtocol = TimeViewModel()
        let startDay = timeViewModel.getStartOfDayCustomizedValue(value: startValue)
        let endValue = startValue + 1
        let endDay = timeViewModel.getStartOfDayCustomizedValue(value: endValue)
        
        return realmRepository.getOneDayData(startDate: startDay, endDate: endDay)
    }
    func getOneDayData(startDate: Date) -> Single<[LocationData]> {
        let timeViewModel: TimeViewModelProtocol = TimeViewModel()
        let startDate = startDate
        let endDate = timeViewModel.specificedDate(value: 1, selectDay: startDate)
        
        return realmRepository.getOneDayData(startDate: startDate, endDate: endDate)
    }
    
    
    func organizeData(deleteTime: Int) -> Single<Void> {
        var allLocationData: [LocationData]!
        
        self.realmRepository.getAllData().subscribe(
            onSuccess: { result in
                allLocationData = result
            }, onError: { error in
                fatalError("想定外のエラーです")
            })
            .dispose()
        
        return self.realmRepository.organizeData(allLocationData: allLocationData, deleteTime: deleteTime)
    }
    /*
    func organizeData(deleteTime: Int) -> Single<Void> {
        return Single<Void>.create { single -> Disposable in
            self.realmRepository.getAllData().subscribe(
                onSuccess: { result in
                    let allLocationData = result
                    self.realmRepository.organizeData(allLocationData: allLocationData, deleteTime: deleteTime).subscribe(
                        onSuccess: {_ in },
                        onError: {_ in })
                        .dispose()
                    
                }, onError: { error in
                    fatalError("想定外のエラーです")
                })
                .dispose()
            return Disposables.create()
        }
    }*/
    
    
    // データ削除
    func deleteData(locationData: LocationData) -> Single<Void> {
        return realmRepository.deleteData(locationData: locationData)
    }
}


protocol CalendarViewModelProtocol {
    func judgeHoliday(_ date : Date) -> Bool
    
    func getWeekId(_ date: Date) -> Int
}
class CalendarViewModel: CalendarViewModelProtocol {
    let calendarRepository: CalendarRepositoryProtocol = CalendarRepository()
    
    // 祝日判定
    func judgeHoliday(_ date : Date) -> Bool {
        let result = calendarRepository.judgeHoliday(date)
        return result
    }
    
    // 曜日判定
    func getWeekId(_ date: Date) -> Int {
        let result =  calendarRepository.getWeekId(date)
        return result
    }
}


protocol AlertViewModelProtocol {
    func showAlert(message: String) -> UIAlertController
    
    func goToSettings(message: String) -> UIAlertController
}
class AlertViewModel: AlertViewModelProtocol {
    // 通常バージョン
    func showAlert(message: String) -> UIAlertController {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        alert.addAction(close)
        return alert
    }
    
    // アクセス許可が降りていない時に設定画面へ飛ぶ処理
    func goToSettings(message: String) -> UIAlertController {
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        let close = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        let goToSettings = UIAlertAction(title: "設定へ移動", style: UIAlertAction.Style.default) { (UIAlertAction) in
            let url = URL(string:UIApplication.openSettingsURLString)! // URL取得
            UIApplication.shared.open(url, options: [:], completionHandler: nil) // URLを開く処理
        }
        alert.addAction(close)
        alert.addAction(goToSettings)
        return alert
    }
}


protocol NotificationViewModelProtocol {
    func askNotificationPermission()
    
    func notification(body: String, timeInterval: Double, title: String)
}
class NotificationViewModel: NotificationViewModelProtocol {
    private let center = UNUserNotificationCenter.current()
    
    // 通知の許可を求める
    func askNotificationPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("通知許可で出ました")
            } else {
                print("通知許可が出ませんでした")
            }
        }
    }
    
    // 通知を送る
    func notification(body: String, timeInterval: Double, title: String) {
        let content = UNMutableNotificationContent()
        // 通知メッセージ
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // 通知リクエストを作成して登録する
        let request = UNNotificationRequest(identifier: title, content: content, trigger: trigger)
        // システムでリクエストをスケジュールします。
        center.add(request) { error in
            if let error = error {
                print("error: \(error)")
            }
        }
    }
}


protocol TimeViewModelProtocol {
    func dateToString(date: Date) -> String
    
    func stringToDate(stringDate: String) -> Date
    
    func difference(startDate: Date, endDate: Date) -> Int
    
    func getStartOfDayCustomizedValue(value: Int) -> Date
    
    func getStartOfDay(selectDay: Date) -> Date
    
    func specificedDate(value: Int, selectDay: Date) -> Date
    
    func timeConversion(secondTime: Int) -> String
    
    func secondConversion(hour: Int, minute: Int, second: Int) -> Int
}
class TimeViewModel: TimeViewModelProtocol {
    let dateFormatter = DateFormatter()
    let calendar = Calendar.current
    
    // DateからStringに型変換
    func dateToString(date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
    }
    
    // StringからDateに型変換
    func stringToDate(stringDate: String) -> Date {
        dateFormatter.dateFormat  = "yyyy-MM-dd HH:mm:ss Z"
        let date = dateFormatter.date(from: stringDate)!
        return date
    }
    
    // Dateの引き算を行う
    func difference(startDate: Date, endDate: Date) -> Int {
        let stayTime = endDate.timeIntervalSince(startDate)
        let time = Int(stayTime)
        return time
    }
    
    // 今日からvalueで指定された日にち分ずれた日を返す
    func getStartOfDayCustomizedValue(value: Int) -> Date {
        let date = Date()
        let startOfDay = calendar.date(byAdding: .day, value: (value + 1), to: calendar.startOfDay(for: date))!
        return startOfDay
    }
    // selectDayの午前0時を返す
    func getStartOfDay(selectDay: Date) -> Date {
        let date = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: selectDay))!
        return date
    }
    // selectDayからvalueで指定された日にち分ずれた日を返す
    func specificedDate(value: Int, selectDay: Date) -> Date {
        let date = calendar.date(byAdding: .day, value: (value + 1), to: calendar.startOfDay(for: selectDay))!
        return date
    }
    
    // 秒を時間に変換
    func timeConversion(secondTime: Int) -> String {
        let day = secondTime / 60 / 60 / 24
        let hour = (secondTime - (60 * 60 * 24 * day)) / 60 / 60
        let minute = (secondTime - (60 * 60 * 24 * day) - 60 * 60 * hour) / 60
        let second = (secondTime - (60 * 60 * 24 * day) - (60 * 60 * hour) - (60 * minute))
        let time = "\(day)日 \(hour)時間 \(minute)分 \(second)秒"
        return time
    }
    
    // 時間を秒に変換
    func secondConversion(hour: Int, minute: Int, second: Int) -> Int {
        let time = (hour * 3600) + (minute * 60) + second
        return time
    }
}
