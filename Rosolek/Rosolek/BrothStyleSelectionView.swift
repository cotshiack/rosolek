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
    let title: String
    let subtitle: String
    let profile: BrothProfile

    var id: String { "\(title)-\(subtitle)-\(profile.rawValue)" }
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
                                        selectedStyle = nil
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

private struct BrothKindCard: View {
    let kind: BrothKind
    let isSelected: Bool
    let selectedStyleID: String?
    let onKindTap: () -> Void
    let onStyleTap: (BrothStyleOption) -> Void

    var body: some View {
        AppCard(
            background: isSelected ? AppTheme.accentSoft.opacity(0.68) : AppTheme.surface,
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

                        if isSelected {
                            Text("Wybrany")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.accentSoft))
                        }

                        Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .buttonStyle(.plain)

                if isSelected {
                    VStack(spacing: 8) {
                        ForEach(kind.styles) { style in
                            Button {
                                onStyleTap(style)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(style.title)
                                            .font(.system(size: 16, weight: .bold))
                                        Text(style.subtitle)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    if selectedStyleID == style.id {
                                        Label("Wybrano", systemImage: "checkmark.circle.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                                .fill(selectedStyleID == style.id ? AppTheme.accentSoft.opacity(0.45) : AppTheme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                                .stroke(selectedStyleID == style.id ? AppTheme.accent : AppTheme.border, lineWidth: selectedStyleID == style.id ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .appSoftShadow()
    }
}

private struct BrothKindIllustration: View {
    let kind: BrothKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surfaceMuted)
                .frame(width: 56, height: 56)

            switch kind {
            case .rosol:
                ZStack {
                    Circle().fill(Color(hex: "E6C36A")).frame(width: 28, height: 28)
                    Circle().stroke(Color(hex: "C79F49"), lineWidth: 2).frame(width: 30, height: 30)
                }
            case .ramen:
                ZStack {
                    Circle().fill(Color(hex: "D9B16A")).frame(width: 26, height: 26)
                    Circle().stroke(Color(hex: "B58748"), lineWidth: 2).frame(width: 30, height: 30)
                }
            case .beef:
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color(hex: "C36D54")).frame(width: 28, height: 20)
                    RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "9E4F3B"), lineWidth: 1.5).frame(width: 28, height: 20)
                }
            case .veggie:
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "65B56E")).frame(width: 7, height: 16)
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "8CCF85")).frame(width: 7, height: 16)
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "5AA463")).frame(width: 7, height: 16)
                }
            case .fish:
                ZStack {
                    Ellipse().fill(Color(hex: "9EB5C7")).frame(width: 24, height: 12)
                    Triangle()
                        .fill(Color(hex: "86A1B5"))
                        .frame(width: 8, height: 10)
                        .offset(x: 12)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
