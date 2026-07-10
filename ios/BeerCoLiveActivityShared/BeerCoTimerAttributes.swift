import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct BeerCoTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var endsAt: Date
    var tableName: String?
  }

  var memberId: String
  var memberName: String
}
