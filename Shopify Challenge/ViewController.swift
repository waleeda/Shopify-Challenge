//
//  ViewController.swift
//  Shopify Challenge
//
//  Created by waleed azhar on 2017-04-25.
//  Copyright © 2017 waleed azhar. All rights reserved.
//

import UIKit

let kb = "Aerodynamic Cotton Keyboard"

class ViewController: UIViewController {
    var orders: Orders!
    
    @IBOutlet weak var revenue: UILabel!
    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var fulfillable: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from  a nib.
        let orderR = Resource<Orders>(url: url){ json in return Orders(dictionary:json as! JSONDictionary)}
        Webservice().load(resource: orderR) { (final) in
            DispatchQueue.main.async {
                self.orders = final
                 self.updateLabels()
            }
           
           
        }

    }
    
    private func updateLabels(){
        if let o = self.orders {
            revenue.text = revenue.text! + " \(o.total_revenue)"
            
            quantity.text = quantity.text! + " \(o.quantityOfOrderFor(item: kb))"
            
            fulfillable.text = fulfillable.text! + " \(o.fulfillableQuantityOfOrderFor(item: kb))"
     
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

