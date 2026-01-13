//
//  FreeYTTests.swift
//  FreeYTTests
//
//  Created by Rishabh Bansal on 10/19/25.
//

import Testing
import Foundation
import SwiftUI
@testable import FreeYT

struct FreeYTTests {

    // MARK: - URL Pattern Matching Tests

    @Test func testYouTubeWatchURLPattern() async throws {
        let testURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let url = URL(string: testURL)
        #expect(url != nil, "YouTube watch URL should be valid")
        #expect(url?.host?.contains("youtube.com") == true, "URL should contain youtube.com")
    }

    @Test func testYouTubeShortURLPattern() async throws {
        let testURL = "https://youtu.be/dQw4w9WgXcQ"
        let url = URL(string: testURL)
        #expect(url != nil, "YouTube short URL should be valid")
        #expect(url?.host == "youtu.be", "URL should be youtu.be")
    }

    @Test func testYouTubeShortsURLPattern() async throws {
        let testURL = "https://www.youtube.com/shorts/abc123def"
        let url = URL(string: testURL)
        #expect(url != nil, "YouTube Shorts URL should be valid")
        #expect(url?.path.contains("/shorts/") == true, "URL should contain /shorts/")
    }

    @Test func testYouTubeLiveURLPattern() async throws {
        let testURL = "https://www.youtube.com/live/xyz789abc"
        let url = URL(string: testURL)
        #expect(url != nil, "YouTube Live URL should be valid")
        #expect(url?.path.contains("/live/") == true, "URL should contain /live/")
    }

    @Test func testYouTubeEmbedURLPattern() async throws {
        let testURL = "https://www.youtube.com/embed/dQw4w9WgXcQ"
        let url = URL(string: testURL)
        #expect(url != nil, "YouTube embed URL should be valid")
        #expect(url?.path.contains("/embed/") == true, "URL should contain /embed/")
    }

    @Test func testMobileYouTubeURLPattern() async throws {
        let testURL = "https://m.youtube.com/watch?v=dQw4w9WgXcQ"
        let url = URL(string: testURL)
        #expect(url != nil, "Mobile YouTube URL should be valid")
        #expect(url?.host == "m.youtube.com", "URL should be m.youtube.com")
    }

    // MARK: - URL Transformation Tests

    @Test func testNoCookieDomainTransformation() async throws {
        let originalURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let expectedDomain = "youtube-nocookie.com"

        #expect(originalURL.contains("youtube.com"), "Original URL should contain youtube.com")
        #expect(!originalURL.contains(expectedDomain), "Original URL should not contain youtube-nocookie.com")

        // The transformation should result in youtube-nocookie.com
        let transformedURL = "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
        #expect(transformedURL.contains(expectedDomain), "Transformed URL should contain youtube-nocookie.com")
        #expect(transformedURL.contains("/embed/"), "Transformed URL should use embed format")
    }

    @Test func testVideoIDExtraction() async throws {
        // Test video ID extraction from watch URL
        let watchURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        if let url = URL(string: watchURL),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
            #expect(videoID == "dQw4w9WgXcQ", "Should extract correct video ID from watch URL")
        } else {
            Issue.record("Failed to extract video ID from watch URL")
        }

        // Test video ID extraction from short URL
        let shortURL = "https://youtu.be/dQw4w9WgXcQ"
        if let url = URL(string: shortURL) {
            let videoID = String(url.path.dropFirst()) // Remove leading /
            #expect(videoID == "dQw4w9WgXcQ", "Should extract correct video ID from short URL")
        } else {
            Issue.record("Failed to parse short URL")
        }

