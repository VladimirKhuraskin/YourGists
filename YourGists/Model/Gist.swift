//
//  Gist.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import Foundation

class Gist {
    
    var id: String?
    var description: String?
    var ownerLogin: String?
    var url: String?
    var files: [File]?
    var createdAt: Date?
    var updatedAt: Date?
    
    static let sharedDateFormatter = dateFormatter()
    
    class func dateFormatter() -> DateFormatter {
        let aDateFormatter = DateFormatter()
        aDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        aDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        aDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return aDateFormatter
    }
    
    required init(){
    }
    
    required init?(json: [String: Any]) {
        guard let description = json["description"] as? String,
            let idValue = json["id"] as? String,
            let url = json["url"] as? String else {
                return nil
        }
        
        self.description = description
        self.id = idValue
        self.url = url
        
        if let ownerJson = json["owner"] as? [String: Any] {
            self.ownerLogin = ownerJson["login"] as? String
        }
        
        self.files = [File]()
        if let filesJSON = json["files"] as? [String: [String: Any]] {
            for(_, fileJSON) in filesJSON {
                if let newFile = File(json: fileJSON) {
                    self.files?.append(newFile)
                }
            }
        }
        
        let dateFormatter = Gist.sharedDateFormatter
        if let dateString = json["created_at"] as? String {
            self.createdAt = dateFormatter.date(from: dateString)
        }
        if let dateString = json["updated_at"] as? String {
            self.updatedAt = dateFormatter.date(from: dateString)
        }
    }
}
