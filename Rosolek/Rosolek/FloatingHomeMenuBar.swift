import SwiftUI

enum HomeMenuTab: CaseIterable {
    case home
    case recipes
    case live
    case history
    case settings

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .recipes: return "book.closed.fill"
        case .live: return "flame.fill"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

struct FloatingHomeMenuBar: View {
    @Binding var selectedTab: HomeMenuTab
    let isLiveActive: Bool
    let onTabTap: (HomeMenuTab) -> Void
    let onLiveTap: () -> Void
    @State private var animatePulse = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach([HomeMenuTab.home, .recipes]) { tab in
                iconButton(for: tab)
            }

            liveButton

            ForEach([HomeMenuTab.history, .settings]) { tab in
                iconButton(for: tab)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.surface.opacity(0.98))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppTheme.borderStrong.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 14, x: 0, y: 6)
    }

    private func iconButton(for tab: HomeMenuTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
            onTabTap(tab)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            Image(systemName: tab.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(selectedTab == tab ? AppTheme.textPrimary : AppTheme.textSecondary)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(selectedTab == tab ? AppTheme.surfaceMuted : .clear)
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedTab == tab ? 1.02 : 1)
    }

    private var liveButton: some View {
        Button {
            guard isLiveActive else { return }
            onLiveTap()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            Image(systemName: HomeMenuTab.live.systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(isLiveActive ? AppTheme.textPrimary : AppTheme.textTertiary)
                .frame(width: 62, height: 62)
                .background(
                    Circle()
                        .fill(isLiveActive ? AppTheme.accent : AppTheme.surfaceMuted)
                )
                .overlay(
                    Circle()
                        .stroke(isLiveActive ? AppTheme.accentPressed.opacity(0.75) : AppTheme.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(isLiveActive ? 0.18 : 0.05), radius: isLiveActive ? 12 : 4, x: 0, y: isLiveActive ? 6 : 2)
                .scaleEffect(isLiveActive && animatePulse ? 1.06 : (isLiveActive ? 1.02 : 1))
                .offset(y: -6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Live cooking")
        .onAppear {
            animatePulse = false
            guard isLiveActive else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
        .onChange(of: isLiveActive) { _, newValue in
            if newValue {
                animatePulse = false
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
            } else {
                animatePulse = false
            }
        }
    }
}

extension HomeMenuTab: Identifiable {
    var id: String { systemImage }
}
