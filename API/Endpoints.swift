//
//  Endpoints.swift
//  API
//
//  Created by Tigran Danielian on 15.05.2025.
//

import Foundation

public extension ApiEndpoint {
    enum Events {
        // >= current date
        public static func dates() -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "event-dates",
                isAuthorizationRequired: false
            )
        }
        
        public static func get(id: Int) -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "event",
                task: .query(["id": id])
            )
        }
        
        public static func all() -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "events"
            )
        }

        /// Query: `page` (default 1), `per` or `perPage` (default 20, max 100).
        public static func schedule(page: Int = 1, per: Int = 20) -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "event-schedule",
                isAuthorizationRequired: false,
                task: .query([
                    "page": page,
                    "per": per,
                ])
            )
        }
    }
    
    enum Musicians {
        public static func musicians() -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "musicians"
            )
        }
        
        public static func eventMusicians(eventId: String) -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "eventMusicians",
                task: .query(["id": eventId])
            )
        }
    }
    
    enum ContentPages {
        public static func all() -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "pages"
            )
        }
        
        public static func get(id: Int) -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "pages",
                task: .query(["id": id])
            )
        }
    }
    
    enum Shop {
        public static func categories(id: Int? = nil) -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "shopCategories"
            )
        }
        
        public static func products(categoryId: Int? = nil) -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "shopProducts",
                task: .query(["categoryId": categoryId])
            )
        }
    }
}
