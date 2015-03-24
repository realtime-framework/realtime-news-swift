//
//  ViewController.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 09/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    var isAuth:Bool?
    var sm:SM?

    @IBOutlet weak var text_UserName: UITextField!
    @IBOutlet weak var text_Password: UITextField!
    @IBOutlet weak var buttonLogin: FUIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.setButton(buttonLogin)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        text_UserName.resignFirstResponder()
        text_Password.resignFirstResponder()
    }

    @IBAction func actionLogin(sender: AnyObject) {
        
        var user = text_UserName.text
        var pass:NSString = text_Password.text as NSString
        var crypto:NSString = Crypto.MD5FromString(pass) as NSString
        
        
        var rsp:NSData? = Utils.authenticateStorageTokenForUser(text_UserName.text, pass: crypto)
        
        if rsp == nil
        {
            var alert:UIAlertView = UIAlertView(title: "Error", message: "Error in authentication", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            return
        }        
        
        
        var respString = NSString(data: rsp!, encoding: NSUTF8StringEncoding)
        Utils.jsonDictionaryFromString(NSString(data: rsp!, encoding: NSUTF8StringEncoding)!,
        onCompletion: { (jsonDict) -> Void in
            var json:NSDictionary = jsonDict as NSDictionary
            if json.objectForKey("token") != nil
            {
                token = json.objectForKey("token") as? String
                NSUserDefaults.standardUserDefaults().setObject(token, forKey: "token")
                NSUserDefaults.standardUserDefaults().setObject(self.text_UserName.text, forKey: "user")
                NSUserDefaults.standardUserDefaults().setObject(Crypto.MD5FromString(self.text_Password.text), forKey: "pass")
                NSUserDefaults.standardUserDefaults().synchronize()
                
                self.isAuth = true
                NSUserDefaults.standardUserDefaults().setObject("1", forKey: "logedIn")
                NSUserDefaults.standardUserDefaults().synchronize()
                
                self.performSegueWithIdentifier("begin", sender: nil)
            }else if (json.objectForKey("Error") != nil)
            {
                var alert:UIAlertView = UIAlertView(title: "Error", message: "Invalid credentials", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
           
        }, onError:{ (error) -> Void in
            var alert:UIAlertView = UIAlertView(title: "Error", message: "Error in authentication", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        })
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        
        if isAuth == true
        {
            return true
        }
        return false
    }
    
    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    
}




