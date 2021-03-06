//
//  Rect.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2019 Susan Cheng. All rights reserved.
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

@_fixed_layout
public struct Size: Hashable {
    
    public var width: Double
    public var height: Double
    
    @inlinable
    @inline(__always)
    public init() {
        self.width = 0
        self.height = 0
    }
    
    @inlinable
    @inline(__always)
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    @inlinable
    @inline(__always)
    public init(width: Int, height: Int) {
        self.width = Double(width)
        self.height = Double(height)
    }
}

extension Size: CustomStringConvertible {
    
    @inlinable
    @inline(__always)
    public var description: String {
        return "Size(width: \(width), height: \(height))"
    }
}

extension Size : Codable {
    
    @inlinable
    @inline(__always)
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.width = try container.decode(Double.self)
        self.height = try container.decode(Double.self)
    }
    
    @inlinable
    @inline(__always)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
    }
}

extension Size {
    
    @inlinable
    @inline(__always)
    public func aspectFit(_ bound: Size) -> Size {
        let u = width * bound.height
        let v = bound.width * height
        if u < v {
            return Size(width: u / height, height: bound.height)
        } else {
            return Size(width: bound.width, height: v / width)
        }
    }
    
    @inlinable
    @inline(__always)
    public func aspectFill(_ bound: Size) -> Size {
        let u = width * bound.height
        let v = bound.width * height
        if u < v {
            return Size(width: bound.width, height: v / width)
        } else {
            return Size(width: u / height, height: bound.height)
        }
    }
}

extension Size : ScalarMultiplicative {
    
    public typealias Scalar = Double
    
    @inlinable
    @inline(__always)
    public static var zero: Size {
        return Size()
    }
}

