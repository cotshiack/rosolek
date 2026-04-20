import SwiftUI

struct SettingsView: View {
    @AppStorage("userFirstName") private var userFirstName = "Paweł"
    @AppStorage("potSizeLiters") private var potSizeLiters = 7
    @AppStorage("hasThermometer") private var hasThermometer = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("returnToHomeTrigger") private var returnToHomeTrigger = 0

    @State private var activeEditor: EditableSetting?

    @State private var draftName = ""
    @State private var draftPotSize = 7
    @State private var draftHasThermometer = true
    @State private var isCustomPotSelected = false
    @State private var customPotSize = ""

    @FocusState private var focusedField: Field?

    private let standardPotSizes = [5, 7, 10, 12]

    private enum EditableSetting {
        case name
        case pot
        case thermometer
    }

    private enum Field {
        case name
        case customPot
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                settingsCard
            }
            .padding(AppSpacing.screen)
            .padding(.bottom, 28)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Ustawienia")
        .navigationBarTitleDisplayMode(.inline)
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
            resetDrafts()
        }
        .onChange(of: customPotSize) { newValue in
            let filtered = newValue.filter(\.isNumber)

            if filtered != newValue {
                customPotSize = filtered
                return
            }

            if isCustomPotSelected, let value = Int(filtered), value > 0 {
                draftPotSize = value
            }
        }
        .animation(.easeInOut(duration: 0.18), value: activeEditor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ustawienia")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Zmień podstawowe ustawienia aplikacji. Wpływają na presety, wyliczenia i sposób prowadzenia rosołu.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var settingsCard: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border
        ) {
            VStack(spacing: 0) {
                settingsRow(
                    icon: "person.fill",
                    title: "Imię",
                    value: displayName,
                    isEditing: activeEditor == .name
                ) {
                    toggleEditor(.name)
                }

                if activeEditor == .name {
                    inlineNameEditor
                }

                divider

                settingsRow(
                    icon: "water.waves",
                    title: "Wielkość garnka",
                    value: potLabel,
                    isEditing: activeEditor == .pot
                ) {
                    toggleEditor(.pot)
                }

                if activeEditor == .pot {
                    inlinePotEditor
                }

                divider

                settingsRow(
                    icon: "thermometer",
                    title: "Termometr",
                    value: thermometerLabel,
                    isEditing: activeEditor == .thermometer
                ) {
                    toggleEditor(.thermometer)
                }

                if activeEditor == .thermometer {
                    inlineThermometerEditor
                }

                divider

                onboardingDebugRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appSoftShadow()
    }

    private var divider: some View {
        Divider()
            .overlay(AppTheme.border)
    }

    private var inlineNameEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Np. Paweł", text: $draftName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(AppTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))

            inlineActions(
                onCancel: cancelEditing,
                onSave: saveName,
                canSave: canSaveName
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var inlinePotEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(standardPotSizes, id: \.self) { size in
                    compactChoiceChip(
                        title: "\(size) l",
                        isSelected: !isCustomPotSelected && draftPotSize == size
                    ) {
                        isCustomPotSelected = false
                        draftPotSize = size
                        customPotSize = "\(size)"
                        focusedField = nil
                    }
                }
            }

            compactChoiceChip(
                title: "Inna pojemność",
                isSelected: isCustomPotSelected,
                fullWidth: true
            ) {
                isCustomPotSelected = true
                if customPotSize.isEmpty {
                    customPotSize = "\(draftPotSize)"
                }
                focusedField = .customPot
            }

            if isCustomPotSelected {
                TextField("Np. 8", text: $customPotSize)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .customPot)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(AppTheme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            }

            inlineActions(
                onCancel: cancelEditing,
                onSave: savePot,
                canSave: canSavePot
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var inlineThermometerEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            compactSelectRow(
                title: "Mam termometr",
                subtitle: "Pokaż dokładny zakres temperatury",
                isSelected: draftHasThermometer
            ) {
                draftHasThermometer = true
            }

            compactSelectRow(
                title: "Nie mam termometru",
                subtitle: "Pokaż wskazówki wizualne bez pełnego wrzenia",
                isSelected: !draftHasThermometer
            ) {
                draftHasThermometer = false
            }

            inlineActions(
                onCancel: cancelEditing,
                onSave: saveThermometer,
                canSave: true
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var onboardingDebugRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Onboarding")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Text("Pokaż ponownie")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer(minLength: 12)

            Button {
                relaunchOnboarding()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold))

                    Text("Uruchom")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(AppTheme.accentSoft)
                .overlay(
                    Capsule()
                        .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
    }

    private func settingsRow(
        icon: String,
        title: String,
        value: String,
        isEditing: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.surfaceMuted)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isEditing ? AppTheme.accentSoft : AppTheme.background)
                        .frame(width: 40, height: 40)

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
    }

    private func inlineActions(
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        canSave: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Button(action: onCancel) {
                compactSecondaryButton(title: "Anuluj")
            }
            .buttonStyle(.plain)

            Button(action: onSave) {
                compactPrimaryButton(title: "Zapisz", disabled: !canSave)
            }
            .disabled(!canSave)
            .buttonStyle(.plain)
        }
    }

    private func compactChoiceChip(
        title: String,
        isSelected: Bool,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isSelected ? AppTheme.accentSoft : AppTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                        .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 1.5 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .gridCellColumns(fullWidth ? 4 : 1)
    }

    private func compactSelectRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AppTheme.textPrimary : AppTheme.border,
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(AppTheme.textPrimary)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(isSelected ? AppTheme.accentSoft : AppTheme.background)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func compactPrimaryButton(title: String, disabled: Bool) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary.opacity(disabled ? 0.45 : 1))
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(disabled ? AppTheme.accentSoft.opacity(0.5) : AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
    }

    private func compactSecondaryButton(title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(AppTheme.background)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
    }

    private var displayName: String {
        let trimmed = userFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Bez imienia" : trimmed
    }

    private var potLabel: String {
        "\(potSizeLiters) l"
    }

    private var thermometerLabel: String {
        hasThermometer ? "Mam termometr" : "Nie mam termometru"
    }

    private var canSaveName: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSavePot: Bool {
        if isCustomPotSelected {
            guard let value = Int(customPotSize) else { return false }
            return value > 0
        }

        return draftPotSize > 0
    }

    private func toggleEditor(_ editor: EditableSetting) {
        focusedField = nil

        if activeEditor == editor {
            cancelEditing()
            return
        }

        resetDrafts()
        activeEditor = editor

        if editor == .name {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                focusedField = .name
            }
        }

        if editor == .pot && isCustomPotSelected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                focusedField = .customPot
            }
        }
    }

    private func cancelEditing() {
        focusedField = nil
        resetDrafts()
        activeEditor = nil
    }

    private func resetDrafts() {
        draftName = userFirstName
        draftPotSize = potSizeLiters
        draftHasThermometer = hasThermometer

        if standardPotSizes.contains(potSizeLiters) {
            isCustomPotSelected = false
            customPotSize = "\(potSizeLiters)"
        } else {
            isCustomPotSelected = true
            customPotSize = "\(potSizeLiters)"
        }
    }

    private func saveName() {
        guard canSaveName else { return }
        userFirstName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        focusedField = nil
        activeEditor = nil
    }

    private func savePot() {
        guard canSavePot else { return }

        if isCustomPotSelected {
            if let value = Int(customPotSize), value > 0 {
                potSizeLiters = value
                draftPotSize = value
            }
        } else {
            potSizeLiters = draftPotSize
        }

        focusedField = nil
        activeEditor = nil
    }

    private func saveThermometer() {
        hasThermometer = draftHasThermometer
        focusedField = nil
        activeEditor = nil
    }

    private func relaunchOnboarding() {
        focusedField = nil
        activeEditor = nil
        hasCompletedOnboarding = false
        returnToHomeTrigger += 1
    }
}
