//
//  GWScreenSimView.swift
//  DrawerTest
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//

import Cocoa

class GWScreenSimView: NSView {

    let bg_color = midnight

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
        bg_color.set()
        NSRectFill(dirtyRect)
    }
    
}
