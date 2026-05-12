import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userFirstName") private var userFirstName = "Paweł"
    @AppStorage("potSizeLiters") private var potSizeLiters = 7
    @AppStorage("hasThermometer") private var hasThermometer = true

    @EnvironmentObject private var router: AppRouter
    @State private var navigationResetID = UUID()

    var body: some View {
        NavigationStack {
            Group {
                if hasCompletedOnboarding {
                    HomeView()
                } else {
                    OnboardingFlowView(
                        hasCompletedOnboarding: $hasCompletedOnboarding,
                        userFirstName: $userFirstName,
                        potSizeLiters: $potSizeLiters,
                        hasThermometer: $hasThermometer
                    )
                }
            }
            .background(AppTheme.background)
        }
        .id(navigationResetID)
        .onChange(of: router.returnToHomeTrigger) { _, _ in
            navigationResetID = UUID()
        }
    }
}

private struct HomeView: View {
    @EnvironmentObject private var batchStore: BatchStore
    @EnvironmentObject private var router: AppRouter

    @AppStorage("userFirstName") private var userFirstName = "Paweł"
    @AppStorage("potSizeLiters") private var potSizeLiters = 7
    @AppStorage("hasThermometer") private var hasThermometer = true

    @State private var selectedPresetFilter: HomeRecipeFilter = .all
    @State private var activeCookingSession: CookingSession?
    @State private var deepLinkBatch: BatchRecord?
    @State private var navigateToDeepLinkedCooking = false
    @State private var selectedMenuTab: HomeMenuTab = .home
    @StateObject private var keyboard = KeyboardObserver()
    @State private var presetItems: [HomePresetItem] = []

    private var latestBatch: BatchRecord? {
        batchStore.batches.first
    }

    private var displayName: String {
        let trimmed = userFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Paweł" : trimmed
    }

    private var filteredPresetItems: [HomePresetItem] {
        presetItems.filter { selectedPresetFilter.matches($0.filter) }
    }

    private func buildPresetItems() -> [HomePresetItem] {
        let pot = Double(potSizeLiters)
        return [
            HomePresetItem(recipe: HomePresetRecipe(preset: .poultryReady, potSizeLiters: pot), artwork: .asset("HomeRecipePoultry"), fallbackStyle: .light, filter: .poultry),
            HomePresetItem(recipe: HomePresetRecipe(preset: .poultryBeefReady, potSizeLiters: pot), artwork: .asset("HomeRecipePoultryBeef"), fallbackStyle: .intense, filter: .poultryBeef),
            HomePresetItem(recipe: HomePresetRecipe(preset: .grandmaReady, potSizeLiters: pot), artwork: .asset("HomeRecipeGrandma"), fallbackStyle: .light, filter: .poultry),
            HomePresetItem(recipe: HomePresetRecipe(preset: .fishReady, potSizeLiters: pot), artwork: .asset("BulionRybny"), fallbackStyle: .light, filter: .fish),
            HomePresetItem(recipe: HomePresetRecipe(preset: .collagenPoultryReady, potSizeLiters: pot), artwork: .asset("HomeRecipeCollagenPoultry"), fallbackStyle: .intense, filter: .poultry)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 860

            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                Group {
                    switch selectedMenuTab {
                    case .home:
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: compact ? 22 : 26) {
                                topBar
                                if activeCookingSession != nil {
                                    activeCookingBanner
                                }
                                greetingSection(compact: compact)
                                calculatorSection(compact: compact)
                                readyRecipesSection(compact: compact)
                                chefRecipesSection(compact: compact)
                                lastCookingSection(compact: compact)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, compact ? 12 : 16)
                            .padding(.bottom, keyboard.isVisible ? 28 : 24)
                        }
                    case .recipes:
                        RecipesHubView(
                            compact: compact,
                            selectedPresetFilter: $selectedPresetFilter
                        )
                    case .history:
                        HistoryView()
                    case .settings:
                        SettingsView()
                    case .live:
                        Color.clear
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: keyboard.isVisible)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !keyboard.isVisible {
                    FloatingHomeMenuBar(
                        selectedTab: $selectedMenuTab,
                        isLiveActive: activeCookingSession != nil
                    ) { tab in
                        handleMenuTabTap(tab)
                    } onLiveTap: {
                        openActiveCookingFromMenu()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, -18)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            CookingSessionCoordinator.clearOrphanedSessionIfNeeded(in: batchStore)
            activeCookingSession = CookingSession.load()
            handlePendingHomeRoute()
            presetItems = buildPresetItems()
        }
        .onChange(of: potSizeLiters) { _, _ in
            presetItems = buildPresetItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            activeCookingSession = CookingSession.load()
        }
        .onChange(of: router.pendingHomeRoute) { _, _ in
            handlePendingHomeRoute()
        }
        .navigationDestination(isPresented: $navigateToDeepLinkedCooking) {
            if let deepLinkBatch {
                CookingModeView(
                    batch: deepLinkBatch,
                    result: deepLinkBatch.calculationResult(potSizeLiters: potSizeLiters),
                    totalWeightGrams: deepLinkBatch.totalWeightGrams,
                    selectedIngredientCount: deepLinkBatch.selectedIngredientCount,
                    hasThermometer: deepLinkBatch.hasThermometer
                )
            }
        }
    }


