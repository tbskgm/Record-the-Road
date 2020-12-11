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
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var button: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //inputTextView()
        //button.isEnabled = false
        
    }
    
    
    //無駄なログを削除する
    @IBAction func button(_ sender: Any) {
        //save()
        button.isEnabled = false
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil) //戻る処理
    }
    
    
    func inputTextView() {
        /*
        let userDefaults: UserDefaults = UserDefaults.standard
        guard let storedCollectedInfomations = userDefaults.object(forKey: "collectedInfomation") as? [[String: Any]] else {
            return print("collectedInfomationの値が存在しませんでした")
        }
        let storedCollectedInfomationsCount = storedCollectedInfomations.count
        
        var count = 0
        var texts: String = ""
        
        for storedCollectedInfomation in storedCollectedInfomations {
            //経度、緯度の取得
            let latitude = storedCollectedInfomation["latitude"] as! CLLocationDegrees //経度の取得
            let longitude = storedCollectedInfomation["longitude"] as! CLLocationDegrees //緯度の取得
            
            //タイトルの取得
            /*
             var title: String!
             if let date = storedCollectedInfomation["timestamp"] as? Date {
             let timeRelationship = TimeRelationship()
             title = timeRelationship.dateToString(date: date) //String型に変換
             } else {
             print("titleがありません")
             //title = ""
             continue
             }*/
            guard let date = storedCollectedInfomation["timestamp"] as? Date else {
                print("titleがありません")
                continue
            }
            let timeRelationship = TimeRelationship()
            let title = timeRelationship.dateToString(date: date)
            print("@x.title: \(String(describing: title))")
            
            //サブタイトルの取得
            guard storedCollectedInfomationsCount > 2 else { //配列の数が足らない時
                print("storedCollectedInfomationの数が足りません")
                var locationInfomation: String { "\n経度: \(longitude), 緯度: \(latitude), 時間: \(title)" }
                return textView.text = locationInfomation
                
            }
            //到着時間の取得
            let arrival = storedCollectedInfomations[count]
            let arrivalTime = arrival["timestamp"] as! Date
            //出発時間の取得
            count += 1
            print("count: \(count)")
            guard (storedCollectedInfomationsCount - 1) != count else { //すべての配列を記録した後に配列外を参照しないため
                //print("全ての滞在時間を算出しました")
                //textView.text = texts
                
                //continue
                break
            }
            let departure = storedCollectedInfomations[count]
            let departureTime = departure["timestamp"] as! Date
            //滞在時間の取得
            var stayTime: Int { Int(departureTime.timeIntervalSince(arrivalTime)) } //出発時間から到着時間を引く
            if stayTime < 600 { //滞在時間が指定時間以下だったら次の処理に移行する
                continue
            }
            var subTitle: String { "\(stayTime/3600): \(stayTime%3600/60): \(stayTime%3600%60)" } //テキストに直す
            //var subTitle: String {text}
            var locationInfomation: String {"\n経度: \(longitude), 緯度: \(latitude), 時間: \(title), 滞在時間: \(subTitle)"}
            texts += locationInfomation
            print("texts: \(texts)")
        }
        print("全ての滞在時間を算出しました")
        textView.text = texts
        */
        
        /*
        let aboutLocation = AboutLocation()
        guard aboutLocation.getLocationData() != nil else {
            return
        }
        let array = aboutLocation.getLocationData()!
        var texts: String = ""
        print("class.stayTime: 終了")
        for i in array {
            print("class.i: \(i)")
            var longitude: CLLocationDegrees { i["longitude"] as! CLLocationDegrees } //経度
            var latitude: CLLocationDegrees { i["latitude"] as! CLLocationDegrees } //緯度
            var timestamp: Date { i["timestamp"] as! Date } //到着時間
            var stayTime: Int { i["stayTime"] as! Int } //滞在時間
            var text : String { "\n経度: \(longitude), 緯度: \(latitude), 時間: \(timestamp), 滞在時間: \(stayTime)" }
            print("stayTime: \(stayTime)")
            texts += text
        }
        textView.text = texts*/
    }
    
}



