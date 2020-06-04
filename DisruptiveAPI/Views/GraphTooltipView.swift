//
//  GraphTooltipView.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 04/06/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import UIKit

internal struct Tooltip {
    let samplePoint: CGPoint
    let title: String
    let subtitle: String
}

internal protocol GraphTooltipViewDelegate: class {
    
    /// Returns a tooltip for the sample that is closest to the specified x position
    func tooltip(forXPosition: CGFloat) -> Tooltip
}

public class GraphTooltipView: UIView {
    
    public var titleFont: UIFont?
    public var subtitleFont: UIFont?
    
    internal weak var delegate: GraphTooltipViewDelegate?
    
    private var currentTouchPos: CGPoint? {
        didSet { setNeedsDisplay() }
    }
    
    
    // -------------------------------
    // MARK: Setup
    // -------------------------------
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        
        // Add gesture recognizer to recognize a long press
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPressRecognizer)
    }
    
    
    // -------------------------------
    // MARK: Action
    // -------------------------------
    
    @objc private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
            case .began:
                // When the long press begins, do a haptic feedback
                let feedback = UIImpactFeedbackGenerator(style: .heavy)
                feedback.impactOccurred()
            
                // We want to show the tooltip as soon as the recognizer begins
                fallthrough
            case .changed:
                let pos = recognizer.location(in: self)
                currentTouchPos = pos
            default:
                currentTouchPos = nil
        }
    }
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard var currentTouchPos = currentTouchPos else { return }
        
        // Make sure the current touch position is constrained by the
        // bounds of the tooltip view
        if currentTouchPos.x < 0 { currentTouchPos.x = 0 }
        if currentTouchPos.x > bounds.width { currentTouchPos.x = bounds.width }
        
        // Get the tooltip from our delegate
        guard let tooltip = delegate?.tooltip(forXPosition: currentTouchPos.x) else { return }
        
        UIColor.secondaryLabel.setStroke()
        
        // Draw the vertical selection line
        let line = UIBezierPath()
        line.move   (to: CGPoint(x: tooltip.samplePoint.x, y: 0))
        line.addLine(to: CGPoint(x: tooltip.samplePoint.x, y: bounds.height))
        line.stroke()
    }
}
