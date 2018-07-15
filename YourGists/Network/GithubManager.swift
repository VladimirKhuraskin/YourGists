//
//  GitHubAPIManager.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import Foundation
import Alamofire

class GithubManager {
    
    static let sharedInstance = GithubManager()
    
    let clientID: String = "44dc49eedd15d7a9e19a"
    let clientSecret: String = "d4fc3174f07eea513a931dedaea5cc292ff88204"
    var OAuthTokenCompletionHandler:((Error?) -> Void)?
    var isLoadingOAuthToken: Bool = false
    var OAuthToken: String?
    
    func fetchGists(_ urlRequest: URLRequestConvertible, completionHandler: @escaping (Result<[Gist]>, String?) -> Void) {
        Alamofire.request(urlRequest)
            .responseJSON { (response) in
                if let urlResponse = response.response, let authError = self.checkUnauthorized(urlResponse: urlResponse) {
                    completionHandler(.failure(authError), nil)
                    return
                }
                let result = self.gistArrayFromResponse(response: response)
                let next = self.parseNextPageFromHeaders(response: response.response)
                completionHandler(result, next)
        }
    }
    
    func fetchMyGists(pageToLoad: String?, completionHandler: @escaping (Result<[Gist]>, String?) -> Void) {
        if let urlString = pageToLoad {
            fetchGists(GistRouter.getAtPath(urlString), completionHandler: completionHandler)
        } else {
            fetchGists(GistRouter.getMine(), completionHandler: completionHandler)
        }
    }
    
    func fetchPublicGists(pageToLoad: String?, completionHandler: @escaping (Result<[Gist]>, String?) -> Void) {
        if let urlString = pageToLoad {
            fetchGists(GistRouter.getAtPath2(urlString), completionHandler: completionHandler)
        } else {
            fetchGists(GistRouter.getPublic(), completionHandler: completionHandler)
        }
    }
    
    private func gistArrayFromResponse(response: DataResponse<Any>) -> Result<[Gist]> {
        
        guard response.result.error == nil else {
            print(response.result.error!)
            return .failure(GithubManagerError.network(error: response.result.error!))
        }
        
        guard let jsonArray = response.result.value as? [[String:Any]] else {
            print("Didnt get array of gists object as JSON from API")
            return .failure(GithubManagerError.objectSerialization(reason: "Did not get JSON dict in response"))
        }
        
        // check for "message" errors in the JSON because this API does that
        if let jsonDictionary = response.result.value as? [String: Any],
            let errorMessage = jsonDictionary["message"] as? String {
            return .failure(GithubManagerError.apiProvidedError(reason: errorMessage))
        }
        
        var gists = [Gist]()
        for item in jsonArray {
            if let gist = Gist(json: item) {
                gists.append(gist)
            }
        }
        return .success(gists)
    }
    
    // MARK - Pagination
    private func parseNextPageFromHeaders(response: HTTPURLResponse?) -> String? {
        
        //Fetch all the link headers from response
        guard let linkHeader = response?.allHeaderFields["Link"] as? String else {
            return nil
        }
        
        //Split by ','
        let components = linkHeader.split { $0 == "," }.map { String($0) }
        
        //Check for rel=next in an item
        for item in components {
            let rangeOfNext = item.range(of: "rel=\"next\"", options: [])
            guard rangeOfNext != nil else {
                continue
            }
            
            //Found component having next url, use regex to fetch the url
            let rangeOfPaddedURL = item.range(of: "<(.*)>;", options: .regularExpression, range: nil, locale: nil)
            
            guard let range = rangeOfPaddedURL else {
                return nil
            }

            let nextURL = String(item[range])

            let start = nextURL.index(range.lowerBound, offsetBy: 1)
            let end = nextURL.index(range.upperBound, offsetBy: -2)
            let trimmedRange = start ..< end
            let finalNextURL =  String(nextURL[trimmedRange])

            return finalNextURL
        }
        return nil
    }
    
    func createNewGist(description: String, isPublic: Bool, files: [File], completionHandler: @escaping (Result<Bool>) -> Void) {
        let publicString = isPublic ? "true" : "false"
        
        var filesDictionary = [String: Any]()
        for file in files {
            if let name = file.filename, let content = file.content {
                filesDictionary[name] = ["content": content]
            }
        }
        
        let parameters : [String: Any] = [
            "description": description,
            "isPublic": publicString,
            "files": filesDictionary
        ]
        
        Alamofire.request(GistRouter.create(parameters))
            .response { response in
                if let urlResponse = response.response,
                    let authError = self.checkUnauthorized(urlResponse: urlResponse) { completionHandler(.failure(authError))
                    return
                }
                
                guard response.error == nil else {
                    print(response.error!)
                    completionHandler(.failure(response.error!))
                    return
                }
                self.clearCache()
                completionHandler(.success(true))
        }
    }
    