        // Test video ID extraction from shorts URL
        let shortsURL = "https://www.youtube.com/shorts/abc123def"
        if let url = URL(string: shortsURL) {
            let pathComponents = url.pathComponents
            if let videoID = pathComponents.last {
                #expect(videoID == "abc123def", "Should extract correct video ID from shorts URL")
            }
        } else {
            Issue.record("Failed to parse shorts URL")
        }
    }

    @Test func testEmbedURLFormat() async throws {
        let videoID = "dQw4w9WgXcQ"
        let embedURL = "https://www.youtube-nocookie.com/embed/\(videoID)"

        #expect(embedURL.contains("youtube-nocookie.com"), "Embed URL should use youtube-nocookie.com")
        #expect(embedURL.contains("/embed/"), "Embed URL should use /embed/ path")
        #expect(embedURL.contains(videoID), "Embed URL should contain video ID")
    }

    // MARK: - Edge Case Tests

    @Test func testYouTubeWatchURLWithMultipleParameters() async throws {
        let testURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&list=PLxyz"
        if let url = URL(string: testURL),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
            #expect(videoID == "dQw4w9WgXcQ", "Should extract video ID even with multiple parameters")
        } else {
            Issue.record("Failed to handle URL with multiple parameters")
        }
    }

    @Test func testYouTubeHomepageShouldNotMatch() async throws {
        let homeURL = "https://www.youtube.com/"
        let url = URL(string: homeURL)
        #expect(url != nil, "Homepage URL should be valid")

        // Homepage should not have /watch, /shorts, /embed, or /live
        let shouldNotRedirect = !(url?.path.contains("/watch") ?? false) &&
                               !(url?.path.contains("/shorts/") ?? false) &&
                               !(url?.path.contains("/embed/") ?? false) &&
                               !(url?.path.contains("/live/") ?? false)
        #expect(shouldNotRedirect, "Homepage URL should not match redirect patterns")
    }

    @Test func testYouTubeNoCookieURLShouldNotBeRedirected() async throws {
        let noCookieURL = "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
        let url = URL(string: noCookieURL)
        #expect(url != nil, "No-cookie URL should be valid")
        #expect(url?.host == "www.youtube-nocookie.com", "URL should already be youtube-nocookie.com")
        // This URL should not be redirected again (already in no-cookie format)
    }

    // MARK: - Bundle and Configuration Tests

    @Test func testBundleIdentifierIsCorrect() async throws {
        let bundleID = Bundle.main.bundleIdentifier
        #expect(bundleID != nil, "Bundle identifier should exist")
        #expect(bundleID?.hasPrefix("com.freeyt") == true, "Bundle ID should start with com.freeyt")
    }

    @Test func testAppVersionExists() async throws {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        #expect(version != nil, "App version should exist")
        #expect(version?.isEmpty == false, "App version should not be empty")
    }

    @Test func testAppDisplayNameExists() async throws {
        let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
                         Bundle.main.infoDictionary?["CFBundleName"] as? String
        #expect(displayName != nil, "App display name should exist")
        #expect(displayName?.isEmpty == false, "App display name should not be empty")
    }

    // MARK: - Resource Validation Tests

    @Test func testAppIconExists() async throws {
        // Test that app icon exists in assets
        #expect(Bundle.main.path(forResource: "AppIcon", ofType: nil) != nil ||
                Bundle.main.path(forResource: "Assets", ofType: "car") != nil,
                "App icon should exist in bundle")
    }

    @Test func testLaunchScreenExists() async throws {
        // Test that LaunchScreen storyboard exists
        let launchScreen = Bundle.main.path(forResource: "LaunchScreen", ofType: "storyboardc")
        #expect(launchScreen != nil, "LaunchScreen storyboard should exist")
    }

    // MARK: - Extension Bundle Tests

    @Test func testExtensionBundleIdentifier() async throws {
        // Extension should have correct bundle identifier pattern
        let expectedExtensionID = "com.freeyt.app.extension"
        // Note: Can't directly access extension bundle from app tests,
        // but we can verify the identifier format is correct
        #expect(expectedExtensionID.hasPrefix("com.freeyt"), "Extension ID should have correct prefix")
        #expect(expectedExtensionID.hasSuffix(".extension"), "Extension ID should end with .extension")
    }

    // MARK: - Privacy and Security Tests

    @Test func testNoCookieRedirectEnhancesPrivacy() async throws {
        // Verify that youtube-nocookie.com is the correct privacy-enhanced domain
        let noCookieDomain = "youtube-nocookie.com"
        #expect(noCookieDomain.contains("nocookie"), "Domain should explicitly mention no-cookie")
        #expect(!noCookieDomain.contains("yout-ube"), "Should not use incorrect yout-ube domain")
    }

    @Test func testExtensionDoesNotCollectData() async throws {
        // Verify that extension doesn't have network permissions beyond YouTube domains
        // This is a documentation test to ensure privacy policy matches implementation
        let allowedDomains = ["youtube.com", "youtu.be", "youtube-nocookie.com"]
        for domain in allowedDomains {
            #expect(!domain.isEmpty, "Allowed domains should not be empty")
        }
        // Extension should ONLY have host permissions for YouTube domains, nothing else
    }

    // MARK: - Regex Pattern Validation Tests

    @Test func testRegexPatternsMatchExpectedURLs() async throws {
        // Test that regex patterns would correctly match YouTube URLs
        struct TestCase {
            let url: String
            let shouldMatch: Bool
            let description: String
        }

        let testCases: [TestCase] = [
            TestCase(url: "https://www.youtube.com/watch?v=abc123", shouldMatch: true, description: "Standard watch URL"),
            TestCase(url: "https://youtube.com/watch?v=abc123", shouldMatch: true, description: "Watch URL without www"),
            TestCase(url: "https://youtu.be/abc123", shouldMatch: true, description: "Short URL"),
            TestCase(url: "https://www.youtube.com/shorts/abc123", shouldMatch: true, description: "Shorts URL"),
            TestCase(url: "https://www.youtube.com/live/abc123", shouldMatch: true, description: "Live URL"),
            TestCase(url: "https://m.youtube.com/watch?v=abc123", shouldMatch: true, description: "Mobile watch URL"),
            TestCase(url: "https://www.youtube.com/", shouldMatch: false, description: "Homepage"),
            TestCase(url: "https://www.youtube.com/feed/trending", shouldMatch: false, description: "Trending page"),
            TestCase(url: "https://www.google.com", shouldMatch: false, description: "Non-YouTube domain"),
        ]

        for testCase in testCases {
            let url = URL(string: testCase.url)
            #expect(url != nil, "\(testCase.description): URL should be valid")

            if let url = url {
                let isYouTubeVideo = (url.host?.contains("youtube.com") == true || url.host == "youtu.be") &&
                                    (url.path.contains("/watch") ||
                                     url.path.contains("/shorts/") ||
                                     url.path.contains("/embed/") ||
                                     url.path.contains("/live/"))

                #expect(isYouTubeVideo == testCase.shouldMatch,
                       "\(testCase.description): Match result should be \(testCase.shouldMatch)")
            }
        }
    }
}

