//
//  RecentsViewController.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 25/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit

var firstMonthYear:String? = nil
let limit:Int = 5
var scrollLimit:Int = limit
var lastTimestamp:String?


class RecentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SMProtocol {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var isFiltred:Bool = false
    var filter:String = ""

    var notificationItem:AnyObject?
    var entrys:NSMutableArray?
    @IBOutlet weak var tableRecents: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableRecents.dataSource = self
        self.tableRecents.delegate = self
    }
    
    override func viewWillDisappear(animated:Bool)
    {
        if self.entrys != nil && self.entrys!.count > 0
        {
            for item in self.entrys!{
                let obj:DataObject = item as DataObject
                obj.isNew = false
                obj.isUpdated = false
            }
            self.tableRecents.reloadData()
        }        
    }
    
    
    func didReceivedData(data:NSMutableArray)
    {
        self.entrys = data
        if self.tableRecents != nil{
            self.tableRecents.reloadData()
            self.tableRecents.setNeedsDisplay()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.entrys == nil
        {
            return 0
        }
        return self.entrys!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var indent:NSString = "cell"
        var cell:DataTableViewCell? = tableView.dequeueReusableCellWithIdentifier(indent) as? DataTableViewCell
        if (cell == nil) {
            cell = DataTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: indent)
        }
        cell?.imageLogo.image = nil
        
        var item:DataObject = self.entrys!.objectAtIndex(indexPath.row) as DataObject
        cell!.setCellForData(item, forRow: indexPath.row)
        self.reload_distance = cell?.frame.size.height
        
        return cell!
    }
    
    var reload_distance:CGFloat?
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var height:CGFloat = scrollView.frame.size.height;
        
        var contentYoffset:CGFloat = scrollView.contentOffset.y;
        
        var distanceFromBottom:CGFloat = scrollView.contentSize.height - contentYoffset;
        
        if(distanceFromBottom < height && self.entrys != nil)
        {
            scrollLimit = self.entrys!.count + limit
            NSNotificationCenter.defaultCenter().postNotificationName("getData", object: nil)
        }
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (self.notificationItem != nil) {
            var content:ContentViewController = segue.destinationViewController as ContentViewController
            content.model = self.notificationItem as? DataObject
            self.notificationItem = nil;
        }else{
            let selectedIndex = self.tableRecents.indexPathForCell(sender as UITableViewCell)
            var content:ContentViewController = segue.destinationViewController as ContentViewController
            content.model = self.entrys!.objectAtIndex(selectedIndex!.row as Int) as? DataObject
        }
        
    }
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if (identifier == "contentView") {
            let selectedIndex = self.tableRecents.indexPathForCell(sender as UITableViewCell)
            var obj:DataObject = self.entrys!.objectAtIndex(selectedIndex!.row as Int) as DataObject
            if ((obj.isOffline == true) && (obj.onDisk == false)) {
                var alert:UIAlertView = UIAlertView(title: "Information", message: "You are currently offline and this content is not saved locally. Please try again later.", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
                return false;
            }
        }
        return true;
    }
    
}
