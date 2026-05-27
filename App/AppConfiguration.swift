//
//  AppConfiguration.swift
//  EsseJazzClub (Develop / Appstore)
//
//  Файл в таргете приложения, а не в Core: флаги DEVELOP / APPSTORE заданы только
//  у таргетов Develop и Appstore (project.yml). Core собирается без них, поэтому
//  #if APPSTORE в модуле Core никогда не срабатывал.
//

import Foundation

let Config: AppConfiguration = {
    #if APPSTORE
    return AppConfigurationAppStore()
    #elseif DEVELOP
    return AppConfigurationDebug()
    #else
    return AppConfigurationDebug()
    #endif
}()

enum Flavor: String {
    case prod
    case dev
}

protocol AppConfiguration {
    var apiBaseUrl: URL { get }
    var imageBaseUrl: URL { get }
    var isRelease: Bool { get }
    var flavor: Flavor { get }
}

struct AppConfigurationDebug: AppConfiguration {
    let apiBaseUrl = URL(string: "http://127.0.0.1:8080")!
    let imageBaseUrl = URL(string: "https://www.jazzesse.ru/upload/")!
    let isRelease = false
    let flavor: Flavor = .dev
}

struct AppConfigurationAppStore: AppConfiguration {
    let apiBaseUrl = URL(string: "http://193.168.3.162:8081")!
    let imageBaseUrl = URL(string: "https://www.jazzesse.ru/upload/")!
    let isRelease = true
    let flavor: Flavor = .prod
}
