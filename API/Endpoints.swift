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
    }
    
    enum Musicians {
        public static func musicians() -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "musicians"
            )
        }
        
        public static func eventMusicians() -> ApiEndpoint {
            ApiEndpoint(
                method: .get,
                path: "eventMusicians"
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
}
