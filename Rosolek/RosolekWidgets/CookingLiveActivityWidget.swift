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
        var isRunning: Bool
    }

    let batchTitle: String
}

private enum WidgetTheme {
    static let accent: Color = Color(red: 0.914, green: 0.827, blue: 0.220)
    static let textPrimary: Color = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let textSecondary: Color = Color(red: 0.50, green: 0.50, blue: 0.50)
    static let surface: Color = Color(red: 0.98, green: 0.97, blue: 0.96)
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
                        if let endDate = context.state.stepEndDate, context.state.isRunning {
                            Text(timerInterval: Date.now...endDate, countsDown: true)
                                .font(.system(size: 20, weight: .bold).monospacedDigit())
                                .foregroundStyle(WidgetTheme.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.stepName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(WidgetTheme.textPrimary)
                            .lineLimit(1)
                        if let endDate = context.state.totalEndDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(WidgetTheme.textSecondary)
                                Text("Koniec za ")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(WidgetTheme.textSecondary)
                                Text(endDate, style: .relative)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(WidgetTheme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accent)
            } compactTrailing: {
                if let endDate = context.state.stepEndDate, context.state.isRunning {
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
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(WidgetTheme.accent)
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Gotowanie na żywo")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WidgetTheme.textPrimary)
                    .lineLimit(1)
                Text(state.stepName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if let endDate = state.stepEndDate, state.isRunning {
                    Text(timerInterval: Date.now...endDate, countsDown: true)
                        .font(.system(size: 22, weight: .bold).monospacedDigit())
                        .foregroundStyle(WidgetTheme.textPrimary)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text("Pauza")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
                Text("Etap \(state.stepNumber)/\(state.totalSteps)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(WidgetTheme.surface)
        .widgetURL(URL(string: "rosolek://cooking"))
    }
}

@main
struct RosolekWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CookingLiveActivityWidget()
    }
}