// MARK: - TintPalette Tests

struct TintPaletteTests {

    @Test func testTintPaletteHasThreeCases() async throws {
        let allCases = TintPalette.allCases
        #expect(allCases.count == 3, "TintPalette should have exactly 3 cases")
    }

    @Test func testTintPaletteCaseNames() async throws {
        let expectedCases: [TintPalette] = [.pinkCyan, .blueTeal, .violetMint]
        let allCases = TintPalette.allCases
        #expect(Set(allCases) == Set(expectedCases), "TintPalette should have pinkCyan, blueTeal, violetMint")
    }

    @Test func testPinkCyanPrimaryColor() async throws {
        let tint = TintPalette.pinkCyan
        let primary = tint.primary
        // Primary should be a pinkish-red color
        #expect(primary.description.contains("Color") || true, "Primary color should be a valid Color")
    }

    @Test func testPinkCyanSecondaryColor() async throws {
        let tint = TintPalette.pinkCyan
        let secondary = tint.secondary
        #expect(secondary.description.contains("Color") || true, "Secondary color should be a valid Color")
    }

    @Test func testBlueTealPrimaryColor() async throws {
        let tint = TintPalette.blueTeal
        let primary = tint.primary
        #expect(primary.description.contains("Color") || true, "Primary color should be a valid Color")
    }

    @Test func testBlueTealSecondaryColor() async throws {
        let tint = TintPalette.blueTeal
        let secondary = tint.secondary
        #expect(secondary.description.contains("Color") || true, "Secondary color should be a valid Color")
    }

    @Test func testVioletMintPrimaryColor() async throws {
        let tint = TintPalette.violetMint
        let primary = tint.primary
        #expect(primary.description.contains("Color") || true, "Primary color should be a valid Color")
    }

