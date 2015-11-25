//
//  Point.swift
//
//  The MIT License
//  Copyright (c) 2015 Susan Cheng. All rights reserved.
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

public struct Point {
    
    public var x: Double
    public var y: Double
    
    public init() {
        self.x = 0
        self.y = 0
    }
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    public init(x: Int, y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }
}

extension Point {
    
    public func offset(dx dx: Double, dy: Double) -> Point {
        return Point(x: self.x + dx, y: self.x + dy)
    }
}

extension Point: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "{x: \(x), y: \(y)}"
    }
    public var debugDescription: String {
        return "{x: \(x), y: \(y)}"
    }
}

extension Point: Hashable {
    
    public var hashValue: Int {
        return hash(x, y)
    }
}

public func == (lhs: Point, rhs: Point) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

public func middle(p: Point ... ) -> Point {
    let count = Double(p.count)
    var _x = 0.0
    var _y = 0.0
    for point in p {
        _x += point.x
        _y += point.y
    }
    return Point(x: _x / count, y: _y / count)
}
public func distance(lhs: Point, _ rhs: Point) -> Double {
    let dx = lhs.x - rhs.x
    let dy = lhs.y - rhs.y
    return sqrt(fma(dx, dx, dy * dy))
}
public func direction(lhs: Point, _ rhs:  Point) -> Double {
    return fma(lhs.x, rhs.y, -lhs.y * rhs.x)
}
public func direction(a: Point, _ b: Point, _ c: Point) -> Double {
    return direction(b - a, c - a)
}

public prefix func +(val: Point) -> Point {
    return val
}
public prefix func -(val: Point) -> Point {
    return Point(x: -val.x, y: -val.y)
}
public func + (lhs : Point, rhs : Point) -> Point {
    return Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func - (lhs : Point, rhs : Point) -> Point {
    return Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func += (inout lhs : Point, rhs : Point) {
    lhs.x += rhs.x
    lhs.y += rhs.y
}

public func -= (inout lhs : Point, rhs : Point) {
    lhs.x -= rhs.x
    lhs.y -= rhs.y
}
