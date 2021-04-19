//
//  Classes.swift
//  Record the Road
//
//  Created by 小駒翼 on 2020/08/19.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import MapKit
import RealmSwift
import FSCalendar
import CalculateCalendarLogic
import KeychainAccess
import RxSwift


protocol LocationRepositoryProtocol {
    func removePins(previousDatas: [Spot]) -> Single<[Spot]>
    
    typealias spotData = (coordinate: CLLocationCoordinate2D,title:  Date,subtitle: Int)
    
    func getPinDatas(locationDatas: [LocationData]) -> Single<[spotData]>
    
    func getAuthorizationStatus(status: CLAuthorizationStatus) -> Single<CLAuthorizationStatus>
}
class LocationRepository: LocationRepositoryProtocol {
    //ピンの削除
    func removePins(previousDatas: [Spot]) -> Single<[Spot]> {
        return Single<[Spot]>.create { single -> Disposable in
            single(.success(previousDatas))
            return Disposables.create()
        }
    }
    
    //ピンを立てる
    typealias spotData = (coordinate: CLLocationCoordinate2D, title:  Date, subtitle: Int)
    
    func getPinDatas(locationDatas: [LocationData]) -> Single<[spotData]> {
        return Single<[spotData]>.create { single -> Disposable in
            // 数値
            let locationDatasCount = locationDatas.count
            var count = 0
            
            // 配列作成
            var spots: [spotData] = []
            
            for locationData in locationDatas {
                // 到着時間の取得
                let arrivalDate = locationData.timestamp
                // 出発時間の取得
                let departureDate: Date!
                if (locationDatasCount - 1) > count {
                    count += 1
                    departureDate = locationDatas[count].timestamp
                } else {
                    // 滞在時間の取得
                    departureDate = Date()
                }
                //滞在時間の取得
                let stayTime = Int(departureDate.timeIntervalSince(arrivalDate))
                
                // CLLocationCoordinate2Dに変換
                let coordinate = CLLocationCoordinate2D(latitude: locationData.latitude, longitude: locationData.longitude)
                // titleとsubtitleの取得
                let title = locationData.timestamp
                let subtitle = stayTime
                let spot = (coordinate: coordinate, title: title, subtitle: subtitle)
                spots.append(spot)
            }
            single(.success(spots))
            return Disposables.create()
        }
    }
    
    // 認証状況を確認して、位置情報へのアクセスを許可されてなかった場合は許可を得る
    func getAuthorizationStatus(status: CLAuthorizationStatus) -> Single<CLAuthorizationStatus> {
        return Single<CLAuthorizationStatus>.create { single -> Disposable in
            switch status {
            case .notDetermined:
                single(.success(.notDetermined))
            case .denied:
                single(.success(.denied))
            case .restricted:
                single(.success(.restricted))
            case .authorizedWhenInUse:
                single(.success(.authorizedWhenInUse))
            case .authorizedAlways:
                single(.success(.authorizedAlways))
            @unknown default:
                fatalError("Appleが新たな値を追加したので修正してください")
            }
            return Disposables.create()
        }
    }
}


protocol RealmRepositoryProtocol {
    func saveData(locationData: LocationData) -> Single<Void>
    
    func getAllData() -> Single<[LocationData]>
    
    func getOneDayData(startDate: Date, endDate: Date) -> Single<[LocationData]>
    
    func organizeData(allLocationData: [LocationData], deleteTime: Int)  -> Single<Void>
    
