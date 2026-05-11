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

        var id: String {
            switch self {
            case .about: return "club-about"
            case .menu: return "club-menu"
            case .contacts: return "club-contacts"
            case .musicians: return "club-musicians"
            case .favorites: return "club-favorites"
            case .giftShop: return "club-gift-shop"
            }
        }
    }

    override init() {
        super.init()
    }
}