    private var topBar: some View {
        HStack(spacing: 8) {
            Spacer()

            TopStatusChip(
                systemImage: "cylinder.fill",
                title: "\(potSizeLiters) l"
            )

            TopStatusChip(
                systemImage: "thermometer",
                title: hasThermometer ? "tak" : "nie"
            )
        }
    }

    private func openActiveCookingFromMenu() {
        guard let batch = CookingSessionCoordinator.activeBatch(in: batchStore) else { return }
        deepLinkBatch = batch
        navigateToDeepLinkedCooking = true
    }

    private func handleMenuTabTap(_ tab: HomeMenuTab) {
        switch tab {
        case .home:
            if selectedMenuTab == .home {
                router.triggerReturnToHome()
            } else {
                selectedMenuTab = .home
            }
        case .recipes, .history, .settings:
            selectedMenuTab = tab
        case .live:
            break
        }
    }

    @ViewBuilder
    private var activeCookingBanner: some View {
        if let session = activeCookingSession,
           let batch = batchStore.batch(for: session.batchID) {
            let result = batch.calculationResult(potSizeLiters: potSizeLiters)

            NavigationLink {
                CookingModeView(
                    batch: batch,
                    result: result,
                    totalWeightGrams: batch.totalWeightGrams,
                    selectedIngredientCount: batch.selectedIngredientCount,
                    hasThermometer: batch.hasThermometer
                )
            } label: {
                ActiveCookingBannerLabel(session: session)
            }
            .buttonStyle(.plain)
        }
    }

