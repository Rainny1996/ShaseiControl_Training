import XCTest

/// UI 冒烟测试（XCUI）
///
/// 目的：现有 159 个用例全为逻辑单测，无任何 UI 测试。本文件补齐最小可用 UI 测试，
/// 验证 App 在模拟器中可正常启动、进入引导流程，并能在跳过引导后到达初始设置页（AC-9.4 首启引导）。
/// 注意：UI 测试运行于独立进程，禁止 @testable import，只通过 XCUIApplication 访问可访问性元素。
final class ControlTrainingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// 冒烟测试：App 成功启动并渲染引导首页
    /// AC-9.4 首启引导可达性
    func testAppLaunchesAndShowsOnboarding() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10),
                      "App 应成功启动并进入前台")
        let welcome = app.staticTexts["欢迎来到控制训练"]
        XCTAssertTrue(welcome.exists, "首启应展示引导首页标题")
    }

    /// 冒烟测试：跳过引导后进入初始设置问卷
    /// AC-9.4 / AC-3.1 初始评估问卷入口可达
    func testSkipOnboardingReachesInitialSetup() {
        let skip = app.buttons["跳过"]
        guard skip.exists else {
            XCTFail("未找到「跳过」按钮，引导流程可能已变更")
            return
        }
        skip.tap()

        let initialSetup = app.staticTexts["初始设置"]
        XCTAssertTrue(initialSetup.waitForExistence(timeout: 10),
                      "跳过引导后应进入初始设置页")
    }
}
