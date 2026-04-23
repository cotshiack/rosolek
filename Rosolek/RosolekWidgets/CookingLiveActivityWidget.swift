import ActivityKit
import SwiftUI
import WidgetKit

// Shared type — also defined in the main app target (CookingActivityAttributes.swift)
struct CookingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stepName: String
        var stepNumber: Int
        var totalSteps: Int
        var stepEndDate: Date?
        var totalEndDate: Date?
        var totalProgress: Double
        var isRunning: Bool
    }

    let batchTitle: String
}

private enum WidgetTheme {
    static let accent: Color = Color(red: 0.914, green: 0.827, blue: 0.220)
    static let textPrimary: Color = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let textSecondary: Color = Color(red: 0.50, green: 0.50, blue: 0.50)
    static let surface: Color = Color(red: 0.98, green: 0.97, blue: 0.96)
    static let statusRunning: Color = Color(red: 0.18, green: 0.62, blue: 0.38)
}

struct CookingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookingActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(WidgetTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gotowanie na żywo")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(WidgetTheme.textPrimary)
                            Text(context.attributes.batchTitle)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(WidgetTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Etap \(context.state.stepNumber)/\(context.state.totalSteps)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WidgetTheme.textSecondary)
                        if let endDate = context.state.stepEndDate, context.state.isRunning, endDate > .now {
                            Text(timerInterval: Date.now...endDate, countsDown: true)
                                .font(.system(size: 20, weight: .bold).monospacedDigit())
                                .foregroundStyle(WidgetTheme.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.isRunning ? "Gotowanie trwa" : "Gotowanie wstrzymane")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(context.state.isRunning ? WidgetTheme.statusRunning : WidgetTheme.textSecondary)
                        Text(context.state.stepName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(WidgetTheme.textPrimary)
                            .lineLimit(1)

                        ProgressView(value: max(0, min(1, context.state.totalProgress)))
                            .tint(WidgetTheme.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accent)
            } compactTrailing: {
                if let endDate = context.state.stepEndDate, context.state.isRunning, endDate > .now {
                    Text(timerInterval: Date.now...endDate, countsDown: true)
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                        .foregroundStyle(WidgetTheme.textPrimary)
                        .frame(maxWidth: 50)
                } else {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
            } minimal: {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accent)
            }
            .widgetURL(URL(string: "rosolek://cooking"))
        }
    }
}

private struct LockScreenView: View {
    let attributes: CookingActivityAttributes
    let state: CookingActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(state.isRunning ? "Gotowanie trwa" : "Gotowanie wstrzymane")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(state.isRunning ? WidgetTheme.statusRunning : WidgetTheme.textSecondary)

                Spacer(minLength: 8)

                Text("Etap \(state.stepNumber)/\(state.totalSteps)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }

            HStack(alignment: .firstTextBaseline) {
                if let endDate = state.stepEndDate, state.isRunning, endDate > .now {
                    Text(timerInterval: Date.now...endDate, countsDown: true)
                        .font(.system(size: 34, weight: .bold).monospacedDigit())
                        .foregroundStyle(WidgetTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("Pauza")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }

            Text(state.stepName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WidgetTheme.textPrimary)
                .lineLimit(1)

            ProgressView(value: clampedProgress)
                .tint(WidgetTheme.accent)

            if let totalEnd = state.totalEndDate, state.isRunning, totalEnd > .now {
                HStack(spacing: 4) {
                    Text("Koniec całości za")
                    Text(totalEnd, style: .relative)
                        .fontWeight(.semibold)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(WidgetTheme.surface)
        .widgetURL(URL(string: "rosolek://cooking"))
    }

    private var clampedProgress: Double {
        max(0, min(1, state.totalProgress))
    }
}

@main
struct RosolekWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CookingLiveActivityWidget()
    }
}
