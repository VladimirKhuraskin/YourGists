//
//  NewGistViewController.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import UIKit

class NewGistViewController: UITableViewController {
    
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var filenameTextField: UITextField!
    @IBOutlet weak var gistContentTextField: UITextView!
    
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        
        let isPublic = true
        
        if gistContentTextField.text == "" || filenameTextField.text == "" || descriptionTextField.text == "" {
            let ac = UIAlertController(title: "Insufficient information", message: "All fields must be filled!", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            ac.addAction(cancel)
            present(ac, animated: true, completion: nil)
        }
        else {
            guard let description = descriptionTextField.text, let filename = filenameTextField.text, let fileContent = gistContentTextField.text else { return }
            var files = [File]()
            if let file = File(gName: filename, gContent: fileContent) {
                files.append(file)
            }
            
            GithubManager.sharedInstance.createNewGist(description: description, isPublic: isPublic, files: files) {
                result in
                guard result.error == nil,
                    let successValue = result.value, successValue == true else {
                        print(result.error!)
                        let ac = UIAlertController(title: "Could not create Gist", message: "Sorry, your gist couldn't be created. Maybe connection is down or you don't have internet connection.", preferredStyle: .alert)
                        
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        ac.addAction(okAction)
                        self.present(ac, animated: true, completion: nil)
                        return
                }
                self.performSegue(withIdentifier: "unwindSegueFromNewGist", sender: nil)
            }
            sender.isEnabled = false
        }
    }
}
