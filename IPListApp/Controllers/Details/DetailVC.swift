//
//  DetailVC.swift
//  IPListApp
//
//  Created by Afsal  on 27/08/24.
//

import UIKit

class DetailVC: UIViewController {
    @IBOutlet weak var ipAddressLabel: UILabel!
        @IBOutlet weak var geoInfoLabel: UILabel!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
            var device: AirplayDevice?
            
            override func viewDidLoad() {
                super.viewDidLoad()
                self.title = "Details"
                setupActivityIndicator()
                self.navigationController?.navigationBar.barTintColor = .black
                    
                    
                    self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
                    
                    
                    self.navigationController?.navigationBar.tintColor = .white
                    
                    
                    self.navigationController?.navigationBar.barStyle = .black
                ipAddressLabel.text = "IP Address: \(device?.ipAddress ?? "Unknown IP")"
                
                fetchPublicIP()
            }
    private func setupActivityIndicator() {
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        view.addSubview(activityIndicator)
        
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
            func fetchPublicIP() {
                let url = URL(string: "https://api.ipify.org?format=json")!
                let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data else { return }
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let ip = json?["ip"] as? String {
                        self.fetchGeoInfo(ip: ip)
                    }
                }
                task.resume()
            }
            
            func fetchGeoInfo(ip: String) {
                DispatchQueue.main.async {
                          self.activityIndicator.startAnimating() // Start the indicator before fetching
                      }
                let url = URL(string: "https://ipinfo.io/\(ip)/geo")!
                let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data else { return }
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        if let geoInfo = json {
                            self.geoInfoLabel.text = """
                            Location: \(geoInfo["city"] ?? "N/A"), \(geoInfo["region"] ?? "N/A")
                            Country: \(geoInfo["country"] ?? "N/A")
                            Org: \(geoInfo["org"] ?? "N/A")
                            """
                        }
                    }
                }
                task.resume()
            }


}
