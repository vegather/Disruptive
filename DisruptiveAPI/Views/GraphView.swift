//
//  GraphView.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 30/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import UIKit

public class LineGraphView: UIView {
    
    public var separatorColor = UIColor.black {
        didSet { setNeedsDisplay() }
    }
    
    public var yAxisGutterWidth: CGFloat = 40 {
        didSet { setNeedsDisplay() }
    }
    
    public var yAxisGutterFont: UIFont = .systemFont(ofSize: 12) {
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
        isOpaque = true
        backgroundColor = .clear
        contentMode = .redraw
    }
    
    
    
    // -------------------------------
    // MARK: Private State
    // -------------------------------
    
    private var graphData: GraphData? {
        didSet { setNeedsDisplay() }
    }
    
    private struct Sample {
        let value: CGFloat
        let timestame: Date
    }
    
    private struct DataSeries {
        let lineColor: UIColor
        let samples: [Sample]
    }
    
    private struct GraphData {
        let series: [DataSeries] // Supports multiple series
        let maxValue: CGFloat
        let minValue: CGFloat
        let startTime: Date
        let endTime: Date
    }
    
    
    
    // -------------------------------
    // MARK: Public Methods
    // -------------------------------
    
    public func clear() {
        graphData = nil
    }
    
    public func plotTempEvents(_ events: [TemperatureEvent], lineColor: UIColor) {
        guard events.count > 0 else { return }
        
        var maxValue = Float.greatestFiniteMagnitude * -1
        var minValue = Float.greatestFiniteMagnitude
        var samples = [Sample]()
        
        for event in events {
            // Min min and max
            if event.value > maxValue { maxValue = event.value }
            if event.value < minValue { minValue = event.value }
            
            // Add new sample
            samples.append(Sample(value: CGFloat(event.value), timestame: event.timestamp))
        }
        
        let series = DataSeries(lineColor: lineColor, samples: samples)
        
        
        graphData = GraphData(
            series     : [series],
            maxValue   : CGFloat(maxValue),
            minValue   : CGFloat(minValue),
            startTime  : events.last! .timestamp,
            endTime    : events.first!.timestamp
        )
    }
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let start = CACurrentMediaTime()
        
        guard let graphData = graphData else { return }
        
        // The width to plot the graph in
        let graphWidth = bounds.width - yAxisGutterWidth
        
        let range = graphData.maxValue - graphData.minValue
        let upperBound = graphData.maxValue + range * 0.1
        let lowerBound = graphData.minValue - range * 0.1
        
        let dy = bounds.height / (upperBound - lowerBound)
        let dx = graphWidth / CGFloat(graphData.endTime.timeIntervalSince(graphData.startTime))
        
        for serie in graphData.series {
            
            let path = UIBezierPath()
            path.lineWidth = 3
            path.lineJoinStyle = .round
            serie.lineColor.setStroke()
                        
            for sample in serie.samples {
                let point = CGPoint(
                    x: CGFloat(sample.timestame.timeIntervalSince(graphData.startTime)) * dx,
                    y: bounds.height - (sample.value - lowerBound) * dy
                )
                
                if path.isEmpty {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            
            path.stroke()
        }
        
        drawYGutter(lowerBound: lowerBound, upperBound: upperBound, dy: dy)
        
        let end = CACurrentMediaTime()
        
        DTLog(String(format: "Drew graph in %.2f ms", (end - start) * 1000))
    }
    
    public func drawYGutter(lowerBound: CGFloat, upperBound: CGFloat, dy: CGFloat) {
        // Set stroke color (for both separator and tickmarks)
        separatorColor.setStroke()

        // Draw separator
        let separator = UIBezierPath()
        separator.lineWidth = 1 / UIScreen.main.nativeScale
        separator.move(to: CGPoint(x: bounds.width - yAxisGutterWidth, y: 0))
        separator.addLine(to: CGPoint(x: bounds.width - yAxisGutterWidth, y: bounds.height))
        separator.stroke()
        
        // Determine divisor for tickmarks
        let range = upperBound - lowerBound
        let divisor: Int
        switch range {
            case   ..<10: divisor = 1  // Range is 0  to 10, tickmarks: 10, 11, 12, 13...
            case 10..<20: divisor = 2  // Range is 10 to 20, tickmarks: 10, 12, 14, 16...
            case 20..<50: divisor = 5  // Range is 20 to 50, tickmarks: 10, 15, 20, 25...
            default:      divisor = 10 // Range is above 50, tickmarks: 10, 20, 30, 40...
        }
        
        print("upperBound: \(upperBound), lowerBound: \(lowerBound), range: \(range), divisor: \(divisor)")
        
        // Get the min and max values as Ints, so we can derive tickmarks from them
        let minInt = Int(ceil(lowerBound))
        let maxInt = Int(floor(upperBound))
        if minInt == maxInt { return } // The highest and lowest values are too close to being equal
        
        // Draw tickmarks
        for value in minInt...maxInt {
            if value % divisor == 0 {
                // The value is divisible by our divisor, so we should draw the tickmark
                
                // Determine the y-position for the tickmark
                let y = bounds.height - (CGFloat(value) - lowerBound) * dy
                
                // If the tickmark is too close to the top or bottom the
                // text will get clipped off, so don't draw it
                let fontHeight = yAxisGutterFont.lineHeight
                if y < fontHeight/2 { continue }
                if y > bounds.height - fontHeight/2 { continue }
                
                // Draw the tickmark
                let tickmarkWidth: CGFloat = 3
                let tickmark = UIBezierPath()
                tickmark.lineWidth = 1
                tickmark.move   (to: CGPoint(x: bounds.width - yAxisGutterWidth, y: y))
                tickmark.addLine(to: CGPoint(x: bounds.width - yAxisGutterWidth + tickmarkWidth, y: y))
                tickmark.stroke()
                
                // Draw text
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: yAxisGutterFont,
                    .foregroundColor: separatorColor
                ]
                let valueString = NSString(string: String(value))
                let tickmarkStringPoint = CGPoint(
                    x: bounds.width - yAxisGutterWidth + tickmarkWidth + 5,
                    y: y - fontHeight / 2
                )
                valueString.draw(at: tickmarkStringPoint, withAttributes: attributes)
            }
        }
    }
}
