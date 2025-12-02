//
//  EventDetailView.swift
//  ScheduleFeature
//
//  Created by Tigran Danielian on 11.06.2025.
//

import SwiftUI
import Core
import Services

public struct EventDetailView: View {
    @ObservedObject var viewModel: EventViewModel
    private var actionHandler: EventActionHandler
    @State private var attributedText: AttributedString = .init()
    
    public init(
        viewModel: EventViewModel,
        actionHandler: @escaping EventActionHandler
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Image(uiImage: viewModel.image ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .clipped()
                        .cornerRadius(12)
                    
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading) {
                            Text(viewModel.dateString)
                                .bold()
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            HStack {
                                ForEach(viewModel.times, id: \.self) { time in
                                    EventTimeView(time: time)
                                }
                                
                                EventPriceView(price: viewModel.priceString)
                            }
                        }
                        .padding([.horizontal, .bottom], 12)
                        
                        HStack {
                            Spacer()
                            EventContextButton(viewModel: viewModel.favoriteButtonViewModel, onTap: { actionHandler(.contextAction(.favorite(viewModel.id))) })
                            EventContextButton(viewModel: viewModel.calendarButtonViewModel, onTap: { actionHandler(.contextAction(.calendar(viewModel))) })
                            EventContextButton(viewModel: viewModel.shareButtonViewModel, onTap: { actionHandler(.contextAction(.share)) })
                        }
                        .padding([.trailing, .top], 12)
                    }
                }
                .clipped()
                .background(Color(uiColor: Colors.altBackground))
                .cornerRadius(12)
                
                Text(viewModel.title)
                    .bold()
                    .padding(.horizontal, 12)
                    .font(.title2)
                    .foregroundColor(Color(uiColor: Colors.text))
                
                ExpandableText(text: $attributedText)
                    .padding(12)
                    .font(.caption2)
                    .foregroundStyle(Color(uiColor: Colors.text))
                
                Spacer()
            }
        }
        .background(Color(uiColor: Colors.mainBackground))
        .onAppear {
            if let text = viewModel.text.htmlAttributed(font: .systemFont(ofSize: 14, weight: .medium), color: Colors.text) {
                attributedText = text
            }
        }
    }
}

struct MyView_Previews: PreviewProvider {
    
    static var previews: some View {
        EventDetailView(viewModel: EventViewModel(model: .preview, hasContextMenu: false, imageLoader: ImageLoaderImpl(host: URL(string: "https://www.jazzesse.ru/upload/")!).loadImage, favoritesStorage: .init()), actionHandler: { _ in })
            .previewDisplayName("Mock preview")
    }
}

extension EventModel {
    static let preview: EventModel = .init(
        id: "",
        title: "Some title",
        description: "Some Description",
        text: "Some Text",
        dateWithTimes: DateWithTimes(id: 0, date: Date(), times: []),
        thumbnailUrl: "17115530506739scale_1200.png",
        bannerUrl: nil,
        type: .main,
        prices: [],
        isTop: false,
        youTubeLinks: [],
        eventId: 123
    )
}
