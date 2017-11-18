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


class SearchViewController: UIViewController {    
    @IBOutlet weak var stockSearchTextField: SearchTextField!
    
    @IBAction func getQuoteButton(_ sender: Any) {
        let query = stockSearchTextField.text?.components(separatedBy: " - ")[0]
        
        if query!.trimmingCharacters(in: .whitespaces).isEmpty {
            // string contains non-whitespace characters
            self.view.showToast("Please enter a stock name or symbol", position: .bottom, popTime: 5, dismissOnTap: true)
            
        } else {
            performSegue(withIdentifier: "showDetailSegue", sender: query!)
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
        
        if segue.destination is DetailViewController {
            let vc = segue.destination as? DetailViewController
            vc?.symbol = sender as! String
        }
    }
    

}
