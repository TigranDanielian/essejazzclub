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
    private let upcomingOccurrences: [EventDetailUpcomingOccurrence]?
    @State private var attributedText: AttributedString = .init()

    public init(
        viewModel: EventViewModel,
        actionHandler: @escaping EventActionHandler,
        upcomingOccurrences: [EventDetailUpcomingOccurrence]? = nil
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
        self.upcomingOccurrences = upcomingOccurrences
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        ZStack {
                            Image(uiImage: viewModel.image ?? UIImage())
                                .resizable()
                                .scaledToFit()
                                .clipped()
                                .cornerRadius(12)

                            if viewModel.isLoadingImage {
                                SkeletonView()
                                    .cornerRadius(12)
                            }
                        }
                        .shadow(radius: 12)
                        
                        ZStack {
                            // 1️⃣ Основной контент
                            VStack(alignment: .leading) {
                                Text(viewModel.dateString(format: "d MMMM, EEEE"))
                                    .bold()
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 8)

                                HStack {
                                    Image(systemName: "clock")
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(Color(uiColor: Colors.text))

                                    ForEach(viewModel.times, id: \.self) { time in
                                        EventTimeView(time: time)
                                    }
                                }

                                HStack {
                                    Image(systemName: "ticket")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 12)
                                        .foregroundColor(Color(uiColor: Colors.text))

                                    EventPriceView(price: viewModel.priceString)
                                }
                            }
                            .padding([.horizontal, .bottom], 12)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // 2️⃣ Кнопки сверху справа
                            VStack {
                                HStack {
                                    Spacer()
                                    EventContextButton(
                                        viewModel: viewModel.favoriteButtonViewModel,
                                        onTap: { actionHandler(.contextAction(.favorite(viewModel.eventId))) }
                                    )
                                    EventContextButton(
                                        viewModel: viewModel.calendarButtonViewModel,
                                        onTap: { actionHandler(.contextAction(.calendar(viewModel))) }
                                    )
                                    EventContextButton(
                                        viewModel: viewModel.shareButtonViewModel,
                                        onTap: { actionHandler(.contextAction(.share)) }
                                    )
                                }
                                .padding(12)

                                Spacer()
                            }

                            // 3️⃣ Кнопка покупки снизу справа
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    BuyButton {
                                        actionHandler(.navigation(.onBuy))
                                    }
                                }
                                .padding(12)
                            }
                        }
                    }
                    .clipped()
                    .background(Color(uiColor: Colors.altBackground))
                    .cornerRadius(12)
                    .shadow(radius: 12)
                    
                    Text(viewModel.title)
                        .bold()
                        .padding(.horizontal, 12)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(uiColor: Colors.text))
                    
                    Text(viewModel.description)
                        .padding(.horizontal, 12)
                        .font(.title3)
                        .foregroundColor(Color(uiColor: Colors.text))
                    
                    SeparatorView()

                    if let upcomingOccurrences, !upcomingOccurrences.isEmpty {
                        upcomingDatesSection(upcomingOccurrences)
                    }
                    
                    ExpandableText(text: $attributedText, limit: 100)
                        .padding(12)
                        .font(.caption2)
                        .foregroundStyle(Color(uiColor: Colors.text))
                    
                    if !viewModel.musicians.isEmpty {
                        Text("Музыканты")
                            .bold()
                            .padding(.horizontal, 12)
                            .font(.title2)
                            .foregroundColor(Color(uiColor: Colors.text))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(viewModel.musicians) { musician in
                                    MusicianRowView(musician: musician, onSelect: {
                                        actionHandler(.navigation(.onMusicianDetails(musician)))
                                    })
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        .frame(height: 120, alignment: .top)
                        
                    }
                    
                    Spacer()
                }
            }
            
            Button(action: { actionHandler(.navigation(.dismiss)) }) {
                Image(systemName: "multiply")
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(uiColor: Colors.textInverted))
                    .background(Color(uiColor: Colors.mainBackground))
                    .cornerRadius(12)
                    .padding(8)
            }
        }
        .background(Color(uiColor: Colors.mainBackground))
        .onAppear {
            if let text = viewModel.text.htmlAttributed(font: .systemFont(ofSize: 14, weight: .medium), color: Colors.text) {
                attributedText = text
            }
        }
    }

    private static let upcomingSectionDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, EEEE"
        return f
    }()

    @ViewBuilder
    private func upcomingDatesSection(_ items: [EventDetailUpcomingOccurrence]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ближайшие даты")
                .bold()
                .font(.title3)
                .foregroundColor(Color(uiColor: Colors.text))
                .padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    HStack(alignment: .firstTextBaseline) {
                        Text(Self.upcomingSectionDayFormatter.string(from: item.date))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color(uiColor: Colors.text))
                        Spacer(minLength: 8)
                        Text(item.timesSummary)
                            .font(.subheadline)
                            .foregroundColor(Color(uiColor: Colors.secondaryText))
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(uiColor: Colors.cardBackground))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

struct MyView_Previews: PreviewProvider {
    
    static var previews: some View {
        EventDetailView(
            viewModel: EventViewModel(model: .preview, hasContextMenu: false, imageLoader: ImageLoaderImpl(host: URL(string: "https://www.jazzesse.ru/upload/")!).loadImage, favoritesStorage: .init(), musiciansProvider: nil),
            actionHandler: { _ in },
            upcomingOccurrences: nil
        )
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

struct MusicianRowView: View {
    @ObservedObject var musician: MusicianViewModel
    var onSelect: () -> Void = { }

    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: musician.image ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())

                if musician.isLoadingImage {
                    SkeletonView()
                        .frame(width: 72, height: 72)
                        .cornerRadius(36)
                }
            }
            .onTapGesture {
                onSelect()
            }
            
            Text(musician.name)
                .frame(maxWidth: 100)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct SeparatorView: View {
    var body: some View {
        Rectangle()
            .frame(height: 5)
            .cornerRadius(5)
            .foregroundColor(Color(uiColor: UIColor.darkGray))
            .padding(.horizontal, 20)
    }
}

struct BuyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Купить билет")
                .font(.caption)
                .foregroundColor(Color(uiColor: Colors.textInverted))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(uiColor: Colors.freetag))
                .cornerRadius(8)
        }
    }
}
