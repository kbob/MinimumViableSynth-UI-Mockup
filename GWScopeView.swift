//
//  GWScopeView.swift
//  HelloWorld
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//

import Cocoa

class GWScopeView: NSView {

    // Public API

    enum Graph {
        case None
        case LFWaveform
        case AudioWaveform
        case Response
        case Envelope
    }

    enum Waveform {
        case SawUp
        case SawDown
        case Square
        case Triangle
        case Sine
        case Random
        case SampleAndHold
    }

    enum FilterType {
        case None
        case LowPass
        case HighPass
        case BandPass
        case BandReject
    }

    // Graph style.
    var graph: Graph = .None {
        didSet {
            invalidate_graph()
        }
    }

    // Filter graph: cutoff frequency
    var cutoff: Float = 20000 {
        didSet {
            invalidate_graph()
        }
    }

    // Appearance

    let PIXEL_PITCH_mm = 0.135
    let bg_color = HSB_color(0, s: 0, b: 0.25)
    let graticule_color = HSBA_color(0, s: 0, b: 1, a: 0.80)

    // Implementation

    let xform = NSAffineTransform()
    var inverse_xform = NSAffineTransform()
    var bg_cache: NSImage?


    // graph style:
    //      none,
    //      LF waveform,
    //      audio waveform + spectrum,
    //      response,
    //      envelope

    // primary waveform: (waveform, shape)
    // waveform modulation: (negative, positive)

    // spectrum: harmonics (5? 8? 10?)

    // response: (Fc, Q, Type)

    // envelope: (amount, Atime, Dtime, Slevel, Rtime)

    required init?(coder: NSCoder) {

        super.init(coder: coder)

        // adjust coordinate system: move origin to center.
        let bsize = self.bounds.size
        xform.translateXBy(bsize.width / 2, yBy: bsize.height / 2)
        inverse_xform.appendTransform(xform)
        inverse_xform.invert()
    }

    func invalidate_graph() {
        setNeedsDisplayInRect(frame)
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        // Drawing code here.
        if bg_cache == nil {
            init_bg_cache()
        }

        bg_cache!.drawInRect(dirtyRect,
                             fromRect: dirtyRect,
                             operation: .CompositeSourceOver,
                             fraction: 1.0)
    }

    func init_bg_cache() {

        var bgc = NSImage(size: bounds.size)
        bgc.lockFocus()
        defer {
            bgc.unlockFocus()
        }

        // fill the background
        bg_color.set()
        NSRectFill(bounds)

        // draw the graticule
        draw_graticule(bgc)

        // draw the bevel
        draw_bevel(bgc)

        bg_cache = bgc
    }

    func draw_graticule(bgc: NSImage) {


        graticule_color.set()

        // push scope coordinates
        let cm: Int = Int(10 / PIXEL_PITCH_mm + 0.5);
        let cgc = NSGraphicsContext.currentContext()!
        cgc.saveGraphicsState()
        defer {
            cgc.restoreGraphicsState()
        }
        xform.concat()

        let origin = NSMakePoint(0, 0)
        let min = inverse_xform.transformPoint(bounds.origin)
        let max = inverse_xform.transformPoint(NSMakePoint(NSMaxX(bounds),
                                                           NSMaxY(bounds)))

        // axes.
        let ax_path = NSBezierPath()
        ax_path.lineWidth = 0.25
        ax_path.moveToPoint(NSMakePoint(min.x, origin.y))
        ax_path.lineToPoint(NSMakePoint(max.x, origin.y))
        ax_path.moveToPoint(NSMakePoint(origin.x, min.y))
        ax_path.lineToPoint(NSMakePoint(origin.x, max.y))
        ax_path.stroke()

        let lines_path = NSBezierPath()
        lines_path.lineWidth = 0.25
        let dash_pattern: [CGFloat] = [5.0, 5.0]
        lines_path.setLineDash(dash_pattern, count: 2, phase: 0)

        // horizontal lines.  start at center, work left.
        let min_i: Int = Int(min.y) / cm
        let max_i: Int = (Int(max.y) + cm - 1) / cm
        for i in min_i ... max_i {
            let y = CGFloat(i * cm)
            if y != 0 {
                lines_path.moveToPoint(NSMakePoint(min.x, y))
                lines_path.lineToPoint(NSMakePoint(max.x, y))
            }
        }
        
        // vertical lines.  start at center, work left.
        let min_j: Int = Int(min.x) / cm
        let max_j: Int = (Int(max.x) + cm - 1) / cm
        for j in min_j ... max_j {
            let x = CGFloat(j * cm)
            if x != 0 {
                lines_path.moveToPoint(NSMakePoint(x, min.y))
                lines_path.lineToPoint(NSMakePoint(x, max.y))
            }
        }

        lines_path.stroke()
    }

    func draw_bevel(bgc: NSImage) {

        // compute bevel colors
        let parent_color = (superview as! GWScreenSimView).bg_color
        var pch: CGFloat = 0, pcs: CGFloat = 0, pcb: CGFloat = 0
        var bch: CGFloat = 0, bcs: CGFloat = 0, bcb: CGFloat = 0
        parent_color.getHue(&pch,
                            saturation: &pcs,
                            brightness: &pcb,
                            alpha: nil)
        bg_color.getHue(&bch, saturation: &bcs, brightness: &bcb, alpha: nil)
        pch *= 360;             // convert to degrees
        bch *= 360;
        let bevel_light = HSB_color(pch, s: pcs, b: pcb + 0.2)
        let bevel_dark = HSB_color(pch, s: pcs, b: pcb * 0.8)
        let bevel_shadow = HSBA_color(0, s: 0, b: 0, a: 0.3)

        // bounds
        let min_x = bounds.origin.x
        let min_y = bounds.origin.y
        let max_x = min_x + bounds.size.width - 1
        let max_y = min_y + bounds.size.height - 1

        // bevel: shadow below the top, left
        var hline_rect = NSRect(x: min_x,
                                y: max_y - 1,
                                width: bounds.width,
                                height: 100)
        var vline_rect = NSRect(x: min_x + 1,
                                y: min_y,
                                width: 1,
                                height: bounds.height)
        bevel_shadow.set()
        NSRectFill(hline_rect)
        NSRectFill(vline_rect)

        // bevel: dark along the top, left
        hline_rect.origin.y = max_y
        hline_rect.size.height = 1
        vline_rect.origin.x = min_x
        vline_rect.size.width = 1
        bevel_dark.set()
        NSRectFill(hline_rect)
        NSRectFill(vline_rect)

        // bevel: light along the bottom, right
        hline_rect.origin.y = min_y
        vline_rect.origin.x = max_x
        bevel_light.set()
        NSRectFill(hline_rect)
        NSRectFill(vline_rect)
    }

}
