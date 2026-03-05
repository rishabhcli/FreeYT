import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-onboardingCompleted", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Helpers

    private func takeScreenshot(named name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Main Screen Screenshots

    @MainActor
    func testScreenshotMainScreenLight() throws {
        let freeYTText = app.staticTexts["FreeYT"]
        XCTAssertTrue(freeYTText.waitForExistence(timeout: 5))
        takeScreenshot(named: "MainScreen-Light")
    }

    @MainActor
    func testScreenshotMainScreenDark() throws {
        let freeYTText = app.staticTexts["FreeYT"]
        XCTAssertTrue(freeYTText.waitForExistence(timeout: 5))
        takeScreenshot(named: "MainScreen-Dark")
    }

    // MARK: - Panel Screenshots

    @MainActor
    func testScreenshotStatusPanel() throws {
        let statusText = app.staticTexts["Shield active"]
        let statusTextAlt = app.staticTexts["Shield paused"]
        let found = statusText.waitForExistence(timeout: 5) || statusTextAlt.waitForExistence(timeout: 5)
        XCTAssertTrue(found, "Status panel should be visible")
        takeScreenshot(named: "StatusPanel")
    }

    @MainActor
    func testScreenshotStepsPanel() throws {
        let stepsHeading = app.staticTexts["Enable in Safari"]
        XCTAssertTrue(stepsHeading.waitForExistence(timeout: 5))
        takeScreenshot(named: "StepsPanel")
    }

    @MainActor
    func testScreenshotStatistics() throws {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 5) else {
            XCTFail("Scroll view not found")
            return
        }
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot(named: "Statistics")
    }

    @MainActor
    func testScreenshotDiagnostics() throws {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 5) else {
            XCTFail("Scroll view not found")
            return
        }
        scrollView.swipeUp()
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot(named: "Diagnostics")
    }

    @MainActor
    func testScreenshotFullScrollSequence() throws {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 5) else {
            XCTFail("Scroll view not found")
            return
        }

        takeScreenshot(named: "FullScroll-Top")

        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.3)
        takeScreenshot(named: "FullScroll-Middle")

        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.3)
        takeScreenshot(named: "FullScroll-Bottom")
    }
}
