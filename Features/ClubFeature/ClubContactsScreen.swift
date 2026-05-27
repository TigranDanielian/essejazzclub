//
//  ClubContactsScreen.swift
//  ClubFeature
//
//  Created by Tigran Danielian on 23.05.2026.
//

import SwiftUI
import UIKit
import Core

public struct ClubContactsScreen: View {
    @Environment(\.openURL) private var openURL
    @State private var showsMapPicker = false

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("ДЖАЗ-КЛУБ «ЭССЕ»")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .frame(maxWidth: .infinity, alignment: .leading)

                contactsCard {
                    contactsRow(
                        symbol: "mappin.and.ellipse",
                        title: "Адрес",
                        subtitle: "г. Москва, ул. Пятницкая, дом 27, стр. 3а",
                        action: { showsMapPicker = true }
                    )
                    contactsDivider
                    contactsRow(
                        symbol: "tram.fill",
                        title: "Метро",
                        subtitle: "м. Третьяковская\nм. Новокузнецкая"
                    )
                }

                contactsCard {
                    contactsRow(
                        symbol: "building.2.fill",
                        title: "ООО «Эссе»",
                        subtitle: "ИНН 9705064881\nОГРН 1167746375610"
                    )
                }

                contactsCard {
                    contactsRow(
                        symbol: "phone.fill",
                        title: "+7(495)9516404",
                        subtitle: nil,
                        action: { openURL(ClubContactsInfo.phonePrimaryURL) }
                    )
                    contactsDivider
                    contactsRow(
                        symbol: "phone.fill",
                        title: "+7(495)1502848",
                        subtitle: nil,
                        action: { openURL(ClubContactsInfo.phoneSecondaryURL) }
                    )
                }

                contactsCard {
                    contactsRow(
                        symbol: "globe",
                        title: "www.jazzesse.ru",
                        subtitle: nil,
                        action: { openURL(ClubContactsInfo.websiteURL) }
                    )
                }

                contactsCard {
                    contactsRow(
                        symbol: "clock.fill",
                        title: "Часы работы",
                        subtitle: "Ежедневно с 11:00 до 00:00"
                    )
                }

                contactsCard {
                    contactsRow(
                        symbol: "envelope.fill",
                        title: "По вопросам сотрудничества",
                        subtitle: ClubContactsInfo.cooperationEmail,
                        action: { openURL(ClubContactsInfo.cooperationEmailURL) }
                    )
                    contactsDivider
                    contactsRow(
                        symbol: "music.note",
                        title: "По вопросам организации концертов",
                        subtitle: ClubContactsInfo.concertsEmail,
                        action: { openURL(ClubContactsInfo.concertsEmailURL) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .appScrollContentBackgroundHidden()
        .background(Color(uiColor: Colors.mainBackground).ignoresSafeArea())
        .navigationTitle("Контакты")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Открыть адрес в картах",
            isPresented: $showsMapPicker,
            titleVisibility: .visible
        ) {
            ForEach(MapNavigationOption.options(for: ClubContactsInfo.mapsAddressQuery)) { option in
                Button(option.title) {
                    openURL(option.url)
                }
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func contactsCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(uiColor: Colors.cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var contactsDivider: some View {
        Divider()
            .overlay(Color(uiColor: Colors.mainBackground).opacity(0.35))
            .padding(.leading, 52)
    }

    @ViewBuilder
    private func contactsRow(
        symbol: String,
        title: String,
        subtitle: String?,
        action: (() -> Void)? = nil
    ) -> some View {
        let content = HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(uiColor: Colors.accentSheet))
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color(uiColor: Colors.text))
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: Colors.secondaryText))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(uiColor: Colors.secondaryText))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())

        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Data

private enum ClubContactsInfo {
    static let cooperationEmail = "info@jazzesse.ru"
    static let concertsEmail = "music@jazzesse.ru"
    static let mapsAddressQuery = "Москва, ул. Пятницкая, 27, стр. 3а"

    static let phonePrimaryURL = URL(string: "tel:+74959516404")!
    static let phoneSecondaryURL = URL(string: "tel:+74951502848")!
    static let websiteURL = URL(string: "https://www.jazzesse.ru")!
    static let cooperationEmailURL = URL(string: "mailto:\(cooperationEmail)")!
    static let concertsEmailURL = URL(string: "mailto:\(concertsEmail)")!
}

// MARK: - Maps

private struct MapNavigationOption: Identifiable {
    let id: String
    let title: String
    let url: URL

    static func options(for address: String) -> [MapNavigationOption] {
        [
            appleMaps(address: address),
            googleMaps(address: address),
            yandexMaps(address: address)
        ].compactMap { $0 }
    }

    private static func appleMaps(address: String) -> MapNavigationOption? {
        guard let url = urlWithQuery(
            base: "https://maps.apple.com/",
            items: [URLQueryItem(name: "address", value: address)]
        ) else { return nil }
        return MapNavigationOption(id: "apple", title: "Apple Карты", url: url)
    }

    private static func googleMaps(address: String) -> MapNavigationOption? {
        let appScheme = URL(string: "comgooglemaps://")!
        if UIApplication.shared.canOpenURL(appScheme),
           let url = urlWithQuery(
               base: "comgooglemaps://",
               items: [URLQueryItem(name: "q", value: address)]
           ) {
            return MapNavigationOption(id: "google", title: "Google Карты", url: url)
        }
        guard let url = urlWithQuery(
            base: "https://www.google.com/maps/search/",
            items: [
                URLQueryItem(name: "api", value: "1"),
                URLQueryItem(name: "query", value: address)
            ]
        ) else { return nil }
        return MapNavigationOption(id: "google", title: "Google Карты", url: url)
    }

    private static func yandexMaps(address: String) -> MapNavigationOption? {
        let appScheme = URL(string: "yandexmaps://")!
        if UIApplication.shared.canOpenURL(appScheme),
           let url = urlWithQuery(
               base: "yandexmaps://maps.yandex.ru/",
               items: [URLQueryItem(name: "text", value: address)]
           ) {
            return MapNavigationOption(id: "yandex", title: "Яндекс Карты", url: url)
        }
        guard let url = urlWithQuery(
            base: "https://yandex.ru/maps/",
            items: [URLQueryItem(name: "text", value: address)]
        ) else { return nil }
        return MapNavigationOption(id: "yandex", title: "Яндекс Карты", url: url)
    }

    private static func urlWithQuery(base: String, items: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: base)
        components?.queryItems = items
        return components?.url
    }
}
