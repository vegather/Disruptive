//
//  GraphView.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 30/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import UIKit

public class LineGraphView: UIView, GraphTooltipViewDelegate {
    
    public var separatorColor = UIColor.black {
        didSet { setNeedsDisplay() }
    }
    
    public var yAxisGutterWidth: CGFloat = 30 {
        didSet {
            // When the width of the y-gutter changes, we need
            // to update the constraints of our tooltip view
            tooltipViewRightConstraint.constant = -yAxisGutterWidth
            setNeedsDisplay()
        }
    }
    
    public var yAxisGutterFont: UIFont = .systemFont(ofSize: 12) {
        didSet { setNeedsDisplay() }
    }
    
    /// Represents the duration of the graph (in the x-axis). The end of the graph
    /// will always be "now" (`Date()`), and the start will be "now - graphDuration".
    public var graphDuration: TimeInterval = 1
    
    private(set) public var tooltipView: GraphTooltipView!
    
    
    
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
        
        addSubviews()
    }
    
    private func addSubviews() {
        tooltipView = GraphTooltipView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        tooltipView.delegate = self
        tooltipView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tooltipView)
        
        tooltipView.leftAnchor  .constraint(equalTo: leftAnchor)  .isActive = true
        tooltipView.topAnchor   .constraint(equalTo: topAnchor)   .isActive = true
        tooltipView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // Keeping track of the right constraint because we need to update
        // it if the `yAxisGutterWidth` changes.
        tooltipViewRightConstraint = tooltipView.rightAnchor.constraint(equalTo: rightAnchor, constant: -yAxisGutterWidth)
        tooltipViewRightConstraint.isActive = true
    }
    
    
    
    
    // -------------------------------
    // MARK: Private Structs
    // -------------------------------
    
    private struct Sample {
        let value: CGFloat
        let timestamp: Date
    }
    
    private struct DataSeries {
        let lineColor: UIColor
        let samples: [Sample]
    }
    
    private struct GraphData {
        let series: [DataSeries] // Supports multiple series
        let maxValue: CGFloat
        let minValue: CGFloat
    }
    
    
    
    // -------------------------------
    // MARK: Private State
    // -------------------------------
    
    /// Constraint on the right side of the tooltip view to compensate
    /// for the y-axis gutter.
    private var tooltipViewRightConstraint: NSLayoutConstraint!
    
    private var graphData: GraphData? {
        didSet { setNeedsDisplay() }
    }
    
    /// Sections where it was determined that the device was disconnected
    private var disconnectPeriods: [(start: Date, end: Date)] = [] {
        didSet { setNeedsDisplay() }
    }
    
    // Used as the start and end of the x-axis. These will be
    // updated when the graphDuration or the data to present changes.
    private var graphStart: TimeInterval = 0
    private var graphEnd  : TimeInterval = 1
    
    // Used for the tooltip
    private var valueName = "Value"
    private var unit = ""
    
    private var disconnectPeriodBackgroundColor: UIColor {
        if case .dark = traitCollection.userInterfaceStyle {
            return UIColor(white: 0.20, alpha: 1)
        } else {
            return UIColor(white: 0.90, alpha: 1)
        }
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
            samples.append(Sample(value: CGFloat(event.value), timestamp: event.timestamp))
        }
        
        let series = DataSeries(lineColor: lineColor, samples: samples)
        
        graphData = GraphData(
            series     : [series],
            maxValue   : CGFloat(maxValue),
            minValue   : CGFloat(minValue)
        )
        
        // Used for the tooltip
        valueName = "Temp"
        unit = "°C"
    }
    
    /// Disconnect periods are defined as any time period between two timestamps
    /// that is more than 50% of the median of timestamps. Meaning that if any sample
    /// is missing (which is 100% of the median), that will count as a disconnect period,
    /// but there is still leeway left in for variations in the heartbeat.
    public func plotDisconnectPeriods(from timestamps: [Date]) {
        // Ensures there are at least 20 timestamps before attempting
        // to determine disconnect periods
        guard timestamps.count >= 20 else { return }
        
        let intervals = stride(from: 1, to: timestamps.count, by: 1).map {
            Float(timestamps[$0-1].timeIntervalSince(timestamps[$0]))
        }
        let median = TimeInterval(intervals.median())
        
        var periods = [(start: Date, end: Date)]()
        
        for i in stride(from: 1, to: timestamps.count, by: 1) {
            let duration = timestamps[i-1].timeIntervalSince(timestamps[i])
            if duration > median * 1.5 {
                periods.append((timestamps[i], timestamps[i-1]))
            }
        }
        
        disconnectPeriods = periods
    }
    
    
    
    // -------------------------------
    // MARK: Tooltip Delegate
    // -------------------------------
    
    func tooltip(forTouchPoint point: CGPoint) -> Tooltip {
        
        // Make sure there is data samples
        guard let graphData = graphData,
              let samples = graphData.series.first?.samples, samples.count > 0
        else {
            return Tooltip(
                samplePoint: CGPoint(x: point.x, y: point.y),
                estimatedSize: CGSize(width: 130, height: 50),
                title: "-",
                subtitle: "-"
            )
        }
        
        let graphWidth = bounds.width - yAxisGutterWidth
        let timeIntervalForTouch = TimeInterval(point.x / graphWidth) * graphDuration + graphStart
        
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMdHHmm") // Will be "31 May, 19:11" in Norwegian locale
        
        // Check first if the tooltip is in the middle of a disconnect period
        let tooltipDate = Date(timeIntervalSince1970: timeIntervalForTouch)
        for period in disconnectPeriods {
            
            // Checks the following:
            // 1. If the tooltip is right on a disconnect period
            // 2. If the tooltip is after the latest sample, AND there is a disconnect period that ends after the latest sample.
            // 3. If the tooltip is before the earliest sample, AND there is a disconnect period that starts before the earliest sample.
            if (tooltipDate > period.start && tooltipDate < period.end) ||
                (tooltipDate > samples.first!.timestamp && period.end > samples.first!.timestamp) ||
                (tooltipDate < samples.last!.timestamp && period.start < samples.last!.timestamp)
            {
                let duration = period.end.timeIntervalSince(period.start)
                
                // Determine the duration string
                let durationString: String
                if      duration < 3600  { durationString = "\(Int((duration / 60)   .rounded())) mins"}
                else if duration < 86400 { durationString = "\(Int((duration / 3600) .rounded())) hours" }
                else                     { durationString = "\(Int((duration / 86400).rounded())) days" }
                                
                return Tooltip(
                    samplePoint: point,
                    estimatedSize: CGSize(width: 160, height: 50),
                    title: "Offline: \(durationString)",
                    subtitle: "\(formatter.string(from: period.start)) - \(formatter.string(from: period.end))"
                )
            }
        }
        
        // The tooltip is for a normal sample, figure out which
        
        var sample = samples.last!
        
        for s in samples {
            if s.timestamp.timeIntervalSince1970 < timeIntervalForTouch {
                sample = s
                break
            }
        }
        
        let samplePoint = createPoints(for: [sample])[0]
        
        return Tooltip(
            samplePoint : CGPoint(x: samplePoint.x, y: point.y),
            estimatedSize: CGSize(width: 130, height: 50),
            title       : String(format: "\(valueName): %.2f \(unit)", sample.value),
            subtitle    : "Time: " + formatter.string(from: sample.timestamp)
        )
    }
    
    
    
    
    // -------------------------------
    // MARK: Drawing
    // -------------------------------
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Ensures the graph start and end are up to date right
        // before we start drawing
        updateStartAndEnd()
        
        let start = CACurrentMediaTime()
        
        // No point in doing any drawing without the graph data
        guard let graphData = graphData else { return }
        
        graphData.series.forEach { drawSeries($0) }
        drawDisconnectPeriods()
        drawYGutter()
        
        let end = CACurrentMediaTime()
        
        DTLog(String(format: "Drew graph in %.2f ms", (end - start) * 1000))
    }
    
    private func drawSeries(_ serie: DataSeries) {
        let path = UIBezierPath()
        path.lineWidth = 3
        path.lineJoinStyle = .round
        serie.lineColor.setStroke()
                
        for point in createPoints(for: serie.samples) {
           if path.isEmpty {
               path.move(to: point)
           } else {
               path.addLine(to: point)
           }
        }

        path.stroke()
    }
    
    private func drawDisconnectPeriods() {
        for period in disconnectPeriods {
            // Abusing the graph drawing function helper to get the x coordinates
            let xCoordinates = createPoints(for: [
                Sample(value: 0, timestamp: period.start),
                Sample(value: 0, timestamp: period.end)
            ]).map { $0.x }
            
            disconnectPeriodBackgroundColor.setFill()
            let rect = CGRect(
                x: xCoordinates[0],
                y: 0,
                width: xCoordinates[1] - xCoordinates[0],
                height: bounds.height
            )
            let box = UIBezierPath(rect: rect)
            box.fill()
        }
    }
    
    public func drawYGutter() {
        guard let graphData = graphData else { return }
        let (upperBound, lowerBound, dy) = getYProperties(graphData: graphData)
        
        // Set stroke color (for both separator and tickmarks)
        separatorColor.setStroke()

        // Draw separator
        let separator = UIBezierPath()
        separator.lineWidth = 1 / UIScreen.main.nativeScale
        separator.move(to: CGPoint(x: bounds.width - yAxisGutterWidth, y: 0))
        separator.addLine(to: CGPoint(x: bounds.width - yAxisGutterWidth, y: bounds.height))
        separator.stroke()
        
        // Determine divisor for tickmarks. This will be used as a modulo
        // so we limit the number of tickmarks if the range is greater.
        let range = upperBound - lowerBound
        let divisor: Int
        switch range {
            case   ..<10: divisor = 1  // Range is 0  to 10, tickmarks: 10, 11, 12, 13...
            case 10..<20: divisor = 2  // Range is 10 to 20, tickmarks: 10, 12, 14, 16...
            case 20..<60: divisor = 5  // Range is 20 to 60, tickmarks: 10, 15, 20, 25...
            default:      divisor = 10 // Range is above 60, tickmarks: 10, 20, 30, 40...
        }
        
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
    
    
    
    // -------------------------------
    // MARK: Helpers
    // -------------------------------
    
    /// The y properties (upperBound, lowerBound, and dy) are used in multiple places,
    /// so this is a slightly less cumbersome (but still cumbersome) way to achieve that.
    private func getYProperties(graphData: GraphData) -> (upperBound: CGFloat, lowerBound: CGFloat, dy: CGFloat) {
        let range = graphData.maxValue - graphData.minValue
        let upperBound = graphData.maxValue + range * 0.1
        let lowerBound = graphData.minValue - range * 0.1
        
        let dy = bounds.height / (upperBound - lowerBound)
        
        return (upperBound, lowerBound, dy)
    }
    
    private func createPoints(for samples: [Sample]) -> [CGPoint] {
        guard let graphData = graphData else { return [] }
        
        // Calculate the delta x
        let graphWidth = bounds.width - yAxisGutterWidth
        let dx = graphWidth / CGFloat(graphDuration) //CGFloat(Date().timeIntervalSince(graphData.startTime))
        
        let (_, lowerBound, dy) = getYProperties(graphData: graphData)
        
        return samples.map {
            CGPoint(
                x: CGFloat($0.timestamp.timeIntervalSince1970 - graphStart) * dx,
                y: bounds.height - ($0.value - lowerBound) * dy
            )
        }
    }
    
    private func updateStartAndEnd() {
        graphEnd = Date().timeIntervalSince1970
        graphStart = graphEnd - graphDuration
    }
    
}
