//
//  OptionsViewController.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 24/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

protocol OptionsViewProtocol
{
    func didTap(option:NSString, onSection:NSString)
}

class OptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SMProtocol {

    struct Static {
        static var onceToken: dispatch_once_t = 0
    }
    
    var isFiltred:Bool
    var filter:String
    
    var isVisible:Bool?
    var isAnimating:Bool?
    var isConnected:Bool?
    
    var menuData:NSMutableDictionary?
    var settings:NSArray?
    var delegate:OptionsViewProtocol?
    
    @IBOutlet weak var table_Options: UITableView!
    @IBOutlet weak var labelVersion: UILabel!
    
    required override init(nibName: String?, bundle: NSBundle?) {
        self.isFiltred = false
        self.filter = ""
        super.init(nibName: nibName, bundle: bundle)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.view.layer.borderWidth = 1.0
        
        self.settings = ["Logout"]
        
        self.table_Options.dataSource = self
        self.table_Options.delegate = self
        
        let version:String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as String
        let built:String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as String
        self.labelVersion.text = "   Version: \(version) (\(built))"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reAuthenticate"), name: "reAuthenticate", object: nil)
    }
    
    func reAuthenticate()
    {
        storage?.tagsTableRef?.getMenu()
    }
    
    func onReconnected() {
        storage?.tagsTableRef?.getMenu()
    }
    
    func onReconnecting() {
        storage?.tagsTableRef?.getMenu()
    }
    
    func didReceivedData(data: NSMutableArray) {
        var menu:NSMutableArray = Utils.orderMenu(data)
        self.removeMenu()
        self.menuData = NSMutableDictionary()
        
        for obj in menu
        {
            self.addItem(obj as DataObject)
        }

        self.table_Options.reloadData()
        self.table_Options.setNeedsDisplay()
    }
    
    func removeMenu()
    {
        if menuData == nil
        {
            return
        }
        
        var copy:NSMutableDictionary = NSMutableDictionary(dictionary: self.menuData!)
        for (menu, val) in enumerate(copy)
        {
            self.menuData?.removeObjectForKey(menu)
        }
        self.menuData = nil
    }
    
    func addItem(obj:DataObject!)
    {
        var tags:NSMutableArray? = self.menuData?.objectForKey(obj.type!) as? NSMutableArray
        
        if tags == nil
        {
            tags = NSMutableArray()
            tags?.addObject(obj.tag!)
            self.menuData?.setObject(tags!, forKey: obj.type!)
            return
        }
        tags?.addObject(obj.tag!)
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var header:UITableViewHeaderFooterView = view as UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor.peterRiverColor()
        header.textLabel.font = UIFont.boldSystemFontOfSize(17.0)
        if section > 0
        {
            var border:UIView = UIView(frame: CGRectMake(0, 0, header.frame.size.width, 1))
            border.layer.borderColor = UIColor(white: 0.8, alpha: 0.5).CGColor
            border.layer.borderWidth = 1.0
            
            header.addSubview(border)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var ident:String = "cell"
        var cell:UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(ident) as? UITableViewCell
        
        if cell == nil
        {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: ident)
        }
        
        cell?.backgroundColor = UIColor.clearColor()
        cell?.textLabel?.textColor = UIColor.blackColor()
        
        if self.menuData?.allKeys == nil || indexPath.section == self.menuData?.allKeys.count
        {
            cell?.textLabel?.text = self.settings?.objectAtIndex(indexPath.row) as? String
            return cell!
        }
        
        let allKeys = self.menuData?.allKeys
        let key = allKeys![indexPath.section] as String
        let val:NSArray = self.menuData?.objectForKey(key) as NSArray
        let tag = val.objectAtIndex(indexPath.row) as String
        cell?.textLabel?.text = tag
        
        return cell!
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        var sections:Int? = self.menuData?.count as Int!
        if sections == nil
        {
            return 1
        }else{
            return (sections! + 1) as Int
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.menuData?.allKeys == nil || section == self.menuData?.allKeys.count
        {
            var settings:Int = self.settings?.count as Int!
            return settings
        }
        let allKeys = self.menuData?.allKeys
        let pSection = allKeys![section] as String
        let elements:NSArray = self.menuData?.objectForKey(pSection) as NSArray
        return elements.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.menuData?.allKeys.count == nil || section == self.menuData?.allKeys.count
        {
            return "Session"
        }
        let allKeys = self.menuData?.allKeys
        return allKeys![section] as? String
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.menuData?.allKeys == nil || indexPath.section == self.menuData?.allKeys.count
        {
            self.delegate?.didTap(self.settings?.objectAtIndex(indexPath.row) as String, onSection: "Session")
            return
        }
        
        self.table_Options.deselectRowAtIndexPath(indexPath, animated: false)
        let allKeys = self.menuData?.allKeys
        var section:NSString = self.menuData?.allKeys[indexPath.section] as NSString
        var rows:NSArray = self.menuData?.objectForKey(section) as NSArray
        self.delegate?.didTap(rows.objectAtIndex(indexPath.row) as String, onSection: section)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
