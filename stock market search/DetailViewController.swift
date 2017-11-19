//
//  DetailViewController.swift
//  stock market search
//
//  Created by Isaac Chien on 11/15/17.
//  Copyright © 2017 Isaac Chien. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireSwiftyJSON
import SwiftSpinner
import WebKit

protocol DetailViewControllerDelegate: class {
    
    func addFavorite(symbol:String, price:Double, change:Double, changePercent:Double)
    func removeFavorite(symbol: String, price:Double, change:Double, changePercent:Double)
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    weak var delegate: DetailViewControllerDelegate?
    
    var symbol:String?
    var price:Double?
    var change:Double?
    var changePercent:Double?
    
    var isFavorite:Bool = false

    var detailLabels: [String] = []
    var detailData: [String: String?] = [:]
    var pickerData: [String] = [String]()
    let cellIdentifier = "DetailCell"

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        SwiftSpinner.show("Loading Data")
        title = symbol
        
        // Favorite
        if (isFavorite) {
            favoriteButton.setImage(UIImage(named:"filled"),for:.normal)
        } else {
            favoriteButton.setImage(UIImage(named:"empty"),for:.normal)
        }
        
        // Detail Table
        detailLabels = ["Stock Symbol", "Last Price", "Change", "Timestamp", "Open", "Close", "Day's Range", "Volume"]
        detailData = ["Stock Symbol":"", "Last Price":"", "Change":"", "Timestamp":"", "Open":"", "Close":"", "Day's Range":"", "Volume":""]
        
        // Picker
        pickerData = ["Price", "SMA", "EMA", "STOCH", "RSI", "ADX", "CCI", "BBANDS", "MACD"]
        
        //Webview
        let myURL = URL(string: "https://www.apple.com")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        webView.scrollView.isScrollEnabled = false

        getStockDetail()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func favoritePressed(_ sender: Any) {
        if (isFavorite){
            favoriteButton.setImage(UIImage(named:"empty"),for:.normal)
            delegate?.removeFavorite(symbol: symbol!, price: self.price!, change: self.change!, changePercent: self.changePercent!)
        } else {
            favoriteButton.setImage(UIImage(named:"filled"),for:.normal)
            delegate?.addFavorite(symbol: symbol!,  price: self.price!, change: self.change!, changePercent: self.changePercent!)
        }
    }
    
    
    func getStockDetail() {
        Alamofire.request("https://stock-search-185322.appspot.com/price/"+self.symbol!).responseSwiftyJSON { dataResponse in
            let json = dataResponse.result.value //A JSON object
            let isSuccess = dataResponse.result.isSuccess
            if (isSuccess && (json != nil)) {
                // get Stock    Symbol,    Last    Price,    Change,    Timestamp,    Open,    Close,    Day’s    Range,    Volume.
                self.detailData["Stock Symbol"] = json!["Meta Data"]["2. Symbol"].string
                let currentDate = json!["Meta Data"]["3. Last Refreshed"].string
                self.detailData["Timestamp"] = currentDate
                
                self.price = json!["Time Series (Daily)"][currentDate!]["4. close"].doubleValue
                self.detailData["Last Price"] = String(format: "%.2f", self.price!)
                
                self.detailData["Open"] = String(format: "%.2f",json!["Time Series (Daily)"][currentDate!]["1. open"].doubleValue)
                let high = json!["Time Series (Daily)"][currentDate!]["2. high"].doubleValue
                let low = json!["Time Series (Daily)"][currentDate!]["3. low"].doubleValue
                self.detailData["Day's Range"] = String(format: "%.2f",(high - low))
                self.detailData["Volume"] = json!["Time Series (Daily)"][currentDate!]["5. volume"].stringValue
                
                // Favorite Data
                var dates = json!["Time Series (Daily)"].dictionary?.keys.sorted(by: >)[0..<112]
                let prevDate = dates![1]
                
                self.change = json!["Time Series (Daily)"][currentDate!]["4. close"].doubleValue - json!["Time Series (Daily)"][prevDate]["4. close"].doubleValue
                self.changePercent = self.change! / json!["Time Series (Daily)"][prevDate]["4. close"].doubleValue
                
                
                self.tableView.reloadData()
                SwiftSpinner.hide()

            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detailLabels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath)
        
        // Fetch Fruit
        let title = detailLabels[indexPath.row]
        
        // Configure Cell
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detailData[title]!
        
        return cell
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
