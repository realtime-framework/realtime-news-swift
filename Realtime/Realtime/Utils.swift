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
        var image:UIImage = UIImage(named: "Button.png")!
        var insets:UIEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
        var stretchedImage:UIImage = image.resizableImageWithCapInsets(insets)
        bt.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        bt.setBackgroundImage(stretchedImage, forState: UIControlState.Normal)
    }
    
    class func setBlueBarButton(bt:UIButton){
        var image:UIImage = UIImage(named: "Button.png")!
        var insets:UIEdgeInsets = UIEdgeInsetsMake(18, 18, 18, 18)
        var stretchedImage:UIImage = image.resizableImageWithCapInsets(insets)
        bt.setImage(stretchedImage, forState: UIControlState.Normal)
    }

    class func jsonDictionaryFromString(text:String, onCompletion:(NSDictionary) -> Void, onError:(NSError) -> Void ){
        var error:NSError?
        var jsonData:NSData = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        var json:NSDictionary? = NSJSONSerialization.JSONObjectWithData(jsonData, options:nil, error: &error) as? NSDictionary
        
        if error == nil{
            onCompletion(json!)
        }else
        {
            onError(error!)
        }
    }
    
    class func jsonStringFromDictionary(dict:NSDictionary, onCompletion:(NSString) -> Void, onError:(NSError) -> Void ){
        var error:NSError?
        var jsonString:NSString
        var jsonData:NSData =  NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted, error: &error)!
        
        if error != nil{
            onCompletion(NSString(data: jsonData, encoding: NSUTF8StringEncoding)!)
        }else
        {
            onError(error!)
        }
    }

    class func convertTimeStamp(data:Double) -> String {
        var time:Double = data / 1000
        var sourceDate:NSDate = NSDate(timeIntervalSince1970: time)
        
        var dateFormater:NSDateFormatter = NSDateFormatter()
        dateFormater.locale = NSLocale.currentLocale()
        dateFormater.dateFormat = "dd/MM/yyyy HH:mm"
        
        return dateFormater.stringFromDate(sourceDate)
    }
    
    class func orderTopics(messages:NSMutableArray) -> NSMutableArray {
        var sortDescriptor:NSSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        var sortDescriptors:NSArray = NSArray(object: sortDescriptor)
        var sortedArray:NSMutableArray = NSMutableArray(array: messages.sortedArrayUsingDescriptors(sortDescriptors))
        return sortedArray
    }
    
    class func orderMenu(messages:NSMutableArray) -> NSMutableArray {
        var sortDescriptor:NSSortDescriptor = NSSortDescriptor(key: "tag", ascending: true)
        var sortDescriptors:NSArray = NSArray(object: sortDescriptor)
        var sortedArray:NSMutableArray = NSMutableArray(array: messages.sortedArrayUsingDescriptors(sortDescriptors))
        return sortedArray
    }
    
    class func goToLogin() {
        NSUserDefaults.standardUserDefaults().setObject("0", forKey: "logedIn")
        NSUserDefaults.standardUserDefaults().synchronize()
        var storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var vc:UIViewController = storyboard.instantiateViewControllerWithIdentifier("root") as UIViewController!
        
        storage!.removeListeners()
        storage = nil
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate? as AppDelegate
        appDelegate.window.rootViewController = vc
    }
    
    class func authenticateStorageTokenForUser(user: String, pass: String) -> NSData?  {
        let url:String = "https://codehosting.realtime.co/\(APP_KEY)/authenticate?"
        
        var urlString:NSMutableString = NSMutableString()
        
        urlString.appendFormat("user=%@&", user)
        urlString.appendFormat("password=%@&", pass)
        urlString.appendFormat("role=%@", "iOSApp")
        
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "\(url)\(urlString)")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        var data:NSData = urlString.dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        
        request.HTTPMethod = "POST"
        request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var resp:NSURLResponse?
        var error:NSError?
        
        return NSURLConnection.sendSynchronousRequest(request, returningResponse: &resp, error: &error)
    }
    
    class func authenticateMessagingToken() -> NSData?  {
        let url:String = "https://codehosting.realtime.co/\(APP_KEY)/saveAuthentication?"
        
        var urlString:NSMutableString = NSMutableString()
        

        urlString.appendFormat("token=%@", ortcToken!)
        
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "\(url)\(urlString)")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        var data:NSData = urlString.dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        
        request.HTTPMethod = "POST"
        request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var resp:NSURLResponse?
        var error:NSError?
        var result:NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse: &resp, error: &error)
        
        return result?
    }

    class func firstMonthYear() -> NSData?  {
        let url:String = "https://codehosting.realtime.co/\(APP_KEY)/firstMonthYear"
        
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "\(url)")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        request.HTTPMethod = "GET"
        
        var resp:NSURLResponse?
        var error:NSError?
        var result:NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse: &resp, error: &error)
        
        return result?
    }


    
    class func reAuth(callback:(result:Bool) -> Void, errorCallBack:() -> Void) {
        var storageRef:StorageRef = StorageRef(APP_KEY, privateKey: nil, authenticationToken: token);
        
        storageRef.isAuthenticated(token, success: { (success) -> Void in
            var result:Bool
            if (success == 1)
            {
                result = true
                callback(result: true)
                return
            }
            else
            {
                result = false
            }
            
            var user:String? = NSUserDefaults.standardUserDefaults().objectForKey("user") as? String
            var pass:String? = NSUserDefaults.standardUserDefaults().objectForKey("pass") as? String
            
            if (user == nil || pass == nil)
            {
                Utils.goToLogin()
            }
            
            var rsp:NSData? = Utils.authenticateStorageTokenForUser(user!, pass: pass!) as NSData?
            if rsp == nil
            {
                Utils.goToLogin()
                return
            }
            
            Utils.jsonDictionaryFromString(NSString(data: rsp!, encoding: NSUTF8StringEncoding)!, onCompletion:
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
        var args:String = ".*\(name!).*"
        var query:NSString = NSString(format: "%@ MATCHES [c] \"%@\"", key, args)
        var predicate:NSPredicate? = NSPredicate(format: query)
        return array.filteredArrayUsingPredicate(predicate!)
    }

    class func GetUUID() -> String{
        return NSUUID().UUIDString
    }
    

    
    class func getCurrentMonthYear() -> String {
        var date:NSDate = NSDate()
        var formater:NSDateFormatter = NSDateFormatter()
        formater.dateFormat = "MM/yyyy"
        return formater.stringFromDate(date)
    }
    
    class func getPreviousMonth(month:String) -> String
    {
        var parts:NSArray = month.componentsSeparatedByString("/");
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










































