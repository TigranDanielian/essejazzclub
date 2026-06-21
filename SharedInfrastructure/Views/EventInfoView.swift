//
//  EventInfoView.swift
//  Services
//
//  Created by Tigran Danielian on 09.06.2025.
//

import SwiftUI
import Core

struct EventInfoView: View {
    @ObservedObject var viewModel: EventViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if viewModel.hasDate {
                    Text(viewModel.dateString)
                        .font(.footnote)
                        .foregroundStyle(Color(uiColor: Colors.text))
                }
               
                HStack(spacing: 4) {
                    ForEach(viewModel.times, id: \.self) { time in
                        EventTimeView(time: time)
                    }

                    EventPriceView(price: viewModel.priceString)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                 Text(viewModel.title)
                     .font(.subheadline)
                     .bold()
                     .foregroundColor(Color(uiColor: Colors.text))
                     .multilineTextAlignment(.leading)
                     .padding(.trailing, 4)
                     .layoutPriority(1)

                 Text(viewModel.description)
                     .font(.caption)
                     .foregroundColor(Color(uiColor: Colors.secondaryText))
                     .multilineTextAlignment(.leading)
                     .padding(.trailing, 4)
                     .layoutPriority(0)
            }
        }
    }
}

//
//#Preview {
//    EventInfoView()
//}
