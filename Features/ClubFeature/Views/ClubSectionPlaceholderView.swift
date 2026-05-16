//
//  ClubSectionPlaceholderView.swift
//  ClubFeature
//

import SwiftUI
import Core

struct ClubSectionPlaceholderView: View {
    let route: ClubNavigationRouter.Route

    var body: some View {
        ScrollView {
            Text(message)
                .font(.body)
                .foregroundStyle(Color(uiColor: Colors.text))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        switch route {
        case .about: return "О клубе"
        case .menu: return "Меню"
        case .contacts: return "Контакты"
        case .giftShop: return "Гифт-шоп"
        case .favorites, .favoriteEventDetail(_, _), .musicianDetail, .musicians:
            return "Клуб"
        }
    }

    private var message: String {
        switch route {
        case .about:
            return "Здесь будет история ESSE Jazz Club, залы, атмосфера и то, что делает клуб особенным."
        case .menu:
            return "Кухня, бар и напитки — меню появится в приложении чуть позже."
        case .contacts:
            return "Адрес, телефон, часы работы и схема проезда будут доступны в этом разделе."
        case .giftShop:
            return "Мерч, подарочные сертификаты и акции гифт-шопа — скоро в этом разделе."
        case .favorites, .favoriteEventDetail(_, _), .musicianDetail, .musicians:
            return ""
        }
    }
}
