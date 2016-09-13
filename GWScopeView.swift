//
//  GWScopeView.swift
//  HelloWorld
//
//  Created by Bob Miller on 9/2/16.
//  Copyright © 2016 kbobsoft.com. All rights reserved.
//


// MARK: Grumpy Wizards' 'Scope View

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
    let shape_default: Float = GWScopeView.shape_default
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
    // TBD

    // Envelope Parameters
    var env_attack: Float = 0.5 {
        didSet {
            invalidate_graph()
        }
    }
    var env_decay: Float = 0.5 {
        didSet {
            invalidate_graph()
        }
    }
    var env_sustain: Float = 0.5 {
        didSet {
            invalidate_graph()
        }
    }
    var env_release: Float = 0.5 {
        didSet {
            invalidate_graph()
        }
    }

    func invalidate_graph() {
        setNeedsDisplayInRect(bounds)
    }


    // MARK: Appearance

    let PIXEL_PITCH_mm = 0.135

    let bg_color           = carbon
    let graticule_color    = white
    let lf_waveform_color  = peacock
    let af_waveform_color  = mustard
    let mod_waveform_color = peacock
    let af_spectrum_color  = cherry
    let mod_spectrum_color = magenta
    let env_fill_color     = grape
    let env_stroke_color   = peacock

    let y_range: Float = 4.0
    let primary_cycles: Float = 3.0
    let primary_h: Float = 4.0
    let mod_h: Float = 1.0

    static let sp_harmonic_count: UInt = 10
    let sp_harmonic_count: UInt = GWScopeView.sp_harmonic_count
    let sp_db_floor: Float = -40
    let sp_primary_spike_width: CGFloat = 2.0
    let sp_secondary_spike_width: CGFloat = 1.0

    let graticule_line_width: CGFloat = 0.2
    let graticule_dash_pattern: [CGFloat] = [5.0, 5.0]


    // MARK: Implementation

    enum Curve {
        case Primary
        case Modulated(relative_freq: Float)
    }
    let co_xform      = NSAffineTransform()   // center origin
    var co_inv_xform  = NSAffineTransform()
    var sp_xform      = NSAffineTransform()  // bottom-left origin
    var env_xform     = NSAffineTransform()
    var env_inv_xform = NSAffineTransform()
    var bg_cache: NSImage?


    // MARK: NSView Methods

    required init?(coder: NSCoder) {

        super.init(coder: coder)

        let bsize = bounds.size

        // create waveform coordinate system: move origin to center.
        do {
            co_xform.translateXBy(bsize.width / 2, yBy: bsize.height / 2)
            co_inv_xform.appendTransform(co_xform)
            co_inv_xform.invert()
        }

        // create spectrum coordinate system: origin off the bottom left
        do {
            let xoffset = -bsize.width / CGFloat(sp_harmonic_count) / 2
            let yoffset = bsize.height / 2
            let xscale = bsize.width / CGFloat(sp_harmonic_count)
            let yscale = bsize.height / CGFloat(fabsf(sp_db_floor)) / 2
            sp_xform.translateXBy(xoffset, yBy: yoffset)
            sp_xform.scaleXBy(xscale, yBy: yscale)
        }

        // create envelope coordinate system: origin at center left
        do {
            let xoffset = CGFloat(0)
            let yoffset = bsize.height / 2
            let xscale = bsize.width / 3
            let yscale = bsize.height / 2
            env_xform.translateXBy(xoffset, yBy: yoffset)
            env_xform.scaleXBy(xscale, yBy: yscale)
            env_inv_xform.appendTransform(env_xform)
            env_inv_xform.invert()
        }
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
        draw_af_spectrum()
        draw_af_waveforms()
    }
    
    func draw_response_graph() {
        let pt_size: CGFloat = 48
        let font = NSFont(name: "Lato Light", size: pt_size)!
        let str = "Bob hasn't figured this out yet."
        let att = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: cherry]
        let mystring = NSMutableAttributedString(string: str, attributes: att)
        mystring.setAlignment(NSCenterTextAlignment,
                              range: NSRange(location: 0,
                                             length: mystring.length))

        mystring.drawInRect(self.bounds)
    }

    func draw_envelope_graph() {

        let env_amt = amount * 2 - 1
        func env_point(x: Float, _ y: Float) -> NSPoint {
            return env_xform.transformPoint(NSMakePoint(CGFloat(x),
                CGFloat(env_amt * y)))
        }

        let env = NSBezierPath()

        let x0 = Float(0),         y0 = Float(0)
        let x1 = env_attack,       y1 = Float(1)
        let x2 = x1 + env_decay,   y2 = env_sustain
        let x3 = Float(2),         y3 = env_sustain
        let x4 = x3 + env_release, y4 = Float(0)
        let x5 = Float(3),         y5 = Float(0)

        env.moveToPoint(env_point(x0, y0))
        env.lineToPoint(env_point(x1, y1))
        env.lineToPoint(env_point(x2, y2))
        env.lineToPoint(env_point(x3, y3))
        env.lineToPoint(env_point(x4, y4))
        env.lineToPoint(env_point(x5, y5))
//        env.lineToPoint(env_point(x4, -y4))
//        env.lineToPoint(env_point(x3, -y3))
//        env.lineToPoint(env_point(x2, -y2))
//        env.lineToPoint(env_point(x1, -y1))
//        env.lineToPoint(env_point(x0, -y0))

//        env_fill_color.set()
//        env.fill()
        env_stroke_color.set()
        env.stroke()
    }


    // MARK: Waveform Drawing

    func draw_lf_waveforms() {
        if lf_freq_mod_min != 1.0 {
            draw_amt_waveforms(lf_waveform,
                               shape: shape_default,
                               freq: lf_freq_mod_min)
        }
        if lf_freq_mod_max != 1.0 {
            draw_amt_waveforms(lf_waveform,
                               shape: shape_default,
                               freq: lf_freq_mod_max)
        }
        if amount_mod_min != 1.0 {
            draw_mod_waveform(lf_waveform,
                              shape: shape_default,
                              freq: 1.0,
                              amt: amount * amount_mod_min)
        }
        if amount_mod_max != 1.0 {
            draw_mod_waveform(lf_waveform,
                              shape: shape_default,
                              freq: 1.0,
                              amt: amount * amount_mod_max)
        }
        draw_primary_waveform(lf_waveform,
                              shape: shape_default,
                              color: lf_waveform_color)
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
            draw_amt_waveforms(af_waveform,
                               shape: af_shape,
                               freq: af_pitch_mod_min)
        }
        if af_pitch_mod_max != 1.0 {
            draw_amt_waveforms(af_waveform,
                               shape: af_shape,
                               freq: af_pitch_mod_max)
        }
        if amount_mod_min != 1.0 {
            draw_mod_waveform(af_waveform,
                              shape: af_shape,
                              freq: 1.0,
                              amt: amount * amount_mod_min)
        }
        if amount_mod_max != 1.0 {
            draw_mod_waveform(af_waveform,
                              shape: af_shape,
                              freq: 1.0,
                              amt: amount * amount_mod_max)
        }
        draw_primary_waveform(af_waveform,
                              shape: af_shape,
                              color: af_waveform_color)
    }

    func draw_af_shape_waveforms(waveform: Waveform, shape: Float) {
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
            draw_mod_waveform(waveform,
                              shape: shape,
                              freq: freq, amt: amount * amount_mod_min)
        }
        if amount_mod_max != 1.0 {
            draw_mod_waveform(waveform,
                              shape: shape,
                              freq: freq,
                              amt: amount * amount_mod_max)
        }
        draw_mod_waveform(waveform, shape: shape, freq: freq, amt: amount)
    }

    func draw_mod_waveform(waveform: Waveform,
                           shape: Float,
                           freq: Float,
                           amt: Float) {
        draw_waveform(waveform,
                      shape: shape,
                      freq: freq,
                      amt: amt,
                      color: mod_waveform_color,
                      primary: false)
    }

    func draw_primary_waveform(waveform: Waveform,
                               shape: Float,
                               color: NSColor) {
        draw_waveform(waveform,
                      shape: shape,
                      freq: 1.0,
                      amt: amount,
                      color: color,
                      primary: true)
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
            x0 = co_inv_xform.transformPoint(x0)
            let sx = Float(x0.x)
            let x = freq * sx * primary_cycles / Float(bounds.width)
            let y = y_value(x, waveform: waveform, shape: shape) * amt
            let sy = y * Float(bounds.height - 10) / y_range - dot_height / 2
            let spt = NSMakePoint(CGFloat(sx), CGFloat(sy))
            curve.moveToPoint(co_xform.transformPoint(spt))
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


    // MARK: Spectrum Drawing

    func draw_af_spectrum() {
        let shape_min = max(GWScopeView.shape_min, af_shape + af_shape_mod_min)
        let shape_max = min(GWScopeView.shape_max, af_shape + af_shape_mod_max)
        if shape_min != af_shape {
            draw_af_shape_spectra(af_waveform, shape: shape_min)
        }
        if shape_max != af_shape {
            draw_af_shape_spectra(af_waveform, shape: shape_max)
        }
        if af_pitch_mod_min != 1.0 {
            draw_amt_spectra(af_waveform,
                             shape: af_shape,
                             freq: af_pitch_mod_min)
        }
        if af_pitch_mod_max != 1.0 {
            draw_amt_spectra(af_waveform,
                             shape: af_shape,
                             freq: af_pitch_mod_max)
        }
        // skip amount_mod_min -- it is behind other spikes.
        if amount_mod_max != 1.0 {
            draw_mod_spectrum(af_waveform,
                              shape: af_shape,
                              freq: 1.0,
                              amt: amount * amount_mod_max)
        }
        draw_primary_spectrum(af_waveform,
                              shape: af_shape,
                              color: af_spectrum_color)
    }

    func draw_af_shape_spectra(waveform: Waveform, shape: Float) {
        if af_pitch_mod_min != 1.0 {
            draw_amt_spectra(waveform, shape: shape, freq: af_pitch_mod_min)
        }
        draw_amt_spectra(waveform, shape: shape, freq: 1.0)
        if af_pitch_mod_max != 1.0 {
            draw_amt_spectra(waveform, shape: shape, freq: af_pitch_mod_max)
        }
    }

    func draw_amt_spectra(waveform: Waveform, shape: Float, freq: Float) {
        // skip amount_mod_min -- it is behind other spikes.
        if amount_mod_max != 1.0 {
            draw_mod_spectrum(waveform,
                              shape: shape,
                              freq: freq,
                              amt: amount * amount_mod_max)
        }
        draw_mod_spectrum(waveform, shape: shape, freq: freq, amt: amount)
    }

    func draw_mod_spectrum(waveform: Waveform,
                           shape: Float,
                           freq: Float,
                           amt: Float) {
        draw_spectrum(waveform,
                      shape: shape,
                      freq: freq,
                      amt: amt,
                      color: mod_spectrum_color,
                      primary: false)
    }

    func draw_primary_spectrum(waveform: Waveform,
                               shape: Float,
                               color: NSColor)
    {
        draw_spectrum(waveform,
                      shape: shape,
                      freq: 1.0,
                      amt: amount,
                      color: af_spectrum_color,
                      primary: true)
    }

    func draw_spectrum(waveform: Waveform,
                       shape: Float,
                       freq: Float,
                       amt: Float,
                       color: NSColor,
                       primary: Bool) {

        func sp_point(x: Float, _ y: Float) -> NSPoint {
            return sp_xform.transformPoint(NSMakePoint(CGFloat(x), CGFloat(y)))
        }

        let spikes_curve = NSBezierPath()
        if primary {

            // draw baseline.
            let bl_curve = NSBezierPath()
            let x0 = Float(1)
            let x1 = Float(sp_harmonic_count + 1)
            let y = sp_db_floor
            let p0 = sp_point(x0, y)
            let p1 = sp_point(x1, y)
            bl_curve.moveToPoint(p0)
            bl_curve.lineToPoint(p1)
            color.set()
            bl_curve.stroke()

            // Make spikes thick
            spikes_curve.lineWidth = sp_primary_spike_width
        } else {
            spikes_curve.lineWidth = sp_secondary_spike_width
        }

        // draw harmonic spikes.
        var h: UInt = 0
        let x_limit = Float(sp_harmonic_count) + 0.5
        while true {
            h += 1
            let x = freq * Float(h)
            if x > x_limit {
                break
            }
            let mag = amt * harmonic_magnitude(waveform,
                                               shape: shape,
                                               harmonic: h)
            let y0 = Float(sp_db_floor)
            let y1 = 20 * log10(mag)
            let p0 = sp_point(x, y0)
            let p1 = sp_point(x, y1)
            spikes_curve.moveToPoint(p0)
            spikes_curve.lineToPoint(p1)
        }

        color.set()
        spikes_curve.stroke()
    }

    func harmonic_magnitude(waveform: Waveform,
                            shape: Float,
                            harmonic: UInt)
        -> Float {
            let hf = Float(harmonic)
            switch waveform {
            case .SawUp:
                return 1 / hf
            case .Square:
                return 1 / hf * abs(sinf(Float(M_PI) * hf * shape))
            case .Triangle:
                return 1 / (hf * hf) * abs(sinf(Float(M_PI) * hf * shape))
            case .Sine:
                return harmonic == 1 ? 1 : powf(10, sp_db_floor / 20)
            default:
                return 0
            }
    }


    // MARK: Static Background Drawing

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
        co_xform.concat()

        let origin = NSMakePoint(0, 0)
        let min = co_inv_xform.transformPoint(bounds.origin)
        let max = co_inv_xform.transformPoint(NSMakePoint(NSMaxX(bounds),
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
