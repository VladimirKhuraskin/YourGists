//
//  MasterViewController.swift
//  YourGists
//
//  Created by Vladimir Khuraskin on 14.07.2018.
//  Copyright © 2018 Vladimir Khuraskin. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire

class GistsViewController: UITableViewController, LoginViewDelegate, SFSafariViewControllerDelegate {
    
    var gists = [Gist]()
    var nextPageURLString: String?
    var isLoading: Bool = false
    var dateFormatter = DateFormatter()
    var safariViewController: SFSafariViewController?
    
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
        if(!GithubManager.sharedInstance.isLoadingOAuthToken) {
            loadInitialData()
        }
    }
    
    func loadInitialData() -> Void {
        isLoading = true
        GithubManager.sharedInstance.OAuthTokenCompletionHandler = { error in
            guard error == nil else {
                print(error!)
                self.isLoading = false
                self.showOAuthLoginview()
                return
            }
            if let _ = self.safariViewController {
                self.dismiss(animated: true, completion: nil)
            }
            self.loadGists(urlToLoad: nil)
        }
        
        if(!GithubManager.sharedInstance.hasOAuthToken()) {
            showOAuthLoginview()
            return
        }
        loadGists(urlToLoad: nil)
    }
    
    func showOAuthLoginview() {
        GithubManager.sharedInstance.isLoadingOAuthToken = true
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let loginVC = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {
            assert(false, "Misnamed view controller")
            return
        }
        loginVC.delegate = self
        self.present(loginVC, animated: true, completion: nil)
    }
    
    func loadGists(urlToLoad: String?) -> Void {
        self.isLoading = true
        
        let completionHandler: (Result<[Gist]>, String?) -> Void = {
            (result, nextPage) in
            self.isLoading = false
            self.nextPageURLString = nextPage
            
            //update last-updated date format
            let now = Date()
            let updatedString = "Last Updated at " + self.dateFormatter.string(from: now)
            self.refreshControl?.attributedTitle = NSAttributedString(string: updatedString)
            
            // tell refresh control it can stop showing up now
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
        GithubManager.sharedInstance.fetchMyGists(pageToLoad: urlToLoad, completionHandler: completionHandler)
    }
    
    @objc func refresh(sender: Any) {
        GithubManager.sharedInstance.isLoadingOAuthToken = false
        nextPageURLString = nil                             //so it doesnt try to append the results
        GithubManager.sharedInstance.clearCache()
        loadInitialData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            self.showOAuthLoginview()
            return
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let gist = gists[indexPath.row]
                if let dvc = segue.destination as? DetailViewController {
                    dvc.gist = gist
                    dvc.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }
    
    func didTapLoginButton() {
        self.dismiss(animated: false) {
            guard let authURL = GithubManager.sharedInstance.URLToStartOAuth2Login() else {
                let error = GithubManagerError.authCouldNot(reason: "Could not obtain an OAuth Token")
                GithubManager.sharedInstance.OAuthTokenCompletionHandler?(error)
                return
            }
            //SFSafari VC calls the handleURL in AppDelegate to start the OAuth Token fetch Process
            self.safariViewController = SFSafariViewController(url: authURL)
            self.safariViewController?.delegate = self
            guard let webViewController = self.safariViewController else {
                return
            }
            self.present(webViewController, animated: true, completion: nil)        }
    }
    
    @IBAction func close(segue: UIStoryboardSegue) {
        guard segue.identifier == "unwindSegueFromNewGist" else { return }
        guard let _ = segue.source as? NewGistViewController else { return }
    }
    
    @IBAction func signOutTapped(_ sender: UIBarButtonItem) {
        gists = []
        self.tableView.reloadData()
        self.showOAuthLoginview()
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if(!didLoadSuccessfully) {
            controller.dismiss(animated: true, completion: nil)
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
        //Check to see if we need to Load more gists
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
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
