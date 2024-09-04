//
//  HomeVC.swift
//  IPListApp
//
//  Created by Afsal  on 27/08/24.
//

import UIKit
import Foundation
import CoreData

class HomeVC: UIViewController {

    @IBOutlet weak var listTable: UITableView!
    @IBOutlet weak var refrershButton: UIButton!
    var services = [NetService]()
    var devices = [AirplayDevice]()
    var serviceBrowser: NetServiceBrowser?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        setUpNavigationBarButtons()
        self.navigationController?.navigationBar.barTintColor = .black
            self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            self.navigationController?.navigationBar.tintColor = .white
            
            self.navigationController?.navigationBar.barStyle = .black
        setUpTableView()
        startServiceDiscovery()
        fetchDevicesFromCoreData()
    }
    private func setUpNavigationBarButtons() {
        
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshBtnTapped)
        )

        
        let logoutButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.backward.square"),
            style: .plain,
            target: self,
            action: #selector(logoutBtnTapped)
        )

        
        navigationItem.rightBarButtonItems = [logoutButton, refreshButton]
    }
    func setUpTableView() {
        listTable.delegate = self
        listTable.dataSource = self
        listTable.register(UINib(nibName: "DeviceListCell", bundle: nil), forCellReuseIdentifier: "deviceListCell")
    }

    func startServiceDiscovery() {
        serviceBrowser = NetServiceBrowser()
        serviceBrowser?.delegate = self
        serviceBrowser?.searchForServices(ofType: "_airplay._tcp.", inDomain: "local.")
        print("Service discovery started")
    }
   
    private func updateOrAddDevice(name: String, ipAddress: String, status: String) {
        let context = CoreDataStack.shared.context
        let fetchRequest: NSFetchRequest<AirplayDevice> = AirplayDevice.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deviceName == %@", name)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let device = results.first {
                device.ipAddress = ipAddress
                device.status = status
            } else {
                let newDevice = AirplayDevice(context: context)
                newDevice.deviceName = name
                newDevice.ipAddress = ipAddress
                newDevice.status = status
            }
            try context.save()
        } catch {
            print("Failed to update or add device: \(error)")
        }
    }

    private func fetchDevicesFromCoreData() {
        let context = CoreDataStack.shared.context
        let fetchRequest: NSFetchRequest<AirplayDevice> = AirplayDevice.fetchRequest()
        
        do {
            devices = try context.fetch(fetchRequest)
            listTable.reloadData()
        } catch {
            print("Failed to fetch devices: \(error)")
        }
        
    }

    private func addressToString(address: Data) -> String {
        var addr = sockaddr_in()
        address.withUnsafeBytes { pointer in
            let baseAddress = pointer.baseAddress!
            addr = baseAddress.load(as: sockaddr_in.self)
        }
        return String(cString: inet_ntoa(addr.sin_addr))
    }

   @objc func refreshBtnTapped() {
        startServiceDiscovery()
    }
    
    @objc func logoutBtnTapped() {
        LoginManager.shared().logoutAction()
        if let sceneDelegate = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.delegate as? SceneDelegate {
                sceneDelegate.showLoginScreen()
            }
        
    }
}

extension HomeVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "deviceListCell", for: indexPath) as? DeviceListCell {
            let device = devices[indexPath.row]
            cell.deviceNameLabel.text = device.deviceName ?? "Unknown"
            cell.ipLabel.text = device.ipAddress ?? "Unknown"
            cell.statusLabel.text = device.status ?? "Unknown"
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let detailVC = self.storyboard?.instantiateViewController(withIdentifier: "detailVC") as? DetailVC {
            
            detailVC.device = devices[indexPath.row]
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension HomeVC: NetServiceDelegate {
    
    func netService(_ sender: NetService, didResolveAddress addresses: [Data]) {
        
        
        
        print("did resolve address called")
        print("Resolved addresses for service: \(sender.name)")
           if addresses.isEmpty {
               print("No addresses found for service: \(sender.name)")
           } else {
               printContent(addresses.count)
               for address in addresses {
                   if let ipAddress = ipAddressFromData(address) {
                       print("Resolved IP Address: \(ipAddress)")
                       updateOrAddDevice(name: sender.name, ipAddress: ipAddress, status: "Reachable")
                   } else {
                       print("Failed to resolve IP address from address data")
                   }
               }
           }
           fetchDevicesFromCoreData()
    }
    func ipAddressFromData(_ data: Data) -> String? {
        if data.count >= MemoryLayout<sockaddr_in>.size {
            // Handle IPv4
            let address = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> sockaddr_in? in
                let sockaddr = pointer.baseAddress?.assumingMemoryBound(to: sockaddr_in.self).pointee
                return sockaddr
            }
            
            guard let sockaddr = address else { return nil }
            let ipAddress = String(cString: inet_ntoa(sockaddr.sin_addr))
            return ipAddress
        } else if data.count >= MemoryLayout<sockaddr_in6>.size {
            // Handle IPv6
            var address = sockaddr_in6()
            data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
                let baseAddress = pointer.baseAddress!.assumingMemoryBound(to: sockaddr_in6.self)
                address = baseAddress.pointee
            }
            
            var hostname = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &address.sin6_addr, &hostname, socklen_t(INET6_ADDRSTRLEN))
            return String(cString: hostname)
        }
        return nil
    }
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("didNotResolve address called \(sender.name)")
        printContent(sender.addresses?.count)
        updateOrAddDevice(name: sender.name, ipAddress: "UnAvailable", status: "Un-Reachable")
        fetchDevicesFromCoreData()
    }
}

extension HomeVC: NetServiceBrowserDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = nil;
       
        services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)

        
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
           print("Did not search: \(errorDict)")
       }

       func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
           print("Service browser did stop search")
       }
   
}
