import SwiftUI

// Legacy persistence type — used only for BatchRecord.styleRawValue storage and migration.
// Do not use in UI code. Use BrothProfile (.cleaner / .richer) instead.
enum BrothStyle: String, CaseIterable, Identifiable {
    case light
    case intense

    var id: String { rawValue }
}

struct BrothStyleSelectionView: View {
    @State private var selectedProfile: BrothProfile? = .cleaner

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 18) {
                header

                VStack(spacing: 12) {
                    ForEach(BrothProfile.allCases) { profile in
                        ProfileChoiceCard(
                            profile: profile,
                            isSelected: selectedProfile == profile
                        ) {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.92)) {
                                selectedProfile = profile
                            }
                        }
                    }
                }

                Spacer(minLength: 12)

                NavigationLink {
                    IngredientSelectionView(
                        selectedProfile: selectedProfile ?? .cleaner
                    )
                } label: {
                    AppPrimaryButtonLabel(
                        title: "Dalej",
                        disabled: selectedProfile == nil
                    )
                }
                .disabled(selectedProfile == nil)
            }
            .padding(AppSpacing.screen)
            .padding(.bottom, max(10, geometry.safeAreaInsets.bottom == 0 ? 10 : geometry.safeAreaInsets.bottom))
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .background(AppTheme.background.ignoresSafeArea())
        }
        .navigationTitle("Własny rosół")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wybierz profil\nrosołu")
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("To ustawia sposób liczenia. Mięso dodasz za chwilę.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ProfileChoiceCard: View {
    let profile: BrothProfile
    let isSelected: Bool
    let action: () -> Void

    private var descriptionText: String {
        switch profile {
        case .cleaner:
            return "Więcej wody względem mięsa. Lżejszy i bardziej klasyczny rosół."
        case .richer:
            return "Mniej wody względem mięsa. Mocniejszy i bardziej esencjonalny rosół."
        }
    }

    private var chips: [String] {
        switch profile {
        case .cleaner:
            return [
                "więcej wody",
                "lżejszy profil",
                "większy uzysk"
            ]
        case .richer:
            return [
                "mniej wody",
                "mocniejszy profil",
                "mniejszy uzysk"
            ]
        }
    }

    var body: some View {
        Button(action: action) {
            AppCard(
                background: isSelected ? AppTheme.accentSoft : AppTheme.surface,
                border: isSelected ? AppTheme.accent : AppTheme.border,
                lineWidth: isSelected ? 1.5 : 1
            ) {
                HStack(alignment: .top, spacing: 14) {
                    ProfileIllustrationTile(
                        profile: profile,
                        selected: isSelected
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.title)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(descriptionText)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 8)

                            ProfileSelectionIndicator(isSelected: isSelected)
                        }

                        ProfilePillRow(items: chips, selected: isSelected)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .appSoftShadow()
        }
        .buttonStyle(.plain)
    }
}

private struct ProfilePillRow: View {
    let items: [String]
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if items.count >= 2 {
                HStack(spacing: 8) {
                    FeaturePill(title: items[0], selected: selected)
                    FeaturePill(title: items[1], selected: selected)
                    Spacer(minLength: 0)
                }
            }

            if items.count >= 3 {
                HStack(spacing: 8) {
                    FeaturePill(title: items[2], selected: selected)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private struct FeaturePill: View {
    let title: String
    let selected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                Capsule()
                    .fill(selected ? AppTheme.surface.opacity(0.92) : AppTheme.surfaceMuted)
            )
            .overlay(
                Capsule()
                    .stroke(selected ? AppTheme.accent.opacity(0.45) : AppTheme.border, lineWidth: 1)
            )
    }
}

private struct ProfileIllustrationTile: View {
    let profile: BrothProfile
    let selected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(selected ? AppTheme.surface : AppTheme.surfaceMuted)
                .frame(width: 72, height: 72)

            illustration
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(selected ? AppTheme.accent.opacity(0.55) : AppTheme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var illustration: some View {
        switch profile {
        case .cleaner:
            ZStack {
                BrothMiniBowl(fillHeight: 8)
                    .offset(y: 13)

                DropAccent()
                    .offset(x: -16, y: -12)

                HerbAccent()
                    .offset(x: 12, y: -12)

                CarrotAccent()
                    .offset(x: 0, y: -4)
            }

        case .richer:
            ZStack {
                BrothMiniBowl(fillHeight: 11)
                    .offset(y: 13)

                BeefAccent()
                    .offset(x: -15, y: -12)

                BoneMiniAccent()
                    .offset(x: 12, y: -12)

                ChickenMiniAccent()
                    .offset(x: 0, y: -2)
            }
        }
    }
}

private struct BrothMiniBowl: View {
    let fillHeight: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.surface)
                .frame(width: 40, height: 28)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderStrong, lineWidth: 1)
                .frame(width: 40, height: 28)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(AppTheme.accent.opacity(0.82))
                .frame(width: 30, height: fillHeight)
                .offset(y: -4)
        }
    }
}

private struct DropAccent: View {
    var body: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
    }
}

private struct HerbAccent: View {
    var body: some View {
        HStack(spacing: 2) {
            Capsule()
                .fill(Color(red: 0.32, green: 0.77, blue: 0.42))
                .frame(width: 5, height: 13)
                .rotationEffect(.degrees(-24))

            Capsule()
                .fill(Color(red: 0.25, green: 0.67, blue: 0.34))
                .frame(width: 5, height: 11)
                .rotationEffect(.degrees(18))
        }
    }
}

private struct CarrotAccent: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(red: 0.98, green: 0.54, blue: 0.12))
                .frame(width: 10, height: 18)
                .rotationEffect(.degrees(22))

            Capsule()
                .fill(Color(red: 0.31, green: 0.79, blue: 0.37))
                .frame(width: 3.5, height: 10)
                .rotationEffect(.degrees(-18))
                .offset(x: -3, y: -9)

            Capsule()
                .fill(Color(red: 0.35, green: 0.84, blue: 0.44))
                .frame(width: 3.5, height: 10)
                .rotationEffect(.degrees(14))
                .offset(x: 1, y: -9)
        }
    }
}

private struct BeefAccent: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(Color(red: 0.73, green: 0.38, blue: 0.30))
            .frame(width: 16, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
            )
    }
}

private struct BoneMiniAccent: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.96, green: 0.64, blue: 0.22))
                .frame(width: 14, height: 5)
                .rotationEffect(.degrees(-28))

            Circle()
                .fill(Color(red: 0.96, green: 0.64, blue: 0.22))
                .frame(width: 5, height: 5)
                .offset(x: -6, y: -1)
        }
    }
}

private struct ChickenMiniAccent: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.95, green: 0.92, blue: 0.87))
                .frame(width: 16, height: 11)
                .offset(x: 2, y: 3)

            Circle()
                .fill(Color(red: 0.95, green: 0.92, blue: 0.87))
                .frame(width: 8, height: 8)
                .offset(x: -4, y: -1)

            Capsule()
                .fill(Color(red: 0.96, green: 0.62, blue: 0.18))
                .frame(width: 8, height: 3)
                .rotationEffect(.degrees(-28))
                .offset(x: 8, y: 1)
        }
    }
}

private struct ProfileSelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? AppTheme.textPrimary : AppTheme.borderStrong, lineWidth: 1.6)
                .frame(width: 28, height: 28)

            if isSelected {
                Circle()
                    .fill(AppTheme.textPrimary)
                    .frame(width: 12, height: 12)
            }
        }
    }
}
