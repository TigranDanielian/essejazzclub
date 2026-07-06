//
//  ClubNavigationRouter.swift
//  ClubFeature
//

import SwiftUI
import SharedInfrastructure

/// Локальная навигация вкладки «Клуб»: стек и модальные ветки.
@MainActor
public final class ClubNavigationRouter: StackNavigationRouter<ClubNavigationRouter.Route> {
    public enum Route: Hashable, Identifiable {
        case about
        case menu
        case contacts
        case musicians
        case favorites
        case giftShop
        case favoriteEventDetail(occurrenceIdentifier: String, mode: FavoriteEventDetailMode)
        case musicianDetail(MusicianViewModel, heroTransitionSourceID: String?)

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
            case .musicianDetail(let musician, let sourceID):
                return "club-musician-\(musician.musicianId)-\(sourceID ?? "plain")"
            }
        }
    }

    public override init() {
        super.init()
    }

    public override func deduplicationKey(for route: Route) -> String {
        switch route {
        case .favoriteEventDetail(let occurrenceIdentifier, _):
            return "event-\(occurrenceIdentifier)"
        case .musicianDetail(let musician, _):
            return "musician-\(musician.musicianId)"
        case .about:
            return "club-about"
        case .menu:
            return "club-menu"
        case .contacts:
            return "club-contacts"
        case .musicians:
            return "club-musicians"
        case .favorites:
            return "club-favorites"
        case .giftShop:
            return "club-gift-shop"
        }
    }
}
