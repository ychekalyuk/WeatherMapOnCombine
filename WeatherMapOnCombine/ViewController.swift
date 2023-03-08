//
//  ViewController.swift
//  WeatherMapOnCombine
//
//  Created by Юрий Альт on 08.03.2023.
//

import UIKit
import Combine

enum WeatherError: Error {
    case invalidResponse
}

final class ViewController: UIViewController {
    //MARK: - Views
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Weather App"
        label.font = UIFont.systemFont(ofSize: 32)
        return label
    }()
    
    private lazy var searchTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "City"
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
    private lazy var temperatureLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Temperature is: 0.0 ºC"
        return label
    }()
    
    private lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Search", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(searchButtonDidTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        return activityIndicator
    }()
    
    //MARK: - Private Properties
    private let celsiusCharacters = "ºC"
    private let openWeatherBaseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let openWratherAPIKey = "fa12b43efaac31a59f56cf50fc900364"
    private var cancellable: AnyCancellable?
    
    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        view.addSubview(titleLabel)
        view.addSubview(searchTextField)
        view.addSubview(temperatureLabel)
        view.addSubview(searchButton)
        view.addSubview(activityIndicator)
        setupConstraints()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    //MARK: - Private Methods
    private func getTemperature(for cityName: String) {
        guard let weatherURL = URL(string: "\(openWeatherBaseURL)?APPID=\(openWratherAPIKey)&q=\(cityName)&units=metric") else { return }
        searchButton.isEnabled = false
        activityIndicator.startAnimating()
        
        cancellable = URLSession.shared.dataTaskPublisher(for: weatherURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw WeatherError.invalidResponse
                }
                return data
            }
            .decode(type: Weather.self, decoder: JSONDecoder())
            .catch { error in
                    Just(Weather.placeholder)
            }
            .map { $0.main?.temp ?? 0.0 }
            .map { "Temperature is: \($0) \(self.celsiusCharacters)" }
            .subscribe(on: DispatchQueue(label: "Combine.Weather"))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                self.activityIndicator.stopAnimating()
                self.searchButton.isEnabled = true
            }, receiveValue: { temp in
                self.temperatureLabel.text = temp
            })
    }
}

//MARK: - Actions
private extension ViewController {
    @objc private func searchButtonDidTap() {
        view.endEditing(true)
        guard let cityName = searchTextField.text else { return }
        getTemperature(for: cityName)
    }
}

//MARK: - Layout
private extension ViewController {
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            searchTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            searchTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            
            temperatureLabel.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 30),
            temperatureLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            temperatureLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            
            searchButton.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 30),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            searchButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
