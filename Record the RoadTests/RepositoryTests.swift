//
//  Record_the_RoadTests.swift
//  Record the RoadTests
//
//  Created by 小駒翼 on 2020/12/13.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import XCTest
import MapKit

@testable import Record_the_Road


class TestLocationData {
    static var testDatas: [LocationData] {
        let testData1 = LocationData()
        testData1.latitude = 150
        testData1.longitude = 150
        testData1.timestamp = Date(timeIntervalSinceNow: -80000)
        
        let testData2 = LocationData()
        testData2.latitude = 150
        testData2.longitude = 150
        testData2.timestamp = Date(timeIntervalSinceNow: -5558)
        
        let datas = [testData1, testData2]
        return datas
    }
}

//class Record_the_RoadTests: XCTestCase {
class LocationRepositoryTests: XCTestCase {
    
    // locationRepositoryのテスト
    let locationRepository: LocationRepositoryProtocol = LocationRepository()
    func testRemovePinsのテスト() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.676226, longitude: 139.699385)
        let title = "2020-12-20-12:53:32 +0000"
        let subTitle = "1日 8時間 37分 7秒"
        let spot = Spot(coordinate: coordinate, title: title, subtitle: subTitle)
        
        let spots = [spot]
        locationRepository.removePins(previousDatas: spots).subscribe(
            onSuccess: { spots in
                let spot = spots[0]
                // 比較
                XCTAssertEqual(coordinate.latitude, spot.coordinate.latitude)
                XCTAssertEqual(coordinate.longitude, spot.coordinate.longitude)
                XCTAssertEqual(title, spot.title)
                XCTAssertEqual(subTitle, spot.subtitle)
            }, onError: { error in
                XCTFail()
            })
    }
    
    func testAddPinsのテスト() {
        typealias spotData = (coordinate: CLLocationCoordinate2D,title:  Date,subtitle: Int)
        
        // テスト情報の作成
        var locationDatas: [LocationData] {
            let date = Date()
            
            let locationData1 = LocationData()
            locationData1.latitude = 35.676226
            locationData1.longitude = 139.699385
            locationData1.timestamp = date
            
            let locationData2 = LocationData()
            locationData2.latitude = 35.5
            locationData2.longitude = 139
            locationData2.timestamp = date
            
            let datas = [locationData1, locationData2]
            return datas
        }
        
        // 地図に立てるピンの情報を取得
        locationRepository.getPinDatas(locationDatas: locationDatas)
    }
    
    func testGetAuthorizationStatusのテスト() {
        let clLocationManager = CLLocationManager()
        let status = clLocationManager.authorizationStatus
        
        locationRepository.getAuthorizationStatus(status: status).subscribe(
            onSuccess: { status in
                XCTAssertNotNil(status, "statusが取得できるかテスト")
            }, onError: { error in
                XCTFail()
            })
            .dispose()
    }
}

class RealmRepositoryTests: XCTestCase {
    let realmRepository: RealmRepositoryProtocol = RealmRepository()
    
    // テストデータ
    let testDatas = TestLocationData.testDatas
    
    func testSaveDataのテスト() {
        // 保存できなかった場合はrepositoryででラーが発生する
        for testData in testDatas {
            realmRepository.saveData(locationData: testData)
        }
    }
    
    func testGetAllDataのテスト() {
        // 取り出す事が可能かテスト
        realmRepository.getAllData().subscribe(
            onSuccess: { result in
                XCTAssertNotNil(result, "結果がnilじゃないかテスト")
            }, onError: { error in
                XCTFail()
            })
            .dispose()
    }
    
