import ComposableArchitecture
import XCTest

@testable import NoteSense

@MainActor
final class AppFeatureTests: XCTestCase {
  func testTabSelection() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.tabSelected(.library)) {
      $0.selectedTab = .library
    }

    await store.send(.tabSelected(.settings)) {
      $0.selectedTab = .settings
    }
  }
}
