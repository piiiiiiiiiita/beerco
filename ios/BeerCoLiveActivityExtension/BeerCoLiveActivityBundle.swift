import ActivityKit
import SwiftUI
import WidgetKit

@main
struct BeerCoLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    BeerCoLiveActivityWidget()
  }
}

struct BeerCoLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BeerCoTimerAttributes.self) { context in
      BeerCoTimerLockScreenView(context: context)
        .activityBackgroundTint(Color(red: 0.06, green: 0.06, blue: 0.06))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(context.attributes.memberName)
            .font(.headline)
        }
        DynamicIslandExpandedRegion(.trailing) {
          BeerCoCountdownText(endsAt: context.state.endsAt)
            .font(.headline.monospacedDigit())
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.tableName ?? "BeerCo")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } compactLeading: {
        Image(systemName: "timer")
          .foregroundStyle(.orange)
      } compactTrailing: {
        BeerCoCountdownText(endsAt: context.state.endsAt)
          .font(.caption2.monospacedDigit())
      } minimal: {
        Image(systemName: "timer")
          .foregroundStyle(.orange)
      }
    }
  }
}

private struct BeerCoTimerLockScreenView: View {
  let context: ActivityViewContext<BeerCoTimerAttributes>

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "timer")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(.orange)
        .frame(width: 36, height: 36)
        .background(.white.opacity(0.12), in: Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(context.attributes.memberName)
          .font(.headline)
          .foregroundStyle(.white)
        Text(context.state.tableName ?? "BeerCo timer")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.66))
      }

      Spacer(minLength: 10)

      BeerCoCountdownText(endsAt: context.state.endsAt)
        .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
        .foregroundStyle(.white)
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
  }
}

private struct BeerCoCountdownText: View {
  let endsAt: Date

  var body: some View {
    Text(timerInterval: Date.now...max(endsAt, Date.now), countsDown: true)
  }
}
