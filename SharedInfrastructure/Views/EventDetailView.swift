//
//  EventDetailView.swift
//  ScheduleFeature
//
//  Created by Tigran Danielian on 11.06.2025.
//

import SwiftUI
import Core
import Services

private struct TitleOffsetPreference: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        print(value)
        value = nextValue()
    }
}

public struct EventDetailView: View {
    @ObservedObject var viewModel: EventViewModel
    private var actionHandler: EventActionHandler
    private let upcomingOccurrences: [EventDetailUpcomingOccurrence]?
    private let displayOptions: EventDetailDisplayOptions
    private let onSelectUpcomingOccurrence: ((String) -> Void)?
    @State private var attributedText: AttributedString = .init()
    @State private var bookingPresentation: BookingPresentation?
    @State private var bookingTimePickerPresentation: EventBookingTimePickerPresentation?
    @State private var navTitleHidden: Bool = true
    @State private var bottomBookButtonHidden: Bool = true

    public init(
        viewModel: EventViewModel,
        actionHandler: @escaping EventActionHandler,
        upcomingOccurrences: [EventDetailUpcomingOccurrence]? = nil,
        displayOptions: EventDetailDisplayOptions = .default,
        onSelectUpcomingOccurrence: ((String) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
        self.upcomingOccurrences = upcomingOccurrences
        self.displayOptions = displayOptions
        self.onSelectUpcomingOccurrence = onSelectUpcomingOccurrence
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        EventDetailHeroSlider(viewModel: viewModel)
                            .shadow(radius: 12)
                        
                        ZStack {
                            // 1️⃣ Основной контент
                            VStack(alignment: .leading) {
                                if displayOptions.showsHeroDateAndTimes {
                                    Text(viewModel.dateString(format: "d MMMM, EEEE"))
                                        .bold()
                                        .font(.headline)
                                        .foregroundColor(Color(uiColor: Colors.text))
                                        .padding(.top, 8)

                                    HStack {
                                        Image(systemName: "clock")
                                            .resizable()
                                            .frame(width: 14, height: 14)
                                            .foregroundColor(Color(uiColor: Colors.text))

                                        ForEach(viewModel.times, id: \.self) { time in
                                            EventTimeView(time: time, large: true)
                                        }
                                    }
                                }
                                
                                Spacer()

                                HStack {
                                    Image(systemName: "ticket")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 14)
                                        .foregroundColor(Color(uiColor: Colors.text))

                                    EventPriceView(price: viewModel.priceString, large: true)
                                }
                            }
                            .padding([.horizontal, .bottom], 12)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // 2️⃣ Кнопки сверху справа
                            VStack {
                                HStack(spacing: 8) {
                                    Spacer()
                                    FavoriteContextButton(
                                        viewModel: viewModel.favoriteHeartButtonViewModel,
                                        onTap: { actionHandler(.contextAction(.favorite(viewModel.eventId))) }
                                    )
                                    EventContextButton(
                                        viewModel: viewModel.calendarButtonViewModel,
                                        onTap: { actionHandler(.contextAction(.calendar(viewModel))) }
                                    )
                                    EventContextButton(
                                        viewModel: viewModel.shareButtonViewModel,
                                        onTap: { actionHandler(.contextAction(.share(viewModel))) }
                                    )
                                }
                                .padding(.horizontal, 12)
                                .padding(.bottom, 4)
                                .padding(.top, 12)

                                Spacer()
                            }

                            if displayOptions.showsBuyTicketButton, !viewModel.bookingSlots.isEmpty {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        GeometryReader { geo in
                                            BuyButton(title: viewModel.bookingButtonTitle) {
                                                presentBooking(for: viewModel)
                                            }
                                            .frame(width: geo.frame(in: .local).width, height: geo.frame(in: .local).height, alignment: .bottomTrailing)
                                            .preference(key: TitleOffsetPreference.self, value: geo.frame(in: .scrollView).minY)
                                        }
                                        .onPreferenceChange(TitleOffsetPreference.self) { value in
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                bottomBookButtonHidden = value > 20
                                            }
                                        }
                                        
                                    }
                                    .padding(12)
                                }
                            }
                        }
                    }
                    .clipped()
                    .background(Color(uiColor: Colors.altBackground))
                    .cornerRadius(12)
                    .shadow(radius: 12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.title)
                            .bold()
                            .padding(.horizontal, 12)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color(uiColor: Colors.text))
                       
                        Text(viewModel.description)
                            .padding(.horizontal, 12)
                            .font(.title3)
                            .foregroundColor(Color(uiColor: Colors.text))
                    }
                    
                    GeometryReader { geo in
                        SeparatorView()
                            .preference(key: TitleOffsetPreference.self, value: geo.frame(in: .scrollView).minY)
                    }
                    .onPreferenceChange(TitleOffsetPreference.self) { value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navTitleHidden = value > 44
                        }
                    }
                    

                    if let upcomingOccurrences, !upcomingOccurrences.isEmpty {
                        upcomingDatesSection(upcomingOccurrences)
                    }
                    
                    ExpandableText(text: $attributedText, limit: 100)
                        .padding(12)
                        .padding(.trailing, 24)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color(uiColor: Colors.text))
                        .lineSpacing(2.2)
                    
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
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .opacity(bottomBookButtonHidden ? 1 : 0)
                    .frame(height: bottomBookButtonHidden ? 0 : 63)
            }
            
            Button(action: { presentBooking(for: viewModel) }) {
                Text(viewModel.bookingButtonTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(uiColor: Colors.textOnAccent))
                    .frame(maxWidth: .infinity, minHeight: 51)
                    .background(Color(uiColor: Colors.accent))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .opacity(bottomBookButtonHidden ? 0 : 1)
        }
        .navigationTitle(navTitleHidden ? "" : viewModel.title)
        .navigationBarTitleDisplayMode(.automatic)
        .appScrollContentBackgroundHidden()
        .background(Color(uiColor: Colors.mainBackground))
        .task(id: viewModel.occurrenceIdentifier) {
            viewModel.loadImageIfNeeded()
            viewModel.loadMusiciansIfNeeded()
            await loadAttributedBio()
        }
        .onDisappear {
            viewModel.cancelImageLoad()
            viewModel.cancelMusiciansLoad()
        }
        .sheet(item: $bookingTimePickerPresentation) { presentation in
            EventBookingTimePickerSheet(
                slots: presentation.slots
            ) { slot in
                bookingPresentation = BookingPresentation(
                    url: slot.url,
                    title: presentation.bookingTitle
                )
            }
        }
        .sheet(item: $bookingPresentation) { presentation in
            TicketBookingSheet(url: presentation.url, title: presentation.title)
        }
    }

    private func presentBooking(for viewModel: EventViewModel) {
        let slots = viewModel.bookingSlots
        guard let first = slots.first else { return }

        if slots.count > 1 {
            bookingTimePickerPresentation = EventBookingTimePickerPresentation(
                slots: slots,
                bookingTitle: viewModel.bookingButtonTitle
            )
        } else {
            bookingPresentation = BookingPresentation(
                url: first.url,
                title: viewModel.bookingButtonTitle
            )
        }
    }

    private struct BookingPresentation: Identifiable {
        let id = UUID()
        let url: URL
        let title: String
    }

    @ViewBuilder
    private func upcomingDatesSection(_ items: [EventDetailUpcomingOccurrence]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Даты выступлений")
                .bold()
                .font(.title3)
                .foregroundColor(Color(uiColor: Colors.text))
                .padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    let row = upcomingOccurrenceRow(item)
                    if displayOptions.linksUpcomingOccurrences, let onSelect = onSelectUpcomingOccurrence {
                        Button {
                            onSelect(item.occurrenceIdentifier)
                        } label: {
                            row
                        }
                        .buttonStyle(.plain)
                    } else {
                        row
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 12)
    }

    private func upcomingOccurrenceRow(_ item: EventDetailUpcomingOccurrence) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(EventDateFormatting.formatDayMonthWeekday(item.date))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(uiColor: Colors.text))
                    .multilineTextAlignment(.leading)
                Text(item.timesSummary)
                    .font(.subheadline)
                    .foregroundColor(Color(uiColor: Colors.secondaryText))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if displayOptions.linksUpcomingOccurrences {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(uiColor: Colors.secondaryText))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(uiColor: Colors.cardBackground))
        .cornerRadius(10)
    }

    private func loadAttributedBio() async {
        guard let parsed = await HTMLBioFormatting.attributedString(from: viewModel.text) else { return }
        guard !Task.isCancelled else { return }
        attributedText = parsed
    }
}

#if DEBUG
struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(
            viewModel: EventViewModel(
                model: .preview,
                hasContextMenu: false,
                imageLoader: ImageLoaderImpl(host: URL(string: "https://www.jazzesse.ru/upload/")!).loadImage,
                favoritesStorage: .init(),
                calendarEventsManager: CalendarEventsManager(),
                musiciansProvider: nil
            ),
            actionHandler: { _ in },
            upcomingOccurrences: nil,
            displayOptions: .default,
            onSelectUpcomingOccurrence: nil
        )
        .previewDisplayName("Mock preview")
    }
}
#endif