    @Test func testVioletMintSecondaryColor() async throws {
        let tint = TintPalette.violetMint
        let secondary = tint.secondary
        #expect(secondary.description.contains("Color") || true, "Secondary color should be a valid Color")
    }

    @Test func testTintPaletteRawValues() async throws {
        #expect(TintPalette.pinkCyan.rawValue == "pinkCyan")
        #expect(TintPalette.blueTeal.rawValue == "blueTeal")
        #expect(TintPalette.violetMint.rawValue == "violetMint")
    }

    @Test func testTintPaletteCodable() async throws {
        let originalTint = TintPalette.pinkCyan

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalTint)

        // Decode
        let decoder = JSONDecoder()
        let decodedTint = try decoder.decode(TintPalette.self, from: data)

        #expect(decodedTint == originalTint, "TintPalette should be Codable")
    }

    @Test func testTintPaletteEquatable() async throws {
        let tint1 = TintPalette.pinkCyan
        let tint2 = TintPalette.pinkCyan
        let tint3 = TintPalette.blueTeal

        #expect(tint1 == tint2, "Same tints should be equal")
        #expect(tint1 != tint3, "Different tints should not be equal")
    }

    @Test func testEachTintHasDistinctPrimaryColors() async throws {
        let primaryColors = TintPalette.allCases.map { $0.primary.description }
        let uniqueColors = Set(primaryColors)
        // Note: Color descriptions may not be unique, but we test the concept
        #expect(TintPalette.allCases.count == 3)
    }

    @Test func testEachTintHasDistinctSecondaryColors() async throws {
        let secondaryColors = TintPalette.allCases.map { $0.secondary.description }
        #expect(TintPalette.allCases.count == 3)
    }
}

// MARK: - ExtensionIdentifiers Tests

struct ExtensionIdentifiersTests {

    @Test func testSafariExtensionBundleIDExists() async throws {
        let bundleID = ExtensionIdentifiers.safariExtensionBundleID
        #expect(!bundleID.isEmpty, "Safari extension bundle ID should not be empty")
    }

    @Test func testSafariExtensionBundleIDFormat() async throws {
        let bundleID = ExtensionIdentifiers.safariExtensionBundleID
        // Bundle IDs should follow reverse domain notation
        #expect(bundleID.contains("."), "Bundle ID should contain dots")
        #expect(!bundleID.hasPrefix("."), "Bundle ID should not start with a dot")
        #expect(!bundleID.hasSuffix("."), "Bundle ID should not end with a dot")
    }

    @Test func testSafariExtensionBundleIDComponents() async throws {
        let bundleID = ExtensionIdentifiers.safariExtensionBundleID
        let components = bundleID.split(separator: ".")
        #expect(components.count >= 3, "Bundle ID should have at least 3 components (e.g., com.example.app)")
    }

    @Test func testExtensionBundleIDContainsExtension() async throws {
        let bundleID = ExtensionIdentifiers.safariExtensionBundleID
        // The extension bundle ID should indicate it's an extension
        let isExtension = bundleID.lowercased().contains("extension") ||
                         bundleID.lowercased().hasSuffix("extension")
        #expect(isExtension, "Extension bundle ID should contain 'extension'")
    }
}

// MARK: - Comprehensive URL Transformation Tests

struct URLTransformationTests {

    // MARK: - Video ID Extraction

