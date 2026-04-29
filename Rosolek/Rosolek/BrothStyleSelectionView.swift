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
                .init(title: "Lekki", subtitle: "Delikatny i klarowny na co dzień.", profile: .cleaner),
                .init(title: "Bogaty", subtitle: "Pełniejszy, gdy bulion gra główną rolę.", profile: .richer)
            ]
        case .ramen:
            return [
                .init(title: "Lekka baza", subtitle: "Czystsza baza do lżejszych ramenów.", profile: .cleaner),
                .init(title: "Mocna baza", subtitle: "Głębsza baza do wyrazistszych misek.", profile: .richer)
            ]
        case .beef:
            return [
                .init(title: "Czysty", subtitle: "Lżejszy wołowy finisz.", profile: .cleaner),
                .init(title: "Mocny", subtitle: "Intensywny profil pod sosy i dania.", profile: .richer)
            ]
        case .veggie:
            return [
                .init(title: "Jasny", subtitle: "Świeży i delikatny profil warzywny.", profile: .cleaner),
                .init(title: "Głęboki", subtitle: "Mocniejsze umami i pełniejsze body.", profile: .richer)
            ]
        case .fish:
            return [
                .init(title: "Delikatny", subtitle: "Lekki fumet do subtelnych dań.", profile: .cleaner),
                .init(title: "Intensywny", subtitle: "Wyraźniejsza baza do mocniejszych kompozycji.", profile: .richer)
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
    private var selectionSummary: String {
        if let kind = selectedKind, let style = selectedStyle {
            return "Wybrano: \(kind.rawValue) · \(style.title)"
        }
        if let kind = selectedKind {
            return "Wybierz styl dla: \(kind.rawValue)"
        }
        return "Wybierz rodzaj bulionu"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Wybierz rodzaj bulionu")
                    .font(AppTypography.flowHeader)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(selectionSummary)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

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
        let normalized = style.title.lowercased()
        if normalized.contains("lek") || normalized.contains("jas") || normalized.contains("czyst") || normalized.contains("delikat") { return "drop" }
        if normalized.contains("klasy") { return "circle.grid.2x1" }
        return "flame"
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
                }
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
                                        if selectedStyleID == style.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundStyle(AppTheme.accent)
                                        }
                                    }

                                    Text(style.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        

                                    Text(style.subtitle)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(3)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, minHeight: 122, alignment: .topLeading)
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
