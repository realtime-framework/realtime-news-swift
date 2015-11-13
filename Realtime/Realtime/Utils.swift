//
//  Utils.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 23/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

class Utils: NSObject {
   
    
    class func setButton(bt:FUIButton){
        bt.buttonColor = UIColor.peterRiverColor()
        bt.shadowColor = UIColor.belizeHoleColor()
        bt.shadowHeight = 3.0
        bt.cornerRadius = 6.0
        bt.titleLabel?.font = UIFont.boldFlatFontOfSize(16)
        bt.setTitleColor(UIColor.cloudsColor(), forState: UIControlState.Normal)
        bt.setTitleColor(UIColor.cloudsColor(), forState: UIControlState.Highlighted)
    }
    
    class func setBlueButton(bt:UIButton){
        let image:UIImage = UIImage(named: "Button.png")!
        let insets:UIEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
        let stretchedImage:UIImage = image.resizableImageWithCapInsets(insets)
        bt.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        bt.setBackgroundImage(stretchedImage, forState: UIControlState.Normal)
    }
    
    class func setBlueBarButton(bt:UIButton){
        let image:UIImage = UIImage(named: "Button.png")!
        let insets:UIEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
        let stretchedImage:UIImage = image.resizableImageWithCapInsets(insets)
        bt.setImage(stretchedImage, forState: UIControlState.Normal)
    }

    class func jsonDictionaryFromString(text:String, onCompletion:(NSDictionary) -> Void, onError:(NSError) -> Void ){
        let jsonData:NSData = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        var json:NSDictionary?
        do{
            json = try NSJSONSerialization.JSONObjectWithData(jsonData, options:NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary
            onCompletion(json!)
        }catch{
             onError(NSError(domain: "json parsing error", code: -1, userInfo: nil))
        }
        
    }
    
    class func jsonStringFromDictionary(dict:NSDictionary, onCompletion:(NSString) -> Void, onError:(NSError) -> Void ){
        var jsonData:NSData
        do{
            jsonData = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
            onCompletion(NSString(data: jsonData, encoding: NSUTF8StringEncoding)!)
        }catch{
            onError(NSError(domain: "json parsing error", code: -1, userInfo: nil))
        }
    }

    class func convertTimeStamp(data:Double) -> String {
        let time:Double = data / 1000
        let sourceDate:NSDate = NSDate(timeIntervalSince1970: time)
        
        let dateFormater:NSDateFormatter = NSDateFormatter()
        dateFormater.locale = NSLocale.currentLocale()
        dateFormater.dateFormat = "dd/MM/yyyy HH:mm"
        
        return dateFormater.stringFromDate(sourceDate)
    }
    
    class func orderTopics(messages:NSMutableArray) -> NSMutableArray {
        let sortDescriptor:NSSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        let sortDescriptors:NSArray = NSArray(object: sortDescriptor)
        let sortedArray:NSMutableArray = NSMutableArray(array: messages.sortedArrayUsingDescriptors(sortDescriptors as! [NSSortDescriptor]))
        return sortedArray
    }
    
    class func orderMenu(messages:NSMutableArray) -> NSMutableArray {
        let sortDescriptor:NSSortDescriptor = NSSortDescriptor(key: "tag", ascending: true)
        let sortDescriptors:NSArray = NSArray(object: sortDescriptor)
        let sortedArray:NSMutableArray = NSMutableArray(array: messages.sortedArrayUsingDescriptors(sortDescriptors as! [NSSortDescriptor]))
        return sortedArray
    }
    
    class func goToLogin() {
        NSUserDefaults.standardUserDefaults().setObject("0", forKey: "logedIn")
        NSUserDefaults.standardUserDefaults().synchronize()
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc:UIViewController = storyboard.instantiateViewControllerWithIdentifier("root") as UIViewController!
        
        storage?.removeListeners()
        storage = nil
        let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window.rootViewController = vc
    }
    
    class func authenticateStorageTokenForUser(user: String, pass: String) -> NSData?  {
        let url:String = "https://storage-codehosting-stag-useast1.realtime.co/\(APP_KEY)/authenticate?"
        
        let urlString:NSMutableString = NSMutableString()
        
