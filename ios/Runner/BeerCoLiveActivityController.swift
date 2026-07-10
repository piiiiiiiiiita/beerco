import ActivityKit
import Flutter
import Foundation

final class BeerCoLiveActivityController {
  static let shared = BeerCoLiveActivityController()

  private var channel: FlutterMethodChannel?

  private init() {}

  func configure(messenger: any FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "beerco/live_activity",
      binaryMessenger: messenger
    )
    channel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startOrUpdateTimer":
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let memberId = arguments["memberId"] as? String,
        let memberName = arguments["memberName"] as? String,
        let endsAtMs = arguments["endsAtMs"] as? NSNumber
      else {
        result(FlutterError(code: "bad_args", message: "Missing timer arguments", details: nil))
        return
      }

      let tableName = arguments["tableName"] as? String
      let endsAt = Date(timeIntervalSince1970: endsAtMs.doubleValue / 1000)
      Task {
        do {
          try await startOrUpdateTimer(
            memberId: memberId,
            memberName: memberName,
            tableName: tableName,
            endsAt: endsAt
          )
          result(true)
        } catch {
          result(FlutterError(code: "activity_error", message: error.localizedDescription, details: nil))
        }
      }

    case "endTimer":
      guard #available(iOS 16.2, *) else {
        result(false)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let memberId = arguments["memberId"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "Missing memberId", details: nil))
        return
      }

      Task {
        await endTimer(memberId: memberId)
        result(true)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private func startOrUpdateTimer(
    memberId: String,
    memberName: String,
    tableName: String?,
    endsAt: Date
  ) async throws {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    let state = BeerCoTimerAttributes.ContentState(
      endsAt: endsAt,
      tableName: tableName?.isEmpty == true ? nil : tableName
    )
    let content = ActivityContent(state: state, staleDate: endsAt)
    let matches = Activity<BeerCoTimerAttributes>.activities.filter {
      $0.attributes.memberId == memberId
    }

    if let activity = matches.first {
      await activity.update(content)
      for duplicate in matches.dropFirst() {
        await duplicate.end(nil, dismissalPolicy: .immediate)
      }
      return
    }

    let attributes = BeerCoTimerAttributes(
      memberId: memberId,
      memberName: memberName
    )
    _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
  }

  @available(iOS 16.2, *)
  private func endTimer(memberId: String) async {
    let matches = Activity<BeerCoTimerAttributes>.activities.filter {
      $0.attributes.memberId == memberId
    }

    for activity in matches {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }
}
