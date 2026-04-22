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
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(spacing: 14) {
                    ForEach(BrothProfile.allCases) { profile in
                        ProfileChoiceCard(
                            profile: profile,
                            isSelected: selectedProfile == profile
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
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

            Text("Decyduje o proporcjach wody do mięsa.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

private struct ProfileChoiceCard: View {
    let profile: BrothProfile
    let isSelected: Bool
    let action: () -> Void

    private let cardHeight: CGFloat = 192

    private var assetName: String {
        switch profile {
        case .cleaner: return "BrothProfileCleaner"
        case .richer:  return "BrothProfileRicher"
        }
    }

    private var icon: String {
        switch profile {
        case .cleaner: return "drop.fill"
        case .richer:  return "flame.fill"
        }
    }

    private var chips: [String] {
        switch profile {
        case .cleaner: return ["więcej wody", "lżejszy profil", "większy uzysk"]
        case .richer:  return ["mniej wody", "mocniejszy profil", "mniejszy uzysk"]
        }
    }

    var body: some View {
        Button(action: action) {
            Color.clear
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .bold))
                            Text(profile.title)
                                .font(.system(size: 21, weight: .bold))
                        }
                        .foregroundStyle(.white)

                        Text(profile.subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            ForEach(chips, id: \.self) { chip in
                                ProfileChip(title: chip)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .background {
                    Group {
                        if UIImage(named: assetName) != nil {
                            Image(assetName)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [AppTheme.accentSoft.opacity(0.92), AppTheme.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text(profile.title)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                        .padding(12)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .stroke(AppTheme.accent, lineWidth: isSelected ? 2.5 : 0)
                )
                .scaleEffect(isSelected ? 1.0 : 0.97)
                .appSoftShadow()
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
    }
}

private struct ProfileChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.white.opacity(0.18))
            .overlay(
                Capsule().stroke(.white.opacity(0.38), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}
