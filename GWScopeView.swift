//
//  GWScopeView.swift
//  HelloWorld
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//

import Cocoa

class GWScopeView: NSView {


    // MARK: Public API

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

    // Amount (generic)
    var amount: Float = 1.0 {
        didSet {
            invalidate_graph()
        }
    }
    var amount_mod_min: Float = 1.0 {
        didSet {
            invalidate_graph()
        }
    }
    var amount_mod_max: Float = 1.0 {
        didSet {
            invalidate_graph()
        }
    }

    // Graph style.
    var graph: Graph = .None {
        didSet {
            invalidate_graph()
        }
    }

    // LFO Parameters
    var lf_waveform: Waveform = .Triangle {
        didSet {
            invalidate_graph()
        }
    }
    var lf_freq_mod_min: Float = 1.0 {
        didSet {
            invalidate_graph()
        }
    }
    var lf_freq_mod_max: Float = 1.0 {
        didSet {
            invalidate_graph()
        }
    }

    // Oscillator Parameters
    static let shape_min: Float = 0.01
    static let shape_max: Float = 0.50
    static let shape_default: Float = shape_max
    var af_waveform: Waveform = .SawUp {
        didSet {
            invalidate_graph()
        }
    }
    var af_shape: Float = shape_default {
        didSet {
            invalidate_graph()
        }
    }
    var af_shape_mod_min: Float = 0.0 {
        didSet {
            invalidate_graph()
        }
    }
    var af_shape_mod_max: Float = 0.0 {
        didSet {
            invalidate_graph()
        }
    }
    var af_pitch_mod_min: Float = 1.0 {
        didSet {
            invalidate_graph()
        }
    }
    var af_pitch_mod_max: Float = 1.0 {
        didSet {
            invalidate_graph()
        }
    }


    // Filter Parameters
    var cutoff: Float = 20000 {
        didSet {
            invalidate_graph()
        }
    }

    func invalidate_graph() {
        setNeedsDisplayInRect(bounds)
    }


    // MARK: Appearance

    let PIXEL_PITCH_mm = 0.135

    let bg_color = carbon
    let graticule_color = white
    let lf_waveform_color = peacock
    let af_waveform_color = mustard
    let mod_waveform_color = peacock
    let af_spectrum_color = cherry

    let graticule_line_width: CGFloat = 0.2
    let graticule_dash_pattern: [CGFloat] = [5.0, 5.0]

    let y_height: Float = 4.0
    let primary_cycles: Float = 3.0
    let primary_h: Float = 4.0
    let mod_h: Float = 1.0


    // MARK: Implementation

    enum Curve {
        case Primary
        case Modulated(relative_freq: Float)
    }
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


    // MARK: NSView Methods

    required init?(coder: NSCoder) {

        super.init(coder: coder)

        // adjust coordinate system: move origin to center.
        let bsize = self.bounds.size
        xform.translateXBy(bsize.width / 2, yBy: bsize.height / 2)
        inverse_xform.appendTransform(xform)
        inverse_xform.invert()
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        if bg_cache == nil {
            init_bg_cache()
        }

        // draw the background and graticule.
        bg_cache!.drawInRect(dirtyRect,
                             fromRect: dirtyRect,
                             operation: .CompositeSourceOver,
                             fraction: 1.0)

        // draw the selected graph.
        switch graph {
        case .None:
            draw_no_graph()
        case .LFWaveform:
            draw_lf_graph()
        case .AudioWaveform:
            draw_audio_graph()
        case .Response:
            draw_response_graph()
        case .Envelope:
            draw_envelope_graph()
        }
    }


    // MARK: Graph Drawing

    func draw_no_graph() {
        // no graph drawn.
    }
    
    func draw_lf_graph() {
        draw_lf_waveforms()
    }

    func draw_audio_graph() {
        draw_af_waveforms()
        draw_af_spectrum()
    }
    
    func draw_response_graph() {

    }
    
    func draw_envelope_graph() {

    }


    // MARK: Waveform Drawing

    func draw_lf_waveforms() {
        if lf_freq_mod_min != 1.0 {
            draw_amt_waveforms(lf_waveform, shape: GWScopeView.shape_default, freq: lf_freq_mod_min)
        }
        if lf_freq_mod_max != 1.0 {
            draw_amt_waveforms(lf_waveform, shape: GWScopeView.shape_default, freq: lf_freq_mod_max)
        }
        if amount_mod_min != 1.0 {
            draw_mod_waveform(lf_waveform, shape: GWScopeView.shape_default, freq: 1.0, amt: amount * amount_mod_min)
        }
        if amount_mod_max != 1.0 {
            draw_mod_waveform(lf_waveform, shape: GWScopeView.shape_default, freq: 1.0, amt: amount * amount_mod_max)
        }
        draw_primary_waveform(lf_waveform, shape: GWScopeView.shape_default, color: lf_waveform_color)
    }

    func draw_af_waveforms() {
        let shape_min = max(GWScopeView.shape_min, af_shape + af_shape_mod_min)
        let shape_max = min(GWScopeView.shape_max, af_shape + af_shape_mod_max)
        if shape_min != af_shape {
            draw_af_shape_waveforms(af_waveform, shape: shape_min)
        }
        if shape_max != af_shape {
            draw_af_shape_waveforms(af_waveform, shape: shape_max)
        }
        if af_pitch_mod_min != 1.0 {
            draw_amt_waveforms(af_waveform, shape: af_shape, freq: af_pitch_mod_min)
        }
        if af_pitch_mod_max != 1.0 {
            draw_amt_waveforms(af_waveform, shape: af_shape, freq: af_pitch_mod_max)
        }
        if amount_mod_min != 1.0 {
            draw_mod_waveform(af_waveform, shape: af_shape, freq: 1.0, amt: amount * amount_mod_min)
        }
        if amount_mod_max != 1.0 {
            draw_mod_waveform(af_waveform, shape: af_shape, freq: 1.0, amt: amount * amount_mod_max)
        }
        draw_primary_waveform(af_waveform, shape: af_shape, color: af_waveform_color)
    }

