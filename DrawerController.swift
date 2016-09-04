//
//  DrawerController.swift
//  DrawerTest
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//

import Cocoa

class DrawerController: NSObject, NSDrawerDelegate {
    @IBOutlet weak var drawer: NSDrawer?

    override init() {
        super.init()
    }

    @IBAction func toggleDrawer(sender: AnyObject) {
        switch NSDrawerState(rawValue: UInt(drawer!.state))! {
        case .OpeningState, .OpenState:
            drawer!.close()
        case .ClosingState, .ClosedState:
            drawer!.open()
        }
    }

}