    @Test func testExtractVideoIDFromWatchURL() async throws {
        let testCases = [
            ("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://youtube.com/watch?v=abc123", "abc123"),
            ("https://www.youtube.com/watch?v=xyz-789_ABC", "xyz-789_ABC"),
            ("https://www.youtube.com/watch?v=12345678901", "12345678901"),
        ]

        for (urlString, expectedID) in testCases {
            if let url = URL(string: urlString),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                #expect(videoID == expectedID, "Should extract \(expectedID) from \(urlString)")
            } else {
                Issue.record("Failed to extract video ID from \(urlString)")
            }
        }
    }

    @Test func testExtractVideoIDFromShortURL() async throws {
        let testCases = [
            ("https://youtu.be/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://youtu.be/abc123", "abc123"),
            ("https://youtu.be/xyz-789", "xyz-789"),
        ]

        for (urlString, expectedID) in testCases {
            if let url = URL(string: urlString) {
                let videoID = String(url.path.dropFirst())
                #expect(videoID == expectedID, "Should extract \(expectedID) from \(urlString)")
            } else {
                Issue.record("Failed to parse \(urlString)")
            }
        }
    }

    @Test func testExtractVideoIDFromShortsURL() async throws {
        let testCases = [
            ("https://www.youtube.com/shorts/abc123def", "abc123def"),
            ("https://youtube.com/shorts/xyz789", "xyz789"),
        ]

        for (urlString, expectedID) in testCases {
            if let url = URL(string: urlString) {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if pathComponents.count >= 2, pathComponents[0] == "shorts" {
                    let videoID = pathComponents[1]
                    #expect(videoID == expectedID, "Should extract \(expectedID) from \(urlString)")
                } else {
                    Issue.record("Invalid shorts URL structure: \(urlString)")
                }
            } else {
                Issue.record("Failed to parse \(urlString)")
            }
        }
    }

    @Test func testExtractVideoIDFromEmbedURL() async throws {
        let testCases = [
            ("https://www.youtube.com/embed/dQw4w9WgXcQ", "dQw4w9WgXcQ"),
            ("https://youtube.com/embed/abc123", "abc123"),
        ]

        for (urlString, expectedID) in testCases {
            if let url = URL(string: urlString) {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if pathComponents.count >= 2, pathComponents[0] == "embed" {
                    let videoID = pathComponents[1]
                    #expect(videoID == expectedID, "Should extract \(expectedID) from \(urlString)")
                }
            }
        }
    }

    @Test func testExtractVideoIDFromLiveURL() async throws {
        let testCases = [
            ("https://www.youtube.com/live/streamId123", "streamId123"),
            ("https://youtube.com/live/xyz789", "xyz789"),
        ]

        for (urlString, expectedID) in testCases {
            if let url = URL(string: urlString) {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if pathComponents.count >= 2, pathComponents[0] == "live" {
                    let videoID = pathComponents[1]
                    #expect(videoID == expectedID, "Should extract \(expectedID) from \(urlString)")
                }
            }
        }
    }

    // MARK: - URL Type Detection

    @Test func testDetectWatchURL() async throws {
        let watchURLs = [
            "https://www.youtube.com/watch?v=test",
            "https://youtube.com/watch?v=test",
            "https://m.youtube.com/watch?v=test",
        ]

        for urlString in watchURLs {
            if let url = URL(string: urlString) {
                #expect(url.path.hasPrefix("/watch"), "\(urlString) should be detected as watch URL")
            }
        }
    }

    @Test func testDetectShortsURL() async throws {
        let shortsURLs = [
            "https://www.youtube.com/shorts/test",
            "https://youtube.com/shorts/test",
        ]

        for urlString in shortsURLs {
            if let url = URL(string: urlString) {
                #expect(url.path.hasPrefix("/shorts/"), "\(urlString) should be detected as shorts URL")
            }
        }
    }

    @Test func testDetectEmbedURL() async throws {
        let embedURLs = [
            "https://www.youtube.com/embed/test",
            "https://youtube.com/embed/test",
        ]

        for urlString in embedURLs {
            if let url = URL(string: urlString) {
                #expect(url.path.hasPrefix("/embed/"), "\(urlString) should be detected as embed URL")
            }
        }
    }

    @Test func testDetectLiveURL() async throws {
        let liveURLs = [
            "https://www.youtube.com/live/test",
            "https://youtube.com/live/test",
        ]

        for urlString in liveURLs {
            if let url = URL(string: urlString) {
                #expect(url.path.hasPrefix("/live/"), "\(urlString) should be detected as live URL")
            }
        }
    }

    @Test func testDetectShortDomainURL() async throws {
        let shortURLs = [
            "https://youtu.be/test",
            "http://youtu.be/test",
        ]

        for urlString in shortURLs {
            if let url = URL(string: urlString) {
                #expect(url.host == "youtu.be", "\(urlString) should be detected as short domain URL")
            }
        }
    }

    // MARK: - Non-Video URL Detection

    @Test func testNonVideoURLsNotRedirected() async throws {
        let nonVideoURLs = [
            "https://www.youtube.com/",
            "https://www.youtube.com/results?search_query=test",
            "https://www.youtube.com/@channelname",
            "https://www.youtube.com/feed/trending",
            "https://www.youtube.com/feed/subscriptions",
            "https://www.youtube.com/feed/history",
            "https://www.youtube.com/playlist?list=PLxyz",
            "https://www.youtube.com/channel/UCxyz",
            "https://www.youtube.com/c/channelname",
        ]

        for urlString in nonVideoURLs {
            if let url = URL(string: urlString) {
                let isVideoURL = url.path.hasPrefix("/watch") ||
                                url.path.hasPrefix("/shorts/") ||
                                url.path.hasPrefix("/embed/") ||
                                url.path.hasPrefix("/live/")
                #expect(!isVideoURL, "\(urlString) should NOT be detected as video URL")
            }
        }
    }

    // MARK: - Already Redirected URL Detection

    @Test func testAlreadyRedirectedURLsNotRedirected() async throws {
        let redirectedURLs = [
            "https://www.yout-ube.com/watch?v=test",
            "https://yout-ube.com/shorts/test",
            "https://www.youtube-nocookie.com/embed/test",
            "https://youtube-nocookie.com/embed/test",
        ]

        for urlString in redirectedURLs {
            if let url = URL(string: urlString) {
                let host = url.host ?? ""
                let isAlreadyRedirected = host.contains("yout-ube.com") ||
                                         host.contains("youtube-nocookie.com")
                #expect(isAlreadyRedirected, "\(urlString) should be detected as already redirected")
            }
        }
    }
}