        urlString.appendFormat("user=%@&", user)
        urlString.appendFormat("password=%@&", pass)
        urlString.appendFormat("role=%@", "iOSApp")
        
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "\(url)\(urlString)")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        let data:NSData = urlString.dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        
        request.HTTPMethod = "POST"
        request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var resp:NSURLResponse?
        var resData:NSData?
        do{
            resData = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &resp)
        }catch{
        
        }
        
        return resData
    }
    
    class func authenticateMessagingToken() -> NSData?  {
        let url:String = "https://storage-codehosting-stag-useast1.realtime.co/\(APP_KEY)/saveAuthentication?"
        
        let urlString:NSMutableString = NSMutableString()
        

        urlString.appendFormat("token=%@", ortcToken!)
        
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "\(url)\(urlString)")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        let data:NSData = urlString.dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        
        request.HTTPMethod = "POST"
        request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var resp:NSURLResponse?

        var result:NSData?
        
        do{
            result = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &resp)
        }catch{
        
        }
        return result
    }

    class func firstMonthYear() -> NSData?  {
        let url:String = "https://storage-codehosting-stag-useast1.realtime.co/\(APP_KEY)/firstMonthYear"
        
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "\(url)")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        request.HTTPMethod = "GET"
        
        var resp:NSURLResponse?
        var result:NSData?
        
        do{
            result = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &resp)
        }catch{
            
        }
        
        return result
    }


    
    class func reAuth(callback:(result:Bool) -> Void, errorCallBack:() -> Void) {
        let storageRef:StorageRef = StorageRef(APP_KEY, privateKey: nil, authenticationToken: token);
        
        storageRef.isAuthenticated(token, success: { (success) -> Void in

            if (success == true)
            {
                callback(result: true)
                return
            }
            
            let user:String? = NSUserDefaults.standardUserDefaults().objectForKey("user") as? String
            let pass:String? = NSUserDefaults.standardUserDefaults().objectForKey("pass") as? String
            
            if (user == nil || pass == nil)
            {
                Utils.goToLogin()
            }
            
            let rsp:NSData? = Utils.authenticateStorageTokenForUser(user!, pass: pass!) as NSData?
            if rsp == nil
            {
                Utils.goToLogin()
                return
            }
            
            Utils.jsonDictionaryFromString(NSString(data: rsp!, encoding: NSUTF8StringEncoding)! as String, onCompletion:
            { (jsonDict) -> Void in
                let json:NSDictionary = jsonDict as NSDictionary
                if (json.objectForKey("token") != nil)
                {
                    token = json.objectForKey("token") as? String
                    NSUserDefaults.standardUserDefaults().setObject(token, forKey: "token")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    callback(result: false)
                }else
                {
                    Utils.goToLogin()
                }
            }, onError: { (error) -> Void in
                Utils.goToLogin()
            })
            
        }) { (error) -> Void in
            errorCallBack()
        }
    }
    
    class func performSearch(array:NSArray, name:NSString?, key:NSString) -> NSArray
    {
        let args:String = ".*\(name!).*"
        let query:NSString = NSString(format: "%@ MATCHES [c] \"%@\"", key, args)
        let predicate:NSPredicate? = NSPredicate(format: query as String)
        return array.filteredArrayUsingPredicate(predicate!)
    }

    class func GetUUID() -> String{
        return NSUUID().UUIDString
    }
    

    
    class func getCurrentMonthYear() -> String {
        let date:NSDate = NSDate()
        let formater:NSDateFormatter = NSDateFormatter()
        formater.dateFormat = "MM/yyyy"
        return formater.stringFromDate(date)
    }
    
    class func getPreviousMonth(month:String) -> String
    {
        let parts:NSArray = month.componentsSeparatedByString("/");
        var mm:Int = parts.objectAtIndex(0).integerValue
        var yy:Int = parts.objectAtIndex(1).integerValue
        
        if mm == 1
        {
            mm = 12
            yy--
            return "\(mm)/\(yy)"
        }
        
        mm--
        if(mm < 10)
        {
            return "0\(mm)/\(yy)"
        }
        return "\(mm)/\(yy)"
    }
    
}










































