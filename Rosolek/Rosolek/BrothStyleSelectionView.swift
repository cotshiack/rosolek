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
            VStack(alignment: .leading, spacing: 10) {
                header

                GeometryReader { cardsGeometry in
                    let cardHeight = max(0, (cardsGeometry.size.height - 8) / 2)

                    VStack(spacing: 8) {
                        ForEach(BrothProfile.allCases) { profile in
                            ProfileChoiceCard(
                                profile: profile,
                                isSelected: selectedProfile == profile,
                                imageHeight: cardHeight * 0.54
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
        VStack(alignment: .leading, spacing: 4) {
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

    private var iconColor: Color {
        switch profile {
        case .cleaner: return isSelected ? Color(hex: "3D8FD4") : AppTheme.textSecondary
        case .richer:  return isSelected ? Color(hex: "E07A35") : AppTheme.textSecondary
        }
    }

    private var chips: [String] {
        switch profile {
        case .cleaner: return ["subtelny aromat", "lekki finisz", "czysty kolor"]
        case .richer:  return ["głęboki aromat", "długi finisz", "mocne body"]
        }
    }

    private var profileAudienceDescription: String {
        switch profile {
        case .cleaner: return "Lżejszy profil, klarowny bulion."
        case .richer:  return "Intensywny aromat i pełne body."
        }
    }

    private var cookTime: String {
        switch profile {
        case .cleaner: return "ok. 5h 15 min"
        case .richer:  return "ok. 5h 45 min"
        }
    }

    private var yieldHint: String {
        switch profile {
        case .cleaner: return "więcej płynu"
        case .richer:  return "mniej płynu"
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
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .clear, .black.opacity(0.50)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    if isSelected {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .black))
                            Text("Twój wybór")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color(hex: "F2D93C"))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "D4B820"), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .padding(14)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(iconColor)
                        Text(profile.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Text(profileAudienceDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary.opacity(0.72))
                        .lineLimit(2)
                        .padding(.top, 4)

                    HStack(spacing: 12) {
                        Label(cookTime, systemImage: "clock")
                        Label(yieldHint, systemImage: "drop")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.62))
                    .padding(.top, 8)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                        alignment: .leading,
                        spacing: 5
                    ) {
                        ForEach(chips, id: \.self) { chip in
                            ProfileChip(title: chip, isSelected: isSelected)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(isSelected ? AppTheme.accentSoft.opacity(0.62) : AppTheme.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isSelected ? 1.0 : 0.94)
            .scaleEffect(isSelected ? 1.0 : 0.975)
            .shadow(
                color: isSelected ? AppTheme.accent.opacity(0.28) : Color.black.opacity(0.05),
                radius: isSelected ? 20 : 8,
                x: 0,
                y: isSelected ? 8 : 3
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
    }
}

private struct ProfileChip: View {
    let title: String
    var isSelected: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textPrimary.opacity(0.76))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? Color(hex: "F2D93C").opacity(0.25)
                    : AppTheme.surface
            )
            .overlay(
                Capsule().stroke(
                    isSelected ? Color(hex: "D4B820") : AppTheme.border.opacity(0.95),
                    lineWidth: 1
                )
            )
            .clipShape(Capsule())
    }
}
