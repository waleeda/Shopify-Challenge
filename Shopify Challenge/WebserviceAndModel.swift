//
//  Webservice.swift
//  Shopify Challenge
//
//  Created by waleed azhar on 2017-04-25.
//  Copyright © 2017 waleed azhar. All rights reserved.
//

import Foundation

typealias JSONDictionary = [String: AnyObject]
typealias JSONArray = [JSONDictionary]


let url = NSURL(string:"https://shopicruit.myshopify.com/admin/orders.json?page=1&access_token=c32313df0d0ef512ca64d5b336a0d7c6")!

extension NSMutableURLRequest {
    convenience init<A>(resource: Resource<A>) {
        self.init(url: resource.url as URL)
        self.httpMethod = resource.method.method
        if case let .post(data) = resource.method {
            setValue("application/json", forHTTPHeaderField: "Content-Type")
            httpBody = data as Data
        }
    }
}

final class Webservice {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        let request = NSMutableURLRequest(resource: resource)
        URLSession.shared.dataTask(with: request as URLRequest) { (data, _, _) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(resource.parse(data as NSData))
            }.resume()
    }
}

enum HttpMethod<Body> {
    
    case get
    
    case post(Body)
    
}

extension HttpMethod {
    
    var method: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }
    
    func map<B>(f: (Body) -> B) -> HttpMethod<B> {
        switch self {
        case .get: return .get
        case .post(let body):
            return .post(f(body))
        }
        
    }
}
// represents a resource to be got from the server
struct Resource<A> {
    let url: NSURL
    let method: HttpMethod<Data>
    //turns data returned from server in to swift object of type A
    let parse: (NSData) -> A?
}

extension Resource {
    init(url: NSURL, method: HttpMethod<AnyObject> = .get, parseJSON: @escaping (AnyObject) -> A?) {
        
        self.url = url
        
        self.method = method.map { json in
            try! JSONSerialization.data(withJSONObject:json, options: [])
        }
        
        self.parse = { data in
            let json = try? JSONSerialization.jsonObject(with: data as Data, options: []) as AnyObject
            return json.flatMap(parseJSON)
        }
    }
}

struct LineItem{
    let fulfillable_quantity:Int
    let quantity:Int
    let title:String
}

extension LineItem{
    init?(dictionary:JSONDictionary){
        guard let f = dictionary["fulfillable_quantity"] as? Int else {return nil}
        guard let q = dictionary["quantity"] as? Int else { return nil}
        guard let t = dictionary["title"] as? String else { return nil}
        
        self.fulfillable_quantity = f
        self.quantity = q
        self.title = t
    }
}

struct  Order {
    let id:Int
    let total_price: Double
    let total_price_usd:Double
    let line_items:[LineItem]
}

extension Order{
    func fulfillableQuantityOfOrderFor(item:String) -> Int{
        return line_items.reduce(0){a,b in
                if b.title != item {return a}
                return a + b.fulfillable_quantity
            }
    }
    
    func quantityOfOrderFor(item:String) -> Int{
        return line_items.reduce(0){a,b in
            if b.title != item {return a}
            return a + b.quantity
        }
    }
}

extension Order{
    init?(dictionary:JSONDictionary){
        
        guard let i = dictionary["id"] as? Int else {print("a");return nil}
        guard let p = dictionary["total_price"] as? String else {print("b"); return nil}
        guard let pUsa = dictionary["total_price_usd"] as? String else {print("c"); return nil}
        guard let lI = dictionary["line_items"] as? NSArray else {print("d");return nil}
        
        self.id = i
        self.total_price_usd = Double(pUsa)!
        self.total_price = Double(p)!
        
        var temp:[LineItem] = []
        for item in lI {
            temp.append(LineItem(dictionary:item as! JSONDictionary)!)
        }
        self.line_items = temp
    }
}
struct Orders {
    let orders: [Order?]
}

extension Orders{
    init?(dictionary: JSONDictionary) {
      
        guard let or = dictionary["orders"]! as? NSArray else {print("dfdf");return nil}
        
        var temp:[Order?] = []
        
        for o in or {
           temp.append(Order(dictionary: o as! JSONDictionary))
        }
        self.orders = temp
    }
}

extension Orders{
    var total_revenue: Double {
        return orders.reduce(0){a,b in return a + b!.total_price_usd}
    }
    
    func fulfillableQuantityOfOrderFor(item:String) -> Int{
        var result:Int = 0
        for o in orders {
            result = result + o!.fulfillableQuantityOfOrderFor(item: item)
        }
        return result
    }
    func quantityOfOrderFor(item:String) -> Int{
        var result:Int = 0
        for o in orders {
            result = result + o!.quantityOfOrderFor(item: item)
        }
        return result
    }
}





