//
//  Weather.swift
//  WeatherMapOnCombine
//
//  Created by Юрий Альт on 09.03.2023.
//


struct Weather: Decodable {
    let main: Main?
    let name: String?
    
    static var placeholder: Self {
        Weather(main: nil, name: nil)
    }
}

struct Main: Decodable {
    let temp: Double?
}