    private func greetingSection(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Co dzisiaj gotujemy \(displayName)?")
                .font(.system(size: compact ? 24 : 26, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func calculatorSection(compact: Bool) -> some View {
        NavigationLink {
            BrothStyleSelectionView()
        } label: {
            CalculatorEntryCard(compact: compact)
        }
        .buttonStyle(.plain)
    }

    private func readyRecipesSection(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gotowe przepisy")
                .font(.system(size: compact ? 22 : 23, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            recipeFilterPills

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(filteredPresetItems) { item in
                        NavigationLink {
                            BrothResultView(
                                preset: item.recipe.preset,
                                potSizeLiters: potSizeLiters
                            )
                        } label: {
                            HomePresetCard(
                                title: item.recipe.title,
                                subtitle: item.recipe.subtitle,
                                artwork: item.artwork,
                                fallbackStyle: item.fallbackStyle,
                                metrics: [
                                    HomeMetric(kind: .time, title: item.recipe.cookingDurationText),
                                    HomeMetric(kind: .yield, title: item.recipe.estimatedYieldText)
                                ],
                                compact: compact
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(width: compact ? 206 : 216)
                    }

                    LockedChefRecipeCard(
                        compact: compact,
                        title: "Klasyczny ramen shoyu",
                        subtitle: "Autorski przepis premium z prowadzeniem krok po kroku.",
                        artwork: .asset("HomeChefRamen"),
                        badgeTitle: "Wkrótce"
                    )
                    .frame(width: compact ? 206 : 216)

                    LockedChefRecipeCard(
                        compact: compact,
                        title: "Bulion wołowy demi-glace",
                        subtitle: "Koncentrat o głębokim smaku, idealny do sosów i redukcji.",
                        artwork: .asset("HomeChefDemiGlace"),
                        badgeTitle: "Wkrótce"
                    )
                    .frame(width: compact ? 206 : 216)
                }
                .padding(.vertical, 2)
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
                        RecipeFilterPill(
                            title: filter.title,
                            isSelected: selectedPresetFilter == filter
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func handlePendingHomeRoute() {
        guard let route = router.pendingHomeRoute else { return }

        switch route {
        case .openActiveCooking(let batchID):
            let batch: BatchRecord?
            if let batchID {
                batch = batchStore.batch(for: batchID)
            } else {
                batch = CookingSessionCoordinator.activeBatch(in: batchStore)
            }

            if let batch {
                deepLinkBatch = batch
                navigateToDeepLinkedCooking = true
            }
        }

        router.consumeHomeRoute()
    }

    private func chefRecipesSection(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Przepisy szefów kuchni")
                .font(.system(size: compact ? 22 : 23, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    LockedChefRecipeCard(
                        compact: compact,
                        title: "Rosół z jabłkami — chef Antoni Wierzba",
                        subtitle: "Polski rosół z pieczonym jabłkiem i majerankiem.",
                        artwork: .asset("HomeChefOne")
                    )
                    .frame(width: compact ? 206 : 216)

                    LockedChefRecipeCard(
                        compact: compact,
                        title: "Azjatycki bulion — chefka Hana Mori",
                        subtitle: "Imbir, trawa cytrynowa i delikatna ostrość.",
                        artwork: .asset("HomeChefTwo")
                    )
                    .frame(width: compact ? 206 : 216)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func lastCookingSection(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Ostatnie gotowanie")
                    .font(.system(size: compact ? 18 : 19, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                NavigationLink {
                    HistoryView()
                } label: {
                    SecondaryActionPill(title: "Cała historia")
                }
                .buttonStyle(.plain)
            }

            if let latestBatch {
                NavigationLink {
                    LastBatchDetailView(batchID: latestBatch.id)
                } label: {
                    RecentBrothCompactCard(
                        batch: latestBatch,
                        compact: compact
                    )
                }
                .buttonStyle(.plain)
            } else {
                EmptyHistoryCompactCard(compact: compact)
            }
        }
    }
}

private struct TopStatusChip: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(
            Capsule()
                .fill(AppTheme.surface)
        )
        .overlay(
            Capsule()
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

private struct SecondaryActionPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(
                Capsule()
                    .fill(AppTheme.accentSoft)
            )
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
            )
    }
}

private struct HomePresetCard: View {
    let title: String
    let subtitle: String
    let artwork: HomeCardArtwork
    let fallbackStyle: BrothIllustrationStyle
    let metrics: [HomeMetric]
    let compact: Bool

    private var cardHeight: CGFloat {
        compact ? 264 : 276
    }

    var body: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: compact ? 16 : 18) {
                HomeRecipeArtwork(
                    artwork: artwork,
                    fallbackStyle: fallbackStyle,
                    compact: compact
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: compact ? 17 : 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.84)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    ForEach(metrics) { metric in
                        HomeMetricChip(metric: metric)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .topLeading)
        }
        .appSoftShadow()
    }
}

private struct CalculatorEntryCard: View {
    let compact: Bool

    private let heroArtwork = HomeCardArtwork.asset("HomeHeroCustomBroth")
    private var cardHeight: CGFloat { compact ? 156 : 164 }

    var body: some View {
        Color.clear
            .frame(height: cardHeight)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Własny rosół od podstaw")
                        .font(.system(size: compact ? 17 : 18, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text("Dobierz składniki i proporcje do swojego garnka.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, AppSpacing.card)
                .padding(.bottom, 14)
                .padding(.top, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.60)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .background {
                Group {
                    if heroArtwork.isAvailable {
                        Image(heroArtwork.assetName)
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
                AppPill(title: "Kreator", systemImage: "sparkles", filled: true)
                    .foregroundStyle(AppTheme.surface)
                    .padding(.top, 12)
                    .padding(.leading, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .appSoftShadow()
    }
}

private struct HeroBrothGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.surface)
                .frame(width: 96, height: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Capsule().fill(AppTheme.textPrimary.opacity(0.28)).frame(width: 20, height: 5)
                    Capsule().fill(AppTheme.textPrimary.opacity(0.22)).frame(width: 14, height: 5)
                }

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.surfaceMuted)
                        .frame(width: 52, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.5))
                        .frame(width: 38, height: 12)
                        .offset(y: -5)
                }
            }
        }
    }
}

private struct LockedChefRecipeCard: View {
    let compact: Bool
    let title: String
    let subtitle: String
    let artwork: HomeCardArtwork
    var badgeTitle: String = "Premium"

    var body: some View {
        AppCard(
            background: AppTheme.surfaceLocked,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: compact ? 14 : 16) {
                HomeRecipeArtwork(
                    artwork: artwork,
                    fallbackStyle: .intense,
                    compact: compact
                )

                HStack {
                    PremiumBadge(title: badgeTitle)
                    Spacer(minLength: 0)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: compact ? 17 : 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 198 : 210, alignment: .topLeading)
        }
        .saturation(0.45)
        .opacity(0.9)
        .appSoftShadow()
    }
}

private struct PremiumBadge: View {
    var title: String = "Premium"

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(
                Capsule()
                    .fill(AppTheme.accentSoft)
            )
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent.opacity(0.38), lineWidth: 1)
            )
    }
}

private struct RecipeFilterPill: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.accentSoft : AppTheme.surface)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppTheme.accent.opacity(0.45) : AppTheme.border, lineWidth: 1)
            )
    }
}

