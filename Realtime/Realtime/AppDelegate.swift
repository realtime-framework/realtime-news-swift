//
//  AppDelegate.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 09/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.


import UIKit


var networkReachability = Reachability.reachabilityForInternetConnection()
var notifications:NSMutableDictionary = NSMutableDictionary()
var ortc:ORTC?


@UIApplicationMain
class AppDelegate: RealtimePushAppDelegate, UIApplicationDelegate{

    override func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        super.application(application, didFinishLaunchingWithOptions: launchOptions)
        networkReachability.startNotifier()
        
        var data:NSData? = Utils.firstMonthYear()?
        if data != nil
        {
            var temp:String = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            Utils.jsonDictionaryFromString(temp, onCompletion: { (dict:NSDictionary) -> Void in
                firstMonthYear = dict.objectForKey("firstMonthYear") as String!
                }) { (error:NSError) -> Void in
                
            }
        }
        
        var dateFormat:String = Utils.getCurrentMonthYear()
        var logedIn:Bool = false
        var isLoged:String? = NSUserDefaults.standardUserDefaults().objectForKey("logedIn") as? String
        
        if (isLoged != nil && isLoged == "1")
        {
            logedIn = true
            var result:String? = NSUserDefaults.standardUserDefaults().objectForKey("token") as? String
            if result != nil
            {
                token = result
                var storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                var controller:UIViewController = storyboard.instantiateViewControllerWithIdentifier("rootNav") as UIViewController
                
                self.window.rootViewController = controller
                self.window.makeKeyWindow()
            }
        }
        ortcToken = Utils.GetUUID()
        var response:NSData? = Utils.authenticateMessagingToken()
        ortc = ORTC()
        ortc!.setClient()

        return true
    }

    override func applicationWillResignActive(application: UIApplication) {

    }

    override func applicationDidEnterBackground(application: UIApplication) {
    
    }

    override func applicationWillEnterForeground(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName("fromBackground", object: nil)
    }

    override func applicationDidBecomeActive(application: UIApplication) {
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }

    override func applicationWillTerminate(application: UIApplication) {

    }
    
    override func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        super.application(application, didReceiveRemoteNotification: userInfo)
        var aps:NSDictionary? = userInfo as NSDictionary
        aps = aps?.objectForKey("aps") as? NSDictionary

        let state = application.applicationState
        
        if aps != nil && application.applicationState != UIApplicationState.Active
        {
            var data:NSMutableDictionary = NSMutableDictionary()
            data.setObject(aps?.objectForKey("Type") as String, forKey: "Type")
            data.setObject(aps?.objectForKey("Timestamp") as String, forKey: "Timestamp")
            
            var type:String = aps?.objectForKey("Type") as String
            var timestamp:String = aps?.objectForKey("Timestamp") as String
            
            notifications.setObject(data, forKey: "\(type)-\(timestamp)")
            NSNotificationCenter.defaultCenter().postNotificationName("notification", object: nil)
        }
    }

    override func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        //var token:NSString = NSString(data: deviceToken, encoding: NSUTF8StringEncoding)!
        //var alert:UIAlertView = UIAlertView(title: "Info", message: " didRegisterForRemoteNotifications appKey:\(APP_KEY)", delegate: nil, cancelButtonTitle: "OK")
        //alert.show()
    }
    
    override func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        //var alert:UIAlertView = UIAlertView(title: "Error", message: " didFailToRegisterForRemoteNotifications appKey:\(APP_KEY)", delegate: nil, cancelButtonTitle: "OK")
        //alert.show()
    }

}

