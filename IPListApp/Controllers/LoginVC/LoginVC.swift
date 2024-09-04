//
//  LoginVC.swift
//  IPListApp
//
//  Created by Afsal  on 27/08/24.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet weak var loginBtn: UIButton!
    override func viewDidLoad() {
            super.viewDidLoad()
        
        
          }

    override func viewWillAppear(_ animated: Bool) {
        setLoginBtn()
    }
         
    func setLoginBtn(){
        loginBtn.setTitle("Login with GitHub", for: .normal)
        loginBtn.layer.cornerRadius = 5
    }
    @IBAction func loginBtnTapped(_ sender: Any) {
        LoginManager.shared().loginAction { success, error in
            DispatchQueue.main.async {
                if success {
                    
                    let homeVC = HomeVC()
                    self.present(homeVC, animated: true, completion: nil)
                } else  {
                    self.showErrorAlert(error: error)
                }
            }
        }
    }

    func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
      
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