private struct RecentBrothCompactCard: View {
    let batch: BatchRecord
    let compact: Bool

    var body: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(batch.displayTitle)
                            .font(.system(size: compact ? 18 : 19, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)

                        Text(batch.createdAtDisplayText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 8)

                    RecentRatingBadge(text: batch.ratingBadgeText, hasRating: batch.overallRating != nil)
                }

                HStack(spacing: 8) {
                    HistoryInfoChip(kind: .time, title: batch.timeDisplayText)
                    HistoryInfoChip(kind: .yield, title: batch.yieldDisplayText)
                    HistoryInfoChip(kind: .profile, title: batch.profileTitle)
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 112 : 118, alignment: .leading)
        }
        .appSoftShadow()
    }
}

private struct RecentRatingBadge: View {
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

private struct EmptyHistoryCompactCard: View {
    let compact: Bool

    var body: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Brak ostatniego gotowania")
                        .font(.system(size: compact ? 18 : 19, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Tu pojawi się Twój ostatni rosół po pierwszym gotowaniu.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                NavigationLink {
                    BrothStyleSelectionView()
                } label: {
                    HStack(spacing: 6) {
                        Text("Zacznij pierwsze gotowanie")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(AppTheme.accentSoft)
                    .overlay(Capsule().stroke(AppTheme.accent.opacity(0.4), lineWidth: 1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appSoftShadow()
    }
}

private struct HomeMetric: Identifiable {
    let id = UUID()
    let kind: HomeMetricKind
    let title: String
}

private struct HomePresetItem: Identifiable {
    let id = UUID()
    let recipe: HomePresetRecipe
    let artwork: HomeCardArtwork
    let fallbackStyle: BrothIllustrationStyle
    let filter: HomeRecipeFilter
}

private enum HomeCardArtwork {
    case asset(String)
    case systemDefault

    var assetName: String {
        switch self {
        case .asset(let name):
            return name
        case .systemDefault:
            return "OnboardingHeroRosolek"
        }
    }

    var isAvailable: Bool {
        UIImage(named: assetName) != nil
    }
}

enum HomeRecipeFilter: String, CaseIterable, Identifiable {
    case all
    case poultry
    case poultryBeef
    case fish

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Wszystkie"
        case .poultry:
            return "Drobiowy"
        case .poultryBeef:
            return "Drobiowo-wołowy"
        case .fish:
            return "Rybny"
        }
    }

    func matches(_ filter: HomeRecipeFilter) -> Bool {
        self == .all || self == filter
    }
}

private enum HomeMetricKind {
    case time
    case yield
}

private struct HomeMetricChip: View {
    let metric: HomeMetric

    var body: some View {
        HStack(spacing: 6) {
            HomeMetricGlyph(kind: metric.kind)

            Text(metric.title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(AppTheme.textPrimary.opacity(0.86))
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
    }
}

private struct HomeMetricGlyph: View {
    let kind: HomeMetricKind

    var body: some View {
        Group {
            switch kind {
            case .time:
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .semibold))
            case .yield:
                AppYieldGlyph()
            }
        }
        .frame(width: 12, height: 12)
    }
}

private enum HistoryInfoKind {
    case time
    case yield
    case profile
}

private struct HistoryInfoChip: View {
    let kind: HistoryInfoKind
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            HistoryInfoGlyph(kind: kind)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(AppTheme.textPrimary.opacity(0.86))
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
    }
}

private struct HistoryInfoGlyph: View {
    let kind: HistoryInfoKind

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
            }
        }
        .frame(width: 12, height: 12)
    }
}

