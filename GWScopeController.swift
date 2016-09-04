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

    let graph_default: GWScopeView.Graph = .None
    let lf_waveform_default: GWScopeView.Waveform = .Triangle

    override init() {
        if view != nil {
            view!.graph = graph_default
            view!.lf_waveform = lf_waveform_default
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
            } else if label == "Response" {
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
    
}
