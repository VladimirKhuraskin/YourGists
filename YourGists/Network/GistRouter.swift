//
//  GistRouter.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import Foundation
import Alamofire

enum GistRouter: URLRequestConvertible {
    
    static let baseURLString = "https://api.github.com/"
    
    case getAtPath(String)
      case getAtPath2(String)
    case getPublic()
    case getMine()
    case create([String: Any])
    
    func asURLRequest() throws -> URLRequest {
        
        var method: HTTPMethod {
            switch self {
            case .getPublic, .getAtPath, .getAtPath2, .getMine:
                return .get
            case .create:
                return .post
            }
        }
        
        let params: ([String: Any]?) = {
            switch self {
            case .getPublic, .getAtPath, .getAtPath2, .getMine:
                return nil
            case .create(let params):
                return (params)
            }
        }()
        
        let url: URL = {
            let relativePath: String?
            
            switch self {
            case .getPublic():
                relativePath = "gists/public"
            case .getAtPath(let path):
                //Already have full URL so just return it without any further actions
                return URL(string: path)!
            case .getAtPath2(let path):
                relativePath = "\(path)"
            case .getMine():
                relativePath = "gists"
            case .create:
                relativePath = "gists"
            }
            
            var url = URL(string: GistRouter.baseURLString)!
            if let relativePath = relativePath {
                url = url.appendingPathComponent(relativePath)
            }
            print(url)
            return url
        }()
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        // Set OAuth token if we have one
        if let token = GithubManager.sharedInstance.OAuthToken {
            urlRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoding = JSONEncoding.default
        return try encoding.encode(urlRequest, with: params)
    }
}
