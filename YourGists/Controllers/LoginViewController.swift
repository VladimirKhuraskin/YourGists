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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = keyboardSize.cgRectValue
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= keyboardFrame.height
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
}
