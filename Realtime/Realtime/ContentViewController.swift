//
//  ContentViewController.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 25/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController, UIWebViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var webViewContent: UIWebView!
    var model:DataObject?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var statusView:UIView?
    var statusLabel:UILabel?
    var connectedFrame:CGRect?
    var disconnectedFrame:CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = model!.title!
        self.navigationController?.delegate = self
        self.webViewContent.scalesPageToFit = true
        self.webViewContent.delegate = self;
        self.configStatusView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.delegate = nil
        self.navigationController?.toolbarHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if notifications.objectForKey("\(model!.type!)-\(model!.timestamp!)") != nil{
            notifications.removeObjectForKey("\(model!.type!)-\(model!.timestamp!)")
        }

        
        if ((self.model!.isOffline == false) && (model!.body != nil) && (model!.body != "")) {
            self.webViewContent.loadHTMLString(self.buildHTMLBody(model!.body!), baseURL: nil)
            return;
        }
        
        if ((self.model!.isOffline == false) && (model!.url != nil) && (model!.url != "")) {
            var request:NSURLRequest
            var nsurl:NSURL? = NSURL(string: model!.url!)
            if nsurl == nil
            {
                self.navigationController?.popViewControllerAnimated(true)
                return
            }
            request = NSURLRequest(URL: nsurl!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            self.webViewContent.loadRequest(request)
            return;
        }
        
        if ((model!.onDiskData != nil) && (model!.onDiskData != "")) {
            self.webViewContent.loadHTMLString(self.buildHTMLBody(model!.onDiskData!), baseURL:nil)
            return;
        }
    }
    
    
    func buildHTMLBody(body:NSString) -> NSString{
        
        var appCSS:NSURL = NSBundle.mainBundle().URLForResource("app", withExtension: "css")!
        
        var bootCSS:NSURL = NSBundle.mainBundle().URLForResource("bootstrap", withExtension: "css")!
        
        var fontCSS:NSURL = NSBundle.mainBundle().URLForResource("fontawesome", withExtension: "css")!
        
        let path:NSString = NSBundle.mainBundle().pathForResource("template", ofType: "html")!
        var template:NSString = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        
        var html:NSString = NSString(format:template, appCSS.description, bootCSS.description, fontCSS.description, body)
        
        return html
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if model!.isOffline == true
        {
            self.setOfflineContent()
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        let mask = Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        return mask
    }
    
    
    func configStatusView()
    {
        var barFrame:CGRect? = self.navigationController!.navigationBar.frame
        
        self.statusView = UIView(frame: CGRectMake(barFrame!.origin.x, barFrame!.size.height, self.view.frame.size.width, 20))
        self.statusLabel = UILabel(frame: CGRectMake(0, 0, self.statusView!.frame.size.width, 20))
        self.statusLabel!.textAlignment = NSTextAlignment.Center
        self.statusLabel!.font = UIFont.boldFlatFontOfSize(10)
        self.statusLabel!.textColor = UIColor.whiteColor()
        self.statusView!.addSubview(self.statusLabel!)
        self.view.addSubview(self.statusView!)
        self.disconnectedFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.statusView!.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.statusView!.frame.size.height);
    }
    
    func setOfflineContent()
    {
        dispatch_async(dispatch_get_main_queue(), {
            self.statusView!.backgroundColor = UIColor.redColor()
            self.statusLabel!.text = "Offline Content"
            
            UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.AllowAnimatedContent, animations: { () -> Void in
                self.view.frame = self.disconnectedFrame!
                }, completion: { (finish) -> Void in
            })
        })
    }
    
    
    func webViewDidStartLoad(webView:UIWebView)
    {
        self.activityIndicator!.startAnimating()
    }
    
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        self.activityIndicator!.stopAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        var url:String = webView.request?.URL.description as String!
        if(webView.request?.URL.description != model!.url && model!.isOffline == false)
        {
            self.navigationController?.toolbarHidden = false
        }else{
            self.navigationController?.toolbarHidden = true
        }
        
        
        self.activityIndicator!.stopAnimating()
        if (model!.onDiskData != nil) {
            self.addLinks()
        }
        self.webViewContent.setNeedsDisplay()
    }
    
    func addLinks()
    {
        var appCSS:NSURL = NSBundle.mainBundle().URLForResource("app", withExtension: "css")!
        
        var bootCSS:NSURL = NSBundle.mainBundle().URLForResource("bootstrap", withExtension: "css")!
        
        var fontCSS:NSURL = NSBundle.mainBundle().URLForResource("fontawesome", withExtension: "css")!
        
        var js:NSString = NSString(format: "var headHTML = document.getElementsByTagName('head')[0].innerHTML; headHTML    += '<link type=\"text/css\" rel=\"stylesheet\" href=\"%@\">'; headHTML    += '<link type=\"text/css\" rel=\"stylesheet\" href=\"%@\">'; headHTML    += '<link type=\"text/css\" rel=\"stylesheet\" href=\"%@\">'; document.getElementsByTagName('head')[0].innerHTML = headHTML;", appCSS, bootCSS, fontCSS)
        var result:NSString = self.webViewContent!.stringByEvaluatingJavaScriptFromString(js)!
    }
    
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if  model!.isOffline == true
        {
            self.navigationController?.toolbarHidden = true
        }
        return true
    }
    
    @IBAction func back(sender: AnyObject) {
        if (model!.body != nil && model!.body != "" && (self.webViewContent.canGoBack == false)) {
             self.webViewContent.loadHTMLString(self.buildHTMLBody(model!.body!), baseURL: nil)
            return;
        }
        self.webViewContent.goBack()
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