    func testGetOneDayDataのテスト() {
        /*// テストデータ追加
        for testData in testDatas {
            realmRepository.saveData(locationData: testData)
        }*/
        
        // 一日分のデータを取得するためのDateを作成
        let startDate = Date(timeIntervalSinceNow: -86400) // 昨日の現在時刻取得
        let endDate = Date() // 現在時刻取得
        
        // 一日分のデータ取得
        let expectation = self.expectation(description: "testGetOneDayDataのテスト.getOneDayData")
        realmRepository.getOneDayData(startDate: startDate, endDate: endDate).subscribe(
            onSuccess: { oneDayData in
                if oneDayData.count < 2 {
                    XCTFail("テストデータの作成にミスがあります")
                }
                // 最初のデータがstartDateよりも後の時刻か調べる
                let firstDate = oneDayData.first!.timestamp
                XCTAssertLessThan(startDate, firstDate, "firstDateがstartDateよりも後の時刻か調べる")
                
                // 最後のデータがendDateよりも前の時刻か調べる
                let lastDate = oneDayData.last!.timestamp
                XCTAssertGreaterThan(endDate, lastDate, "lastDateがendDateよりも前の時刻か調べる")
                
                // 非同期処理
                expectation.fulfill()
                
            }, onError: { error in
                XCTFail()
            })
        wait(for: [expectation], timeout: 10)
        
        /*// テストデータ削除
        let deleteExpectation = self.expectation(description: "testGetOneDayDataのテスト.getOneDayData(delete)")
        realmRepository.getOneDayData(startDate: startDate, endDate: endDate).subscribe(
            onSuccess: { results in
                for result in results {
                    // 緯度、経度が150以外はcontinue
                    guard result.latitude == 150, result.longitude == 150 else {
                        continue
                    }
                    self.realmRepository.deleteData(locationData: result).subscribe(onSuccess: {_ in}, onError: {_ in })
                    deleteExpectation.fulfill()
                }
            }, onError: { error in
                XCTFail()
            })
        waitForExpectations(timeout: 20, handler: nil)
        //wait(for: [deleteExpectation], timeout: 30)*/
    }
    
    func testDeleteDataのテスト() {
        // テストデータの削除
        let expectation = self.expectation(description: "testDeleteDataのテスト.getAllData")
        realmRepository.getAllData().subscribe(
            onSuccess: { allData in
                for data in allData {
                    // テストデータ以外はcontinue
                    guard data.latitude == 150, data.longitude == 150 else {
                        continue
                    }
                    self.realmRepository.deleteData(locationData: data).subscribe(
                        onSuccess: { result in
                            XCTFail()
                        }, onError: { error in
                            XCTFail()
                        })
                }
                expectation.fulfill()
            }, onError: { error in
                XCTFail()
            })
            .dispose()
        wait(for: [expectation], timeout: 20)
    }
}

class CalendarRepositoryTests: XCTestCase {
    let calendarRepository: CalendarRepositoryProtocol = CalendarRepository()
    
    func testJudgeHolidayのテスト() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        //平日の日曜日
        let sundayString = "2021-2-7-13:00:00 +0000"
        let sunday = dateFormatter.date(from: sundayString)!
        print("sunday: \(sunday)")
        let isSunday = calendarRepository.judgeHoliday(sunday)
        XCTAssertFalse(isSunday)
        
        //建国記念の日
        let holiDayString = "2021-2-11-13:00:00 +0000"
        let holiDay = dateFormatter.date(from: holiDayString)!
        print("thursDay: \(holiDay)")
        let isHoliDay = calendarRepository.judgeHoliday(holiDay)
        XCTAssertTrue(isHoliDay)
        
    }
    
    func testGetWeekIdのテスト() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        //日曜日
        let sundayString = "2021-2-7-13:00:00 +0000"
        let sunday = dateFormatter.date(from: sundayString)!
        let one = calendarRepository.getWeekId(sunday)
        XCTAssertEqual(1, one)
        
        //月曜日
        let mondayString = "2021-2-8-13:00:00 +0000"
        let monday = dateFormatter.date(from: mondayString)!
        let two = calendarRepository.getWeekId(monday)
        XCTAssertEqual(2, two)
        
        //火曜日
        let tuesDayString = "2021-2-9-13:00:00 +0000"
        let tuesDay = dateFormatter.date(from: tuesDayString)!
        let three = calendarRepository.getWeekId(tuesDay)
        XCTAssertEqual(3, three)
        
        //水曜日
        let wednesDayString = "2021-2-10-13:00:00 +0000"
        let wednesDay = dateFormatter.date(from: wednesDayString)!
        let four = calendarRepository.getWeekId(wednesDay)
        XCTAssertEqual(4, four)
        
        //木曜日
        let thursDayString = "2021-2-11-13:00:00 +0000"
        let thursDay = dateFormatter.date(from: thursDayString)!
        let five = calendarRepository.getWeekId(thursDay)
        XCTAssertEqual(5, five)
        
        //金曜日
        let friDayString = "2021-2-12-13:00:00 +0000"
        let friDay = dateFormatter.date(from: friDayString)!
        let six = calendarRepository.getWeekId(friDay)
        XCTAssertEqual(6, six)
        
        //土曜日
        let saturDayString = "2021-2-13-13:00:00 +0000"
        let saturDay = dateFormatter.date(from: saturDayString)!
        let seven = calendarRepository.getWeekId(saturDay)
        XCTAssertEqual(7, seven)
    }
}
