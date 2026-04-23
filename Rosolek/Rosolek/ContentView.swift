import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userFirstName") private var userFirstName = "Paweł"
    @AppStorage("potSizeLiters") private var potSizeLiters = 7
    @AppStorage("hasThermometer") private var hasThermometer = true
    @AppStorage("returnToHomeTrigger") private var returnToHomeTrigger = 0

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
        .onChange(of: returnToHomeTrigger) { _, _ in
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
    @AppStorage("returnToHomeTrigger") private var returnToHomeTrigger = 0

    @State private var selectedPresetFilter: HomeRecipeFilter = .all
    @State private var activeCookingSession: CookingSession?
    @State private var deepLinkBatch: BatchRecord?
    @State private var navigateToDeepLinkedCooking = false
    @State private var selectedMenuTab: HomeMenuTab = .home
    @StateObject private var keyboard = KeyboardObserver()

    private var latestBatch: BatchRecord? {
        batchStore.batches.first
    }

    private var displayName: String {
        let trimmed = userFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Paweł" : trimmed
    }

    private var poultryPresetRecipe: HomePresetRecipe {
        HomePresetRecipe(
            preset: .poultryReady,
            potSizeLiters: Double(potSizeLiters)
        )
    }

    private var poultryBeefPresetRecipe: HomePresetRecipe {
        HomePresetRecipe(
            preset: .poultryBeefReady,
            potSizeLiters: Double(potSizeLiters)
        )
    }

    private var presetItems: [HomePresetItem] {
        [
            HomePresetItem(
                recipe: poultryPresetRecipe,
                artwork: .asset("HomeRecipePoultry"),
                fallbackStyle: .light,
                filter: .poultry
            ),
            HomePresetItem(
                recipe: poultryBeefPresetRecipe,
                artwork: .asset("HomeRecipePoultryBeef"),
                fallbackStyle: .intense,
                filter: .poultryBeef
            )
        ]
    }

    private var filteredPresetItems: [HomePresetItem] {
        presetItems.filter { selectedPresetFilter.matches($0.filter) }
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
                            .padding(.bottom, keyboard.isVisible ? 28 : 128)
                        }
                    case .recipes:
                        RecipesHubView(
                            compact: compact,
                            selectedPresetFilter: $selectedPresetFilter
                        )
                    case .history:
                        HistoryView()
                            .padding(.bottom, keyboard.isVisible ? 0 : 112)
                    case .settings:
                        SettingsView()
                            .padding(.bottom, keyboard.isVisible ? 0 : 112)
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
                    .padding(.bottom, max(geo.safeAreaInsets.bottom - 34, 0))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            returnToHomeTrigger = 0
            selectedMenuTab = .home
            CookingSessionCoordinator.clearOrphanedSessionIfNeeded(in: batchStore)
            activeCookingSession = CookingSession.load()
            handlePendingHomeRoute()
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
        .onChange(of: returnToHomeTrigger) { _, _ in
            selectedMenuTab = .home
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
                returnToHomeTrigger += 1
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
        case .openActiveCooking:
            if let batch = CookingSessionCoordinator.activeBatch(in: batchStore) {
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
                        title: "Klasyczny ramen shoyu",
                        subtitle: "Autorski przepis premium z prowadzeniem krok po kroku.",
                        artwork: .asset("HomeChefRamen")
                    )
                    .frame(width: compact ? 206 : 216)

                    LockedChefRecipeCard(
                        compact: compact,
                        title: "Bulion wołowy demi-glace",
                        subtitle: "Koncentrat o głębokim smaku, idealny do sosów i redukcji.",
                        artwork: .asset("HomeChefDemiGlace")
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

    var body: some View {
        AppCard(
            background: AppTheme.surfaceMuted,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: compact ? 14 : 16) {
                HomeRecipeArtwork(
                    artwork: artwork,
                    fallbackStyle: .intense,
                    compact: compact
                )

                HStack {
                    PremiumBadge()
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
    var body: some View {
        Text("Premium")
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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Wszystkie"
        case .poultry:
            return "Drobiowy"
        case .poultryBeef:
            return "Drobiowo-wołowy"
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

                    Image(systemName: "flame.fill")
                        .font(.system(size: 15, weight: .semibold))
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
        }
    }

    var subtitle: String {
        switch preset {
        case .poultryReady:
            return "Gotowa receptura drobiowa — czystszy smak i prostszy start."
        case .poultryBeefReady:
            return "Gotowa receptura z drobiem i wołowiną — pełniejszy smak i mocniejszy wywar."
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



private struct OnboardingFlowView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var userFirstName: String
    @Binding var potSizeLiters: Int
    @Binding var hasThermometer: Bool

    @State private var step: OnboardingStep = .welcome
    @State private var localName = ""
    @State private var selectedPotSize: Int? = nil
    @State private var isCustomPotSelected = false
    @State private var customPotSize = ""
    @State private var localHasThermometer: Bool? = nil

    @FocusState private var focusedField: OnboardingField?

    private let standardPotSizes = UserPreferencesConstants.standardPotSizes

    private var welcomeBackgroundColor: Color {
        Color(red: 0.914, green: 0.827, blue: 0.220)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                (step == .welcome ? welcomeBackgroundColor : AppTheme.background)
                    .ignoresSafeArea()

                if step == .welcome {
                    welcomeStep(in: geo)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            if step.showsProgress {
                                OnboardingProgressHeader(
                                    current: step.progressValue,
                                    total: 3,
                                    title: step.progressTitle
                                )
                            }

                            stepContent
                        }
                        .padding(.horizontal, AppSpacing.screen)
                        .padding(.top, 34)
                        .padding(.bottom, 94)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom) {
            onboardingFooter
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Gotowe") {
                    focusedField = nil
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .onAppear {
            localName = userFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
            selectedPotSize = potSizeLiters
            localHasThermometer = hasThermometer

            if standardPotSizes.contains(potSizeLiters) {
                isCustomPotSelected = false
                customPotSize = ""
            } else {
                isCustomPotSelected = true
                customPotSize = "\(potSizeLiters)"
            }
        }
        .onChange(of: customPotSize) { _, newValue in
            let filtered = UserPreferencesConstants.filteredPotSizeInput(newValue)
            if filtered != newValue {
                customPotSize = filtered
                return
            }
            if isCustomPotSelected, let value = Int(filtered), value > 0 {
                selectedPotSize = value
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.92), value: step)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            EmptyView()
        case .pot:
            potStep
        case .thermometer:
            thermometerStep
        case .name:
            nameStep
        }
    }

    private var onboardingFooter: some View {
        Group {
            if step == .welcome {
                Button {
                    goForward()
                } label: {
                    HStack(spacing: 10) {
                        Spacer(minLength: 0)

                        Text("Zaczynamy")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.black)

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 6)
                .padding(.bottom, 8)
                .background(Color.clear)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    if step.showsBackButton {
                        Button {
                            goBack()
                        } label: {
                            OnboardingBackButtonLabel(title: "Wstecz")
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        goForward()
                    } label: {
                        OnboardingPrimaryButton(
                            title: step.primaryButtonTitle,
                            disabled: !canContinue
                        )
                    }
                    .disabled(!canContinue)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(
                    AppTheme.background
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(AppTheme.border.opacity(0.75))
                                .frame(height: 1)
                        }
                )
            }
        }
    }

    private var customPotCard: some View {
        AppCard(
            background: isCustomPotSelected ? AppTheme.accentSoft : AppTheme.surface,
            border: isCustomPotSelected ? AppTheme.accent : AppTheme.border,
            lineWidth: isCustomPotSelected ? 1.5 : 1
        ) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isCustomPotSelected ? AppTheme.surface : AppTheme.surfaceMuted)
                            .frame(width: 44, height: 44)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Inna pojemność garnka")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Wpisz litraż ręcznie, jeśli najczęściej gotujesz w innym garnku.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 10)

                    ZStack {
                        Circle()
                            .fill(AppTheme.textPrimary)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.surface)
                    }
                    .opacity(isCustomPotSelected ? 1 : 0)
                }
                .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    isCustomPotSelected = true
                    if customPotSize.isEmpty, let selectedPotSize {
                        customPotSize = "\(selectedPotSize)"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        focusedField = .customPot
                    }
                }

                if isCustomPotSelected {
                    Rectangle()
                        .fill(AppTheme.border)
                        .frame(height: 1)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Np. 8", text: $customPotSize)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .customPot)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(AppTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        if let customPotAlert {
                            OnboardingInlineAlertCard(
                                systemImage: customPotAlert.systemImage,
                                message: customPotAlert.message,
                                tone: customPotAlert.tone
                            )
                        }
                    }
                    .padding(.top, 12)
                }
            }
        }
        .appSoftShadow()
    }

    private func welcomeStep(in geo: GeometryProxy) -> some View {
        ZStack(alignment: .topLeading) {
            Image("OnboardingHeroRosolek")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.bottom + 120)
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: geo.safeAreaInsets.top + 20)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Awansuj na rosołowego eksperta")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(-4)

                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.95, blue: 0.16),
                            Color(red: 0.98, green: 0.64, blue: 0.11)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 118, height: 5)
                    .clipShape(Capsule())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Złocisty, klarowny, pachnący — i tym razem naprawdę twój.")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white)
                    .lineSpacing(1)
                }
                .frame(maxWidth: geo.size.width * 0.44, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.screen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var potStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("W jakim garnku\ngotujesz najczęściej?")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Na tej podstawie kalkulator dobierze wodę, policzy ilość składników i pokaże, kiedy w garnku robi się za ciasno.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Wybierz pojemność")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(standardPotSizes, id: \.self) { size in
                    Button {
                        isCustomPotSelected = false
                        selectedPotSize = size
                        customPotSize = ""
                        focusedField = nil
                    } label: {
                        OnboardingPotTile(
                            title: "\(size) l",
                            subtitle: defaultPotSubtitle(for: size),
                            isSelected: !isCustomPotSelected && selectedPotSize == size
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            customPotCard

            Text("To tylko punkt startowy. Później możesz to zmienić.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 2)
        }
    }

    private var thermometerStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Jak chcesz\npilnować gotowania?")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Możemy prowadzić Cię z termometrem albo po tym, co dzieje się na powierzchni rosołu i na ogniu.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button {
                    localHasThermometer = true
                } label: {
                    OnboardingOptionCard(
                        icon: "thermometer",
                        title: "Mam termometr",
                        subtitle: "Będziesz sprawdzać go samodzielnie. Aplikacja tylko podpowie, kiedy i na co zwrócić uwagę.",
                        isSelected: localHasThermometer == true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    localHasThermometer = false
                } label: {
                    OnboardingOptionCard(
                        icon: "eye",
                        title: "Gotuję bez termometru",
                        subtitle: "Poprowadzimy Cię po wyglądzie powierzchni i pracy ognia.",
                        isSelected: localHasThermometer == false
                    )
                }
                .buttonStyle(.plain)
            }

            OnboardingInlineAlertCard(
                systemImage: "info.circle",
                message: "Aplikacja nie odczytuje temperatury automatycznie — także z termometru Bluetooth.",
                tone: .neutral
            )

            Text("To ustawienie możesz później zmienić.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 2)
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Jak mamy się do Ciebie\nzwracać?")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("To imię pokażemy na ekranie głównym i w kilku drobnych miejscach w aplikacji. Nie wpływa na liczenie.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField("Np. Paweł", text: $localName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .name)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("Możesz wpisać imię, ksywkę albo skrót. Zmienisz to później w ustawieniach.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 2)
        }
    }

    private func defaultPotSubtitle(for size: Int) -> String {
        switch size {
        case 5: return "mały domowy gar"
        case 7: return "najczęstszy wybór"
        case 10: return "na większy rosół"
        case 12: return "na duży gar"
        default: return ""
        }
    }

    private struct CustomPotAlertData {
        let systemImage: String
        let message: String
        let tone: OnboardingInlineAlertTone
        let blocksContinue: Bool
    }

    private var customPotAlert: CustomPotAlertData? {
        guard isCustomPotSelected else { return nil }
        guard let value = Int(customPotSize), value > 0 else { return nil }

        switch value {
        case 1...2:
            return CustomPotAlertData(
                systemImage: "exclamationmark.triangle",
                message: "To bardzo mały garnek. Do domyślnego ustawienia aplikacji zwykle lepiej wybrać większy.",
                tone: .warning,
                blocksContinue: false
            )
        case 3...20:
            return nil
        case 21...35:
            return CustomPotAlertData(
                systemImage: "info.circle",
                message: "To duży garnek. Jeśli naprawdę najczęściej gotujesz w takim, zostaw tę wartość.",
                tone: .neutral,
                blocksContinue: false
            )
        case 36...60:
            return CustomPotAlertData(
                systemImage: "exclamationmark.triangle",
                message: "To wygląda na bardzo duży garnek. Sprawdź, czy litraż nie został wpisany omyłkowo.",
                tone: .warning,
                blocksContinue: false
            )
        default:
            return CustomPotAlertData(
                systemImage: "xmark.octagon",
                message: "To raczej nie jest domowy garnek. Sprawdź litraż jeszcze raz.",
                tone: .danger,
                blocksContinue: true
            )
        }
    }

    private var canContinue: Bool {
        switch step {
        case .welcome:
            return true
        case .pot:
            if isCustomPotSelected {
                guard let value = Int(customPotSize), value > 0 else { return false }
                return customPotAlert?.blocksContinue != true
            }
            return selectedPotSize != nil
        case .thermometer:
            return localHasThermometer != nil
        case .name:
            return !localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var resolvedPotSize: Int {
        if isCustomPotSelected {
            return Int(customPotSize) ?? selectedPotSize ?? 7
        }
        return selectedPotSize ?? 7
    }

    private func goForward() {
        switch step {
        case .welcome:
            step = .pot
        case .pot:
            focusedField = nil
            step = .thermometer
        case .thermometer:
            step = .name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .name
            }
        case .name:
            userFirstName = localName.trimmingCharacters(in: .whitespacesAndNewlines)
            potSizeLiters = resolvedPotSize
            hasThermometer = localHasThermometer ?? true
            hasCompletedOnboarding = true
        }
    }

    private func goBack() {
        focusedField = nil

        switch step {
        case .welcome:
            break
        case .pot:
            step = .welcome
        case .thermometer:
            step = .pot
        case .name:
            step = .thermometer
        }
    }
}
private enum OnboardingStep {
    case welcome
    case pot
    case thermometer
    case name

    var showsProgress: Bool {
        self != .welcome
    }

    var showsBackButton: Bool {
        self != .welcome
    }

    var progressTitle: String {
        switch self {
        case .pot:
            return "Krok 1 z 3"
        case .thermometer:
            return "Krok 2 z 3"
        case .name:
            return "Krok 3 z 3"
        case .welcome:
            return ""
        }
    }

    var progressValue: Int {
        switch self {
        case .pot: return 1
        case .thermometer: return 2
        case .name: return 3
        case .welcome: return 0
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .welcome:
            return "Zaczynamy"
        case .pot, .thermometer:
            return "Dalej"
        case .name:
            return "Wejdź do aplikacji"
        }
    }
}

private enum OnboardingField {
    case name
    case customPot
}

private struct OnboardingProgressHeader: View {
    let current: Int
    let total: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 10) {
                ForEach(1...total, id: \.self) { index in
                    Capsule()
                        .fill(index <= current ? AppTheme.accent : AppTheme.border.opacity(0.8))
                        .frame(height: 6)
                }
            }
        }
    }
}

