//
//  LoginViewController.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import UIKit
import Alamofire

protocol LoginViewDelegate: class {
    func didTapLoginButton()
}

class LoginViewController: UIViewController, UIGestureRecognizerDelegate {
    
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
        userExistsWith(username: usernameTextField.text!) { response in
            if response {
                self.performSegue(withIdentifier: "showGistsSegue", sender: nil)
            } else {
                let ac = UIAlertController(title: "Incorrect information", message: "There is no user with this Username, please check your details", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                ac.addAction(cancel)
                self.present(ac, animated: true, completion: nil)
            }
        }
        self.username = username
    }
    
    func userExistsWith(username: String, completion: @escaping (Bool) -> Void){
        Alamofire.request("https://api.github.com/users/\(username)", method: .get).validate().responseJSON { response in
            switch response.result {
            case .success( _):
                completion(true)
            case .failure(let error):
                debugPrint(error)
                completion(false)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let dvc = segue.destination as? UINavigationController {
            if let targetController = dvc.topViewController as? PublicGistsViewController {
                targetController.username = self.username
            }
        }
    }
    
    @IBOutlet var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView(gesture:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    @objc func didTapView(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: nil) {
            notification in
            self.keyboardWillShow(notification: notification)
        }
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: nil) {
            notification in
            self.keyboardWillHide(notification: notification)
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo, let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let contentInsert = UIEdgeInsets(top: 0, left: 0, bottom: frame.height + 70, right: 0)
        scrollView.contentInset = contentInsert
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = UIEdgeInsets.zero
    }
    
}
