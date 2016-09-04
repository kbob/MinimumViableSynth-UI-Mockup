//
//  ColorUtil.swift
//  DrawerTest
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//

import Cocoa

let midnight = HSB_color(259, s:1.00, b:0.18)
let mustard  = HSB_color( 43, s:0.96, b:0.88)
let lime     = HSB_color( 79, s:0.77, b:0.91)
let magenta  = HSB_color(290, s:0.77, b:1.00)
let grape    = HSB_color(265, s:0.56, b:1.00)
let peacock  = HSB_color(192, s:1.00, b:1.00)
let cherry   = HSB_color(342, s:0.79, b:1.00)
let carbon   = HSB_color(  0, s:0.00, b:0.25)
let white    = HSB_color(  0, s:0.00, b:1.00)


func HSB_color(h: CGFloat, s: CGFloat, b: CGFloat) -> NSColor {
    return NSColor(deviceHue: h/360, saturation: s, brightness: b, alpha: 1.0)
}

func HSBA_color(h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) -> NSColor {
    return NSColor(deviceHue: h/360, saturation: s, brightness: b, alpha: a)
}