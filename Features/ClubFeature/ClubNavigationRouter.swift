//
//  ClubNavigationRouter.swift
//  ClubFeature
//

import SwiftUI
import SharedInfrastructure

/// Локальная навигация вкладки «Клуб»: стек и модальные ветки.
@MainActor
public final class ClubNavigationRouter: StackNavigationRouter<ClubNavigationRouter.Route> {
    /// Режим деталки избранного концерта: обзор по событию или конкретный слот с датой и покупкой.
    public enum FavoriteEventDetailMode: String, Hashable {
        case overview
        case slot
    }

    public enum Route: Hashable, Identifiable {
        case about
        case menu
        case contacts
        case musicians
        case favorites
        case giftShop
        case favoriteEventDetail(occurrenceIdentifier: String, mode: FavoriteEventDetailMode)
        case musicianDetail(MusicianViewModel)

        public var id: String {
            switch self {
            case .about: return "club-about"
            case .menu: return "club-menu"
            case .contacts: return "club-contacts"
            case .musicians: return "club-musicians"
            case .favorites: return "club-favorites"
            case .giftShop: return "club-gift-shop"
            case .favoriteEventDetail(let oid, let mode):
                return "club-fav-detail-\(oid)-\(mode.rawValue)"
            case .musicianDetail(let m):
                return "club-musician-\(m.musicianId)"
            }
        }
    }

    public override init() {
        super.init()
    }
}