    func draw_af_shape_waveforms(waveform: Waveform,
                                 shape: Float) {
        if af_pitch_mod_min != 1.0 {
            draw_amt_waveforms(waveform, shape: shape, freq: af_pitch_mod_min)
        }
        draw_amt_waveforms(waveform, shape: shape, freq: 1.0)
        if af_pitch_mod_max != 1.0 {
            draw_amt_waveforms(waveform, shape: shape, freq: af_pitch_mod_max)
        }
    }

    func draw_amt_waveforms(waveform: Waveform,
                            shape: Float,
                            freq: Float) {
        if amount_mod_min != 1.0 {
            draw_mod_waveform(waveform, shape: shape, freq: freq, amt: amount * amount_mod_min)
        }
        if amount_mod_max != 1.0 {
            draw_mod_waveform(waveform, shape: shape, freq: freq, amt: amount * amount_mod_max)
        }
        draw_mod_waveform(waveform, shape: shape, freq: freq, amt: amount)
    }

    func draw_mod_waveform(waveform: Waveform, shape: Float, freq: Float, amt: Float) {
        draw_waveform(waveform, shape: shape, freq: freq, amt: amt, color: mod_waveform_color, primary: false)
    }

    func draw_primary_waveform(waveform: Waveform,
                               shape: Float,
                               color: NSColor) {
        draw_waveform(waveform, shape: shape, freq: 1.0, amt: amount, color: color, primary: true)
    }

    func draw_waveform(waveform: Waveform,
                       shape: Float,
                       freq: Float,
                       amt: Float,
                       color: NSColor,
                       primary: Bool) {
        let curve = NSBezierPath()
        let min_i = Int(NSMinX(bounds))
        let max_i = Int(NSMaxX(bounds))
        let dot_height = primary ? primary_h : mod_h
        for i in min_i...max_i {
            if (i % 2) == 0 && !primary {
                continue
            }
            var x0 = NSPoint(x: CGFloat(i), y: 0)
            x0 = inverse_xform.transformPoint(x0)
            let sx = Float(x0.x)
            let x = freq * sx * primary_cycles / Float(bounds.width)
            let y = y_value(x, waveform: waveform, shape: shape) * amt
            let sy = y * Float(bounds.height - 10) / y_height - dot_height / 2
            let spt = NSMakePoint(CGFloat(sx), CGFloat(sy))
            curve.moveToPoint(xform.transformPoint(spt))
            curve.relativeLineToPoint(NSPoint(x:0, y:CGFloat(dot_height)))
        }
        color.set()
        curve.stroke()
    }

    func y_value(x: Float, waveform: Waveform, shape: Float) -> Float {

        let phase = x - floor(x)
        switch waveform {
        case .SawUp:
            return 2 * phase - 1
        case .SawDown:
            return -2 * phase + 1
        case .Square:
            return phase < shape ? +1 : shape / (shape - 1)
        case .Triangle:
            return y_value_triangle(phase, shape: shape)
        case .Sine:
            return sinf(phase * Float(2 * M_PI))
        case .Random:
            return y_value_random(x)
        case .SampleAndHold:
            return y_value_sample_hold(x)
        }
    }

    func y_value_triangle(phase: Float, shape: Float) -> Float {
        if phase < shape {
            let slope = 2 / shape
            return slope * phase - 1
        } else {
            let slope = -2 / (1 - shape)
            return slope * (phase - shape) + 1
        }
    }

    func y_value_random(x: Float) -> Float {

        func bigrand(n: Int, b: Int) -> Int {
            if n != 0 {
                return Int(Int64(bigrand(n - 1, b: b)) * 48271 % 0x7fffffff)
            } else {
                return b
            }
        }

        func random(n: Int, b: Int) -> Float {
            return Float(bigrand(n, b: b) % 23) / 23.0
        }

        func rand_noise(x: Float, b: Int) -> Float {
            let a = random(Int(x + 100), b: b)
            let b = random(Int(x + 100) + 1, b: b)
            return (a + (x-floor(x)) * (b - a)) * 2 - 1
        }

        return rand_noise(x, b: 9)
    }

    func y_value_sample_hold(x: Float) -> Float {
        return y_value_random(floor(x))
    }


    // MARK: Waveform Drawing

    func draw_af_spectrum() {
    }


    // MARK: Background Drawing

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
        ax_path.lineWidth = graticule_line_width
        ax_path.moveToPoint(NSMakePoint(min.x, origin.y))
        ax_path.lineToPoint(NSMakePoint(max.x, origin.y))
        ax_path.moveToPoint(NSMakePoint(origin.x, min.y))
        ax_path.lineToPoint(NSMakePoint(origin.x, max.y))
        ax_path.stroke()

        let lines_path = NSBezierPath()
        lines_path.lineWidth = graticule_line_width
        lines_path.setLineDash(graticule_dash_pattern, count: 2, phase: 0)

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
        parent_color.getHue(&pch,
                            saturation: &pcs,
                            brightness: &pcb,
                            alpha: nil)
        pch *= 360;             // convert to degrees
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