private struct HomeRecipeArtwork: View {
    let artwork: HomeCardArtwork
    let fallbackStyle: BrothIllustrationStyle
    let compact: Bool

    var body: some View {
        Group {
            if artwork.isAvailable {
                Image(artwork.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: compact ? 120 : 128)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: compact ? 18 : 20, style: .continuous))
            } else if HomeCardArtwork.systemDefault.isAvailable {
                Image(HomeCardArtwork.systemDefault.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: compact ? 120 : 128)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: compact ? 18 : 20, style: .continuous))
            } else {
                HStack(alignment: .top) {
                    PresetIngredientIllustration(style: fallbackStyle, compact: compact)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private struct HomeHeroArtwork: View {
    let compact: Bool

    private var size: CGFloat {
        compact ? 118 : 126
    }

    private let heroArtwork = HomeCardArtwork.asset("HomeHeroCustomBroth")

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.surface.opacity(0.84))
                .frame(width: size, height: size)

            if heroArtwork.isAvailable {
                Image(heroArtwork.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 10, height: size - 10)
                    .clipShape(Circle())
            } else if HomeCardArtwork.systemDefault.isAvailable {
                Image(HomeCardArtwork.systemDefault.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 10, height: size - 10)
                    .clipShape(Circle())
            } else {
                HeroBrothGlyph()
                    .scaleEffect(compact ? 0.96 : 1)
            }
        }
    }
}

private enum BrothIllustrationStyle {
    case light
    case intense
    case custom
}

private struct PresetIngredientIllustration: View {
    let style: BrothIllustrationStyle
    let compact: Bool

    private var tileSize: CGFloat {
        compact ? 82 : 88
    }

    private var cornerRadius: CGFloat {
        compact ? 22 : 24
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.surfaceMuted.opacity(0.88))

            Group {
                switch style {
                case .light:
                    LightPresetGlyph(compact: compact)
                case .intense:
                    IntensePresetGlyph(compact: compact)
                case .custom:
                    CustomPresetGlyph(compact: compact)
                }
            }
        }
        .frame(width: tileSize, height: tileSize)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

private struct LightPresetGlyph: View {
    let compact: Bool

    var body: some View {
        ZStack {
            BrothBowlShape(compact: compact)
                .offset(y: 14)

            ChickenPieceShape(compact: compact)
                .scaleEffect(1.12)
                .offset(x: -10, y: 4)
                .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)

            CarrotMiniShape(compact: compact)
                .scaleEffect(1.14)
                .offset(x: 17, y: -11)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

            HerbLeafPair(compact: compact)
                .scaleEffect(1.08)
                .offset(x: -19, y: -10)
        }
    }
}

private struct IntensePresetGlyph: View {
    let compact: Bool

    var body: some View {
        ZStack {
            BrothBowlShape(compact: compact)
                .offset(y: 14)

            ChickenPieceShape(compact: compact)
                .scaleEffect(1.10)
                .offset(x: -12, y: 6)
                .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)

            BeefCubeShape(compact: compact)
                .scaleEffect(1.24)
                .offset(x: 18, y: -10)
                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)

            BoneAccent(compact: compact)
                .offset(x: -18, y: -11)
        }
    }
}

private struct CustomPresetGlyph: View {
    let compact: Bool

