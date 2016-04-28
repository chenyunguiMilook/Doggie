//
//  SDEllipse.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2016 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public struct SDEllipse : SDShape {
    
    public var baseTransform : SDTransform = SDTransform(SDTransform.Identity())
    
    public var rotate: Double = 0 {
        didSet {
            center = position * baseTransform * SDTransform.Scale(x: xScale, y: yScale) * SDTransform.Rotate(oldValue)
        }
    }
    public var xScale: Double = 1 {
        didSet {
            center = position * baseTransform * SDTransform.Scale(x: oldValue, y: yScale) * SDTransform.Rotate(rotate)
        }
    }
    public var yScale: Double = 1 {
        didSet {
            center = position * baseTransform * SDTransform.Scale(x: xScale, y: oldValue) * SDTransform.Rotate(rotate)
        }
    }
    
    public var x: Double
    public var y: Double
    
    public var rx: Double
    public var ry: Double
    
    @_transparent
    public var position: Point {
        get {
            return Point(x: x, y: y)
        }
        set {
            self.x = newValue.x
            self.y = newValue.y
        }
    }
    @_transparent
    public var radius: Radius {
        get {
            return Radius(x: rx, y: ry)
        }
        set {
            self.rx = newValue.x
            self.ry = newValue.y
        }
    }
    
    @_transparent
    public var boundary : Rect {
        return EllipseBound(position, radius, transform)
    }
    
    @_transparent
    public var frame : [Point] {
        let _transform = self.transform
        return Rect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry).points.map { $0 * _transform }
    }
    
    @_transparent
    public init(center: Point, radius: Double) {
        self.x = center.x
        self.y = center.y
        self.rx = radius
        self.ry = radius
    }
    
    @_transparent
    public init(x: Double, y: Double, radius: Double) {
        self.x = x
        self.y = y
        self.rx = radius
        self.ry = radius
    }
    
    @_transparent
    public init(center: Point, radius: Radius) {
        self.x = center.x
        self.y = center.y
        self.rx = radius.x
        self.ry = radius.y
    }
    
    @_transparent
    public init(x: Double, y: Double, rx: Double, ry: Double) {
        self.x = x
        self.y = y
        self.rx = rx
        self.ry = ry
    }
    
    @_transparent
    public init(inRect: Rect) {
        let center = inRect.center
        self.x = center.x
        self.y = center.y
        self.rx = inRect.width * 0.5
        self.ry = inRect.height * 0.5
    }
    
    @_transparent
    public var center : Point {
        get {
            return position * transform
        }
        set {
            position = newValue * transform.inverse
        }
    }
    
    @_transparent
    public var width : Double {
        get {
            return 2 * rx
        }
        set {
            rx = newValue * 0.5
        }
    }
    
    @_transparent
    public var height : Double {
        get {
            return 2 * ry
        }
        set {
            ry = newValue * 0.5
        }
    }
    
    @_transparent
    public var path: SDPath {
        let scale = SDTransform.Scale(x: self.radius.x, y: self.radius.y)
        let point = BezierCircle.lazy.map { $0 * scale + self.position }
        var path: SDPath = [
            SDPath.Move(point[0]),
            SDPath.CubicBezier(point[1], point[2], point[3]),
            SDPath.CubicBezier(point[4], point[5], point[6]),
            SDPath.CubicBezier(point[7], point[8], point[9]),
            SDPath.CubicBezier(point[10], point[11], point[12]),
            SDPath.ClosePath()
        ]
        path.rotate = self.rotate
        path.xScale = self.xScale
        path.yScale = self.yScale
        path.transform = self.transform
        return path
    }
}
