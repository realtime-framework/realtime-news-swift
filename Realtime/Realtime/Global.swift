//
//  Global.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 03/03/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit


//BEGIN APP_KEY CONFIG
#if DEBUG
    //INSERT HERE YOUR DEVELOPMENT APP_KEY
    let APP_KEY = "DEV_APP_KEY"//"NcOeQJ"
#else
    //INSERT HERE YOUR PRODUCTION APP_KEY
    let APP_KEY = "PRD_APP_KEY"
#endif
//END APP_KEY CONFIG


let TABCONTENTS = "Contents"
let TABTAGS = "Tags"

let METADATA = "METADATA"
let URL = "http://ortc-developers.realtime.co/server/2.1/"


class Global: NSObject {
   
}
