//
//  ClubNavigationRouter.swift
//  ClubFeature
//

import SwiftUI
import SharedInfrastructure

/// Локальная навигация вкладки «Клуб»: детальные экраны разделов хаба.
@MainActor
final class ClubNavigationRouter: StackNavigationRouter<ClubNavigationRouter.Route> {
    enum Route: Hashable, Identifiable {
        case about
        case menu
        case contacts
        case musicians
        case favorites
        case giftShop
        case favoriteEventDetail(occurrenceIdentifier: String)
        case musicianDetail(MusicianViewModel)

        var id: String {
            switch self {
            case .about: return "club-about"
            case .menu: return "club-menu"
            case .contacts: return "club-contacts"
            case .musicians: return "club-musicians"
            case .favorites: return "club-favorites"
            case .giftShop: return "club-gift-shop"
            case .favoriteEventDetail(let oid):
                return "club-fav-detail-\(oid)"
            case .musicianDetail(let m):
                return "club-musician-\(m.musicianId)"
            }
        }
    }

    override init() {
        super.init()
    }
}