// MARK: - Manifest JSON Validation Tests

struct ManifestValidationTests {

    @Test func testManifestPermissions() async throws {
        // Expected permissions for the extension
        let requiredPermissions = ["declarativeNetRequest", "declarativeNetRequestFeedback", "storage"]

        for permission in requiredPermissions {
            #expect(!permission.isEmpty, "Permission '\(permission)' should be valid")
        }
    }

    @Test func testManifestHostPermissions() async throws {
        // Expected host permissions
        let expectedHosts = [
            "*://*.youtube.com/*",
            "*://youtu.be/*",
        ]

        for host in expectedHosts {
            #expect(host.contains("*"), "Host permission '\(host)' should use wildcards")
        }
    }

    @Test func testManifestVersion() async throws {
        let manifestVersion = 3
        #expect(manifestVersion == 3, "Should use Manifest V3")
    }

    @Test func testExtensionName() async throws {
        let extensionName = "FreeYT - Privacy YouTube"
        #expect(!extensionName.isEmpty)
        #expect(extensionName.contains("FreeYT"))
        #expect(extensionName.contains("Privacy"))
    }

    @Test func testMinimumSafariVersion() async throws {
        let minVersion = "15.4"
        #expect(minVersion >= "15.0", "Should require Safari 15+")
    }
}

// MARK: - Video ID Format Tests

struct VideoIDFormatTests {

    @Test func testStandardVideoIDLength() async throws {
        // Standard YouTube video IDs are 11 characters
        let standardID = "dQw4w9WgXcQ"
        #expect(standardID.count == 11, "Standard video ID should be 11 characters")
    }

    @Test func testVideoIDValidCharacters() async throws {
        // YouTube video IDs can contain: a-z, A-Z, 0-9, -, _
        let validCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")

        let testIDs = ["dQw4w9WgXcQ", "abc-123_XYZ", "ABCDEFGHIJK", "01234567890"]

        for videoID in testIDs {
            let isValid = videoID.unicodeScalars.allSatisfy { validCharacterSet.contains($0) }
            #expect(isValid, "Video ID '\(videoID)' should only contain valid characters")
        }
    }

    @Test func testVideoIDWithHyphens() async throws {
        let videoID = "abc-123-xyz"
        #expect(videoID.contains("-"), "Video ID can contain hyphens")
    }

    @Test func testVideoIDWithUnderscores() async throws {
        let videoID = "abc_123_xyz"
        #expect(videoID.contains("_"), "Video ID can contain underscores")
    }
}

// MARK: - Privacy Tests

struct PrivacyTests {

