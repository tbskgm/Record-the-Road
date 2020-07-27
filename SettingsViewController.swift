//
//  SettingsViewController.swift
//  Record the Road
//
//  Created by 小駒翼 on 2020/07/20.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import UIKit
import EventKit

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let recordOnyourCalendar = RecordOnYourCalendar()
        
        //カレンダーへのアクセス許可を取る
        guard recordOnyourCalendar.requestAuthorization() == true else {
            //アラートを表示
            //ボタンを押せないようにする処理
            //戻る処理(dismissの事)
            return
        }
        
    }
    
    
    @IBAction func button(_ sender: Any) {
        
        func recordCalendar() {
            let userDefaults: UserDefaults = UserDefaults.standard
            
            guard let array = userDefaults.object(forKey: "collectedInfomation") as? [[String: Any]] else {
                return
            }
            guard let collectedInfomation = array.last else {
                return
            }
            let latitude = collectedInfomation["latitude"] as? Double
            let longitude = collectedInfomation["longitude"] as? Double
            let date = collectedInfomation["date"]
            
            var notes: String {
                "経度:\(longitude!)\n緯度: \(latitude!)\n時間: \(date!)"
            }
            
            //カレンダーに記録する
            let recordOnYourCalendar: RecordOnYourCalendar = RecordOnYourCalendar()
            recordOnYourCalendar.recordEvent(title: "行動履歴", viewController: self, notes: notes)
            
            //戻る処理
            let queue: DispatchQueue = DispatchQueue.main
            queue.asyncAfter(deadline: .now() + 1) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        recordCalendar()
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil) //戻る処理
    }
    
    
}



//カレンダー連携
class RecordOnYourCalendar {
    // EventStoreを初期化
    let eventStore: EKEventStore = EKEventStore()
    
    //認証状況を確認して、カレンダーへのアクセスを許可されてなかった場合は許可を得る
    func requestAuthorization() -> Bool{
        if getAuthorizationStatus() {
            print("許可を得ています")
            return true
            
        } else {
            eventStore.requestAccess(to: .event, completion: {(granted, error) in //https://developer.apple.com/documentation/eventkit/ekeventstore/1507547-requestaccess
                if granted {
                    return
                } else {
                    print("許可を得ていません")
                }
            })
            return false
        }
    }
    
    //認証ステータスを確認する
    func getAuthorizationStatus() -> Bool {
        //承認ステータスを取得
        let status = EKEventStore.authorizationStatus(for: .event) //https://developer.apple.com/documentation/eventkit/ekeventstore/1507239-authorizationstatus
        
        // ステータスを表示 許可されている場合のみtrueを返す
        switch status {
        case .notDetermined:
            print("NotDetermined")
            return false
        case .denied:
            print("Denied")
            return false
        case .authorized:
            print("Aythorized")
            return true
        case .restricted:
            print("Restricted")
            return false
        default:
            assertionFailure("今までにない新しいケースです。Apple Developerを確認！！") //列挙型の変更に対するお備え
            return false
        }
    }
    
    
    //カレンダーに記録
    func recordEvent(title: String, viewController view: UIViewController, notes: String) {
        /*
        let authenticationResult: Bool = requestAuthorization() //カレンダーへのアクセス許可を取る
        guard authenticationResult == true else { //カレンダーへのアクセスが許可されていないときの処理
            let alert: Alert = Alert()
            alert.showAlert(viewController: view, message: "カレンダーへのアクセスが許可されていません")
            return print("カレンダーへのアクセスが許可されていないので、記録できませんでした")
        }*/
        // イベントの情報を準備
        let startDate: Date = Date() //カレンダーの時間指定のために必須
        let endDate: Date = Date()
        let defaultCalendar = eventStore.defaultCalendarForNewEvents
        // イベントを作成して情報をセット
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = defaultCalendar
        event.notes = notes
        
        // イベントの登録
        do {
            try eventStore.save(event, span: .thisEvent)
            print("できました")
        } catch {
            print(error)
            print("できませんでした")
        }
    }
    
}
