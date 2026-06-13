//
//  MusicianPresentation.swift
//  SharedInfrastructure
//

import Foundation
import Services

struct MusicianPresentation {
    private let model: Musician

    init(model: Musician) {
        self.model = model
    }

    var name: String { model.name }
    var description: String { model.description }
    var text: String { model.text }
    var profession: String { model.profession }
    var imageUrlString: String? { model.imageUrl }
}