@inlinable
@inline(__always)
public prefix func +(val: Size) -> Size {
    return val
}
@inlinable
@inline(__always)
public prefix func -(val: Size) -> Size {
    return Size(width: -val.width, height: -val.height)
}
@inlinable
@inline(__always)
public func +(lhs: Size, rhs: Size) -> Size {
    return Size(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}
@inlinable
@inline(__always)
public func -(lhs: Size, rhs: Size) -> Size {
    return Size(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

@inlinable
@inline(__always)
public func *(lhs: Double, rhs: Size) -> Size {
    return Size(width: lhs * rhs.width, height: lhs * rhs.height)
}
@inlinable
@inline(__always)
public func *(lhs: Size, rhs: Double) -> Size {
    return Size(width: lhs.width * rhs, height: lhs.height * rhs)
}

@inlinable
@inline(__always)
public func /(lhs: Size, rhs: Double) -> Size {
    return Size(width: lhs.width / rhs, height: lhs.height / rhs)
}

@inlinable
@inline(__always)
public func *= (lhs: inout Size, rhs: Double) {
    lhs.width *= rhs
    lhs.height *= rhs
}
@inlinable
@inline(__always)
public func /= (lhs: inout Size, rhs: Double) {
    lhs.width /= rhs
    lhs.height /= rhs
}
@inlinable
@inline(__always)
public func += (lhs: inout Size, rhs: Size) {
    lhs.width += rhs.width
    lhs.height += rhs.height
}
@inlinable
@inline(__always)
public func -= (lhs: inout Size, rhs: Size) {
    lhs.width -= rhs.width
    lhs.height -= rhs.height
}

@_fixed_layout
public struct Rect: Hashable {
    
    public var origin : Point
    public var size : Size
    
    @inlinable
    @inline(__always)
    public init() {
        self.origin = Point()
        self.size = Size()
    }
    
    @inlinable
    @inline(__always)
    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
    
    @inlinable
    @inline(__always)
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
    
    @inlinable
    @inline(__always)
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
}

extension Rect: CustomStringConvertible {
    
    @inlinable
    @inline(__always)
    public var description: String {
        return "Rect(x: \(x), y: \(y), width: \(width), height: \(height))"
    }
}

extension Rect : Codable {
    
    @inlinable
    @inline(__always)
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.origin = try container.decode(Point.self)
        self.size = try container.decode(Size.self)
    }
    
    @inlinable
    @inline(__always)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(origin)
        try container.encode(size)
    }
}

extension Rect {
    
    @inlinable
    @inline(__always)
    public var x : Double {
        get {
            return origin.x
        }
        set {
            origin.x = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    public var y : Double {
        get {
            return origin.y
        }
        set {
            origin.y = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    public var width : Double {
        get {
            return size.width
        }
        set {
            size.width = newValue
        }
    }
    
    @inlinable
    @inline(__always)
    public var height : Double {
        get {
            return size.height
        }
        set {
            size.height = newValue
        }
    }
}

extension Rect {
    
    @inlinable
    @inline(__always)
    public var minX : Double {
        return width < 0 ? x + width : x
    }
    @inlinable
    @inline(__always)
    public var minY : Double {
        return height < 0 ? y + height : y
    }
    @inlinable
    @inline(__always)
    public var maxX : Double {
        return width < 0 ? x : x + width
    }
    @inlinable
    @inline(__always)
    public var maxY : Double {
        return height < 0 ? y : y + height
    }
    @inlinable
    @inline(__always)
    public var midX : Double {
        get {
            return 0.5 * width + x
        }
        set {
            x = newValue - 0.5 * width
        }
    }
    @inlinable
    @inline(__always)
    public var midY : Double {
        get {
            return 0.5 * height + y
        }
        set {
            y = newValue - 0.5 * height
        }
    }
    @inlinable
    @inline(__always)
    public var center : Point {
        get {
            return Point(x: midX, y: midY)
        }
        set {
            midX = newValue.x
            midY = newValue.y
        }
    }
}

extension Rect {
    
    @inlinable
    @inline(__always)
    public var standardized: Rect {
        return Rect(x: minX, y: minY, width: abs(width), height: abs(height))
    }
}

extension Rect {
    
    @inlinable
    @inline(__always)
    public func aspectFit(bound: Rect) -> Rect {
        var rect = Rect(origin: Point(), size: self.size.aspectFit(bound.size))
        rect.center = bound.center
        return rect
    }
    
    @inlinable
    @inline(__always)
    public func aspectFill(bound: Rect) -> Rect {
        var rect = Rect(origin: Point(), size: self.size.aspectFill(bound.size))
        rect.center = bound.center
        return rect
    }
}

extension Rect {
    
    @inlinable
    @inline(__always)
    public var points : [Point] {
        let minX = self.minX
        let maxX = self.maxX
        let minY = self.minY
        let maxY = self.maxY
        let a = Point(x: maxX, y: minY)
        let b = Point(x: maxX, y: maxY)
        let c = Point(x: minX, y: maxY)
        let d = Point(x: minX, y: minY)
        return [a, b, c, d]
    }
    
    @inlinable
    @inline(__always)
    public static func bound<S : Sequence>(_ points: S) -> Rect where S.Element == Point {
        
        var minX = 0.0
        var maxX = 0.0
        var minY = 0.0
        var maxY = 0.0
        
        for (i, p) in points.enumerated() {
            if i == 0 {
                minX = p.x
                maxX = p.x
                minY = p.y
                maxY = p.y
            } else {
                minX = min(minX, p.x)
                maxX = max(maxX, p.x)
                minY = min(minY, p.y)
                maxY = max(maxY, p.y)
            }
        }
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension Rect {
    
    @inlinable
    @inline(__always)
    public func union(_ other : Rect) -> Rect {
        let minX = min(self.minX, other.minX)
        let minY = min(self.minY, other.minY)
        let maxX = max(self.maxX, other.maxX)
        let maxY = max(self.maxY, other.maxY)
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    @inlinable
    @inline(__always)
    public func intersect(_ other : Rect) -> Rect {
        let minX = max(self.minX, other.minX)
        let minY = max(self.minY, other.minY)
        let _width = max(0, min(self.maxX, other.maxX) - minX)
        let _height = max(0, min(self.maxY, other.maxY) - minY)
        return Rect(x: minX, y: minY, width: _width, height: _height)
    }
    @inlinable
    @inline(__always)
    public func inset(dx: Double, dy: Double) -> Rect {
        let rect = self.standardized
        return Rect(x: rect.x + dx, y: rect.y + dy, width: rect.width - 2 * dx, height: rect.height - 2 * dy)
    }
    @inlinable
    @inline(__always)
    public func inset(top: Double, left: Double, right: Double, bottom: Double) -> Rect {
        let rect = self.standardized
        return Rect(x: rect.x + left, y: rect.y + top, width: rect.width - left - right, height: rect.height - top - bottom)
    }
    @inlinable
    @inline(__always)
    public func offset(dx: Double, dy: Double) -> Rect {
        return Rect(x: self.x + dx, y: self.y + dy, width: self.width, height: self.height)
    }
    @inlinable
    @inline(__always)
    public func contains(_ point: Point) -> Bool {
        return minX...maxX ~= point.x && minY...maxY ~= point.y
    }
    @inlinable
    @inline(__always)
    public func contains(_ rect: Rect) -> Bool {
        let a = Point(x: rect.minX, y: rect.minY)
        let b = Point(x: rect.maxX, y: rect.maxY)
        return self.contains(a) && self.contains(b)
    }
    @inlinable
    @inline(__always)
    public func isIntersect(_ rect: Rect) -> Bool {
        return self.minX < rect.maxX && self.maxX > rect.minX && self.minY < rect.maxY && self.maxY > rect.minY
    }
}

extension Rect {
    
    @inlinable
    @inline(__always)
    public func apply(_ transform: SDTransform) -> Rect? {
        
        let minX = self.minX
        let maxX = self.maxX
        let minY = self.minY
        let maxY = self.maxY
        
        let a = Point(x: maxX, y: minY) * transform
        let b = Point(x: maxX, y: maxY) * transform
        let c = Point(x: minX, y: maxY) * transform
        let d = Point(x: minX, y: minY) * transform
        
        if a.x == b.x && c.x == d.x && b.y == c.y && d.y == a.y {
            
            let minX = min(a.x, c.x)
            let maxX = max(a.x, c.x)
            let minY = min(a.y, c.y)
            let maxY = max(a.y, c.y)
            
            return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        
        if b.x == c.x && d.x == a.x && a.y == b.y && c.y == d.y {
            
            let minX = min(a.x, c.x)
            let maxX = max(a.x, c.x)
            let minY = min(a.y, c.y)
            let maxY = max(a.y, c.y)
            
            return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        
        return nil
    }
}

@inlinable
@inline(__always)
public func *(lhs: Double, rhs: Rect) -> Rect {
    return Rect(origin: lhs * rhs.origin, size: lhs * rhs.size)
}
@inlinable
@inline(__always)
public func *(lhs: Rect, rhs: Double) -> Rect {
    return Rect(origin: lhs.origin * rhs, size: lhs.size * rhs)
}

@inlinable
@inline(__always)
public func /(lhs: Rect, rhs: Double) -> Rect {
    return Rect(origin: lhs.origin / rhs, size: lhs.size / rhs)
}

@inlinable
@inline(__always)
public func *= (lhs: inout Rect, rhs: Double) {
    lhs.origin *= rhs
    lhs.size *= rhs
}
@inlinable
@inline(__always)
public func /= (lhs: inout Rect, rhs: Double) {
    lhs.origin /= rhs
    lhs.size /= rhs
}
