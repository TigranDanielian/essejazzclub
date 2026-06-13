//
//  MenuYMLParser.swift
//  Services
//

import Foundation

enum MenuYMLParserError: LocalizedError {
    case invalidData
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .invalidData: return "Некорректные данные меню"
        case .parseFailed: return "Не удалось разобрать меню"
        }
    }
}

enum MenuYMLParser {
    private static let kitchenCategoryID = "235215950212"
    private static let lentenCategoryID = "785170775712"
    private static let ignoredCategoryIDs: Set<String> = ["383656712322"]

    private static let tildaStoreCategoryNames: [String: String] = [
        "1569415901": "Холодные закуски",
        "1569432411": "Тапасы",
        "1569432551": "Салаты",
        "1569432651": "Горячие закуски",
        "1569432981": "Горячие блюда",
        "1569433131": "Десерты",
    ]

    private static let categoryDisplayOrder = [
        "Постное меню",
        "Холодные закуски",
        "Тапасы",
        "Салаты",
        "Горячие закуски",
        "Горячие блюда",
        "Десерты",
    ]

    static func parse(data: Data) throws -> MenuCatalog {
        guard !data.isEmpty else { throw MenuYMLParserError.invalidData }
        let delegate = ParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            throw delegate.parseError ?? MenuYMLParserError.parseFailed
        }
        return MenuCatalog(sections: delegate.makeSections())
    }

    private final class ParserDelegate: NSObject, XMLParserDelegate {
        private var categories: [String: String] = [:]
        private var offers: [MutableOffer] = []
        fileprivate var parseError: Error?

        private var currentElement = ""
        private var currentText = ""
        private var currentOffer: MutableOffer?

        func makeSections() -> [MenuSection] {
            let items = offers.compactMap(makeMenuItem(from:))
            let grouped = Dictionary(grouping: items, by: \.categoryName)
            let orderedNames = MenuYMLParser.categoryDisplayOrder.filter { grouped[$0] != nil }
            let extraNames = grouped.keys
                .filter { !MenuYMLParser.categoryDisplayOrder.contains($0) }
                .sorted()
            return (orderedNames + extraNames).compactMap { name in
                guard let sectionItems = grouped[name], !sectionItems.isEmpty else { return nil }
                return MenuSection(categoryName: name, items: sectionItems)
            }
        }

        private func makeMenuItem(from raw: MutableOffer) -> MenuItem? {
            let name = raw.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, let price = raw.price else { return nil }
            guard let categoryName = resolveCategoryName(for: raw) else { return nil }

            return MenuItem(
                id: raw.id,
                name: name,
                descriptionHTML: raw.descriptionHTML?.trimmingCharacters(in: .whitespacesAndNewlines),
                pictureURL: raw.pictureURL?.trimmingCharacters(in: .whitespacesAndNewlines),
                price: price,
                categoryName: categoryName
            )
        }

        private func resolveCategoryName(for raw: MutableOffer) -> String? {
            guard let categoryID = raw.categoryID else { return nil }
            if MenuYMLParser.ignoredCategoryIDs.contains(categoryID) { return nil }

            if categoryID == MenuYMLParser.lentenCategoryID {
                return categories[categoryID] ?? "Постное меню"
            }

            if categoryID == MenuYMLParser.kitchenCategoryID,
               let storeID = tildaStoreID(from: raw.url),
               let mapped = MenuYMLParser.tildaStoreCategoryNames[storeID] {
                return mapped
            }

            return categories[categoryID]
        }

        private func tildaStoreID(from url: String?) -> String? {
            guard let url else { return nil }
            let pattern = #"tproduct/(\d+)-"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            let range = NSRange(url.startIndex..., in: url)
            guard let match = regex.firstMatch(in: url, range: range),
                  let idRange = Range(match.range(at: 1), in: url) else { return nil }
            return String(url[idRange])
        }

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            currentElement = elementName
            currentText = ""

            if elementName == "category", let id = attributeDict["id"] {
                currentOffer = MutableOffer(id: id)
            } else if elementName == "offer", let id = attributeDict["id"] {
                currentOffer = MutableOffer(id: id)
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentText += string
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            defer {
                currentText = ""
                if elementName == "offer" || elementName == "category" {
                    currentOffer = nil
                }
            }

            switch elementName {
            case "category":
                if let id = currentOffer?.id, !value.isEmpty {
                    categories[id] = value
                }
            case "offer":
                if let offer = currentOffer {
                    offers.append(offer)
                }
            case "name":
                currentOffer?.name = value
            case "description":
                currentOffer?.descriptionHTML = currentText
            case "picture":
                currentOffer?.pictureURL = value
            case "url":
                currentOffer?.url = value
            case "price":
                currentOffer?.price = Decimal(string: value.replacingOccurrences(of: ",", with: "."))
            case "categoryId":
                currentOffer?.categoryID = value
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
            self.parseError = parseError
        }
    }

    private final class MutableOffer {
        let id: String
        var name = ""
        var descriptionHTML: String?
        var pictureURL: String?
        var url: String?
        var price: Decimal?
        var categoryID: String?

        init(id: String) {
            self.id = id
        }
    }
}
