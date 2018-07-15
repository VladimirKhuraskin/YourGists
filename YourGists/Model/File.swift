//
//  File.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import Foundation

class File {
    var filename: String?
    var raw_url: String?
    var content: String?
    
    required init?(json: [String: Any]) {
        self.filename = json["filename"] as? String
        self.raw_url = json["raw_url"] as? String
    }
    
    init?(gName: String?, gContent: String?) {
        self.content = gContent
        self.filename = gName
    }
}
