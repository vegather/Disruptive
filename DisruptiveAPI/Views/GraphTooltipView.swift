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
    let estimatedSize: CGSize
    let title: String
    let subtitle: String
}

internal protocol GraphTooltipViewDelegate: class {
    
    /// Returns a tooltip for the sample that is closest to the specified x position
    func tooltip(forTouchPoint point: CGPoint) -> Tooltip
}

public class GraphTooltipView: UIView {
    
    public var titleFont = UIFont.boldSystemFont(ofSize: 14) {
        didSet { setNeedsDisplay() }
    }
    public var subtitleFont = UIFont.systemFont(ofSize: 10) {
        didSet { setNeedsDisplay() }
    }
    public var titleFontColor = UIColor.white {
        didSet { setNeedsDisplay() }
    }
    public var subtitleFontColor = UIColor(white: 0.9, alpha: 1) {
        didSet { setNeedsDisplay() }
    }

    internal weak var delegate: GraphTooltipViewDelegate?
    
    /// The point to render the tooltip for. Nil if the tooltip is currently inactive
    private var currentTouchPos: CGPoint?
    
    /// Color to use for the background box of the tooltip
    private var tooltipbackgroundColor: UIColor {
        return UIColor(white: 0.18, alpha: 0.92)
    }
            
    /// Specifies the horizontal position of the tooltip in relation to the users finger
    private enum HorizontalPosition {
        case left
        case right
    }
    private var horizontalPos = HorizontalPosition.right
    
    
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
        
        setNeedsDisplay()
    }
    
    
    
    // -------------------------------
    // MARK: Tooltip Positioning
    // -------------------------------
    
    private func updateTooltipPositions(forTouchPoint point: CGPoint, size: CGSize) {
        switch horizontalPos {
            case .left:
                if point.x < size.width + 4 {
                    horizontalPos = .right
                }
            case .right:
                if point.x > bounds.width - (size.width + 4) {
                    horizontalPos = .left
                }
        }
    }
    
    private func createTooltipFrame(forTouchPoint point: CGPoint, size: CGSize) -> CGRect {
        var tooltipFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        // Update x-position
        switch horizontalPos {
            case .left  : tooltipFrame.origin.x = point.x - size.width - 4
            case .right : tooltipFrame.origin.x = point.x + 4
        }
        
        // Update y-position
        let minY = CGFloat(0)
        let maxY = bounds.height - size.height
        let defaultY = point.y - size.height - 30
        tooltipFrame.origin.y = max(minY, min(defaultY, maxY))
        
        return tooltipFrame
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
        guard let tooltip = delegate?.tooltip(forTouchPoint: currentTouchPos) else { return }
        
        UIColor.secondaryLabel.setStroke()
        
        // Draw the vertical selection line
        drawVerticalLine(at: tooltip.samplePoint.x)
        
        // Update the tooltip position
        updateTooltipPositions(forTouchPoint: tooltip.samplePoint, size: tooltip.estimatedSize)
        
        // Draw the tooltip
        let tooltipFrame = createTooltipFrame(forTouchPoint: tooltip.samplePoint, size: tooltip.estimatedSize)
        drawTooltipBackground(in: tooltipFrame)
        drawTooltipText(in: tooltipFrame, title: tooltip.title, subtitle: tooltip.subtitle)
    }
    
    private func drawVerticalLine(at xPos: CGFloat) {
        let line = UIBezierPath()
        line.move   (to: CGPoint(x: xPos, y: 0))
        line.addLine(to: CGPoint(x: xPos, y: bounds.height))
        line.stroke()
    }
    
    private func drawTooltipBackground(in rect: CGRect) {
        tooltipbackgroundColor.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 8).fill()
    }
    
    private func drawTooltipText(in rect: CGRect, title: String, subtitle: String) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: titleFontColor
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: subtitleFontColor
        ]
        
        let titlePoint    = CGPoint(x: rect.origin.x + 8, y: rect.origin.y + 6)
        let subtitlePoint = CGPoint(x: rect.origin.x + 8, y: rect.origin.y + 26)
        
        NSString(string: title)   .draw(at: titlePoint,    withAttributes: titleAttributes)
        NSString(string: subtitle).draw(at: subtitlePoint, withAttributes: subtitleAttributes)
    }
}
