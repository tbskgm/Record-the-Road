//
//  ViewModelTests.swift
//  Record the RoadTests
//
//  Created by 小駒翼 on 2021/02/09.
//  Copyright © 2021 Tsubasa Kogoma. All rights reserved.
//

import XCTest
import RxSwift
import MapKit

@testable import Record_the_Road

class MockLocationViewModel: LocationViewModelProtocol {
    let locationRepository: LocationRepositoryProtocol = LocationRepository()
    // 地図に立てられているピンを保存する
    private var previousDatas = [Spot]()
    
    // テスト情報の作成
    typealias spotData = (coordinate: CLLocationCoordinate2D, title:  Date, subtitle: Int)
    
    var fakeData: [spotData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let coordinate = CLLocationCoordinate2D(latitude: 180, longitude: 180)
        let string1 = "2020-12-20 12:53:32 +0900"
        let title1: Date = dateFormatter.date(from: string1)!
        let subtitle1 = 100
        
        let string2 = "2020-12-20 12:53:42 +0900"
        let title2: Date = dateFormatter.date(from: string2)!
        let subtitle2 = 100
        
        let data: [spotData] = [(coordinate, title1, subtitle1), (coordinate, title2, subtitle2)]
        return data
    }
    
    
    func getPinDatas(startValue: Int, deleteTime: Int) -> Single<[Spot]> {
        return Single<[Spot]>.create { single -> Disposable in
            let spots = self.fakeData
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
            
            single(.success(spotArray))
            return Disposables.create()
        }
    }
    
    func getPinDatas(startDate: Date, deleteTime: Int) -> Single<[Spot]> {
        return Single<[Spot]>.create { single -> Disposable in
            let spots = self.fakeData
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
            single(.success(spotArray))
            return Disposables.create()
        }
    }
    
    func removePins() -> Single<[Spot]> {
        return self.locationRepository.removePins(previousDatas: previousDatas).map { spots -> [Spot] in
            self.previousDatas = []
            return spots
        }
    }
    
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
class LocationViewModelTests: XCTestCase {
    let mockLocationViewModel: LocationViewModelProtocol = MockLocationViewModel()
    var fakeSpotData: [Spot] {
        let coordinate = CLLocationCoordinate2D(latitude: 180, longitude: 180)
        let subtitle = "0日 0時間 1分 40秒"
        let title1 = "2020-12-20 12:53:32 +0900"
        let spot1 = Spot(coordinate: coordinate, title: title1, subtitle: subtitle)
        
        let title2 = "2020-12-20 12:53:42 +0900"
        let spot2 = Spot(coordinate: coordinate, title: title2, subtitle: subtitle)
        
        let data = [spot1, spot2]
        return data
    }
    
