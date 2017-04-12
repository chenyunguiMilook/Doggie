//
//  Geometry.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2017 Susan Cheng. All rights reserved.
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

@_inlineable
public func CircleInside(_ p0: Point, _ p1: Point, _ p2: Point, _ q: Point) -> Bool? {
    
    func det(_ x0: Double, _ y0: Double, _ z0: Double,
             _ x1: Double, _ y1: Double, _ z1: Double,
             _ x2: Double, _ y2: Double, _ z2: Double) -> Double {
        
        return x0 * y1 * z2 +
            y0 * z1 * x2 +
            z0 * x1 * y2 -
            z0 * y1 * x2 -
            y0 * x1 * z2 -
            x0 * z1 * y2
    }
    
    let s = dot(q, q)
    
    let r = det(p0.x - q.x, p0.y - q.y, dot(p0, p0) - s,
                p1.x - q.x, p1.y - q.y, dot(p1, p1) - s,
                p2.x - q.x, p2.y - q.y, dot(p2, p2) - s)
    
    return r.almostZero() ? nil : r.sign == cross(p1 - p0, p2 - p0).sign
}

@_inlineable
public func Barycentric(_ p0: Point, _ p1: Point, _ p2: Point, _ q: Point) -> Vector? {
    
    let det = (p1.y - p2.y) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.y - p2.y)
    
    if det.almostZero() {
        return nil
    }
    
    let s = ((p1.y - p2.y) * (q.x - p2.x) + (p2.x - p1.x) * (q.y - p2.y)) / det
    let t = ((p2.y - p0.y) * (q.x - p2.x) + (p0.x - p2.x) * (q.y - p2.y)) / det
    
    return Vector(x: s, y: t, z: 1 - s - t)
}
        