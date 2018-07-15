//
//  PublicGistsViewController.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 15.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import UIKit
import Alamofire

class PublicGistsViewController: UITableViewController {
    
    var username: String!
    var gists = [Gist]()
    var nextPageURLString: String?
    var isLoading: Bool = false
    var dateFormatter = DateFormatter()
    
    override func viewWillAppear(_ animated: Bool) {
        if(self.refreshControl == nil) {
            self.refreshControl = UIRefreshControl()
            self.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
            self.dateFormatter.dateStyle = .short
            self.dateFormatter.timeStyle = .short
        }
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func loadGists(urlToLoad: String?) -> Void {
        self.isLoading = true
        
        let completionHandler: (Result<[Gist]>, String?) -> Void = {
            (result, nextPage) in
            self.isLoading = false
            self.nextPageURLString = nextPage
            
            let now = Date()
            let updatedString = "Last Updated at " + self.dateFormatter.string(from: now)
            self.refreshControl?.attributedTitle = NSAttributedString(string: updatedString)
            
            if self.refreshControl != nil, self.refreshControl!.isRefreshing {
                self.refreshControl?.endRefreshing()
            }
            
            guard result.error == nil else {
                self.handleLoadGistsError(result.error!)
                return
            }
            
            guard let fetchedGists = result.value else {
                print("no gists fetched")
                return
            }
            
            if urlToLoad == nil {
                self.gists = []
            }
            
            self.gists += fetchedGists
            
            self.tableView.reloadData()
        }
        GithubManager.sharedInstance.fetchPublicGists(pageToLoad: urlToLoad, completionHandler: completionHandler)
    }
    
    @objc func refresh(sender: Any) {
        GithubManager.sharedInstance.isLoadingOAuthToken = false
        nextPageURLString = nil
        GithubManager.sharedInstance.clearCache()
        gists = []
        loadGists(urlToLoad: "users/\(username!)/gists")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadGists(urlToLoad: "users/\(username!)/gists")
        title = username + "/gists"
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
    }
    
    func handleLoadGistsError(_ error: Error) {
        print(error)
        nextPageURLString = nil
        
        self.isLoading = false
        switch error {
        case GithubManagerError.authLost:
            return
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail2" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let gist = gists[indexPath.row]
                if let dvc = segue.destination as? DetailViewController {
                    dvc.gist = gist
                    dvc.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! GistCell
        cell.backgroundColor = .clear
        let gist = gists[indexPath.row]
        if !isLoading {
            let rowsLoaded = gists.count
            let rowsRemaining = rowsLoaded - indexPath.row
            let rowsToLoadFromBottom = 5
            
            if rowsRemaining <= rowsToLoadFromBottom {
                if let nextPage = nextPageURLString {
                    self.loadGists(urlToLoad: nextPage)
                }
            }
        }
        cell.configure(with: gist)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