private struct OnboardingPrimaryButton: View {
    let title: String
    let disabled: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary.opacity(disabled ? 0.45 : 1))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(disabled ? AppTheme.accentSoft.opacity(0.55) : AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct OnboardingBackButtonLabel: View {
    let title: String

    var body: some View {
        Image(systemName: "chevron.left")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppTheme.textSecondary)
            .frame(width: 54, height: 54)
            .background(AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
    }
}


private struct OnboardingHeroPhotoSection: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = UIImage(named: "OnboardingHeroRosolek") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                OnboardingFallbackHeroPhoto()
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.00),
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text("Dopasowany start")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Color.white.opacity(0.16))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .clipShape(Capsule())
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, 18)
        }
        .frame(height: 286)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct OnboardingFallbackHeroPhoto: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.88, blue: 0.82),
                    Color(red: 0.86, green: 0.79, blue: 0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.40))
                .frame(width: 180, height: 180)
                .blur(radius: 6)
                .offset(x: -90, y: -60)

            Circle()
                .fill(Color(red: 0.90, green: 0.74, blue: 0.23).opacity(0.90))
                .frame(width: 140, height: 140)
                .offset(x: -40, y: 4)

            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 18)
                .frame(width: 154, height: 154)
                .offset(x: -40, y: 4)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 166, height: 192)
                .rotationEffect(.degrees(22))
                .offset(x: 110, y: -8)
                .blur(radius: 0.6)

            Circle()
                .fill(Color(red: 0.92, green: 0.73, blue: 0.22))
                .frame(width: 78, height: 78)
                .offset(x: 118, y: 62)
        }
    }
}