    func testGetPinDatasのテスト(){
        let expectation = self.expectation(description: "testGetPinDatasのテスト")
        expectation.expectedFulfillmentCount = 2
        // 引数に使用していない
        var spot1: [Spot]!
        mockLocationViewModel.getPinDatas(startValue: 0, deleteTime: 0).subscribe(onSuccess: { result in
            spot1 = result
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        
        var spot2: [Spot]!
        mockLocationViewModel.getPinDatas(startDate: Date(), deleteTime: 0).subscribe(onSuccess: { result in
            spot2 = result
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        
        // spot1の比較
        XCTAssertEqual(spot1[0].coordinate.latitude, fakeSpotData[0].coordinate.latitude)
        XCTAssertEqual(spot1[0].coordinate.longitude, fakeSpotData[0].coordinate.longitude)
        XCTAssertEqual(spot1[0].title, fakeSpotData[0].title)
        XCTAssertEqual(spot1[0].subtitle, fakeSpotData[0].subtitle)
        XCTAssertEqual(spot1[1].coordinate.latitude, fakeSpotData[1].coordinate.latitude)
        XCTAssertEqual(spot1[1].coordinate.longitude, fakeSpotData[1].coordinate.longitude)
        XCTAssertEqual(spot1[1].title, fakeSpotData[1].title)
        XCTAssertEqual(spot1[1].subtitle, fakeSpotData[1].subtitle)
        
        // spot2の比較
        XCTAssertEqual(spot2[0].coordinate.latitude, fakeSpotData[0].coordinate.latitude)
        XCTAssertEqual(spot2[0].coordinate.longitude, fakeSpotData[0].coordinate.longitude)
        XCTAssertEqual(spot2[0].title, fakeSpotData[0].title)
        XCTAssertEqual(spot2[0].subtitle, fakeSpotData[0].subtitle)
        XCTAssertEqual(spot2[1].coordinate.latitude, fakeSpotData[1].coordinate.latitude)
        XCTAssertEqual(spot2[1].coordinate.longitude, fakeSpotData[1].coordinate.longitude)
        XCTAssertEqual(spot2[1].title, fakeSpotData[1].title)
        XCTAssertEqual(spot2[1].subtitle, fakeSpotData[1].subtitle)
        
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testRemovePinsのテスト() {
        let expectation = self.expectation(description: "testRemovePinsのテスト")
        mockLocationViewModel.removePins().subscribe(onSuccess: { result in
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        wait(for: [expectation], timeout: 1)
    }
    
    func xtestGetAuthorizationStatusのテスト() {
        
    }
}

class RealmViewModelTests: XCTestCase {
    let realmViewModel: RealmViewModelProtocol = RealmViewModel()
    
    //テストデータ
    let testDatas = LocationDataTests.testDatas
    
    func testSaveDataのテスト() {
        for testData in testDatas {
            let latitude = testData.latitude
            let longitude = testData.longitude
            let timestamp = testData.timestamp
            realmViewModel.saveData(longitude: latitude, latitude: longitude, timestamp: timestamp)
        }
    }
    
    func testGetOneDayDataのテスト() {
        // startValueで今日の日付を取得
        var startValue:[LocationData]!
        realmViewModel.getOneDayData(startValue: 0).subscribe(onSuccess: { result in
            startValue = result
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        // startDayで今日の日付を取得
        let timeViewModel: TimeViewModelProtocol = TimeViewModel()
        let date = timeViewModel.getStartOfDay(selectDay: Date())
        var startDate: [LocationData]!
        realmViewModel.getOneDayData(startDate: date).subscribe(onSuccess: { result in
            startDate = result
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        // 同じデータが取れているかテスト
        XCTAssertEqual(startValue, startDate)
    }
    
    func testFilterのテスト() {
        let realmRepository: RealmRepositoryProtocol = RealmRepository()
        let expectation = self.expectation(description: "testFilterのテスト")
        expectation.assertForOverFulfill = false
        
        realmRepository.getAllData().subscribe(onSuccess: { allData in
            for data in allData {
                // テストデータ以外はcontinue
                guard data.latitude == 150, data.longitude == 150 else {
                    expectation.fulfill()
                    continue
                }
                self.realmViewModel.deleteData(locationData: data).subscribe(onSuccess: { _ in
                }, onError: { error in
                    XCTFail()
                })
            }
            expectation.fulfill()
        }, onError: { error in
            XCTFail()
        })
        .dispose()
        
        wait(for: [expectation], timeout: 1)
    }
}

class CalendarViewModelTests: XCTestCase {
    let calendarViewModel: CalendarViewModelProtocol = CalendarViewModel()
    
    func testJudgeHolidayのテスト() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        //平日の日曜日
        let sundayString = "2021-2-7-13:00:00 +0000"
        let sunday = dateFormatter.date(from: sundayString)!
        let isSunday = calendarViewModel.judgeHoliday(sunday)
        XCTAssertFalse(isSunday)
        
        //建国記念の日
        let holiDayString = "2021-2-11-13:00:00 +0000"
        let holiDay = dateFormatter.date(from: holiDayString)!
        let isHoliDay = calendarViewModel.judgeHoliday(holiDay)
        XCTAssertTrue(isHoliDay)
    }
    
    func testGetWeekIdのテスト() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        //日曜日
        let sundayString = "2021-2-7-13:00:00 +0000"
        let sunday = dateFormatter.date(from: sundayString)!
        let one = calendarViewModel.getWeekId(sunday)
        XCTAssertEqual(1, one)
        
        //月曜日
        let mondayString = "2021-2-8-13:00:00 +0000"
        let monday = dateFormatter.date(from: mondayString)!
        let two = calendarViewModel.getWeekId(monday)
        XCTAssertEqual(2, two)
        
        //火曜日
        let tuesDayString = "2021-2-9-13:00:00 +0000"
        let tuesDay = dateFormatter.date(from: tuesDayString)!
        let three = calendarViewModel.getWeekId(tuesDay)
        XCTAssertEqual(3, three)
        
        //水曜日
        let wednesDayString = "2021-2-10-13:00:00 +0000"
        let wednesDay = dateFormatter.date(from: wednesDayString)!
        let four = calendarViewModel.getWeekId(wednesDay)
        XCTAssertEqual(4, four)
        
        //木曜日
        let thursDayString = "2021-2-11-13:00:00 +0000"
        let thursDay = dateFormatter.date(from: thursDayString)!
        let five = calendarViewModel.getWeekId(thursDay)
        XCTAssertEqual(5, five)
        
        //金曜日
        let friDayString = "2021-2-12-13:00:00 +0000"
        let friDay = dateFormatter.date(from: friDayString)!
        let six = calendarViewModel.getWeekId(friDay)
        XCTAssertEqual(6, six)
        
        //土曜日
        let saturDayString = "2021-2-13-13:00:00 +0000"
        let saturDay = dateFormatter.date(from: saturDayString)!
        let seven = calendarViewModel.getWeekId(saturDay)
        XCTAssertEqual(7, seven)
    }
}

class TimeViewModelTests: XCTestCase {
    let timeViewModel: TimeViewModelProtocol = TimeViewModel()
    var dateFormatter = DateFormatter()
    let calendar = Calendar.current
    
    func returnYearMonthDay(date: Date) -> (year: Int, month: Int, day: Int) {
        let calendarComponent = Calendar.Component.self
        let components = calendar.dateComponents([calendarComponent.year, calendarComponent.month, calendarComponent.day], from: date)
        let year = components.year!
        let month = components.month!
        let day = components.day!
        return (year: year, month: month, day: day)
    }
    
    func testDateToStringのテスト() {
        // 比較対象を取得
        let dateToString = timeViewModel.dateToString(date: Date())
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let formatterString = dateFormatter.string(from: Date())
        
        // 比較
        XCTAssertEqual(dateToString, formatterString)
    }
    
    func testStringToDateのテスト() {
        // 比較対象を取得
        let stringToDate = timeViewModel.stringToDate(stringDate: "1970-01-01 00:00:00 +0000")
        let dateIn1970 = Date(timeIntervalSince1970: 0)
        
        XCTAssertEqual(stringToDate, dateIn1970)
    }
    
    func testDifferenceのテスト() {
        let startDate = Date()
        let endDate = Date(timeIntervalSinceNow: 86400)
        
        let difference = timeViewModel.difference(startDate: startDate, endDate: endDate)
        
        XCTAssertEqual(difference, 86400)
    }
    
    func testGetstartOfDayCustomizedValueのテスト() {
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        // 年、月、日を取得
        let date = Date()
        let yearMonthDay = returnYearMonthDay(date: date)
        let year = yearMonthDay.year
        let month = yearMonthDay.month
        let day = yearMonthDay.day
        
        let string = "\(year)-\(month)-\(day)-15:00:00 +0000"
        let correctToday = dateFormatter.date(from: string)!
        
        // 取得
        let testToday = timeViewModel.getStartOfDayCustomizedValue(value: 0)
        
        XCTAssertEqual(testToday, correctToday)
    }
    
    func testGetstartOfDayのテスト() {
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        // 年、月、日を取得
        let date = Date()
        let yearMonthDay = returnYearMonthDay(date: date)
        let year = yearMonthDay.year
        let month = yearMonthDay.month
        let day = yearMonthDay.day
        
        let string = "\(year)-\(month)-\(day)-15:00:00 +0000"
        let correctToday = dateFormatter.date(from: string)!
        
        // テストインスタンス作成
        let testToday = timeViewModel.getStartOfDay(selectDay: date)
        
        // 比較テスト
        XCTAssertEqual(testToday, correctToday)
    }
    
    func testSpecificedDateのテスト() {
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss Z"
        
        // 年、月、日を取得
        let date = Date()
        let todayDay = returnYearMonthDay(date: date)
        let year0 = todayDay.year
        let month0 = todayDay.month
        let day0 = todayDay.day
        
        let todayString = "\(year0)-\(month0)-\(day0)-15:00:00 +0000"
        let correctToday = dateFormatter.date(from: todayString)!
        
        // テストインスタンス作成
        let testToday = timeViewModel.specificedDate(value: 0, selectDay: date)
        
        // 比較テスト
        XCTAssertEqual(testToday, correctToday)
        
        let tomorrowDate = Date(timeIntervalSinceNow: 86400)
        let tomorrowDay = returnYearMonthDay(date: tomorrowDate)
        let year1 = tomorrowDay.year
        let month1 = tomorrowDay.month
        let day1 = tomorrowDay.day
        
        let tomorrowString = "\(year1)-\(month1)-\(day1)-15:00:00 +0000"
        let correctTomorrow = dateFormatter.date(from: tomorrowString)!
        
        XCTAssertNotEqual(testToday, correctTomorrow)
    }
    
    func testTimeConversionのテスト() {
        // 正解になるテスト
        let second1Day1hour1minute1second = 90061
        let allOne = timeViewModel.timeConversion(secondTime: second1Day1hour1minute1second)
        XCTAssertEqual(allOne, "1日 1時間 1分 1秒")
        
        // 不正解になるテスト
        let oneHour = 3600
        let hour = timeViewModel.timeConversion(secondTime: oneHour)
        XCTAssertNotEqual(hour, "0日 1時間 1分 0秒")
    }
    
    func testSecondConversion() {
        // 正解になるテスト
        let correct = 3600
        let test = timeViewModel.secondConversion(hour: 1, minute: 0, second: 0)
        XCTAssertEqual(test, correct)
        
        // 不正解になるテスト
        let oneMinute = 60
        let unCorrect = timeViewModel.secondConversion(hour: 0, minute: 1, second: 1)
        XCTAssertNotEqual(unCorrect, oneMinute)
    }
}

class AlertViewModelTests: XCTestCase {
    let alertViewModel: AlertViewModelProtocol = AlertViewModel()
    
    func testShowAlertのテスト() {
        let alert = alertViewModel.showAlert(message: "テスト")
        XCTAssertNotNil(alert)
    }
    
    func testGoToSettingsのテスト() {
        let alert = alertViewModel.goToSettings(message: "テスト")
        XCTAssertNotNil(alert)
    }
}

class NotificationViewModelTests: XCTestCase {
    let notificationViewModel: NotificationViewModelProtocol = NotificationViewModel()

    func xtestAskNotificationPermissionのテスト() {
        
    }
    
    func xtestNotificationのテスト() {
        
    }
}

