//
//  SmartToolsModels.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

// MARK: - Shared enums

enum StudyLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case professional = "Professional"

    var id: String { rawValue }
}

// MARK: - API generation helper

enum SmartToolGeneration {

    @MainActor
    static func run(
        isLoading: Binding<Bool>,
        output: Binding<String>,
        errorMessage: Binding<String?>,
        showResult: Binding<Bool>? = nil,
        task: @escaping () async throws -> String
    ) {
        isLoading.wrappedValue = true
        errorMessage.wrappedValue = nil
        output.wrappedValue = ""

        Task {
            do {
                output.wrappedValue = try await task()
                if !output.wrappedValue.isEmpty {
                    showResult?.wrappedValue = true
                }
            } catch {
                errorMessage.wrappedValue = error.localizedDescription
            }
            isLoading.wrappedValue = false
        }
    }
}

// MARK: - Result sheet

extension View {
    func smartToolResultSheet(
        isPresented: Binding<Bool>,
        resultText: String,
        downloadFileName: String
    ) -> some View {
        sheet(isPresented: isPresented) {
            ResultView(resultText: resultText, downloadFileName: downloadFileName)
        }
    }
}

// MARK: - Shared header

struct SmartToolScreenHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textWhite)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: "#1C1C1C"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appStroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.sfProDisplaySemiBold(20))
                .foregroundStyle(Color.textWhite)

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(Color.appSecondarybg)
    }
}

// MARK: - Description field

struct SmartToolDescriptionField: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            ChatInputView(text: $text, onSend: onSubmit)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(.sfProDisplayRegular(16))
                    .foregroundStyle(Color.tetxGray)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }
        }
        .background(Color(hex: "#2B2B2B"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Labeled field

struct SmartToolLabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.sfProDisplaySemiBold(16))
                .foregroundStyle(Color.textWhite)

            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Color.tetxGray))
                .textFieldStyle(.plain)
                .font(.sfProDisplayRegular(16))
                .foregroundStyle(Color.textWhite)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(Color(hex: "#2B2B2B"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Chip section

struct SmartToolChipSection<T: Identifiable & RawRepresentable & Hashable>: View
where T.RawValue == String {
    let title: String
    let options: [T]
    let selection: T
    let onSelect: (T) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.sfProDisplaySemiBold(16))
                .foregroundStyle(Color.textWhite)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options) { option in
                        SmartToolSelectionChip(
                            title: option.rawValue,
                            isSelected: selection.id == option.id,
                            action: { onSelect(option) }
                        )
                    }
                }
            }
        }
    }
}

struct SmartToolSelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.sfProDisplayMedium(14))
                .foregroundStyle(Color.textWhite)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color(hex: "#1C1C1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.tetxGray : Color.appStroke,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generate button

struct SmartToolGenerateButton: View {
    let isLoading: Bool
    let action: () -> Void

    init(isLoading: Bool = false, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color(hex: "#D4D4D4"))
                }
                Text(isLoading ? "Generating…" : "Generate now")
                    .font(.sfProDisplaySemiBold(18))
                    .foregroundStyle(Color(hex: "#D4D4D4"))
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 14)
            .background(Color(hex: "#8F6B4F"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Output & status

struct SmartToolOutputSection: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Result")
                .font(.sfProDisplaySemiBold(16))
                .foregroundStyle(Color.textWhite)

            ScrollView {
                Group {
                    if let attributed = try? AttributedString(markdown: text) {
                        Text(attributed)
                    } else {
                        Text(text)
                    }
                }
                .font(.sfProDisplayRegular(16))
                .foregroundStyle(Color.textWhite)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .frame(minHeight: 160, maxHeight: 280)
            .background(Color(hex: "#1C1C1C"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SmartToolErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.sfProDisplayRegular(14))
            .foregroundStyle(Color.red.opacity(0.9))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
