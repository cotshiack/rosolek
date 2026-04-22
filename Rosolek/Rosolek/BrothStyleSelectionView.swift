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
            let cardHeight = cardHeight(for: geometry)

            VStack(alignment: .leading, spacing: 12) {
                header

                VStack(spacing: 10) {
                    ForEach(BrothProfile.allCases) { profile in
                        ProfileChoiceCard(
                            profile: profile,
                            isSelected: selectedProfile == profile,
                            imageHeight: cardHeight * 0.56
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedProfile = profile
                            }
                        }
                        .frame(height: cardHeight)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(AppSpacing.screen)
            .padding(.bottom, 8)
            .background(AppTheme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                floatingBottomBar
            }
        }
        .navigationTitle("Własny rosół")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wybierz profil rosołu")
                .font(AppTypography.flowHeader)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Wpływa na smak i ilość rosołu.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func cardHeight(for geometry: GeometryProxy) -> CGFloat {
        let containerHeight = geometry.size.height
        let safeBottom = geometry.safeAreaInsets.bottom
        let ctaZone: CGFloat = 56 + 8 + safeBottom
        let headerZone: CGFloat = 90
        let topAndBottomPadding: CGFloat = AppSpacing.screen + 8
        let headerToCardsSpacing: CGFloat = 12
        let cardSpacing: CGFloat = 10
        let available = containerHeight - ctaZone - headerZone - topAndBottomPadding - headerToCardsSpacing - cardSpacing
        return max(212, available / 2)
    }

    private var floatingBottomBar: some View {
        VStack(spacing: 10) {
            NavigationLink {
                IngredientSelectionView(
                    selectedProfile: selectedProfile ?? .cleaner
                )
            } label: {
                AppPrimaryButtonLabel(
                    title: "Wybierz składniki",
                    disabled: selectedProfile == nil
                )
            }
            .disabled(selectedProfile == nil)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            AppTheme.background
                .opacity(0.98)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct ProfileChoiceCard: View {
    let profile: BrothProfile
    let isSelected: Bool
    let imageHeight: CGFloat
    let action: () -> Void

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
        case .cleaner: return ["klarowny", "więcej bulionu", "na co dzień"]
        case .richer:  return ["mocny aromat", "pełne body", "na bogato"]
        }
    }

    private var profileAudienceDescription: String {
        switch profile {
        case .cleaner:
            return "Dla osób, które wolą lekki i delikatny rosół."
        case .richer:
            return "Dla osób, które lubią mocniejszy, esencjonalny smak."
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
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
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.26)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )

                    if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Wybrany profil")
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

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(profile.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Text(profileAudienceDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                        alignment: .leading,
                        spacing: 6
                    ) {
                        ForEach(chips, id: \.self) { chip in
                            ProfileChip(title: chip)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 2.5 : 1)
            )
            .scaleEffect(isSelected ? 1.0 : 0.985)
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
            .foregroundStyle(AppTheme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(AppTheme.surfaceMuted)
            .overlay(
                Capsule().stroke(AppTheme.borderStrong, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}
