//
//  LoginViewController.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import UIKit

protocol LoginViewDelegate: class {
    func didTapLoginButton()
}

class LoginViewController: UIViewController {
    
    weak var delegate: LoginViewDelegate?
    
    @IBAction func tappedLoginButton(_ sender: UIButton) {
        delegate?.didTapLoginButton()
    }
    
    @IBAction func unwindToLoginScreen(segue: UIStoryboardSegue) {
        usernameTextField.text = ""
    }
    
    var username: String?
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBAction func searchTapped(_ sender: UIButton) {
        guard let username = usernameTextField.text, username != "" else {
            let ac = UIAlertController(title: "Incorrect information", message: "Field Username can't be empty!", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            ac.addAction(cancel)
            present(ac, animated: true, completion: nil)
            return
        }
        self.username = username
        
        self.performSegue(withIdentifier: "showGistsSegue", sender: nil)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let dvc = segue.destination as? UINavigationController {
            if let targetController = dvc.topViewController as? PublicGistsViewController {
                targetController.username = self.username
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
