//
//  ClubScreen.swift
//  ClubFeature
//

import SwiftUI
import Core

public struct ClubScreen: View {
    @StateObject private var viewModel: ClubScreenViewModel

    public init(dependencies: ClubScreenDependencies) {
        _viewModel = StateObject(wrappedValue: ClubScreenViewModel(dependencies: dependencies))
    }

    private let bannerItems: [ClubBannerItem] = [
        .init(
            title: "С приложением выгодно!",
            subtitle: "Покажите это приложение в клубе и получите скидку 10%",
            imageName: "Logo_black_eng"
        ),
        .init(
            title: "Специальные мероприятия",
            subtitle: "Авторские сеты, фестивали и камерные концерты.",
            imageName: "Logo_black_eng"
        )
    ]

    public var body: some View {
        ClubNavigationShell(viewModel: viewModel, bannerItems: bannerItems)
    }
}

/// Стек привязан к `router.path` через отдельный `@ObservedObject` на роутере.
/// Раньше `router.objectWillChange` пробрасывали в `ClubScreenViewModel`, и каждый push/pop
/// перерисовывал всю вкладку поверх обновления `NavigationStack` — после серии переходов ломались жесты.
private struct ClubNavigationShell: View {
    @ObservedObject var viewModel: ClubScreenViewModel
    @ObservedObject var router: ClubNavigationRouter
    let bannerItems: [ClubBannerItem]

    init(viewModel: ClubScreenViewModel, bannerItems: [ClubBannerItem]) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _router = ObservedObject(wrappedValue: viewModel.router)
        self.bannerItems = bannerItems
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    clubIdentityHeader

                    ClubFeaturesSlider(items: bannerItems)
                        .frame(height: 220)

                    hubSectionGroups
                }
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
            .navigationTitle("Клуб")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ClubNavigationRouter.Route.self) { route in
                ClubRouteDestinationView(route: route, clubViewModel: viewModel)
            }
        }
    }

    private var clubIdentityHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Уникальная джазовая площадка, объединяющая истинных ценителей качественного звука.")
                .font(.title2)
                .foregroundStyle(Color(uiColor: Colors.secondaryText))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private var hubSectionGroups: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(ClubHubGroup.allCases, id: \.self) { group in
                VStack(alignment: .leading, spacing: 10) {
                    Text(group.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                        .textCase(.uppercase)
                        .padding(.horizontal, 16)

                    VStack(spacing: 0) {
                        ForEach(Array(group.routes.enumerated()), id: \.element) { index, route in
                            ClubHubRow(route: route) {
                                viewModel.openHubRoute(route)
                            }
                            if index < group.routes.count - 1 {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color(uiColor: Colors.cardBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Hub grouping

private enum ClubHubGroup: CaseIterable {
    case guest
    case club
    case connect

    var title: String {
        switch self {
        case .guest: return "Для гостя"
        case .club: return "Клуб"
        case .connect: return "Как нас найти"
        }
    }

    var routes: [ClubNavigationRouter.Route] {
        switch self {
        case .guest:
            return [.favorites]
        case .club:
            return [.about, .musicians, .menu, .giftShop]
        case .connect:
            return [.contacts]
        }
    }
}

// MARK: - Row

private struct ClubHubRow: View {
    let route: ClubNavigationRouter.Route
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: route.symbolName)
                    .font(.title3)
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.hubTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color(uiColor: Colors.text))
                    Text(route.hubSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Route presentation (хаб)

private extension ClubNavigationRouter.Route {
    var hubTitle: String {
        switch self {
        case .about: return "О клубе"
        case .menu: return "Меню"
        case .contacts: return "Контакты"
        case .musicians: return "Музыканты"
        case .favorites: return "Избранное"
        case .giftShop: return "Гифт-шоп"
        case .favoriteEventDetail(_, _), .musicianDetail:
            return ""
        }
    }

    var hubSubtitle: String {
        switch self {
        case .about: return "История, залы, атмосфера"
        case .menu: return "Кухня и бар"
        case .contacts: return "Адрес, телефон, часы работы"
        case .musicians: return "Кто выступает в клубе"
        case .favorites: return "Концерты и музыканты"
        case .giftShop: return "Мерч и подарки"
        case .favoriteEventDetail(_, _), .musicianDetail:
            return ""
        }
    }

    var symbolName: String {
        switch self {
        case .about: return "building.columns.fill"
        case .menu: return "fork.knife"
        case .contacts: return "mappin.and.ellipse"
        case .musicians: return "music.mic"
        case .favorites: return "heart.fill"
        case .giftShop: return "gift.fill"
        case .favoriteEventDetail(_, _), .musicianDetail:
            return "circle"
        }
    }
}

// MARK: - Promo slider model

struct ClubBannerItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
}

#Preview("Club") {
    Text("ClubScreen(dependencies:) — см. RootView")
}
