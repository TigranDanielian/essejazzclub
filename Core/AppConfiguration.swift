//
//  AppConfiguration.swift
//  Core
//
//  Created by Tigran Danielian on 15.05.2025.
//

import Foundation

public let Config: AppConfiguration = {
    #if APPSTORE
    return AppConfigurationAppStore()
    #elseif DEVELOP
    return AppConfigurationDebug()
    #else
    return AppConfigurationDebug()
    #endif
}()

public enum Flavor: String {
    case prod
    case dev
}

public protocol AppConfiguration {
    var apiBaseUrl: URL { get }
    
    var imageBaseUrl: URL { get }
    
    var isRelease: Bool { get }
    
    var flavor: Flavor { get }
}


public struct AppConfigurationDebug: AppConfiguration {
    public let apiBaseUrl = URL(string: "http://127.0.0.1:8080")!
    
    public let imageBaseUrl = URL(string: "https://www.jazzesse.ru/upload/")!
    
    public let isRelease: Bool = false
    
    public let flavor: Flavor = .dev
}


public struct AppConfigurationAppStore: AppConfiguration {
    public let apiBaseUrl = URL(string: "http://127.0.0.1:8080")!
    
    public let imageBaseUrl = URL(string: "https://www.jazzesse.ru/upload/")!
    
    public let isRelease: Bool = true
    
    public let flavor: Flavor = .prod
}
