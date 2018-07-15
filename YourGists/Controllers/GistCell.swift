//
//  GistCell.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import UIKit

class GistCell: UITableViewCell {
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func configure(with gist: Gist) {
        if gist.description == "" {
            self.descriptionLabel.text = "noname gist"
        } else {
            self.descriptionLabel.text = gist.description!
        }
    }
}
