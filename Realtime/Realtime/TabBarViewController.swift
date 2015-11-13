//
//  TabBarViewController.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 24/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

var currentSearchMonth:String?

class TabBarViewController: UITabBarController, UITabBarControllerDelegate, UINavigationControllerDelegate, OptionsViewProtocol, SMProtocol{
    
    struct Static {
        static var onceToken: dispatch_once_t = 0
    }
    
    required init(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)!
    }
    
    @IBOutlet weak var filterButton: UIBarButtonItem!

    @IBOutlet weak var optionButton: UIBarButtonItem!
    
    var isFiltred:Bool = false
    var filter:String = ""
    
    var optionsView:OptionsViewController?
    var entrys:NSMutableArray?
    var statusView:UIView?
    var statusLabel:UILabel?
    var activity:UIActivityIndicatorView?
    var viewframe:CGRect?
    var connect:Bool?
    var connectFrame:CGRect?
    var disconnectFrame:CGRect?
    var viewDidAppear:Bool = false
    var swipeLeft:UISwipeGestureRecognizer?
    var swipeRight:UISwipeGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.configStatusView()
        self.setOptionsView()
        self.setActivityView()
        self.verifyAuth()
        self.title = "Recent"
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(20)]

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("setViewFrame"), name: "fromBackground", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("verifyAuth"), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showActivityView"), name: "startLoad", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("hideActivityView"), name: "endLoad", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("verifyAuth"), name: kReachabilityChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("getData"), name: "getData", object: nil)
        
        self.swipeLeft = UISwipeGestureRecognizer(target: self, action: Selector("swipeLeft:"))
        self.swipeLeft!.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(self.swipeLeft!)
        
        self.swipeRight = UISwipeGestureRecognizer(target: self, action: Selector("swipeRight:"))
        self.swipeRight!.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(self.swipeRight!)
    }
    
    
    func swipeRight(recognizer:UIGestureRecognizer)
    {
        if self.optionsView?.isVisible == nil || self.optionsView?.isVisible == false
        {
            self.toggleMenu()
        }
    }
    
    func swipeLeft(recognizer:UIGestureRecognizer)
    {
        if self.optionsView?.isVisible == true
        {
            self.toggleMenu()
        }
    }
    
    func setActivityView()
    {
        self.activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        self.activity?.color = UIColor.redColor()
        self.hideActivityView()
        
        let activityButton:UIBarButtonItem = UIBarButtonItem(customView: self.activity!)
        self.navigationItem.leftBarButtonItems = [self.optionButton, activityButton]
    }
    
    func showActivityView(){
        self.activity?.hidden = false
        self.activity?.startAnimating()
    }
    
    func hideActivityView(){
        self.activity?.hidden = true
        self.activity?.stopAnimating()
    }
    
    func updateConnectionStatus(){
        if self.viewDidAppear == true{
            let internetStatus:NetworkStatus = networkReachability.currentReachabilityStatus()
            
            if internetStatus != NetworkStatus.NotReachable && isConnected == true{
                self.setStatus(true)
            }else{
                self.setStatus(false)
            }
        }
    }
    
    func verifyAuth(){
        
        Utils.reAuth ({ (result:Bool) -> Void in
            if result == false || storage == nil{
                if storage != nil {
                    storage!.removeListeners()
                    storage!.contentsTableRef!.disableListeners()
                    storage!.tagsTableRef!.disableListeners()
                }
                storage = Storage(contentsDelegate: self, tagsDelegate: self.optionsView!)
                self.getData()
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName("reAuthenticate", object: nil, userInfo: nil)
            self.setStatus(true)
            },
            errorCallBack: {() ->Void in
                if storage == nil {
                    let contents:SM = SM(tableName: TABCONTENTS, storageRef: nil)
                    contents.delegate = self
                    contents.loadOffLineData()
                    
                    let options:SM = SM(tableName: TABTAGS, storageRef: nil)
                    options.delegate = self.optionsView
                    options.loadOffLineMenu()
                }else{
                    storage?.contentsTableRef?.loadOffLineData()
                    storage?.tagsTableRef?.loadOffLineMenu()
                }
            self.setStatus(false)
    })
}

    func onReconnected()
    {
        NSLog("( onReconnected )")

        storage?.contentsTableRef?.reset()
        self.getData()
        self.setStatus(true)
    }
    
    func onReconnecting()
    {
        storage?.contentsTableRef?.loadOffLineData()
        self.setStatus(false)
    }
    
    func loadFirstMonthYear() {
        let data:NSData? = Utils.firstMonthYear()
        if data != nil
        {
            let temp:String = NSString(data: data!, encoding: NSUTF8StringEncoding)! as String
            Utils.jsonDictionaryFromString(temp, onCompletion: { (dict:NSDictionary) -> Void in
                firstMonthYear = dict.objectForKey("firstMonthYear") as! String!
                }) {
                    (error:NSError) -> Void in
            }
        }
    }
    
    

    func getData()
    {
        dispatch_semaphore_wait(flag, DISPATCH_TIME_FOREVER)
        
        if storage?.contentsTableRef?.processing == false{
            
            if firstMonthYear == nil || firstMonthYear == ""
            {
                currentSearchMonth = nil
                scrollLimit = limit
                lastTimestamp = nil
                self.loadFirstMonthYear()
            }
            if currentSearchMonth != firstMonthYear
            {
                if currentSearchMonth == nil
                {
                    currentSearchMonth = Utils.getCurrentMonthYear()
                }else if(currentSearchMonth != nil && storage?.contentsTableRef?.lastCount < limit){
                    currentSearchMonth = Utils.getPreviousMonth(currentSearchMonth!)
                }
                storage?.contentsTableRef?.resetFilter()
                storage?.contentsTableRef?.appendFilter(currentSearchMonth!, field: "MonthYear")
                if lastTimestamp != nil
                {
                    storage?.contentsTableRef?.appendFilterLesser(lastTimestamp!, field: "Timestamp")
                }
                storage?.contentsTableRef?.getData()
            }
        }
        
        dispatch_semaphore_signal(flag)
    }
    
    
    func didReceivedData(data:NSMutableArray)
    {
        self.entrys = Utils.orderTopics(data)
        
        if self.entrys != nil && self.entrys!.count > 0{
            let last:DataObject = self.entrys!.objectAtIndex(self.entrys!.count - 1) as! DataObject
            lastTimestamp = last.timestamp as? String
        }
        
        if self.entrys?.count < scrollLimit && currentSearchMonth != firstMonthYear
        {
            dispatch_semaphore_signal(flag)
            self.getData()
            return
        }
        
        let array = self.viewControllers as [AnyObject]?
        for view in array! {
            view.didReceivedData!(self.entrys!)
        }
        
//        if self.entrys != nil && self.entrys?.count > 0{
//            //let item:DataObject = self.entrys!.objectAtIndex(0) as! DataObject
//        }
        dispatch_semaphore_signal(flag)
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            sleep(1)
            dispatch_async(dispatch_get_main_queue()) {
                self.processPush()
            }
        }
        
    }

    
    func setViewFrame(){
        dispatch_async(dispatch_get_main_queue(), {
            if (!CGRectIsNull(self.viewframe!)) {
                self.view.frame = self.viewframe!
            }
        });
    }
    
    
    func configStatusView(){
        let barFrame:CGRect! = self.navigationController?.navigationBar.frame
        self.viewframe = self.view.frame
        
        self.statusView = UIView(frame: CGRectMake(barFrame.origin.x, barFrame.size.height, self.view.frame.size.width, 20))
        self.statusLabel = UILabel(frame: CGRectMake(0, 0, self.statusView!.frame.size.width, 20))
        self.statusLabel?.textAlignment = NSTextAlignment.Center
        self.statusLabel?.font = UIFont.boldSystemFontOfSize(10)
        self.statusLabel?.textColor = UIColor.whiteColor()
        self.statusView?.addSubview(self.statusLabel!)
        self.view?.addSubview(self.statusView!)
        
        self.disconnectFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.statusView!.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.statusView!.frame.size.height)
        self.connectFrame = CGRectMake(self.disconnectFrame!.origin.x, self.disconnectFrame!.origin.y - self.statusView!.frame.size.height, self.disconnectFrame!.size.width,self.disconnectFrame!.size.height + self.statusView!.frame.size.height);
    }
    
    func setStatus(connect:Bool)
    {
        dispatch_async(queue){
            while self.viewDidAppear == false
            {
                sleep(1)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                if (connect == true) {
                    self.statusView?.backgroundColor = UIColor.greenColor()
                    self.statusLabel?.text = "Connected";
                    UIView.animateWithDuration(1.0, animations: { () -> Void in
                        self.view.frame = self.connectFrame!
                        }, completion: { (finish) -> Void in
                            self.viewframe = self.view.frame
                    })
                }else if(connect == false)
                {
                    self.statusView?.backgroundColor = UIColor.redColor()
                    self.statusLabel?.text = "Not Connected";
                    UIView.animateWithDuration(1.0, animations: { () -> Void in
                        self.view.frame = self.disconnectFrame!
                        }, completion: { (finish) -> Void in
                            self.viewframe = self.view.frame
                    })
                }
            });
            
        }
    }
    
    func filterData(view:SMProtocol, filter:NSString?)
    {
        if (filter != nil) {
            let res:NSArray = Utils.performSearch(self.entrys!, name: filter, key: "tag")
            view.didReceivedData!(NSMutableArray(array: res))
            view.isFiltred = true
            view.filter = filter! as String
        }else
        {
            view.didReceivedData!(self.entrys!)
        }
        self.setFiltredButton(view)
    }
    
    func removeFilter()
    {
        let view:SMProtocol = self.selectedViewController as! SMProtocol
        view.isFiltred = false;
        self.filterData(view, filter: nil);
    }
    
    func setFiltredButton(view:SMProtocol)
    {
        if (view.isFiltred == false) {
            self.filterButton.enabled = false;
            self.filterButton.tintColor = UIColor.clearColor()
        }else
        {
            self.filterButton.enabled = true
            self.filterButton.tintColor = nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        let view = self.selectedViewController as? SMProtocol
        if view != nil
        {
            self.setFiltredButton(view!)
        }else
        {
            self.filterButton.enabled = false;
            self.filterButton.tintColor = UIColor.clearColor()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.viewDidAppear = true
        self.navigationController?.delegate = self
        self.setViewFrame()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func processPush()
    {
        var temp:NSMutableDictionary?
        var dicKey:NSString?
        for (key, _) in notifications {
            dicKey = key as? NSString
            temp = notifications.objectForKey(key) as? NSMutableDictionary
            break;
        }
        
        if dicKey == nil
        {
            return
        }
        
        for it in self.entrys!
        {
            let item:DataObject = it as! DataObject
            if ("\(item.type!)-\(item.timestamp!)" == dicKey! as String) {
                temp?.setObject(item, forKey: "DataObject")
                break;
            }
        }
        
        if (temp!.objectForKey("DataObject") != nil) {
            let array:NSArray = self.viewControllers! as NSArray
            let recent = array.objectAtIndex(0) as! RecentsViewController
            self.selectedViewController = recent
            recent.notificationItem = temp!.objectForKey("DataObject")
            array.objectAtIndex(0).performSegueWithIdentifier("contentView", sender:self)
        }
    }
    
    
    func didReceivedItem(item:DataObject)
    {
        let obj:DataObject? = storage?.contentsTableRef?.dataIndex!.objectForKey("\(item.type!)-\(item.timestamp!)") as? DataObject
        if (obj != nil) {
            obj!.updateItem(item)
            self.setUpdated(obj!)
        }else{
            self.entrys!.addObject(item)
            //var test:NSMutableDictionary = storage?.contentsTableRef?.dataIndex  as NSMutableDictionary!
            storage?.contentsTableRef?.dataIndex!.setObject(item, forKey:"\(item.type!)-\(item.timestamp!)")
            self.setNew(item)
        }
        self.entrys = Utils.orderTopics(self.entrys!)
        let array:NSArray = self.viewControllers! as NSArray
        
        let recent = array.objectAtIndex(0) as! SMProtocol
        recent.didReceivedData!(self.entrys!)
        
        let blog:SMProtocol = array.objectAtIndex(1) as! SMProtocol
        blog.didReceivedData!(self.entrys!)
        
        let white:SMProtocol = array.objectAtIndex(2) as! SMProtocol
        white.didReceivedData!(self.entrys!)
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            sleep(1)
            dispatch_async(dispatch_get_main_queue()) {
                self.processPush()
            }
        }
    }
    
    
    func setNew(item:DataObject)
    {
        item.isNew = true;
        let array:NSArray = self.viewControllers! as NSArray
        if (item.type == "Blog") {
            array.objectAtIndex(1).tabBarItem!.badgeValue = "New";
        }
        
        if (item.type == "White Papers")
        {
            array.objectAtIndex(2).tabBarItem!.badgeValue = "New";
        }
    }
    
    
    func setUpdated(item:DataObject)
    {
        item.isUpdated = true
        let array:NSArray = self.viewControllers! as NSArray
        if (item.type == "Blog") {
            array.objectAtIndex(1).tabBarItem!.badgeValue = "Updated";
        }
        
        if (item.type == "White Papers")
        {
            array.objectAtIndex(2).tabBarItem!.badgeValue = "Updated";
        }
    }
    
    
    func didDeleteItem(item:DataObject)
    {
        //let dict:NSMutableDictionary =  storage?.contentsTableRef?.dataIndex as NSMutableDictionary!
        let entry:DataObject? = storage?.contentsTableRef?.dataIndex!.objectForKey("\(item.type!)-\(item.timestamp!)") as? DataObject
        if (entry != nil) {
            entry!.removeFromDisk()
            self.entrys!.removeObject(entry!)
            storage?.contentsTableRef?.dataIndex!.removeObjectForKey("\(item.type!)-\(item.timestamp!)")
            storage?.contentsTableRef?.data!.removeObject(entry!)
            
            let onDisk:NSMutableDictionary = contentsOnDiskData
            onDisk.removeObjectForKey("\(item.type!)-\(item.timestamp!)")
            DataObject.writeContentOndisk()
            
            let array:NSArray = self.viewControllers! as NSArray
            
            self.entrys = Utils.orderTopics(self.entrys!)
            if (item.type == "Blog") {
                let blog:SMProtocol = array.objectAtIndex(1) as! SMProtocol
                blog.didReceivedData!(self.entrys!)
            }
            
            if (item.type == "White Papers")
            {
                let blog:SMProtocol = array.objectAtIndex(2) as! SMProtocol
                blog.didReceivedData!(self.entrys!)
            }
            let blog:SMProtocol = array.objectAtIndex(0) as! SMProtocol
            blog.didReceivedData!(self.entrys!)
        }
    }
    
    
    func setOptionsView(){
        self.optionsView = OptionsViewController(nibName: "OptionsViewController", bundle: NSBundle.mainBundle())
        self.optionsView!.delegate = self;
        let selfFrame:CGRect = self.view.frame;
        self.optionsView!.view.frame = CGRectMake(selfFrame.size.width * (-1), selfFrame.origin.y, selfFrame.size.width, selfFrame.size.height - self.tabBar.frame.size.height)
        self.view.addSubview(self.optionsView!.view)
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        self.title = viewController.title
        self.setFiltredButton(viewController as! SMProtocol)
    }
    
    @IBAction func actionRemoveFilter(sender: AnyObject) {
        self.removeFilter()
    }
    
    
    func didTap(option: NSString, onSection: NSString)
    {
        if (onSection == "Session") {
            self.toggleMenu()
            if (option == "Logout") {
                storage?.contentsTableRef?.data = NSMutableArray()
                Utils.goToLogin()
            }
            return;
        }
        self.removeFilter()
        let array:NSArray = self.viewControllers! as NSArray
        for view in array {
            if (view.title == onSection) {
                self.toggleMenu()
                self.filterData(view as! SMProtocol, filter: option)
                self.selectedViewController = view as? UIViewController
                self.title = view.title
            }
        }
    }
    
    
    @IBAction func action_SplitView(sender: AnyObject) {
        self.toggleMenu()
    }
    
    
    
    func toggleMenu()
    {
        if (self.optionsView!.isAnimating == true) {
            return;
        }
        
        self.optionsView!.isAnimating = true
        let selfFrame:CGRect = self.view.frame
        let optionFrame:CGRect  = self.optionsView!.view.frame
        let tableFrame:CGRect = self.optionsView!.table_Options.frame
        
        if (self.optionsView!.isVisible == true) {
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.optionsView!.view.frame = CGRectMake(selfFrame.size.width * (-1), selfFrame.origin.y, selfFrame.size.width, selfFrame.size.height - self.tabBar.frame.size.height)
            }, completion: { (finish) -> Void in
                self.optionsView!.isVisible = false
                self.optionsView!.isAnimating = false
            })
        }else
        {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.optionsView!.view.frame = CGRectMake(tableFrame.origin.x * (-1), selfFrame.origin.y, optionFrame.size.width, selfFrame.size.height - self.tabBar.frame.size.height)
                }, completion: { (finish) -> Void in
                    self.optionsView!.isVisible = true
                    self.optionsView!.isAnimating = false
            })

        }
    }

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
}
