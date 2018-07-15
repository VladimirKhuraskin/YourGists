//
//  DetailViewController.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var detailTextView: UITextView!
    var gist: Gist?
    var file: File?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let files = gist?.files else { return }
        for i in files {
            file = i
        }
        title = file?.filename
        if file?.raw_url != nil {
            guard let gistUrl = URL(string: (file?.raw_url)!) else { return }
            URLSession.shared.downloadTask(with: gistUrl) { localURL, urlResponse, error in
                if let localURL = localURL {
                    if let string = try? String(contentsOf: localURL) {
                        DispatchQueue.main.async {
                            self.detailTextView.text = string
                        }
                    }
                }
                }.resume()
        }
    }
}
