//
//  FreeYTUITests.swift
//  FreeYTUITests
//

import XCTest

final class FreeYTUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    @MainActor
    func testOnboardingShowsGuidedSetupFlow() throws {
        launchApp(onboardingCompleted: false)

        XCTAssertTrue(app.staticTexts["FreeYT setup"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A privacy-first YouTube companion"].exists)
        XCTAssertTrue(app.buttons["Continue"].exists)
    }

    @MainActor
    func testOnboardingCanAdvanceIntoDashboard() throws {
        launchApp(onboardingCompleted: false)

        for _ in 0..<3 {
            let continueButton = app.buttons["Continue"]
            XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
            continueButton.tap()
        }

        let openDashboardButton = app.buttons["Open dashboard"]
        XCTAssertTrue(openDashboardButton.waitForExistence(timeout: 5))
        openDashboardButton.tap()

        XCTAssertTrue(app.staticTexts["Protect YouTube privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Protection is active"].exists || app.staticTexts["Protection is paused"].exists)
    }

    @MainActor
    func testOverviewDashboardShowsStatusAndActions() throws {
        launchApp(onboardingCompleted: true, section: "overview", seeded: true)

        XCTAssertTrue(app.staticTexts["Protect YouTube privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Protection is active"].exists || app.staticTexts["Protection is paused"].exists)
        XCTAssertTrue(app.buttons["Open Safari Settings"].exists)
        XCTAssertTrue(app.switches["FreeYT Shield toggle"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActivitySectionShowsTrendAndRecentRoutes() throws {
        launchApp(onboardingCompleted: true, section: "activity", seeded: true)

        XCTAssertTrue(app.staticTexts["Recent protection"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Latest protected routes"].exists)
        XCTAssertTrue(app.staticTexts["Video protected"].exists || app.staticTexts["Short link protected"].exists)
    }

    @MainActor
    func testExceptionsSectionShowsTrustedSiteManagement() throws {
        launchApp(onboardingCompleted: true, section: "exceptions", seeded: true)

        XCTAssertTrue(app.staticTexts["Trusted site exceptions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["music.youtube.com"].exists)
        XCTAssertTrue(app.buttons["Add"].exists)
        XCTAssertTrue(app.staticTexts["music.youtube.com"].exists)
    }

    @MainActor
    func testTrustSectionExplainsLocalProcessing() throws {
        launchApp(onboardingCompleted: true, section: "trust", seeded: true)

        XCTAssertTrue(app.staticTexts["Why FreeYT is trustworthy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Local only"].exists)
        XCTAssertTrue(app.buttons["Refresh dashboard"].exists)
        XCTAssertTrue(app.buttons["Review Safari access"].exists)
    }

    @MainActor
    func testSetupSectionShowsVerificationChecklist() throws {
        launchApp(onboardingCompleted: true, section: "setup", seeded: true)

        XCTAssertTrue(app.staticTexts["Setup and verification"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Verify a protected route"].exists)
        XCTAssertTrue(app.staticTexts["Use Exceptions only when needed"].exists)
    }

    @MainActor
    func testDashboardRemainsStableAcrossOrientationChanges() throws {
        launchApp(onboardingCompleted: true, section: "overview", seeded: true)
        XCTAssertTrue(app.staticTexts["Protect YouTube privacy"].waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["Protect YouTube privacy"].waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["Protect YouTube privacy"].waitForExistence(timeout: 5))
    }

    private func launchApp(onboardingCompleted: Bool, section: String? = nil, seeded: Bool = false) {
        app = XCUIApplication()
        app.launchArguments = [
            "-uiTestingResetState", "YES",
            "-onboardingCompleted", onboardingCompleted ? "YES" : "NO"
        ]

        if let section {
            app.launchArguments += ["-dashboardSection", section]
        }

        if seeded {
            app.launchArguments += ["-uiTestingSeedDashboard", "YES"]
        }

        app.launch()
    }
}
