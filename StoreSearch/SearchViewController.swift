//
//  ViewController.swift
//  StoreSearch
//
//  Created by Russ Rosaura on 8/11/21.
//  Copyright © 2021 Malysh Tim. All rights reserved.
//


import UIKit


class SearchViewController: UIViewController {
    
    // MARK: -- Outlets
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // MARK: -- Data Model
    private let search = Search()
    var landscapeVC: LandscapeViewController?
    
    struct TableView {
        struct ReuseIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customizeAppearance()
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        var cellNib = UINib(nibName: TableView.ReuseIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.ReuseIdentifiers.searchResultCell)
        cellNib = UINib(nibName: TableView.ReuseIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.ReuseIdentifiers.nothingFoundCell)
        cellNib = UINib(nibName: TableView.ReuseIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.ReuseIdentifiers.loadingCell)
        searchBar.becomeFirstResponder()
        let segmentControl = UIColor(red: 10/255, green: 80/255, blue: 80/255, alpha: 1)
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: segmentControl]
        
        segmentedControl.selectedSegmentTintColor = segmentControl
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .highlighted)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .compact:
            showLandscape(with: coordinator)
        case .regular, .unspecified:
            hideLandscape(with: coordinator)
        @unknown default:
            fatalError()
        }
    }

    
    // MARK: -- IBActions
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    
    // MARK: -- Helper Methods
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error accessing the iTunes Store." + " Please try again.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func customizeAppearance() {
        let barTintColor = UIColor(red: 20/255, green: 160/255,
                                  blue: 160/255, alpha: 1)
        searchBar.barTintColor = barTintColor
        searchBar.searchTextField.backgroundColor = .white
    }

    func performSearch() {
        if let category = Search.Category(rawValue: segmentedControl.selectedSegmentIndex) {
            search.performSearch(for: searchBar.text!, category: category, completion: { success in
                if !success {
                    self.showNetworkError()
                }
                self.tableView.reloadData()
            })
            tableView.reloadData()
            self.landscapeVC?.searchResultsReceived()
            searchBar.resignFirstResponder()
        }
    }
    
    // MARK: -- Landscape
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        guard landscapeVC == nil else { return }
        
        landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        
        if let controller = landscapeVC {
            controller.search = search
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            
            view.addSubview(controller.view)
            addChild(controller)
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }, completion: { _ in
                controller.didMove(toParent: self)
            })
        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeVC {
            controller.willMove(toParent: nil)
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 0
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }, completion: { _ in
                controller.view.removeFromSuperview()
                controller.removeFromParent()
                self.landscapeVC = nil
            })
        }
    }
    
    //MARK: -- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            if case .results(let list) = search.state {
                let detailViewController = segue.destination as! DetailViewController
                let indexPath = sender as! IndexPath
                let searchResult = list[indexPath.row]
                detailViewController.searchResult = searchResult
            }
        }
    }
}


// MARK: - SearchBar

extension SearchViewController: UISearchBarDelegate {

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
}


// MARK: - TableView

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch search.state {
        case .notSearchedYet: return 0
        case .loading: return 1
        case .noResults: return 1
        case .results(let list): return list.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch search.state {
        case .notSearchedYet:
            fatalError("Should never get here")
            
        case .loading:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.ReuseIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
            
        case .noResults:
            return tableView.dequeueReusableCell(withIdentifier: TableView.ReuseIdentifiers.nothingFoundCell, for: indexPath)
            
        case .results(let list):
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.ReuseIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            let searchResult = list[indexPath.row]
            cell.configure(for: searchResult)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch search.state {
        case .notSearchedYet, .loading, .noResults:
            return nil
        case .results:
            return indexPath
        }
    }
    
}



