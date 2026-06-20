//
//  SearchTextField.swift
//  Core
//
//  Created by Tigran Danielian on 01.07.2025.
//

import SwiftUI
import Core

struct SearchTextField: View {
    @Binding var textInput: String
    var prompt: String = "Search event"
    var onClear: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(uiColor: Colors.secondaryText))
                .padding(4)

            ZStack(alignment: .trailing) {
                TextField(
                    "",
                    text: $textInput,
                    prompt: Text(prompt).foregroundColor(Color(uiColor: Colors.secondaryText))
                )
                .padding([.trailing, .vertical], 8)
                .foregroundColor(Color(uiColor: Colors.text))
                .background(.clear)
                .tint(Color(uiColor: Colors.text))

                if !textInput.isEmpty {
                    Button(action: clearInput) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(uiColor: Colors.secondaryText))
                    }
                }
            }

            Spacer()
        }
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(8)
    }

    private func clearInput() {
        if let onClear {
            onClear()
        } else {
            textInput = ""
        }
    }
}

#Preview {
    SearchTextField(textInput: .constant(""), prompt: "Search event")
}
