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
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKLoginKit
import FacebookShare
import EasyToast

class DetailTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var arrowImage: UIImageView!
    
    
}

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
}

protocol DetailViewControllerDelegate: class {
    func addFavorite(symbol:String, price:Double, change:Double, changePercent:Double)
    func removeFavorite(symbol: String, price:Double, change:Double, changePercent:Double)
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, XMLParserDelegate {
    weak var delegate: DetailViewControllerDelegate?
    
    var symbol:String?
    var price:Double?
    var change:Double?
    var changePercent:Double?
    var isFavorite:Bool = false

    var detailLabels: [String] = []
    var detailData: [String: String?] = [:]
    var pickerData: [String] = [String]()
    
    // News Feed
    var parser = XMLParser()
    var posts: [[String:String]] = []
    var elements: [String: String] = [:]
    var element: String?
    var newsTitle: String?
    var newsDate: String?
    var newsAuthor: String?
    var newsLink: String?
    
    var historicalIsLoaded: Bool?
    var hasErrorHistorical: Bool?
    var hasErrorNews: Bool?

    var currentIndicator: String?
    var chartOptions: Any?
    let backendURL = "https://stock-search-185322.appspot.com/"
    
    
    @IBAction func facebookPressed(_ sender: Any) {
        var exportURL = "https://export.highcharts.com/"
        
        let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = NSURL(string: "https://export.highcharts.com/charts/chart.4d00902956ff47e3867b49aa637b0b6c.png")! as URL

        let dialog : FBSDKShareDialog = FBSDKShareDialog()
        dialog.fromViewController = self
        dialog.shareContent = content
        dialog.mode = FBSDKShareDialogMode.web
        dialog.show()

    }
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var detailTableView: UITableView!
    
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var historicalActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var newsTableView: UITableView!
    @IBOutlet weak var historicalWebView: WKWebView!
    @IBOutlet weak var currentView: UIScrollView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
            case 0:
                currentView.isHidden = false
                historicalWebView.isHidden = true
                newsTableView.isHidden = true
                historicalActivityIndicator.isHidden = true

            case 1:
                currentView.isHidden = true
                historicalWebView.isHidden = false
                newsTableView.isHidden = true
                if (!historicalIsLoaded!) {
                    historicalActivityIndicator.isHidden = false
                }
                if (hasErrorHistorical!) {
                    print("failed to load historical")
                }

            case 2:
                currentView.isHidden = true
                historicalWebView.isHidden = true
                newsTableView.isHidden = false
                historicalActivityIndicator.isHidden = true

            default:
                break;
        }
    }
    @IBOutlet weak var changeButton: UIButton!
    
    @IBAction func changePressed(_ sender: Any) {
        changeButton.isEnabled = false
        self.webView.isHidden = true
        self.indicatorActivityIndicator.isHidden = false
        let index = picker.selectedRow(inComponent: 0)
        let indicator = pickerData[index]
        currentIndicator = indicator
        if (indicator == "Price"){
            loadInitCharts()
        } else {
            Alamofire.request(backendURL + "indicator/" + indicator + "/" + self.symbol!).responseSwiftyJSON { dataResponse in
                let json = dataResponse.result.value //A JSON object
                let isSuccess = dataResponse.result.isSuccess
                if (isSuccess && (json != nil)) {
                    
                    do {
                        let jsonData = try json!.rawData()
                        let jsonEncodedData = jsonData.base64EncodedString() // base64 eencode the data dictionary
                        let javascript = "makeIndicatorChart('\(jsonEncodedData)')"     // set funcName parameter as a single quoted string
                        self.webView.evaluateJavaScript(javascript, completionHandler: { (result, error) in
                            if error != nil {
                                print(error!)
                            } else {
                                self.webView.isHidden = false
                                self.indicatorActivityIndicator.isHidden = true
                                print("no error")
                            }
                        })
                    } catch {
                        print("caught exception")
                    }
                }
            }

        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        currentView.contentSize = CGSize(width: self.view.frame.size.width, height: 800)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // only show currentview on load
        currentView.delegate = self
        currentView.isHidden = false
        historicalWebView.isHidden = true
        newsTableView.isHidden = true
        historicalIsLoaded = false
        changeButton.isEnabled = false
        historicalActivityIndicator.isHidden = true
        indicatorActivityIndicator.startAnimating()
        historicalActivityIndicator.startAnimating()
        hasErrorHistorical = false
        currentIndicator = "Price"
        
        
        SwiftSpinner.show("Loading Data")
        title = symbol
        
        // Favorite
        if (isFavorite) {
            favoriteButton.setImage(UIImage(named:"filled"),for:.normal)
        } else {
            favoriteButton.setImage(UIImage(named:"empty"),for:.normal)
        }
        
        facebookButton.setImage(UIImage(named:"facebook"),for:.normal)

        // Detail Table
        detailLabels = ["Stock Symbol", "Last Price", "Change", "Timestamp", "Open", "Close", "Day's Range", "Volume"]
        detailData = ["Stock Symbol":"", "Last Price":"", "Change":"", "Timestamp":"", "Open":"", "Close":"", "Day's Range":"", "Volume":""]
        
        // Picker
        pickerData = ["Price", "SMA", "EMA", "STOCH", "RSI", "ADX", "CCI", "BBANDS", "MACD"]
        
        //Webview

        getStockDetail()
        loadInitCharts()

        // News Feed
        
        getNewsFeed()
        
        
        // charts
        var htmlFile = Bundle.main.path(forResource: "index", ofType: "html")
        var html = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        webView.loadHTMLString(html!, baseURL: nil)
        
        
        htmlFile = Bundle.main.path(forResource: "historicalIndex", ofType: "html")
        html = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        historicalWebView.loadHTMLString(html!, baseURL: nil)

        
    }
    func loadInitCharts() {
        Alamofire.request(backendURL + "Price/"+self.symbol!).responseSwiftyJSON { dataResponse in
            let json = dataResponse.result.value //A JSON object
            let isSuccess = dataResponse.result.isSuccess
            if (isSuccess && (json != nil)) {
                
                var dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YYYY-MM-DD"

                var dates = json!["Time Series (Daily)"].dictionaryValue.keys.sorted(by: >)[0..<112].map{String($0)}
                
                let prices = dates.map{json!["Time Series (Daily)"][$0]["4. close"].doubleValue}
                let volumes = dates.map{json!["Time Series (Daily)"][$0]["5. volume"].doubleValue}
                dates = dates.map{
                    var monthDay = $0.components(separatedBy: ("-"))
                    return monthDay[1] + "/" + monthDay[2]
                }
                var transferData = ["symbol":self.symbol!, "dates":dates, "prices":prices, "volumes":volumes] as [String : Any]
                
                do {
                    var jsonData = try JSONSerialization.data(withJSONObject: transferData, options: [])  // serialize the data dictionary
                    var jsonEncodedData = jsonData.base64EncodedString() // base64 eencode the data dictionary
                    var javascript = "makePriceChart('\(jsonEncodedData)')"     // set funcName parameter as a single quoted string
                    self.webView.evaluateJavaScript(javascript, completionHandler: { (result, error) in
                        if error != nil {
                            self.view.showToast("Failed to load data. Please try again later.", position: .bottom, popTime: 5, dismissOnTap: true)
                            self.indicatorActivityIndicator.isHidden = false

                        } else {
                            self.chartOptions = result
                            self.indicatorActivityIndicator.isHidden = true
                            self.webView.isHidden = false
                        }
                    })
                    
                    dateFormatter = DateFormatter()
                    dateFormatter.dateFormat="yyyy-MM-dd"
                    
                    var historicalDatesStrings: [String] = []
                    var historicalDates: [Int] = []
                    if json!["Time Series (Daily)"].dictionaryValue.keys.count >= 1000 {
                        historicalDatesStrings = json!["Time Series (Daily)"].dictionaryValue.keys.sorted(by: >)[0..<1000].map{String($0)}
                        historicalDates = json!["Time Series (Daily)"].dictionaryValue.keys.sorted(by: >)[0..<1000].map{Int(dateFormatter.date(from: $0)!.timeIntervalSince1970) * 1000}
                    } else {
                        historicalDatesStrings = json!["Time Series (Daily)"].dictionaryValue.keys.sorted(by: >).map{String($0)}
                        historicalDates = json!["Time Series (Daily)"].dictionaryValue.keys.sorted(by: >).map{Int(dateFormatter.date(from: $0)!.timeIntervalSince1970) * 1000}
                    }

                    let historicalPrices = historicalDatesStrings.map{json!["Time Series (Daily)"][$0]["4. close"].doubleValue}
                    transferData = ["symbol":self.symbol!, "historicalDates":historicalDates, "historicalPrices":historicalPrices] as [String : Any]
                    jsonData = try JSONSerialization.data(withJSONObject: transferData, options: [])  // serialize the data dictionary
                    jsonEncodedData = jsonData.base64EncodedString() // base64 eencode the data dictionary
                    javascript = "makeHistoricalChart('\(jsonEncodedData)')"
                    self.historicalWebView.evaluateJavaScript(javascript, completionHandler: { (result, error) in
                        if error != nil {
                            self.hasErrorHistorical = true

                        } else {
                            self.historicalIsLoaded = true;
                            self.historicalActivityIndicator.isHidden = true
                            self.hasErrorHistorical = false
                        }

                    })

                } catch {
                    print("caught exception")
                }

            }
        }
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
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]){
        element = elementName
        if (elementName as String) == "item"{
            elements = [:]
            newsTitle = ""
            newsDate = ""
            newsAuthor = ""
            newsLink = ""
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        
        if newsTitle != nil && newsDate != nil && newsAuthor != nil && newsLink != nil && !string.contains("\n"){
            if element == "title" {
                newsTitle! = string
            } else if element == "pubDate" {
                newsDate! = string
            } else if element == "sa:author_name" {
                newsAuthor! = string
            } else if element == "link" {
                newsLink! = string
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?){
        element = elementName
        if ((elementName as String) == "item") {
            if newsTitle != nil {
                elements["title"] = newsTitle
            }
            if newsDate != nil {
                elements["date"] = newsDate
            }
            if newsAuthor != nil {
                elements["author"] = newsAuthor
            }
            if newsLink != nil {
                elements["link"] = newsLink
            }
            posts.append(elements)
        }
    }
    func getNewsFeed() {
        var parser = XMLParser()
        parser = XMLParser(contentsOf:(URL(string:backendURL + "news/" + symbol!))!)!
        parser.delegate = self
        parser.parse()
        
        if posts.count >= 5 {
            posts = Array(posts[0..<5])
            newsTableView.reloadData()
        } else {
            print("failed to load historical chart.")
        }
    }

    func getStockDetail() {
        Alamofire.request(backendURL + "Price/"+self.symbol!).responseSwiftyJSON { dataResponse in
            let json = dataResponse.result.value //A JSON object
            let isSuccess = dataResponse.result.isSuccess

            if (isSuccess && (json != nil) && json!.dictionaryValue.count > 0) {
                // get Stock    Symbol,    Last    Price,    Change,    Timestamp,    Open,    Close,    Day’s    Range,    Volume.
                let dates = json!["Time Series (Daily)"].dictionary?.keys.sorted(by: >)[0..<112].map{String($0)}

                self.detailData["Stock Symbol"] = json!["Meta Data"]["2. Symbol"].string
                let currentDate = dates![0]
                self.detailData["Timestamp"] = currentDate
                
                self.price = json!["Time Series (Daily)"][currentDate]["4. close"].doubleValue
                self.detailData["Last Price"] = String(format: "%.2f", self.price!)
                
                self.detailData["Open"] = String(format: "%.2f",json!["Time Series (Daily)"][currentDate]["1. open"].doubleValue)
                let high = json!["Time Series (Daily)"][currentDate]["2. high"].doubleValue
                let low = json!["Time Series (Daily)"][currentDate]["3. low"].doubleValue
                self.detailData["Day's Range"] = String(format: "%.2f",(high - low))
                self.detailData["Volume"] = json!["Time Series (Daily)"][currentDate]["5. volume"].stringValue
                
                // Favorite Data
                let prevDate = dates![1]
                
                self.change = json!["Time Series (Daily)"][currentDate]["4. close"].doubleValue - json!["Time Series (Daily)"][prevDate]["4. close"].doubleValue
                self.changePercent = (self.change! / json!["Time Series (Daily)"][prevDate]["4. close"].doubleValue) * 100
                
                self.detailData["Change"] = String(format: "%.2f", self.change!) + " (" + String(format: "%.2f", self.changePercent!) + ")%"
                
                self.detailTableView.reloadData()
                SwiftSpinner.hide()
            } else {
                SwiftSpinner.hide()
                self.indicatorActivityIndicator.isHidden = true
                self.view.showToast("Failed to load data. Please try again later.", position: .bottom, popTime: 5, dismissOnTap: true)
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == detailTableView {
            return detailLabels.count
        } else {
            return posts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == detailTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath as IndexPath) as! DetailTableViewCell
            
            // Fetch Fruit
            let title = detailLabels[indexPath.row]
            
            // Configure Cell
            cell.titleLabel?.text = title
            cell.detailLabel?.text = detailData[title]!
            if title == "Change" {
                if self.change != nil && self.change! < 0 {
                    cell.arrowImage.image = UIImage(named:"Red_Arrow_Down")
                } else if self.change != nil && self.change! > 0 {
                    cell.arrowImage.image = UIImage(named:"Green_Arrow_Up")
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath as IndexPath) as! NewsTableViewCell

            // Fetch Fruit
            let post = posts[indexPath.row]
            // Configure Cell
            cell.titleLabel?.text = post["title"]
            cell.authorLabel?.text = "Author: " + post["author"]!
            cell.dateLabel?.text = "Date: " + post["date"]!

            return cell

        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if tableView == newsTableView {
            return 120
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == newsTableView {
            let post = posts[indexPath.row]
            print(post["link"]!)
            if let url = URL(string: post["link"]!) {
                UIApplication.shared.open(url, options: [:])
            }
        }
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (currentIndicator != pickerData[row]) {
            changeButton.isEnabled = true
        } else {
            changeButton.isEnabled = false
        }
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
