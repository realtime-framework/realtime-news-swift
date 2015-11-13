//
//  BlogViewController.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 25/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

class BlogViewController: UIViewController, UITableViewDataSource,  UITableViewDelegate, SMProtocol {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    var isFiltred:Bool = false
    var filter:String = ""
    
    var notificationItem:AnyObject?
    var entrys:NSMutableArray?

    @IBOutlet weak var tableBlog: UITableView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableBlog.dataSource = self
        self.tableBlog.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tabBarItem.badgeValue = nil
    }
    
    override func viewWillDisappear(animated:Bool)
    {
        if self.entrys != nil && self.entrys!.count > 0
        {
            for item in self.entrys!{
                let obj:DataObject = item as! DataObject
                obj.isNew = false
                obj.isUpdated = false
            }
            self.tableBlog.reloadData()
        }
    }
    
    
    func didReceivedData(data:NSMutableArray)
    {
        self.entrys = data
        self.entrys = NSMutableArray(array: Utils.performSearch(self.entrys!, name: "Blog", key: "type"))
        if (self.isFiltred == true) {
            self.entrys = NSMutableArray(array: Utils.performSearch(self.entrys!, name: filter, key: "tag"))
        }
        self.entrys = Utils.orderTopics(self.entrys!)
        self.tableBlog?.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.entrys == nil
        {
            return 0
        }
        return self.entrys!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let indent:NSString = "cell"
        var cell:DataTableViewCell? = tableView.dequeueReusableCellWithIdentifier(indent as String) as? DataTableViewCell
        if (cell == nil) {
            cell = DataTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: indent as String)
        }
        
        cell?.imageLogo.image = nil
        let item:DataObject = self.entrys!.objectAtIndex(indexPath.row) as! DataObject
        cell!.setCellForData(item, forRow: indexPath.row)
        return cell!;
    }
    
    var reload_distance:CGFloat?
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let height:CGFloat = scrollView.frame.size.height;
        
        let contentYoffset:CGFloat = scrollView.contentOffset.y;
        
        let distanceFromBottom:CGFloat = scrollView.contentSize.height - contentYoffset;
        
        if(distanceFromBottom < height && self.entrys != nil)
        {
            scrollLimit = self.entrys!.count + limit
            NSNotificationCenter.defaultCenter().postNotificationName("getData", object: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (self.notificationItem != nil) {
            let content:ContentViewController = segue.destinationViewController as! ContentViewController
            content.model = self.notificationItem as? DataObject
            self.notificationItem = nil;
        }else{
            let selectedIndex = self.tableBlog.indexPathForCell(sender as! UITableViewCell)
            let content:ContentViewController = segue.destinationViewController as! ContentViewController
            content.model = self.entrys!.objectAtIndex(selectedIndex!.row as Int) as? DataObject
        }
        
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if (identifier == "contentView") {
            let selectedIndex = self.tableBlog.indexPathForCell(sender as! UITableViewCell)
            let obj:DataObject = self.entrys!.objectAtIndex(selectedIndex!.row as Int) as! DataObject
            if ((obj.isOffline == true) && (obj.onDisk == false)) {
                let alert:UIAlertView = UIAlertView(title: "Information", message: "You are currently offline and this content is not saved locally. Please try again later.", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
                return false;
            }
        }
        return true;
    }

}
