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
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(uiColor: Colors.secondaryText))
                .padding(4)
            
            TextField(
                "",
                text: $textInput,
                prompt: Text("Search event").foregroundColor(.gray)
            )
            .padding([.trailing, .vertical], 4)
            .foregroundColor(Color(uiColor: Colors.text))
            .background(.clear)
            .tint(Color(uiColor: Colors.text))
            
            Spacer()
        }
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(8)
    }
}

#Preview {
    SearchTextField(textInput: .constant(""))
}