private struct OnboardingEditorialBenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

private enum OnboardingInlineAlertTone {
    case neutral
    case warning
    case danger

    var background: Color {
        switch self {
        case .neutral: return AppTheme.surfaceSoft
        case .warning: return AppTheme.accentSoft.opacity(0.65)
        case .danger: return Color(hex: "FFF1EF")
        }
    }

    var border: Color {
        switch self {
        case .neutral: return AppTheme.border
        case .warning: return AppTheme.accent.opacity(0.9)
        case .danger: return Color(hex: "F2B7AE")
        }
    }

    var foreground: Color {
        switch self {
        case .neutral, .warning: return AppTheme.textPrimary
        case .danger: return Color(hex: "8A2F24")
        }
    }
}

private struct OnboardingInlineAlertCard: View {
    let systemImage: String
    let message: String
    let tone: OnboardingInlineAlertTone

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tone.foreground)
                .frame(width: 18, height: 18)
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tone.foreground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.background)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tone.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct OnboardingPotTile: View {
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        AppCard(
            background: isSelected ? AppTheme.accentSoft : AppTheme.surface,
            border: isSelected ? AppTheme.accent : AppTheme.border,
            lineWidth: isSelected ? 1.5 : 1
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer(minLength: 0)

                    ZStack {
                        Circle()
                            .fill(AppTheme.textPrimary)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.surface)
                    }
                    .opacity(isSelected ? 1 : 0)
                }

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
        }
        .appSoftShadow()
    }
}

private struct OnboardingOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        AppCard(
            background: isSelected ? AppTheme.accentSoft : AppTheme.surface,
            border: isSelected ? AppTheme.accent : AppTheme.border,
            lineWidth: isSelected ? 1.5 : 1
        ) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? AppTheme.surface : AppTheme.surfaceMuted)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(AppTheme.textPrimary)
                        .frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.surface)
                }
                .opacity(isSelected ? 1 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 98, alignment: .leading)
        }
        .appSoftShadow()
    }
}


#Preview("Home") {
    NavigationStack {
        HomeView()
            .environmentObject(BatchStore())
    }
}

private struct OnboardingPreviewHost: View {
    @State private var hasCompletedOnboarding = false
    @State private var userFirstName = "Paweł"
    @State private var potSizeLiters = 7
    @State private var hasThermometer = true

    var body: some View {
        OnboardingFlowView(
            hasCompletedOnboarding: $hasCompletedOnboarding,
            userFirstName: $userFirstName,
            potSizeLiters: $potSizeLiters,
            hasThermometer: $hasThermometer
        )
    }
}

#Preview("Onboarding") {
    NavigationStack {
        OnboardingPreviewHost()
    }
}