    var body: some View {
        ZStack {
            PotMiniShape(compact: compact)
                .offset(y: 12)

            VStack(spacing: compact ? 7 : 8) {
                SliderLine(knobOffset: compact ? -11 : -12)
                SliderLine(knobOffset: 2)
                SliderLine(knobOffset: compact ? 10 : 11)
            }
            .offset(y: -14)
        }
    }
}

private struct BrothBowlShape: View {
    let compact: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 11 : 12, style: .continuous)
                .fill(AppTheme.surface)

            RoundedRectangle(cornerRadius: compact ? 11 : 12, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AppTheme.accent.opacity(0.42))
                .frame(width: compact ? 36 : 40, height: compact ? 10 : 11)
                .offset(y: compact ? 9 : 10)
        }
        .frame(width: compact ? 46 : 50, height: compact ? 34 : 36)
    }
}

private struct PotMiniShape: View {
    let compact: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 11 : 12, style: .continuous)
                .fill(AppTheme.surface)

            RoundedRectangle(cornerRadius: compact ? 11 : 12, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AppTheme.accent.opacity(0.30))
                .frame(width: compact ? 34 : 36, height: compact ? 9 : 10)
                .offset(y: compact ? 9 : 10)
        }
        .frame(width: compact ? 44 : 48, height: compact ? 32 : 34)
    }
}

private struct SliderLine: View {
    let knobOffset: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(AppTheme.textSecondary.opacity(0.34))
                .frame(width: 32, height: 3)

            Circle()
                .fill(AppTheme.textPrimary)
                .frame(width: 8, height: 8)
                .offset(x: knobOffset)
        }
    }
}

private struct HerbLeafPair: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: 2) {
            Capsule()
                .fill(Color(red: 0.26, green: 0.72, blue: 0.36))
                .frame(width: 6, height: compact ? 15 : 16)
                .rotationEffect(.degrees(-24))

            Capsule()
                .fill(Color(red: 0.34, green: 0.80, blue: 0.46))
                .frame(width: 6, height: compact ? 14 : 15)
                .rotationEffect(.degrees(18))
        }
    }
}

private struct BoneAccent: View {
    let compact: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.96, green: 0.64, blue: 0.22))
                .frame(width: compact ? 14 : 15, height: 5)
                .rotationEffect(.degrees(-28))

            Circle()
                .fill(Color(red: 0.96, green: 0.64, blue: 0.22))
                .frame(width: 5, height: 5)
                .offset(x: -7, y: -1)
        }
    }
}

private struct CarrotMiniShape: View {
    let compact: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(red: 0.98, green: 0.50, blue: 0.10))
                .frame(width: compact ? 12 : 13, height: compact ? 23 : 25)
                .rotationEffect(.degrees(22))

            Capsule()
                .fill(Color(red: 0.27, green: 0.74, blue: 0.33))
                .frame(width: 4, height: compact ? 14 : 15)
                .rotationEffect(.degrees(-18))
                .offset(x: -4, y: -12)

            Capsule()
                .fill(Color(red: 0.35, green: 0.80, blue: 0.43))
                .frame(width: 4, height: compact ? 14 : 15)
                .rotationEffect(.degrees(14))
                .offset(x: 1, y: -12)
        }
    }
}

private struct ChickenPieceShape: View {
    let compact: Bool

    private var bodyColor: Color {
        Color(red: 0.95, green: 0.92, blue: 0.87)
    }

    private var boneColor: Color {
        Color(red: 0.96, green: 0.62, blue: 0.18)
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(bodyColor)
                .frame(width: compact ? 30 : 33, height: compact ? 20 : 22)
                .overlay(
                    Ellipse()
                        .stroke(Color.black.opacity(0.06), lineWidth: 0.8)
                )
                .offset(x: 4, y: 5)

            Circle()
                .fill(bodyColor)
                .frame(width: compact ? 16 : 18, height: compact ? 16 : 18)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.06), lineWidth: 0.8)
                )
                .offset(x: 14, y: -1)

            Capsule()
                .fill(boneColor)
                .frame(width: compact ? 14 : 15, height: 5)
                .rotationEffect(.degrees(-28))
                .offset(x: -13, y: -4)

            Circle()
                .fill(boneColor)
                .frame(width: 5, height: 5)
                .offset(x: -19, y: -6)

            Circle()
                .fill(Color(red: 0.94, green: 0.34, blue: 0.28))
                .frame(width: 4.5, height: 4.5)
                .offset(x: 16, y: -11)
        }
    }
}