    func deleteData(locationData: LocationData) -> Single<Void>
}
class RealmRepository: RealmRepositoryProtocol {
    private var config: Realm.Configuration {
        let config = Realm.Configuration(
            fileURL: URL(fileURLWithPath: NSHomeDirectory() + "/Documents" + "/recordTheRoad.realm"),
            encryptionKey: getEncryptionKey(),
            schemaVersion: 0,
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            })
        return config
    }
    
    // 暗号鍵の取得
    private func getEncryptionKey() -> Data {
        // キーチェーンからパスワード取得
        let keychain = Keychain(service: "com.TK.RecordTheRoad")
        // 値の取得
        let storedPassword: Data?
        do {
            storedPassword = try keychain.getData("realmPassword")
        } catch {
            storedPassword = nil
        }
        
        // 値が存在していた時return
        if let password = storedPassword {
            return password
        }
        // 値が存在しない場合はkeyを生成
        var key = Data(count: 64)
        // keyの乱数化
        let _ = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
        }
        // キーチェーンに保存
        do {
            try keychain.set(key, key: "realmPassword")
        } catch {
            fatalError("想定外のエラーが発生しました")
        }
        // 戻り値を返す
        return key
    }
    
    
    // データを保存する
    func saveData(locationData: LocationData) -> Single<Void> {
        return Single<Void>.create { single -> Disposable in
            // Realmにデータを保存
            do {
                let realm = try! Realm(configuration: self.config)
                try realm.write {
                    realm.add(locationData)
                }
            } catch {
                single(.error(error))
                print("error: \(error)")
            }
            return Disposables.create()
        }
    }
    
    
    // 指定日のデータを返す関数
    func getOneDayData(startDate: Date, endDate: Date) -> Single<[LocationData]> {
        return Single<[LocationData]>.create { single -> Disposable in
            let realm = try! Realm(configuration: self.config)
            let realmLocationDatas = realm.objects(LocationData.self).filter("timestamp >= %@ AND timestamp < %@", startDate, endDate) // 1日分の情報を取得
            let locationDatas = Array(realmLocationDatas)
            
            single(.success(locationDatas))
            return Disposables.create()
        }
    }
    
    // 全データを取得する
    func getAllData() -> Single<[LocationData]> {
        return Single<[LocationData]>.create { single -> Disposable in
            let realm = try! Realm(configuration: self.config)
            
            let realmAllLocationData = realm.objects(LocationData.self)
            let allLocationData = Array(realmAllLocationData)
            
            single(.success(allLocationData))
            return Disposables.create()
        }
    }
    
    
    /*filterで効率化できないかな？*/
    // Realmからデータを削除
    func organizeData(allLocationData: [LocationData], deleteTime: Int) -> Single<Void> {
        return Single<Void>.create { single -> Disposable in
            let allLocationDataCount = allLocationData.count
            var count = 0
            var deleteCount = 0
            // Realmに保存されている全データから滞在時間が指定時間以下の情報を削除する
            exit: for locationData in allLocationData {
                guard (allLocationDataCount - 1) > count else {
                    break exit
                }
                count += 1
                
                // 到着時間、出発時間、滞在時間の取得
                let arrivalDate = locationData.timestamp // 到着時間の取得
                let departureDate = allLocationData[(count - deleteCount)].timestamp // 出発時間の取得
                
                let stayTime = Int(departureDate.timeIntervalSince(arrivalDate)) // 滞在時間の取
                guard stayTime < deleteTime else {
                    continue
                }
                
                // Realmからデータを削除
                let realm = try! Realm(configuration: self.config)
                try! realm.write() {
                    realm.delete(locationData)
                }
                deleteCount += 1
            }
            return Disposables.create()
        }
    }
    
    
    func deleteData(locationData: LocationData) -> Single<Void> {
        return Single<Void>.create { single -> Disposable in
            let realm = try! Realm(configuration: self.config)
            do {
                try realm.write() {
                    realm.delete(locationData)
                }
            } catch {
                single(.error(error))
            }
            return Disposables.create()
        }
    }
    
    
}


protocol CalendarRepositoryProtocol {
    func judgeHoliday(_ date : Date) -> Bool
    
    typealias yearMonthDay = (year: Int,month: Int,day: Int)
    
    //func getDay(_ date:Date) -> yearMonthDay
    
    func getWeekId(_ date: Date) -> Int
}
class CalendarRepository: CalendarRepositoryProtocol {
    private let calendar = Calendar(identifier: .gregorian)
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-hh:mm:ss Z"
        return dateFormatter
    }
    
    // 祝日判定を行い結果を返すメソッド(True:祝日)
    func judgeHoliday(_ date : Date) -> Bool {
        // 祝日判定を行う日にちの年、月、日を取得
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // CalculateCalendarLogic()：祝日判定のインスタンスの生成
        let holiday = CalculateCalendarLogic()
        let isHoliday = holiday.judgeJapaneseHoliday(year: year, month: month, day: day)
        return isHoliday
    }
    
    /*
    // date型 -> 年月日をIntで取得
    typealias yearMonthDay = (year: Int,month: Int,day: Int)
    func getDay(_ date:Date) -> yearMonthDay {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return (year: year,month: month,day: day)
        
    }*/
    
    // 曜日判定(日曜日:1 〜 土曜日:7)
    func getWeekId(_ date: Date) -> Int {
        let component = calendar.component(.weekday, from: date)
        return component
    }
    
    
}