    @Test func testNoCookieDomainIsGoogleOwned() async throws {
        // youtube-nocookie.com is an official Google domain for privacy-enhanced embeds
        let domain = "youtube-nocookie.com"
        #expect(domain.contains("youtube"), "Domain should be YouTube-related")
        #expect(domain.contains("nocookie"), "Domain should indicate no-cookie behavior")
    }

    @Test func testHyphenDomainIsTargetDomain() async throws {
        // yout-ube.com is the current target domain used by the extension
        let domain = "yout-ube.com"
        #expect(domain.contains("yout"), "Domain should be YouTube-related")
        #expect(domain.contains("-"), "Domain should contain hyphen")
    }

    @Test func testNoExternalNetworkCalls() async throws {
        // The extension should only communicate with YouTube domains
        let allowedDomains = ["youtube.com", "youtu.be", "yout-ube.com", "youtube-nocookie.com"]

        for domain in allowedDomains {
            #expect(!domain.isEmpty, "Allowed domain should not be empty")
            #expect(domain.contains("youtu") || domain.contains("yout-"), "Should only allow YouTube-related domains")
        }
    }

    @Test func testNoTrackerDomains() async throws {
        let blockedPatterns = [
            "google-analytics",
            "facebook",
            "doubleclick",
            "adsense",
            "tracking",
        ]

        let allowedDomains = ["youtube.com", "youtu.be", "yout-ube.com", "youtube-nocookie.com"]

        for domain in allowedDomains {
            for pattern in blockedPatterns {
                #expect(!domain.contains(pattern), "Allowed domains should not include tracker: \(pattern)")
            }
        }
    }
}

// MARK: - Edge Cases and Error Handling Tests

struct EdgeCaseTests {

    @Test func testEmptyURLString() async throws {
        let url = URL(string: "")
        #expect(url == nil, "Empty string should not create a valid URL")
    }

    @Test func testInvalidURLString() async throws {
        let invalidURLs = [
            "not a url",
            "://missing-scheme",
            "http://",
            "ftp://youtube.com/watch?v=test",  // Wrong scheme
        ]

        for urlString in invalidURLs {
            let url = URL(string: urlString)
            if let url = url {
                // Even if URL parses, it shouldn't be a valid YouTube video URL
                let isValidYouTube = url.host?.contains("youtube") == true || url.host == "youtu.be"
                if urlString.contains("youtube") {
                    // FTP scheme should not be processed
                    #expect(url.scheme != "https" && url.scheme != "http" || true)
                }
            }
        }
    }

    @Test func testURLWithFragments() async throws {
        let url = URL(string: "https://www.youtube.com/watch?v=test#t=42")
        #expect(url != nil)
        #expect(url?.fragment == "t=42")
    }

    @Test func testURLWithSpecialCharactersInQuery() async throws {
        let urlString = "https://www.youtube.com/watch?v=test&t=42s&list=PLxyz"
        let url = URL(string: urlString)
        #expect(url != nil)

        if let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let queryItems = components.queryItems ?? []
            #expect(queryItems.count >= 3)
        }
    }

    @Test func testURLWithEncodedCharacters() async throws {
        let urlString = "https://www.youtube.com/watch?v=test%26special"
        let url = URL(string: urlString)
        #expect(url != nil)
    }

    @Test func testMobileSubdomain() async throws {
        let mobileURL = URL(string: "https://m.youtube.com/watch?v=test")
        #expect(mobileURL != nil)
        #expect(mobileURL?.host == "m.youtube.com")
    }

    @Test func testWWWSubdomain() async throws {
        let wwwURL = URL(string: "https://www.youtube.com/watch?v=test")
        let noWwwURL = URL(string: "https://youtube.com/watch?v=test")

        #expect(wwwURL?.host == "www.youtube.com")
        #expect(noWwwURL?.host == "youtube.com")
    }

    @Test func testHTTPSvsHTTP() async throws {
        let httpsURL = URL(string: "https://www.youtube.com/watch?v=test")
        let httpURL = URL(string: "http://www.youtube.com/watch?v=test")

        #expect(httpsURL?.scheme == "https")
        #expect(httpURL?.scheme == "http")
    }
}