private struct BeefCubeShape: View {
    let compact: Bool

    private var beefColor: Color {
        Color(red: 0.73, green: 0.38, blue: 0.30)
    }

    private var fatColor: Color {
        Color(red: 0.99, green: 0.86, blue: 0.78)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 8 : 9, style: .continuous)
                .fill(beefColor)
                .frame(width: compact ? 24 : 26, height: compact ? 21 : 23)
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 8 : 9, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.9)
                )

            Circle()
                .fill(fatColor)
                .frame(width: 4.5, height: 4.5)
                .offset(x: -5, y: -3)

            Circle()
                .fill(fatColor)
                .frame(width: 4, height: 4)
                .offset(x: 5, y: 2)

            Circle()
                .fill(fatColor)
                .frame(width: 3.4, height: 3.4)
                .offset(x: 1, y: -6)
        }
    }
}

private struct ActiveCookingBannerLabel: View {
    let session: CookingSession

    @State private var isPulsing = false

    private func overallRemaining(at now: Date) -> Int? {
        guard let total = session.overallRemainingSeconds else { return nil }
        guard let bg = session.backgroundedAt else { return total }
        return max(0, total - Int(now.timeIntervalSince(bg)))
    }

    private func formatSeconds(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        if m >= 60 {
            return String(format: "%d:%02d:%02d", m / 60, m % 60, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let remaining = overallRemaining(at: context.date)
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent, lineWidth: 2)
                        .frame(width: 48, height: 48)
                        .opacity(isPulsing ? 0.15 : 0.85)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                            value: isPulsing
                        )

                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 38, height: 38)

                    Image("RosolekLogoMark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .onAppear { isPulsing = true }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Wróć do ekranu gotowania")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    if let remaining, remaining > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text("Pozostało \(formatSeconds(remaining))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.accentSoft)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
    }
}

private struct HomePresetRecipe {
    let preset: BrothPreset
    let result: BrothCalculationResult

    init(preset: BrothPreset, potSizeLiters: Double) {
        self.preset = preset
        self.result = BrothCalculator.calculate(
            preset: preset,
            potSizeLiters: potSizeLiters
        )
    }

    var title: String {
        switch preset {
        case .poultryReady:
            return "Rosół drobiowy"
        case .poultryBeefReady:
            return "Rosół drobiowo-wołowy"
        case .grandmaReady:
            return "Szybki domowy rosół"
        case .fishReady:
            return "Bulion rybny"
        case .collagenPoultryReady:
            return "Bulion kolagenowy drobiowy"
        }
    }

    var subtitle: String {
        switch preset {
        case .poultryReady:
            return "Gotowa receptura drobiowa — czystszy smak i prostszy start."
        case .poultryBeefReady:
            return "Gotowa receptura z drobiem i wołowiną — pełniejszy smak i mocniejszy wywar."
        case .grandmaReady:
            return "Szybki przepis domowy w stylu babcinym — prosty i wyraźny."
        case .fishReady:
            return "Delikatny bulion rybny bez owoców morza — lekki i czysty."
        case .collagenPoultryReady:
            return "Bulion kolagenowy drobiowy — wysoka żelatynowość i głębsze body."
        }
    }

    var selectedIngredientIDs: [String] {
        preset.defaultSelectedIDs
    }

    var totalWeightGrams: Int {
        result.meatParts.reduce(0) { $0 + $1.grams }
    }

    var estimatedYieldText: String {
        litersString(result.estimatedYieldLiters)
    }

    var cookingDurationText: String {
        durationString(result.totalMinutes)
    }

    private func litersString(_ value: Double) -> String {
        let formatted = value.formatted(.number.precision(.fractionLength(1)))
            .replacingOccurrences(of: ".", with: ",")
        return "\(formatted) l"
    }

    private func durationString(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if mins == 0 {
            return "\(hours) h"
        }

        if mins < 10 {
            return "\(hours),\(mins) h"
        }

        return "\(hours) h \(mins) min"
    }
}



