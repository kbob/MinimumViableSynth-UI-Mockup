//
//  GWScopeController.swift
//  DrawerTest
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//

import Cocoa

class GWScopeController: NSObject, NSTabViewDelegate {
    @IBOutlet weak var view: GWScopeView?
    @IBOutlet weak var tabView: NSTabView?

    func tabView(sender: NSTabView,
                 didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        if let label = tabViewItem?.label {
            if label == "None" {
                view!.graph = .None
            } else if label == "LFO" {
                view!.graph = .LFWaveform
            } else if label == "??" {

            }
        } else {
            view!.graph = .None
        }
    }
    
}
