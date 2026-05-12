import SwiftUI

struct OnboardingFlowView: View {
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
        Color(red: 0.975, green: 0.968, blue: 0.955) // ciepły kremowy — pasuje do zdjęcia
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
                            .foregroundStyle(Color(red: 0.110, green: 0.102, blue: 0.090))

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(red: 0.110, green: 0.102, blue: 0.090))
                    }
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(red: 0.988, green: 0.792, blue: 0.11)) // żółty #FCCB1C
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
        let dark  = Color(red: 0.110, green: 0.102, blue: 0.090)
        let cream = Color(red: 0.975, green: 0.968, blue: 0.955)

        return ZStack(alignment: .top) {
            cream.ignoresSafeArea()

            // Image is 2.16:1 portrait; at screen width → ~841pt tall vs ~790pt content height.
            // Using full geo.size.height cuts only ~50pt of white bg at top — all ingredients visible.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Image("OnboardingHeroRosolek")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                    .clipped()
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(alignment: .center, spacing: 0) {
                // Fixed top gap — removes the excess space caused by safeAreaInsets double-counting
                Spacer().frame(height: 20)

                Image("RosolekLogoMark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(dark)
                    .padding(.bottom, 14)

                Text("Gotowy na\nprawdziwy\nbulion?")
                    .font(.system(size: 40, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(dark)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.95, blue: 0.16),
                        Color(red: 0.98, green: 0.64, blue: 0.11)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 128, height: 4)
                .clipShape(Capsule())
                .padding(.top, 14)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.screen)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
