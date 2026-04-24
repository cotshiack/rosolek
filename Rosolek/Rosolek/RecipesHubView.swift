import SwiftUI

struct RecipesHubView: View {
    @AppStorage("potSizeLiters") private var potSizeLiters = 7
    let compact: Bool
    @Binding var selectedPresetFilter: HomeRecipeFilter
    @State private var selectedChefFilter: ChefRecipeFilter = .all

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: compact ? 22 : 26) {
                readyRecipesSection
                chefRecipesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, compact ? 8 : 12)
            .padding(.bottom, 32)
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

                if selectedPresetFilter.matches(.poultry) {
                    NavigationLink {
                        BrothResultView(preset: .grandmaReady, potSizeLiters: potSizeLiters)
                    } label: {
                        RecipeListCard(
                            title: "Szybki domowy rosół",
                            subtitle: "Babciny styl: szybki i wyraźny, z doprawianiem po cedzeniu.",
                            assetName: "HomeRecipeGrandma"
                        )
                    }
                    .buttonStyle(.plain)
                }

                RecipeListCard(
                    title: "Klasyczny ramen shoyu",
                    subtitle: "Autorski przepis premium z prowadzeniem krok po kroku.",
                    assetName: "HomeChefRamen",
                    isLocked: true,
                    badgeTitle: "Wkrótce"
                )

                RecipeListCard(
                    title: "Bulion wołowy demi-glace",
                    subtitle: "Koncentrat o głębokim smaku, idealny do sosów i redukcji.",
                    assetName: "HomeChefDemiGlace",
                    isLocked: true,
                    badgeTitle: "Wkrótce"
                )
            }
        }
    }

    private var chefRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Przepisy szefów kuchni")
                .font(.system(size: compact ? 22 : 23, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            chefRecipeFilterPills

            if selectedChefFilter.matches(.polish) {
                RecipeListCard(
                    title: "Rosół z jabłkami — chef Antoni Wierzba",
                    subtitle: "Polski rosół z pieczonym jabłkiem i majerankiem.",
                    assetName: "HomeChefOne",
                    isLocked: true
                )
            }

            if selectedChefFilter.matches(.asian) {
                RecipeListCard(
                    title: "Azjatycki bulion — chefka Hana Mori",
                    subtitle: "Imbir, trawa cytrynowa i delikatna ostrość.",
                    assetName: "HomeChefTwo",
                    isLocked: true
                )
            }
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

    private var chefRecipeFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChefRecipeFilter.allCases) { filter in
                    Button {
                        selectedChefFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedChefFilter == filter ? AppTheme.textPrimary : AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(
                                Capsule()
                                    .fill(selectedChefFilter == filter ? AppTheme.accentSoft : AppTheme.surface)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedChefFilter == filter ? AppTheme.accent.opacity(0.45) : AppTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private enum ChefRecipeFilter: String, CaseIterable, Identifiable {
    case all
    case polish
    case asian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Wszystkie"
        case .polish: return "Polskie"
        case .asian: return "Azjatyckie"
        }
    }

    func matches(_ category: ChefRecipeFilter) -> Bool {
        self == .all || self == category
    }
}

private struct RecipeListCard: View {
    let title: String
    let subtitle: String
    let assetName: String
    var isLocked = false
    var badgeTitle: String? = nil

    var body: some View {
        AppCard(
            background: isLocked ? AppTheme.surfaceLocked : AppTheme.surface,
            border: AppTheme.border
        ) {
            HStack(spacing: 14) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    if badgeTitle != nil || isLocked {
                        HStack(spacing: 8) {
                            if let badgeTitle {
                                Text(badgeTitle)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .padding(.horizontal, 8)
                                    .frame(height: 20)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.accentSoft)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
                                    )
                            }

                            Spacer(minLength: 0)

                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)
                    }

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)

                if !isLocked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .opacity(isLocked ? 0.9 : 1)
        .saturation(isLocked ? 0.45 : 1)
        .appSoftShadow()
    }
}
