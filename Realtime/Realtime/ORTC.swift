//
//  ORTC.swift
//  RealtimeNews
//
//  Created by Joao Caixinha on 09/02/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

import UIKit




var ortcToken:String?
class ORTC: NSObject, OrtcClientDelegate{
    
    
    var ortc: OrtcClient?
    
    func setClient(){
        self.ortc = OrtcClient.ortcClientWithConfig(self) as? OrtcClient
        self.ortc!.connectionMetadata = METADATA
        self.ortc!.clusterUrl = URL
        
        var app = APP_KEY
        self.ortc!.connect(APP_KEY, authenticationToken: ortcToken)
    }
    
    func onConnected(ortc: OrtcClient!) {
        self.ortc!.subscribeWithNotifications("notifications", subscribeOnReconnected: true, onMessage: { (ortc:OrtcClient!, channel:String!, msg:String!) -> Void in
        
       })
    }
    
    func onDisconnected(ortc: OrtcClient!) {
        NSLog("did disconnect")
    }
    
    func onException(ortc: OrtcClient!, error: NSError!) {
        NSLog("onException: %@", error.localizedDescription)
    }
    
    func onReconnected(ortc: OrtcClient!) {
        
    }
    
    func onReconnecting(ortc: OrtcClient!) {
        
    }
    
    func onSubscribed(ortc: OrtcClient!, channel: String!) {
        NSLog("onSubscribed channel %@", channel)
        self.ortc!.disconnect()
    }
    
    func onUnsubscribed(ortc: OrtcClient!, channel: String!) {
         NSLog("onUnsubscribed channel %@", channel)
    }

}
