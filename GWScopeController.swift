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

    let amount_default: Float = 1.0
    let amount_mod_min_default: Float = 1.0
    let amount_mod_max_default: Float = 1.0
    let graph_default: GWScopeView.Graph = .None

    let lf_waveform_default: GWScopeView.Waveform = .Triangle
    let lf_freq_mod_min_default: Float = 1.0
    let lf_freq_mod_max_default: Float = 1.0

    let af_waveform_default: GWScopeView.Waveform = .SawUp
    let af_shape_default: Float = GWScopeView.shape_default
    let af_shape_mod_min_default: Float = 0.0
    let af_shape_mod_max_default: Float = 0.0
    let af_pitch_mod_min_default: Float = 1.0
    let af_pitch_mod_max_default: Float = 1.0

    override init() {
        if view != nil {
            view!.amount = amount_default
            view!.amount_mod_min = amount_mod_min_default
            view!.amount_mod_max = amount_mod_max_default
            view!.graph = graph_default

            view!.lf_waveform = lf_waveform_default
            view!.lf_freq_mod_min = lf_freq_mod_min_default
            view!.lf_freq_mod_max = lf_freq_mod_max_default

            view!.af_waveform = af_waveform_default
            view!.af_shape = af_shape_default
            view!.af_shape_mod_min = af_shape_mod_min_default
            view!.af_shape_mod_max = af_shape_mod_max_default
            view!.af_pitch_mod_min = af_pitch_mod_min_default
            view!.af_pitch_mod_max = af_pitch_mod_max_default
        }
    }

    @IBAction func set_amount(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.amount = ctl.floatValue / 100
        }
    }

    @IBAction func set_amount_mod_min(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.amount_mod_min = 1 - (ctl.floatValue / 100) * 0.75
        }
    }

    @IBAction func set_amount_mod_max(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.amount_mod_max = 1 + ctl.floatValue / 100 * 2
        }
    }

    func tabView(sender: NSTabView,
                 didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        if let label = tabViewItem?.label {
            if label == "None" {
                view!.graph = .None
            } else if label == "LFO" {
                view!.graph = .LFWaveform
            } else if label == "Oscillator" {
                view!.graph = .AudioWaveform
            } else if label == "Filter" {
                view!.graph = .Response
            } else if label == "Envelope" {
                view!.graph = .Envelope
            } else {
                view!.graph = .None
            }
        } else {
            view!.graph = .None
        }
    }

    @IBAction func set_lf_waveform(sender: AnyObject) {
        if let button = sender as? NSButton {
            let title = button.title
            if title == "Triangle" {
                view!.lf_waveform = .Triangle
            } else if title == "Saw Up" {
                view!.lf_waveform = .SawUp
            } else if title == "Saw Down" {
                view!.lf_waveform = .SawDown
            } else if title == "Square" {
                view!.lf_waveform = .Square
            } else if title == "Random" {
                view!.lf_waveform = .Random
            } else if title == "Sample/Hold" {
                view!.lf_waveform = .SampleAndHold
            }
        }
    }

    @IBAction func set_lf_freq_mod_min(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.lf_freq_mod_min = 1 - (ctl.floatValue / 100) * 0.75
        }
    }

    @IBAction func set_lf_freq_mod_max(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.lf_freq_mod_max = 1 + ctl.floatValue / 100 * 2
        }
    }

    @IBAction func set_af_waveform(sender: AnyObject) {
        if let button = sender as? NSButton {
            let title = button.title
            if title == "Sawtooth" {
                view!.af_waveform = .SawUp
            } else if title == "Square" {
                view!.af_waveform = .Square
            } else if title == "Triangle" {
                view!.af_waveform = .Triangle
            } else if title == "Sine" {
                view!.af_waveform = .Sine
            }
        }
    }

    @IBAction func set_af_shape(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            let min = GWScopeView.shape_min
            let max = GWScopeView.shape_max
            let frac = ctl.floatValue / 100
            view!.af_shape = min + frac * (max - min)
        }
    }

    @IBAction func set_af_shape_mod_min(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.af_shape_mod_min = -0.49 * (ctl.floatValue / 100)
        }
    }

    @IBAction func set_af_shape_mod_max(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.af_shape_mod_max = +0.49 * (ctl.floatValue / 100)
        }
    }

    @IBAction func set_af_pitch_mod_min(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.af_pitch_mod_min = 1 - (ctl.floatValue / 100) * 0.75
        }
    }

    @IBAction func set_af_pitch_mod_max(sender: AnyObject) {
        if let ctl = sender as? NSControl {
            view!.af_pitch_mod_max = 1 + ctl.floatValue / 100 * 2
        }
    }

}
