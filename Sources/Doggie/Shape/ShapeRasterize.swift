//
//  ShapeRasterize.swift
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

import Foundation
import Dispatch

extension Shape {
    
    public enum RenderOperation {
        case triangle(Point, Point, Point)
        case quadratic(Point, Point, Point)
        case cubic(Point, Point, Point, Vector, Vector, Vector)
    }
}

@inline(__always)
private func _cubic(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, operation: (Shape.RenderOperation) -> Void) {
    
    let q1 = 3 * (p1 - p0)
    let q2 = 3 * (p2 + p0) - 6 * p1
    let q3 = p3 - p0 + 3 * (p1 - p2)
    
    let d1 = -cross(q3, q2)
    let d2 = cross(q3, q1)
    let d3 = -cross(q2, q1)
    
    let discr = 3 * d2 * d2 - 4 * d1 * d3
    
    let area = Bezier(p0, p1, p2, p3).area + Bezier(p3, p0).area
    
    @inline(__always)
    func draw(_ k0: Vector, _ k1: Vector, _ k2: Vector, _ k3: Vector, operation: (Shape.RenderOperation) -> Void) {
        
        var v0 = k0
        var v1 = k0 + k1 / 3
        var v2 = k0 + (2 * k1 + k2) / 3
        var v3 = k0 + k1 + k2 + k3
        
        if area.sign == .minus {
            v0.x = -v0.x
            v1.x = -v1.x
            v2.x = -v2.x
            v3.x = -v3.x
            v0.y = -v0.y
            v1.y = -v1.y
            v2.y = -v2.y
            v3.y = -v3.y
        }
        
        operation(.cubic(p0, p1, p2, v0, v1, v2))
        operation(.cubic(p0, p2, p3, v0, v2, v3))
    }
    
    if d1.almostZero() {
        
        if d2.almostZero() {
            
            if !d3.almostZero(), let intersect = LinesIntersect(p0, p1, p2, p3) {
                operation(.quadratic(p0, intersect, p3))
            }
        } else {
            
            // cusp with cusp at infinity
            
            let tl = d3
            let sl = 3 * d2
            
            let tl2 = tl * tl
            let sl2 = sl * sl
            
            let k0 = Vector(x: tl, y: tl2 * tl, z: 1)
            let k1 = Vector(x: -sl, y: -3 * sl * tl2, z: 0)
            let k2 = Vector(x: 0, y: 3 * sl2 * tl, z: 0)
            let k3 = Vector(x: 0, y: -sl2 * sl, z: 0)
            
            draw(k0, k1, k2, k3, operation: operation)
        }
        
    } else {
        
        if discr.almostZero() || discr > 0 {
            
            // serpentine
            
            let delta = sqrt(Swift.max(0, discr)) / sqrt(3)
            
            let tl = d2 + delta
            let sl = 2 * d1
            let tm = d2 - delta
            let sm = 2 * d1
            
            let tl2 = tl * tl
            let sl2 = sl * sl
            let tm2 = tm * tm
            let sm2 = sm * sm
            
            var k0 = Vector(x: tl * tm, y: tl2 * tl, z: tm2 * tm)
            var k1 = Vector(x: -sm * tl - sl * tm, y: -3 * sl * tl2, z: -3 * sm * tm2)
            var k2 = Vector(x: sl * sm, y: 3 * sl2 * tl, z: 3 * sm2 * tm)
            var k3 = Vector(x: 0, y: -sl2 * sl, z: -sm2 * sm)
            
            if d1.sign == .minus {
                k0.x = -k0.x
                k1.x = -k1.x
                k2.x = -k2.x
                k3.x = -k3.x
                k0.y = -k0.y
                k1.y = -k1.y
                k2.y = -k2.y
                k3.y = -k3.y
            }
            
            draw(k0, k1, k2, k3, operation: operation)
            
        } else {
            
            // loop
            
            let delta = sqrt(-discr)
            
            let td = d2 + delta
            let sd = 2 * d1
            let te = d2 - delta
            let se = 2 * d1
            
            let td2 = td * td
            let sd2 = sd * sd
            let te2 = te * te
            let se2 = se * se
            
            var k0 = Vector(x: td * te, y: td2 * te, z: td * te2)
            var k1 = Vector(x: -se * td - sd * te, y: -se * td2 - 2 * sd * te * td, z: -sd * te2 - 2 * se * td * te)
            var k2 = Vector(x: sd * se, y: te * sd2 + 2 * se * td * sd, z: td * se2 + 2 * sd * te * se)
            var k3 = Vector(x: 0, y: -sd2 * se, z: -sd * se2)
            
            let v1x = k0.x + k1.x / 3
            if d1.sign != v1x.sign {
                k0.x = -k0.x
                k1.x = -k1.x
                k2.x = -k2.x
                k3.x = -k3.x
                k0.y = -k0.y
                k1.y = -k1.y
                k2.y = -k2.y
                k3.y = -k3.y
            }
            
            draw(k0, k1, k2, k3, operation: operation)
        }
    }
}

extension Shape.Component {
    
    public func render(_ operation: (Shape.RenderOperation) -> Void) {
        
        @inline(__always)
        func drawCubic(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, operation: (Shape.RenderOperation) -> Void) {
            
            let bezier = Bezier(p0, p1, p2, p3)
            
            if let (t1, t2) = CubicBezierSelfIntersect(p0, p1, p2, p3) {
                
                let split_t = [t1, t2].filter { !$0.almostZero() && !$0.almostEqual(1) && 0...1 ~= $0 }
                
                if split_t.count == 0 {
                    
                    _cubic(p0, p1, p2, p3, operation: operation)
                    
                } else {
                    
                    let beziers = bezier.split(split_t)
                    
                    operation(.triangle(p0, beziers.last![0], beziers.last![3]))
                    
                    beziers.forEach {
                        _cubic($0[0], $0[1], $0[2], $0[3], operation: operation)
                    }
                }
                
            } else {
                
                let inflection = bezier.inflection.filter { !$0.almostZero() && !$0.almostEqual(1) && 0...1 ~= $0 }
                
                if inflection.count == 0 {
                    
                    _cubic(p0, p1, p2, p3, operation: operation)
                    
                } else {
                    
                    var last: Point?
                    
                    for b in bezier.split(inflection) {
                        if let last = last {
                            operation(.triangle(p0, last, b[3]))
                        }
                        _cubic(b[0], b[1], b[2], b[3], operation: operation)
                        last = b[3]
                    }
                }
            }
        }
        
        if let first = self.first {
            
            var last = self.start
            
            switch first {
            case let .line(q1): last = q1
            case let .quad(q1, q2):
                operation(.quadratic(last, q1, q2))
                last = q2
            case let .cubic(q1, q2, q3):
                drawCubic(last, q1, q2, q3, operation: operation)
                last = q3
            }
            for segment in self.dropFirst() {
                switch segment {
                case let .line(q1):
                    operation(.triangle(self.start, last, q1))
                    last = q1
                case let .quad(q1, q2):
                    operation(.triangle(self.start, last, q2))
                    operation(.quadratic(last, q1, q2))
                    last = q2
                case let .cubic(q1, q2, q3):
                    operation(.triangle(self.start, last, q3))
                    drawCubic(last, q1, q2, q3, operation: operation)
                    last = q3
                }
            }
        }
    }
}

extension Shape {
    
    @_inlineable
    public func render(_ operation: (Shape.RenderOperation) -> Void) {
        
        for component in self {
            component.render(operation)
        }
    }
}
