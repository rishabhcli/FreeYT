import XCTest

final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    @MainActor
    func testScreenshotOverviewDashboard() throws {
        launchDashboard(section: "overview")
        XCTAssertTrue(app.staticTexts["Protect YouTube privacy"].waitForExistence(timeout: 5))
        takeScreenshot(named: "Dashboard-Overview")
    }

    @MainActor
    func testScreenshotActivityDashboard() throws {
        launchDashboard(section: "activity")
        XCTAssertTrue(app.staticTexts["Recent protection"].waitForExistence(timeout: 5))
        takeScreenshot(named: "Dashboard-Activity")
    }

    @MainActor
    func testScreenshotExceptionsDashboard() throws {
        launchDashboard(section: "exceptions")
        XCTAssertTrue(app.staticTexts["Trusted site exceptions"].waitForExistence(timeout: 5))
        takeScreenshot(named: "Dashboard-Exceptions")
    }

    @MainActor
    func testScreenshotTrustDashboard() throws {
        launchDashboard(section: "trust")
        XCTAssertTrue(app.staticTexts["Why FreeYT is trustworthy"].waitForExistence(timeout: 5))
        takeScreenshot(named: "Dashboard-Trust")
    }

    @MainActor
    func testScreenshotSetupDashboard() throws {
        launchDashboard(section: "setup")
        XCTAssertTrue(app.staticTexts["Setup and verification"].waitForExistence(timeout: 5))
        takeScreenshot(named: "Dashboard-Setup")
    }

    private func launchDashboard(section: String) {
        app = XCUIApplication()
        app.launchArguments = [
            "-uiTestingResetState", "YES",
            "-uiTestingSeedDashboard", "YES",
            "-onboardingCompleted", "YES",
            "-dashboardSection", section
        ]
        app.launch()
    }

    private func takeScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
