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
        GeometryReader { _ in
            VStack(alignment: .leading, spacing: 12) {
                header

                GeometryReader { cardsGeometry in
                    let cardHeight = max(0, (cardsGeometry.size.height - 8) / 2)

                    VStack(spacing: 8) {
                        ForEach(BrothProfile.allCases) { profile in
                            ProfileChoiceCard(
                                profile: profile,
                                isSelected: selectedProfile == profile,
                                imageHeight: cardHeight * 0.50
                            ) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    selectedProfile = profile
                                }
                            }
                            .frame(height: cardHeight)
                        }
                    }
                }
                .layoutPriority(1)
            }
            .padding(AppSpacing.screen)
            .frame(maxHeight: .infinity, alignment: .top)
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
        case .cleaner: return ["klarowniejszy", "większy uzysk", "na co dzień"]
        case .richer:  return ["mocniejszy aromat", "pełniejsze body", "dłuższe gotowanie"]
        }
    }

    private var profileAudienceDescription: String {
        switch profile {
        case .cleaner:
            return "Lżejszy profil i bardziej klarowny bulion."
        case .richer:
            return "Mocniejszy aromat i pełniejsze body."
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
                            Text("Ten profil")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .frame(height: 26)
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
                            .font(.system(size: 17, weight: .semibold))
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
                .frame(maxHeight: .infinity, alignment: .top)
                .background(AppTheme.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isSelected ? 1 : 0.96)
            .scaleEffect(isSelected ? 1.0 : 0.992)
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
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
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
