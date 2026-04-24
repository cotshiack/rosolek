import SwiftUI

enum AppTheme {
    static let background = Color(hex: "FAFAF8")
    static let surface = Color(hex: "FFFFFF")
    static let surfaceMuted = Color(hex: "F7F7F5")
    static let surfaceSoft = Color(hex: "FCFCFA")
    static let surfaceLocked = Color(hex: "F9F9F7")

    static let textPrimary = Color(hex: "111111")
    static let textSecondary = Color(hex: "6E6E73")
    static let textTertiary = Color(hex: "C7C7CC")

    static let accent = Color(hex: "F4D83F")
    static let accentPressed = Color(hex: "EACF37")
    static let accentSoft = Color(hex: "FFF8D6")

    static let border = Color(hex: "ECECEC")
    static let borderStrong = Color(hex: "DEDEDE")

    static let success = Color(hex: "57A868")
    static let warning = Color(hex: "D6A93A")

    static let darkCard = Color(hex: "111111")
    static let shadow = Color.black.opacity(0.03)
}

extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1
        )
    }
}

enum AppSpacing {
    static let screen: CGFloat = 24
    static let section: CGFloat = 20
    static let card: CGFloat = 16
    static let small: CGFloat = 12
    static let micro: CGFloat = 8
}

enum AppTypography {
    static let screenHeader = Font.system(size: 34, weight: .bold)
    static let flowHeader   = Font.system(size: 29, weight: .bold)
    static let cardHeader   = Font.system(size: 22, weight: .bold)
}

enum AppRadius {
    static let card: CGFloat = 26
    static let button: CGFloat = 18
    static let chip: CGFloat = 16
    static let icon: CGFloat = 16
}

struct AppShadowCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

extension View {
    func appSoftShadow() -> some View {
        modifier(AppShadowCardModifier())
    }
}

struct AppSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.3)
            .foregroundStyle(AppTheme.textSecondary)
    }
}

struct AppPill: View {
    let title: String
    var systemImage: String? = nil
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(filled ? AppTheme.accent : AppTheme.surface)
        .overlay(
            Capsule()
                .stroke(filled ? AppTheme.accent : AppTheme.border, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct AppPrimaryButtonLabel: View {
    let title: String
    var disabled: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(disabled ? AppTheme.accent.opacity(0.4) : AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
    }
}

struct AppSecondaryButtonLabel: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(AppTheme.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
    }
}

struct AppIconCircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 44, height: 44)
            .background(AppTheme.surface)
            .overlay(
                Circle()
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(Circle())
    }
}

struct AppMenuCircleButton: View {
    var body: some View {
        Image(systemName: "ellipsis")
            .font(.system(size: 15, weight: .semibold))
            .rotationEffect(.degrees(90))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 42, height: 42)
            .background(AppTheme.surface)
            .overlay(
                Circle()
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(Circle())
    }
}

struct AppCard<Content: View>: View {
    var background: Color = AppTheme.surface
    var border: Color = AppTheme.border
    var lineWidth: CGFloat = 1
    let content: Content

    init(
        background: Color = AppTheme.surface,
        border: Color = AppTheme.border,
        lineWidth: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background
        self.border = border
        self.lineWidth = lineWidth
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.card)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(border, lineWidth: lineWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

struct AppMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    var dark: Bool = false
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(1.3)
                .foregroundStyle(dark ? Color.white.opacity(0.72) : AppTheme.textSecondary)

            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(
                    dark ? Color.white : (accent ? AppTheme.accent : AppTheme.textPrimary)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(dark ? Color.white.opacity(0.72) : AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(dark ? AppTheme.darkCard : AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(dark ? AppTheme.darkCard : AppTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct AppMiniProgress: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < current ? AppTheme.accent : AppTheme.border)
                    .frame(height: 4)
            }
        }
    }
}

struct AppTimerRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.border, lineWidth: 12)

            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AppTheme.accent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)

            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("ukończono")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(width: 210, height: 210)
    }
}

enum AppMetaMetricKind {
    case time
    case yield
    case profile
    case weight
    case water
    case ingredients
    case thermometer
    case warnings
}

struct AppMetaMetric: Identifiable {
    let id = UUID()
    let kind: AppMetaMetricKind
    let title: String
}

struct AppMetaChip: View {
    let metric: AppMetaMetric

    var body: some View {
        HStack(spacing: 6) {
            AppMetaGlyph(kind: metric.kind)

            Text(metric.title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(AppTheme.textPrimary.opacity(0.88))
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            Capsule()
                .fill(AppTheme.surfaceMuted)
        )
        .overlay(
            Capsule()
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct AppMetaGlyph: View {
    let kind: AppMetaMetricKind

    var body: some View {
        Group {
            switch kind {
            case .time:
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .semibold))
            case .yield:
                AppYieldGlyph()
            case .profile:
                AppProfileGlyph()
            case .weight:
                Image(systemName: "scalemass")
                    .font(.system(size: 10, weight: .semibold))
            case .water:
                Image(systemName: "drop")
                    .font(.system(size: 10, weight: .semibold))
            case .ingredients:
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 10, weight: .semibold))
            case .thermometer:
                Image(systemName: "thermometer")
                    .font(.system(size: 10, weight: .semibold))
            case .warnings:
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 10, weight: .semibold))
            }
        }
        .frame(width: 12, height: 12)
    }
}

struct AppYieldGlyph: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(AppTheme.textPrimary.opacity(0.82), lineWidth: 1.35)
                .frame(width: 10, height: 10)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.accent.opacity(0.95))
                .frame(width: 8, height: 4)
                .offset(y: -1)
        }
    }
}

struct AppProfileGlyph: View {
    var body: some View {
        VStack(spacing: 2) {
            Capsule()
                .fill(AppTheme.textPrimary.opacity(0.82))
                .frame(width: 10, height: 3)

            Capsule()
                .fill(AppTheme.accent.opacity(0.95))
                .frame(width: 7, height: 3)
        }
    }
}

struct SharedRatingBadge: View {
    let text: String
    let hasRating: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(hasRating ? AppTheme.textPrimary : AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(hasRating ? AppTheme.accent : AppTheme.surfaceMuted)
            .overlay(
                Capsule()
                    .stroke(hasRating ? AppTheme.accent : AppTheme.border, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

struct AppBatchSummaryCard<Trailing: View>: View {
    let title: String
    let subtitle: String
    let metrics: [AppMetaMetric]
    let trailing: Trailing

    init(
        title: String,
        subtitle: String,
        metrics: [AppMetaMetric],
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.metrics = metrics
        self.trailing = trailing()
    }

    var body: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.88)

                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    trailing
                }

                HStack(spacing: 8) {
                    ForEach(metrics) { metric in
                        AppMetaChip(metric: metric)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appSoftShadow()
    }
}

enum UserPreferencesConstants {
    static let standardPotSizes = [5, 7, 10, 12]

    static func isValidCustomPotSize(_ text: String) -> Bool {
        guard let value = Int(text.filter(\.isNumber)), value > 0 else { return false }
        return true
    }

    static func filteredPotSizeInput(_ text: String) -> String {
        text.filter(\.isNumber)
    }
}
