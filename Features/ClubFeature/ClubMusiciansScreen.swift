//
//  ClubMusiciansScreen.swift
//  ClubFeature
//
//  Created by Tigran Danielian on 16.05.2026.
//

import Foundation
import SwiftUI
import Services
import SharedInfrastructure
import Core


public struct ClubMusiciansScreenDependencies {
    public let musiciansService: MusiciansService
    public let favoritesStorage: FavoritesStorage<String>
    public let imageLoader: ImageLoader
    public let viewModelFactory: ViewModelFactory
    public let uiFactory: any UIFactory
}

public struct ClubMusiciansScreen: View {
    public let dependencies: ClubScreenDependencies
    public var router: ClubNavigationRouter
    
    public init(dependencies: ClubMusiciansScreenDependencies, router: ClubNavigationRouter) {
        self.dependencies = dependencies
        self.router = router
    }
    
    public var body: some View {
        
    }
}

public final class ClubMusiciansScreenViewModel: ObservableObject {
    
}
