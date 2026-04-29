import SwiftUI

// Legacy persistence type — used only for BatchRecord.styleRawValue storage and migration.
// Do not use in UI code. Use BrothProfile (.cleaner / .richer) instead.
enum BrothStyle: String, CaseIterable, Identifiable {
    case light
    case intense

    var id: String { rawValue }
}

enum BrothKind: String, CaseIterable, Identifiable {
    case rosol = "Rosół"
    case ramen = "Ramen"
    case beef = "Wołowy"
    case veggie = "Warzywny"
    case fish = "Rybny"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .rosol: return "Klasyczny bulion domowy"
        case .ramen: return "Baza ramenowa"
        case .beef: return "Głębszy bulion wołowy"
        case .veggie: return "Bulion bez mięsa"
        case .fish: return "Delikatna baza rybna"
        }
    }

    var styles: [BrothStyleOption] {
        switch self {
        case .rosol:
            return [
                .init(key: "rosol_light", title: "Lekki", subtitle: "Klarowny i subtelny na co dzień.", profile: .cleaner),
                .init(key: "rosol_rich", title: "Bogaty", subtitle: "Pełny smak do wyrazistych dań.", profile: .richer)
            ]
        case .ramen:
            return [
                .init(key: "ramen_shio", title: "Shio", subtitle: "Lżejsza, czystsza baza ramenowa.", profile: .cleaner),
                .init(key: "ramen_tonkotsu", title: "Tonkotsu", subtitle: "Gęsta i głęboka baza umami.", profile: .richer)
            ]
        case .beef:
            return [
                .init(key: "beef_clean", title: "Czysty", subtitle: "Lżejszy charakter bulionu wołowego.", profile: .cleaner),
                .init(key: "beef_strong", title: "Mocny", subtitle: "Intensywny fundament do sosów.", profile: .richer)
            ]
        case .veggie:
            return [
                .init(key: "veggie_bright", title: "Jasny", subtitle: "Świeży i lekki profil warzywny.", profile: .cleaner),
                .init(key: "veggie_umami", title: "Umami", subtitle: "Głębszy i pełniejszy smak warzyw.", profile: .richer)
            ]
        case .fish:
            return [
                .init(key: "fish_delicate", title: "Delikatny", subtitle: "Lekki fumet do subtelnych potraw.", profile: .cleaner),
                .init(key: "fish_intense", title: "Intensywny", subtitle: "Mocniejszy profil do głębszych dań.", profile: .richer)
            ]
        }
    }
}
struct BrothStyleOption: Identifiable, Hashable {
    let key: String
    let title: String
    let subtitle: String
    let profile: BrothProfile

    var id: String { key }
}

struct BrothStyleSelectionView: View {
    @State private var selectedKind: BrothKind? = nil
    @State private var selectedStyle: BrothStyleOption?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Wybierz rodzaj bulionu")
                    .font(AppTypography.flowHeader)
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(spacing: 12) {
                    ForEach(BrothKind.allCases) { kind in
                        BrothKindCard(
                            kind: kind,
                            isSelected: selectedKind == kind,
                            selectedStyleID: selectedStyle?.id,
                            onKindTap: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                    if selectedKind == kind {
                                        selectedKind = nil
                                        selectedStyle = nil
                                    } else {
                                        selectedKind = kind
                                        selectedStyle = kind.styles.first
                                    }
                                }
                            },
                            onStyleTap: { style in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedStyle = style
                                }
                            }
                        )
                    }
                }
            }
            .padding(AppSpacing.screen)
        }
        .background(AppTheme.background)
        .navigationTitle("Własny bulion")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if selectedKind == nil || selectedStyle == nil {
                    Text(selectedKind == nil ? "Wybierz rodzaj bulionu, aby kontynuować." : "Wybierz styl, aby kontynuować.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                NavigationLink {
                IngredientSelectionView(
                    selectedProfile: selectedStyle?.profile ?? .cleaner,
                    selectedKind: selectedKind ?? .rosol,
                    selectedStyleName: selectedStyle?.title ?? "Lekki"
                )
                } label: {
                    AppPrimaryButtonLabel(title: "Przejdź do składników", disabled: selectedKind == nil || selectedStyle == nil)
                }
                .disabled(selectedKind == nil || selectedStyle == nil)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, 8)
            .background(AppTheme.background.opacity(0.98).ignoresSafeArea(edges: .bottom))
        }
    }
}

private struct BrothKindCard: View {
    let kind: BrothKind
    let isSelected: Bool
    let selectedStyleID: String?
    let onKindTap: () -> Void
    let onStyleTap: (BrothStyleOption) -> Void

    private func iconName(for style: BrothStyleOption) -> String {
        switch style.key {
        case "rosol_light", "beef_clean", "veggie_bright", "fish_delicate", "ramen_shio":
            return "drop"
        default:
            return "flame"
        }
    }

    var body: some View {
        AppCard(
            background: AppTheme.surface,
            border: isSelected ? AppTheme.accent : AppTheme.border,
            lineWidth: isSelected ? 1.5 : 1
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: onKindTap) {
                    HStack(spacing: 12) {
                        BrothKindIllustration(kind: kind)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(kind.rawValue)
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(kind.subtitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .buttonStyle(.plain)

                if isSelected {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                        spacing: 10
                    ) {
                        ForEach(kind.styles) { style in
                            Button {
                                onStyleTap(style)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: iconName(for: style))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(selectedStyleID == style.id ? AppTheme.accent : AppTheme.textSecondary)
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(AppTheme.accent)
                                            .opacity(selectedStyleID == style.id ? 1 : 0)
                                    }

                                    Text(style.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        

                                    Text(style.subtitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(selectedStyleID == style.id ? AppTheme.accentSoft.opacity(0.2) : AppTheme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(selectedStyleID == style.id ? AppTheme.accent : AppTheme.border, lineWidth: selectedStyleID == style.id ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .appSoftShadow()
    }
}

private struct BrothKindIllustration: View {
    let kind: BrothKind
    
    private var assetName: String {
        switch kind {
        case .rosol: return "BulionRosol"
        case .ramen: return "BulionRamen"
        case .beef: return "BulionWolowy"
        case .veggie: return "BulionWarzywny"
        case .fish: return "BulionRybny"
        }
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
