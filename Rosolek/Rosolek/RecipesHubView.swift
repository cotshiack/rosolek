import SwiftUI

struct RecipesHubView: View {
    @AppStorage("potSizeLiters") private var potSizeLiters = 7
    let compact: Bool
    @Binding var selectedPresetFilter: HomeRecipeFilter

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: compact ? 22 : 26) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Przepisy")
                        .font(.system(size: compact ? 24 : 26, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Gotowe przepisy i inspiracje od szefów kuchni.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                readyRecipesSection
                chefRecipesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, compact ? 12 : 16)
            .padding(.bottom, 128)
        }
        .background(AppTheme.background)
    }

    private var readyRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gotowe przepisy")
                .font(.system(size: compact ? 22 : 23, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            recipeFilterPills

            VStack(spacing: 12) {
                if selectedPresetFilter.matches(.poultry) {
                    NavigationLink {
                        BrothResultView(preset: .poultryReady, potSizeLiters: potSizeLiters)
                    } label: {
                        RecipeListCard(
                            title: "Rosół drobiowy",
                            subtitle: "Klasyczny i delikatny smak dla całej rodziny.",
                            assetName: "HomeRecipePoultry"
                        )
                    }
                    .buttonStyle(.plain)
                }

                if selectedPresetFilter.matches(.poultryBeef) {
                    NavigationLink {
                        BrothResultView(preset: .poultryBeefReady, potSizeLiters: potSizeLiters)
                    } label: {
                        RecipeListCard(
                            title: "Rosół drobiowo-wołowy",
                            subtitle: "Bardziej intensywny i pełniejszy profil smaku.",
                            assetName: "HomeRecipePoultryBeef"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var chefRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Przepisy szefów kuchni")
                .font(.system(size: compact ? 22 : 23, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            RecipeListCard(
                title: "Klasyczny ramen shoyu",
                subtitle: "Autorski przepis premium z prowadzeniem krok po kroku.",
                assetName: "HomeChefRamen",
                isLocked: true
            )

            RecipeListCard(
                title: "Bulion wołowy demi-glace",
                subtitle: "Koncentrat o głębokim smaku, idealny do sosów i redukcji.",
                assetName: "HomeChefDemiGlace",
                isLocked: true
            )
        }
    }

    private var recipeFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HomeRecipeFilter.allCases) { filter in
                    Button {
                        selectedPresetFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedPresetFilter == filter ? AppTheme.textPrimary : AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(
                                Capsule()
                                    .fill(selectedPresetFilter == filter ? AppTheme.accentSoft : AppTheme.surface)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedPresetFilter == filter ? AppTheme.accent.opacity(0.45) : AppTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RecipeListCard: View {
    let title: String
    let subtitle: String
    let assetName: String
    var isLocked = false

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .opacity(isLocked ? 0.85 : 1)
        .saturation(isLocked ? 0.5 : 1)
        .appSoftShadow()
    }
}
