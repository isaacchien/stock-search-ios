//
//  SearchViewController.swift
//  stock market search
//
//  Created by Isaac Chien on 11/14/17.
//  Copyright © 2017 Isaac Chien. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SearchTextField
import EasyToast

class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    
}

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DetailViewControllerDelegate {

    
    @IBOutlet weak var stockSearchTextField: SearchTextField!
    var favorites = [(symbol: String, price: Double, change:Double, changePercent:Double)]()
    @IBOutlet weak var tableView: UITableView!

    @IBAction func getQuoteButton(_ sender: Any) {
        let query = stockSearchTextField.text?.components(separatedBy: " - ")[0]
        
        if query!.trimmingCharacters(in: .whitespaces).isEmpty {
            // string contains non-whitespace characters
            self.view.showToast("Please enter a stock name or symbol", position: .bottom, popTime: 5, dismissOnTap: true)
            
        } else {
            performSegue(withIdentifier: "showDetailSegue", sender: query!.uppercased())
        }
    }
    @IBAction func clearButton(_ sender: Any) {
        stockSearchTextField.text = ""
    }
    @IBAction func stockSearchEditedChanged(_ sender: Any) {
        let query = stockSearchTextField.text
        let parameters: Parameters = ["query": query!]
        Alamofire.request("https://stock-search-185322.appspot.com/search/", parameters: parameters).responseSwiftyJSON { dataResponse in
            let json = dataResponse.result.value //A JSON object
            let isSuccess = dataResponse.result.isSuccess
            if (isSuccess && (json != nil)) {
                var searchResults = [String]()
                for (key, subJson) in json! {
                    var searchResult = ""
                    if let symbol = subJson["Symbol"].string {
                        searchResult += symbol + " - "
                    }
                    if let name = subJson["Name"].string {
                        searchResult += name + " "
                    }
                    if let exchange = subJson["Exchange"].string {
                        searchResult += "(" + exchange + ")"
                    }
                    searchResults.append(searchResult)
                    if key == "4" {
                        break;
                    }
                }
                self.stockSearchTextField.filterStrings(searchResults)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // init the favorites
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let vc = segue.destination as? DetailViewController {
            vc.symbol = sender as? String
            print("segue: " + vc.symbol!)
            if favorites.contains(where: {$0.0 == vc.symbol}) {
                vc.isFavorite = true
            } else {
                vc.isFavorite = false
            }
            vc.delegate = self
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath as IndexPath) as! TableViewCell
        
        // Fetch Fruit
        let favorite = favorites[indexPath.row]
        // Configure Cell
        cell.symbolLabel.text = favorite.symbol
        cell.priceLabel.text = "$" + String(favorite.price)
        cell.changeLabel.text = String(format: "%.2f", favorite.change) + " (" + String(format: "%.2f", favorite.change) + "%)"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath as IndexPath) as! TableViewCell
        let favorite = favorites[indexPath.row]

        performSegue(withIdentifier: "showDetailSegue", sender: favorite.symbol)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleted")
            self.favorites.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func addFavorite(symbol: String, price:Double, change:Double, changePercent:Double) {
        favorites.append((symbol:symbol, price:price, change:change, changePercent:changePercent))
        self.tableView.reloadData()
    }
    func removeFavorite(symbol: String, price:Double, change:Double, changePercent:Double) {
        favorites = favorites.filter{$0.symbol != symbol}
        self.tableView.reloadData()
    }
}
