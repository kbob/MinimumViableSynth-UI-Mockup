//
//  ColorUtil.swift
//  DrawerTest
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//

import Cocoa

public func HSB_color(h: CGFloat, s: CGFloat, b: CGFloat) -> NSColor {
    return NSColor(deviceHue: h/360, saturation: s, brightness: b, alpha: 1.0)
}

public func HSBA_color(h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)
    -> NSColor {
    return NSColor(deviceHue: h/360, saturation: s, brightness: b, alpha: a)
}