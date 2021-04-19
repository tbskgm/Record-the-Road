//
//  Record_the_RoadTests.swift
//  Record the RoadTests
//
//  Created by 小駒翼 on 2020/12/13.
//  Copyright © 2020 Tsubasa Kogoma. All rights reserved.
//

import XCTest
import MapKit
import RxSwift

@testable import Record_the_Road


class LocationDataTests: XCTestCase {
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


class LocationRepositoryTests: XCTestCase {
    let locationRepository: LocationRepositoryProtocol = LocationRepository()
    
    func testRemovePinsのテスト() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.676226, longitude: 139.699385)
        let title = "2020-12-20-12:53:32 +0000"
        let subTitle = "1日 8時間 37分 7秒"
        let spot = Spot(coordinate: coordinate, title: title, subtitle: subTitle)
        
        let spots = [spot]
        let expectation = self.expectation(description: "testRemovePinsのテスト")
        locationRepository.removePins(previousDatas: spots).subscribe(onSuccess: { spots in
            let spot = spots[0]
            /// 比較
            XCTAssertEqual(coordinate.latitude, spot.coordinate.latitude)
            XCTAssertEqual(coordinate.longitude, spot.coordinate.longitude)
            XCTAssertEqual(title, spot.title)
            XCTAssertEqual(subTitle, spot.subtitle)
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testAddPinsのテスト() {
        let testLocationDatas = TestLocationData.testDatas
        
        /// 地図に立てるピンの情報を取得
        let expectation = self.expectation(description: "testAddPinsのテスト")
        expectation.assertForOverFulfill = false
        
        locationRepository.getPinDatas(locationDatas: testLocationDatas).subscribe(onSuccess: { pinDatas in
            var count = 0
            for pinData in pinDatas {
                let coordinate = pinData.coordinate
                let timestamp = pinData.title
                
                let testLatitude = testLocationDatas[count].latitude
                let testLongitude = testLocationDatas[count].longitude
                let testTimestamp = testLocationDatas[count].timestamp
                
                // 比較
                XCTAssertEqual(coordinate.latitude, testLatitude)
                XCTAssertEqual(coordinate.longitude, testLongitude)
                XCTAssertEqual(timestamp, testTimestamp)
                
                count += 1
                expectation.fulfill()
            }
        }, onError: { error in
            XCTFail("\(error)")
        })
        .dispose()
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetAuthorizationStatusのテスト() {
        let clLocationManager = CLLocationManager()
        let status = clLocationManager.authorizationStatus
        
        let expectation = self.expectation(description: "testGetAuthorizationStatusのテスト")
        locationRepository.getAuthorizationStatus(status: status).subscribe(onSuccess: { status in
            XCTAssertNotNil(status, "statusが取得できるかテスト")
            
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        wait(for: [expectation], timeout: 1)
    }
}

class RealmRepositoryTests: XCTestCase {
    let realmRepository: RealmRepositoryProtocol = RealmRepository()
    let disposeBag = DisposeBag()
    // テストデータ
    let testDatas = TestLocationData.testDatas
    
    func testSaveDataのテスト() {
        // 保存できなかった場合はrepositoryでラーが発生する
        let expectation = self.expectation(description: "testSaveDataのテスト")
        expectation.assertForOverFulfill = false
        for testData in testDatas {
            realmRepository.saveData(locationData: testData).subscribe().dispose()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetAllDataのテスト() {
        // 取り出す事が可能かテスト
        let expectation = self.expectation(description: "testGetAllDataのテスト")
        
        realmRepository.getAllData().subscribe(onSuccess: { result in
            XCTAssertNotNil(result, "結果がnilじゃないかテスト")
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testGetOneDayDataのテスト() {
        // テストデータの追加
        let expectation = self.expectation(description: "testGetOneDayDataのテスト")
        expectation.assertForOverFulfill = false
        
        for testData in testDatas {
            realmRepository.saveData(locationData: testData).subscribe(onSuccess: { _ in
                expectation.fulfill()
            }, onError: { _ in
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }
        
        // 一日分のデータを取得するためのDateを作成
        let yesterday = Date(timeIntervalSinceNow: -86400)
        let today = Date()
        
        // 一日分のデータ取得
        realmRepository.getOneDayData(startDate: yesterday, endDate: today).subscribe(onSuccess: { oneDayData in
            // 最初のデータが存在するか確認、時刻を取得
            guard let firstDate = oneDayData.first?.timestamp else {
                XCTFail("テストデータの作成にミスがあります")
                return
            }
            XCTAssertLessThan(yesterday, firstDate)
            
            // 最後のデータがendDateよりも前の時刻か調べる
            guard let lastDate = oneDayData.last?.timestamp else {
                XCTFail("テストデータの作成にミスがあります")
                return
            }
            XCTAssertGreaterThan(today, lastDate)
            
            expectation.fulfill()
        }, onError: { error in
            XCTFail("\(error)")
        })
        .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDeleteDataのテスト() {
        let expectation = self.expectation(description: "testDeleteDataのテスト.getAllData")
        expectation.assertForOverFulfill = false
        
        // テストデータ追加
        for testData in testDatas {
            realmRepository.saveData(locationData: testData).subscribe().disposed(by: disposeBag)
            expectation.fulfill()
        }
        
        // テストデータの削除
        var allData: [LocationData]?
        
        realmRepository.getAllData().subscribe(onSuccess: { result in
            let data: [LocationData] = result
            allData = data
            
            // allDataが0だったらエラーを起こす
            guard allData?.count != 0 else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .disposed(by: disposeBag)
        
        for data in allData! {
            // テストデータ以外はcontinue
            guard data.latitude == 150, data.longitude == 150 else {
                continue
            }
            
            // テストデータ削除
            self.realmRepository.deleteData(locationData: data).subscribe(onSuccess: { result in
                expectation.fulfill()
            }, onError: { error in
                XCTFail()
            })
            .disposed(by: disposeBag)
        }
        wait(for: [expectation], timeout: 3)
    }
}

class CalendarRepositoryTests: XCTestCase {
    let calendarRepository: CalendarRepositoryProtocol = CalendarRepository()
    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        return dateFormatter
    }
    func testJudgeHolidayのテスト() {
        // 平日の日曜日
        let sundayString = "2021-2-7-13:00:00 +0000"
        let sunday = dateFormatter.date(from: sundayString)!
        let isSunday = calendarRepository.judgeHoliday(sunday)
        XCTAssertFalse(isSunday)
        
        // 建国記念の日
        let holiDayString = "2021-2-11-13:00:00 +0000"
        let holiDay = dateFormatter.date(from: holiDayString)!
        let isHoliDay = calendarRepository.judgeHoliday(holiDay)
        XCTAssertTrue(isHoliDay)
        
    }
    
    func testGetWeekIdのテスト() {
        // 日曜日
        let sundayString = "2021-2-7-13:00:00 +0000"
        let sunday = dateFormatter.date(from: sundayString)!
        let one = calendarRepository.getWeekId(sunday)
        XCTAssertEqual(1, one)
        
        // 月曜日
        let mondayString = "2021-2-8-13:00:00 +0000"
        let monday = dateFormatter.date(from: mondayString)!
        let two = calendarRepository.getWeekId(monday)
        XCTAssertEqual(2, two)
        
        // 火曜日
        let tuesDayString = "2021-2-9-13:00:00 +0000"
        let tuesDay = dateFormatter.date(from: tuesDayString)!
        let three = calendarRepository.getWeekId(tuesDay)
        XCTAssertEqual(3, three)
        
        // 水曜日
        let wednesDayString = "2021-2-10-13:00:00 +0000"
        let wednesDay = dateFormatter.date(from: wednesDayString)!
        let four = calendarRepository.getWeekId(wednesDay)
        XCTAssertEqual(4, four)
        
        // 木曜日
        let thursDayString = "2021-2-11-13:00:00 +0000"
        let thursDay = dateFormatter.date(from: thursDayString)!
        let five = calendarRepository.getWeekId(thursDay)
        XCTAssertEqual(5, five)
        
        // 金曜日
        let friDayString = "2021-2-12-13:00:00 +0000"
        let friDay = dateFormatter.date(from: friDayString)!
        let six = calendarRepository.getWeekId(friDay)
        XCTAssertEqual(6, six)
        
        // 土曜日
        let saturDayString = "2021-2-13-13:00:00 +0000"
        let saturDay = dateFormatter.date(from: saturDayString)!
        let seven = calendarRepository.getWeekId(saturDay)
        XCTAssertEqual(7, seven)
    }
}
