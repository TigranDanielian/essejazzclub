//
//  MusicianUpcomingEventsProvider.swift
//  SharedInfrastructure
//

import Combine
import Services

public typealias MusicianUpcomingEventsProvider = (Int) -> AnyPublisher<[EventViewModel], Never>
