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
                .init(title: "Lekki", subtitle: "Czystszy i delikatny", profile: .cleaner),
                .init(title: "Klasyczny", subtitle: "Domowy, zbalansowany", profile: .cleaner),
                .init(title: "Bogaty", subtitle: "Pełniejszy i mocniejszy", profile: .richer)
            ]
        case .ramen:
            return [
                .init(title: "Lekka baza", subtitle: "Bardziej klarowna", profile: .cleaner),
                .init(title: "Pełna baza", subtitle: "Bardziej kremowa", profile: .richer),
                .init(title: "Mocna baza", subtitle: "Dłużej gotowana", profile: .richer)
            ]
        case .beef:
            return [
                .init(title: "Czysty", subtitle: "Lżejszy finisz", profile: .cleaner),
                .init(title: "Klasyczny", subtitle: "Zbalansowany", profile: .richer),
                .init(title: "Mocny", subtitle: "Wyraźnie wołowy", profile: .richer)
            ]
        case .veggie:
            return [
                .init(title: "Jasny", subtitle: "Lekki profil", profile: .cleaner),
                .init(title: "Klasyczny", subtitle: "Warzywny balans", profile: .cleaner),
                .init(title: "Głęboki", subtitle: "Więcej umami", profile: .richer)
            ]
        case .fish:
            return [
                .init(title: "Delikatny", subtitle: "Subtelny aromat", profile: .cleaner),
                .init(title: "Klasyczny", subtitle: "Zbalansowany", profile: .cleaner),
                .init(title: "Intensywny", subtitle: "Mocniejsza baza", profile: .richer)
            ]
        }
    }
}

struct BrothStyleOption: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let profile: BrothProfile
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

                VStack(spacing: 10) {
                    ForEach(BrothKind.allCases) { kind in
                        Button {
                            selectedKind = kind
                            selectedStyle = nil
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(kind.rawValue).font(.system(size: 17, weight: .bold))
                                    Text(kind.subtitle).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                if selectedKind == kind { Image(systemName: "checkmark.circle.fill") }
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(selectedKind == kind ? AppTheme.accentSoft : AppTheme.surface))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedKind == kind ? AppTheme.accent : AppTheme.border, lineWidth: 1))
                        }.buttonStyle(.plain)
                    }
                }

                if let selectedKind {
                    Text("Wybierz styl")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    VStack(spacing: 10) {
                        ForEach(selectedKind.styles) { style in
                            Button {
                                selectedStyle = style
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(style.title).font(.system(size: 16, weight: .bold))
                                        Text(style.subtitle).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    if selectedStyle?.id == style.id { Image(systemName: "checkmark") }
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(selectedStyle?.id == style.id ? AppTheme.accentSoft : AppTheme.surface))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedStyle?.id == style.id ? AppTheme.accent : AppTheme.border, lineWidth: 1))
                            }.buttonStyle(.plain)
                        }
                    }
                } else {
                    AppCard {
                        HStack(spacing: 10) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 15, weight: .bold))
                            Text("Najpierw wybierz rodzaj bulionu, a potem styl.")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding(AppSpacing.screen)
        }
        .background(AppTheme.background)
        .navigationTitle("Własny bulion")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
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
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, 8)
            .background(AppTheme.background.opacity(0.98).ignoresSafeArea(edges: .bottom))
        }
    }
}
