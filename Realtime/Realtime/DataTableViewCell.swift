//
//  DataTableViewCell.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 25/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit
import Foundation

infix operator ~> {}

let queue = dispatch_queue_create("serial-worker", DISPATCH_QUEUE_SERIAL)

func ~> (
    backgroundClosure:  () -> (),
    mainClosure:        () -> ())
{
    dispatch_async(queue){
        backgroundClosure()
        dispatch_async(dispatch_get_main_queue()){ mainClosure()}
    }
}

let defaultImage:NSData = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("realtime-logo", ofType: "jpg") as String!)!

class DataTableViewCell: UITableViewCell {
    
    var data:DataObject?
    var viewHeader:UIView?
    
    let savedImage:UIImage = UIImage(named: "saved.png")!
    let downloadImage:UIImage = UIImage(named: "download.png")!
    @IBOutlet weak var imageLogo: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelTag: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var labelIsNew: UILabel!
    @IBOutlet weak var buttonDataState: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    func setCellForData(pData:DataObject, forRow:NSInteger)
    {
        self.data = pData;
        self.data!.callback = {(img:NSData?)in
            self.imageLogo.image = UIImage(data: img!)
            self.setNeedsDisplay()
        }
        
        if self.data!.image != nil
        {
            self.imageLogo.image = UIImage(data: self.data!.image!)
        }    
        self.labelDate.text = "  \(self.data!.date!)"
        self.labelTag.text = self.data!.tag
        
        self.labelDescription.text = self.data!.textDescription;
        self.labelDescription.numberOfLines = 8;
        self.labelDescription.sizeToFit()
        
        self.labelTitle.text = self.data!.title
        self.buttonDataState.hidden = false;
        
        if (self.data!.onDisk == true) {
            self.buttonDataState.setImage(self.savedImage, forState: UIControlState.Normal)
        }else
        {
            self.buttonDataState.setImage(self.downloadImage, forState: UIControlState.Normal)
        }
        
        self.labelIsNew.layer.masksToBounds = true
        self.labelIsNew.layer.borderWidth = 1.0
        self.labelIsNew.layer.borderColor = UIColor.blackColor().CGColor;
        self.labelIsNew.layer.cornerRadius = 7
        self.labelIsNew.font = UIFont.boldSystemFontOfSize(12.0)
        
        self.labelIsNew.hidden = true;
        
        if (self.data!.isNew == true) {
            self.labelIsNew.hidden = false
            self.labelIsNew.text = "NEW  "
        }
        
        if (self.data!.isUpdated == true) {
            self.labelIsNew.hidden = false;
            self.labelIsNew.text = "UPDATED  "
        }
        
        if (self.data!.isOffline == true) {
            if (self.data!.onDisk == true) {
                self.buttonDataState.hidden = false;
            }else
            {
                self.buttonDataState.hidden = true;
            }
        }
    }
    
    
    @IBAction func actionSaveOnDisk(sender: UIButton) {
        if (self.data!.onDisk == false && (self.data!.onDiskData == nil || self.data!.onDiskData == "")) {
            
            if ((self.data!.body != nil) && (self.data!.body != "")) {
                var siteData:NSData = self.data!.body!.dataUsingEncoding(NSUTF8StringEncoding)!
                siteData.writeToFile("\(DataObject.applicationDocumentsDirectory())/\(self.data!.type!)-\(self.data!.timestamp!).onDiskData", atomically: true)
                self.data!.onDisk = true;
                self.data!.onDiskData = NSString(data: siteData, encoding: NSUTF8StringEncoding)
                self.data!.storeOnDisk()
                var onDisk:NSMutableDictionary = contentsOnDiskData
                onDisk.setObject("1", forKey: "\(self.data!.type!)-\(self.data!.timestamp!).item")
                DataObject.writeContentOndisk()
                self.setCellForData(self.data!, forRow: 0)
                self.setNeedsDisplay()
                return
            }else if ((self.data!.url != nil) && (self.data!.url != "")) {
                var error:NSError?
                var response:NSURLResponse?
                var siteData:NSData = NSURLConnection.sendSynchronousRequest(NSURLRequest(URL: NSURL(string: self.data!.url!)!), returningResponse: &response, error: &error)!
                siteData.writeToFile("\(DataObject.applicationDocumentsDirectory())/\(self.data!.type!)-\(self.data!.timestamp!).onDiskData", atomically: true)
                self.data!.onDisk = true;
                self.data!.onDiskData = NSString(data: siteData, encoding: NSUTF8StringEncoding)
                self.data!.storeOnDisk()
                var onDisk:NSMutableDictionary = contentsOnDiskData
                onDisk.setObject("1", forKey: "\(self.data!.type!)-\(self.data!.timestamp!).item")
                DataObject.writeContentOndisk()
                self.setCellForData(self.data!, forRow: 0)
                self.setNeedsDisplay()
                return
            }
        }
        
    }
    
}
