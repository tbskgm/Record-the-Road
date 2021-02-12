//
//  ViewModelTests.swift
//  Record the RoadTests
//
//  Created by 小駒翼 on 2021/02/09.
//  Copyright © 2021 Tsubasa Kogoma. All rights reserved.
//

import XCTest

@testable import Record_the_Road


class LocationViewModelTests: XCTestCase {
    let locationViewModel: LocationViewModelProtocol = LocationViewModel()
    
    func testGetPinDatasのテスト(){
        // テスト情報の作成
        var fakeLocationDatas: [LocationData] {
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
        
        // 両方のデータを取り出しEqualで比較する, repositoryのgetOneDayDataのやり方を使用する
        let deleteTime = 120
        locationViewModel.getPinDatas(startValue: -1, deleteTime: deleteTime)
        
        locationViewModel.getPinDatas(startDate: Date(timeIntervalSinceNow: -86400), deleteTime: deleteTime)
    }
    
    func testRemovePinsのテスト() {
        locationViewModel.removePins().subscribe(
            onSuccess: { result in
                // 成功
                
            }, onError: { error in
                XCTFail()
            })
    }
    
    func testGetAuthorizationStatusのテスト() {
        
    }
}

class RealmViewModelTests: XCTestCase {
    let realmViewModel: RealmViewModelProtocol = RealmViewModel()
    
    //テストデータ
    let testDatas = TestLocationData.testDatas
    
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
        realmViewModel.getOneDayData(startValue: 0).subscribe(
            onSuccess: { result in
                startValue = result
            }, onError: { error in
                XCTFail()
            })
            .dispose()
        
        // startDayで今日の日付を取得
        let timeViewModel: TimeViewModelProtocol = TimeViewModel()
        let date = timeViewModel.getStartOfDay(selectDay: Date())
        var startDate: [LocationData]!
        realmViewModel.getOneDayData(startDate: date).subscribe(
            onSuccess: { result in
                startDate = result
            }, onError: { error in
                XCTFail()
            })
            .dispose()
        
        // 同じデータが取れているかテスト
        XCTAssertEqual(startValue, startDate)
    }
    
    func testDeleteDataのテスト() {
        let realmRepository: RealmRepositoryProtocol = RealmRepository()
        realmRepository.getAllData().subscribe(onSuccess: { allData in
            for data in allData {
                // テストデータ以外はcontinue
                guard data.latitude == 150, data.longitude == 150 else {
                    continue
                }
                self.realmViewModel.deleteData(locationData: data)
            }
        }, onError: { error in
            XCTFail()
        })
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

class xNotificationViewModelTests: XCTestCase {
    let notificationViewModel: NotificationViewModelProtocol = NotificationViewModel()
    
    func xtestAskNotificationPermissionのテスト() {
        
    }
    
    func xtestNotificationのテスト() {
        
    }
    
    
}

