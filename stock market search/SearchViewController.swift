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

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DetailViewControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    var sortPickerData: [String] = []
    var orderPickerData: [String] = []
    var sortState:String?
    var orderState:String?
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var stockSearchTextField: SearchTextField!
    var favoritesDefault = [(symbol: String, price: Double, change:Double, changePercent:Double)]()
    var favoritesSorted = [(symbol: String, price: Double, change:Double, changePercent:Double)]()
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
        
        // sort favorites
        sortFavoritesTable()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // init the favorites
        self.sortPickerData = ["Default", "Symbol", "Price", "Change", "Change(%)"]
        self.orderPickerData = ["Ascending", "Descending"]
        self.sortState = "Default"
        self.orderState = "Ascending"
        refreshButton.setImage(UIImage(named:"refresh"),for:.normal)

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
            if favoritesDefault.contains(where: {$0.0 == vc.symbol}) {
                vc.isFavorite = true
            } else {
                vc.isFavorite = false
            }
            vc.delegate = self
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return sortPickerData.count
        } else {
            return orderPickerData.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return sortPickerData[row]
        } else {
            return orderPickerData[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            // sorting
            sortState = sortPickerData[pickerView.selectedRow(inComponent: component)]
        } else {
            orderState = orderPickerData[pickerView.selectedRow(inComponent: component)]
        }
        sortFavoritesTable()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoritesDefault.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath as IndexPath) as! TableViewCell
        
        // Fetch Fruit
        let favorite = favoritesSorted[indexPath.row]
        // Configure Cell
        cell.symbolLabel.text = favorite.symbol
        cell.priceLabel.text = "$" + String(favorite.price)
        cell.changeLabel.text = String(format: "%.2f", favorite.change) + " (" + String(format: "%.2f", favorite.change) + "%)"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath as IndexPath) as! TableViewCell
        let favorite = favoritesSorted[indexPath.row]

        performSegue(withIdentifier: "showDetailSegue", sender: favorite.symbol)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleted")
            self.favoritesSorted.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func addFavorite(symbol: String, price:Double, change:Double, changePercent:Double) {
        favoritesDefault.append((symbol:symbol, price:price, change:change, changePercent:changePercent))
    }
    func removeFavorite(symbol: String, price:Double, change:Double, changePercent:Double) {
        favoritesDefault = favoritesDefault.filter{$0.symbol != symbol}
    }
    
    func sortFavoritesTable() {
        if sortState == "Default" {
            favoritesSorted = favoritesDefault
        } else if sortState == "Symbol" {
            if orderState == "Ascending" {
                favoritesSorted = favoritesDefault.sorted(by: {$0.symbol <= $1.symbol})
            } else {
                favoritesSorted = favoritesDefault.sorted(by: {$0.symbol > $1.symbol})
            }
        } else if sortState == "Price" {
            if orderState == "Ascending" {
                favoritesSorted = favoritesDefault.sorted(by: {$0.price <= $1.price})
            } else {
                favoritesSorted = favoritesDefault.sorted(by: {$0.price > $1.price})
            }
        } else if sortState == "Change" {
            if orderState == "Ascending" {
                favoritesSorted = favoritesDefault.sorted(by: {$0.change <= $1.change})
            } else {
                favoritesSorted = favoritesDefault.sorted(by: {$0.change > $1.change})
            }
        } else if sortState == "Change(%)" {
            if orderState == "Ascending" {
                favoritesSorted = favoritesDefault.sorted(by: {$0.changePercent <= $1.changePercent})
            } else {
                favoritesSorted = favoritesDefault.sorted(by: {$0.changePercent > $1.changePercent})
            }
        }
        self.tableView.reloadData()
    }
}