    func clearCache() -> Void {
        let cache = URLCache.shared
        cache.removeAllCachedResponses()
    }
    
    func hasOAuthToken() -> Bool {
        if let token = self.OAuthToken {
            return !token.isEmpty
        }
        return false
    }
    
    func URLToStartOAuth2Login() -> URL? {
        let authPath: String = "https://github.com/login/oauth/authorize" + "?client_id=\(clientID)&scope=gist&state=TEST_STATE"
        return URL(string: authPath)
    }
    
    func processOAuthStep1Response(_ url: URL) {
        guard let code = extractCodeFromOAuthStep1Response(url) else {
            self.isLoadingOAuthToken = false
            let error = GithubManagerError.authCouldNot(reason: "Could not obtain an OAuth Token - extracrCodeFromOAuthStep1Response")
            self.OAuthTokenCompletionHandler?(error)
            return
        }
        swapAuthCodeForToken(code: code)
    }
    
    func swapAuthCodeForToken(code: String) -> Void {
        
        let getTokenPath = "https://github.com/login/oauth/access_token"
        let tokenParams = ["client_id" : clientID, "client_secret": clientSecret, "code": code]
        let jsonHeader = ["Accept": "application/json"]
        
        Alamofire.request(getTokenPath, method: .post, parameters: tokenParams, encoding: URLEncoding.default, headers: jsonHeader)
            .responseJSON { (response) in
                
                guard response.result.error == nil else {
                    print(response.result.error!)
                    self.isLoadingOAuthToken = false
                    let errorMessage = response.result.error?.localizedDescription ?? "Could not obtain an OAuth token"
                    let error = GithubManagerError.authCouldNot(reason: errorMessage)
                    self.OAuthTokenCompletionHandler?(error)
                    return
                }
                guard let value = response.result.value else {
                    print("no string received in response when swapping oauth code for token")
                    self.isLoadingOAuthToken = false
                    let error = GithubManagerError.authCouldNot(reason:
                        "Could not obtain an OAuth token")
                    self.OAuthTokenCompletionHandler?(error)
                    return
                }
                guard let jsonResult = value as? [String: String] else {
                    print("no data received or data not JSON")
                    self.isLoadingOAuthToken = false
                    let error = GithubManagerError.authCouldNot(reason:
                        "Could not obtain an OAuth token")
                    self.OAuthTokenCompletionHandler?(error)
                    return
                }
                
                //fetch OAuth token string from the response returned by POST call with accessToken/code
                self.OAuthToken = self.parseOAuthTokenResponse(jsonResult)
                
                self.isLoadingOAuthToken = false
                
                if(self.hasOAuthToken()) {
                    self.OAuthTokenCompletionHandler?(nil)
                } else {
                    let error = GithubManagerError.authCouldNot(reason: "Could Not obtain Auth Token - end - processOAuthStep1Response")
                    self.OAuthTokenCompletionHandler?(error)
                }                
        }
    }
    
    // MARK - Parse the OAuth token and fetch it
    func parseOAuthTokenResponse(_ json: [String: String]) -> String? {
        
        var token : String?
        for (key, value) in json {
            switch key {
            case "access_token":
                token = value
            case "scope":
                print("SET SCOPE")
            case "token_type":
                print("Check if Bearer")
            default:
                print("got more than I expected from the OAuth token exchange")
                print(key)
            }
        }
        return token
    }
    
    func extractCodeFromOAuthStep1Response(_ url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var code: String?
        
        guard let queryItems = components?.queryItems else {
            return nil
        }
        
        for queryItem in queryItems {
            if (queryItem.name.lowercased() == "code") {
                code = queryItem.value
                break
            }
        }
        return code
    }
    
    func checkUnauthorized(urlResponse: HTTPURLResponse) -> Error? {
        if(urlResponse.statusCode == 401) {
            self.OAuthToken = nil
            return GithubManagerError.authLost(reason: "Not Logged in")
        }
        return nil
    }
}
