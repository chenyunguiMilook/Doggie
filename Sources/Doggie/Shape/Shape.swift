//
//  Shape.swift
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

public struct Shape : RandomAccessCollection, MutableCollection, ExpressibleByArrayLiteral {
    
    public typealias Indices = CountableRange<Int>
    
    public typealias Index = Int
    
    fileprivate class Cache {
        
        var originalBoundary: Rect?
        var boundary: Rect?
        var identity : Shape?
        
        var area: Double?
        
        var table: [String : Any]
        
        init() {
            self.originalBoundary = nil
            self.boundary = nil
            self.identity = nil
            self.area = nil
            self.table = [:]
        }
        init(originalBoundary: Rect?, boundary: Rect?, table: [String : Any]) {
            self.originalBoundary = originalBoundary
            self.boundary = boundary
            self.identity = nil
            self.area = nil
            self.table = table
        }
    }
    
    public enum Segment {
        
        case line(Point)
        case quad(Point, Point)
        case cubic(Point, Point, Point)
    }
    
    public struct Component {
        
        public var start: Point
        public var isClosed: Bool
        
        fileprivate var segments: [Segment]
        
        fileprivate var cache = Shape.Component.Cache()
        
        public init() {
            self.start = Point()
            self.isClosed = false
            self.segments = []
        }
        
        public init<S : Sequence>(start: Point, closed: Bool = false, segments: S) where S.Iterator.Element == Segment {
            self.start = start
            self.isClosed = closed
            self.segments = Array(segments)
        }
    }
    
    fileprivate var cache = Cache()
    fileprivate var components: [Component]
    
    public var baseTransform : SDTransform = SDTransform(SDTransform.Identity()) {
        willSet {
            if baseTransform != newValue {
                cache = Cache(originalBoundary: cache.originalBoundary, boundary: nil, table: cache.table)
            }
        }
    }
    
    public var rotate: Double = 0 {
        willSet {
            if rotate != newValue {
                cache = Cache(originalBoundary: cache.originalBoundary, boundary: nil, table: cache.table)
            }
        }
    }
    public var scale: Double = 1 {
        didSet {
            if scale != oldValue {
                let boundary = cache.boundary
                let center = self.center
                let _scale = self.scale / oldValue
                cache = Cache(originalBoundary: cache.originalBoundary, boundary: boundary.map { Rect.bound($0.points.map { ($0 - center) * _scale + center }) }, table: cache.table)
            }
        }
    }
    public var transform : SDTransform {
        get {
            let center = self.center
            let translate = SDTransform.Translate(x: center.x, y: center.y)
            let scale = SDTransform.Scale(self.scale)
            let rotate = SDTransform.Rotate(self.rotate)
            return baseTransform * translate.inverse * scale * rotate * translate
        }
        set {
            let center = originalBoundary.center * newValue
            let translate = SDTransform.Translate(x: center.x, y: center.y)
            let scale = SDTransform.Scale(self.scale)
            let rotate = SDTransform.Rotate(self.rotate)
            baseTransform = newValue * translate.inverse * rotate.inverse * scale.inverse * translate
        }
    }
    
    public init() {
        self.components = []
    }
    
    public init(arrayLiteral elements: Component ...) {
        self.components = elements
    }
    
    public init(_ elements: Component ...) {
        self.components = elements
    }
    
    public init<S : Sequence>(_ components: S) where S.Iterator.Element == Component {
        self.components = Array(components)
    }
    
    public var center : Point {
        get {
            return originalBoundary.center * baseTransform
        }
        set {
            let _center = center
            if _center != newValue {
                var boundary = cache.boundary
                let offset = newValue - _center
                boundary?.origin += offset
                baseTransform *= SDTransform.Translate(x: offset.x, y: offset.y)
                cache = Cache(originalBoundary: cache.originalBoundary, boundary: boundary, table: cache.table)
            }
        }
    }
    
    public subscript(position : Int) -> Component {
        get {
            return components[position]
        }
        set {
            cache = Cache()
            components[position] = newValue
        }
    }
    
    public var startIndex: Int {
        return components.startIndex
    }
    
    public var endIndex: Int {
        return components.endIndex
    }
    
    public var boundary : Rect {
        if cache.boundary == nil {
            cache.boundary = identity.originalBoundary
        }
        return cache.boundary!
    }
    
    public var originalBoundary : Rect {
        if cache.originalBoundary == nil {
            cache.originalBoundary = self.components.reduce(nil) { $0?.union($1.boundary) ?? $1.boundary } ?? Rect()
        }
        return cache.originalBoundary!
    }
    
    public var frame : [Point] {
        let _transform = self.transform
        return originalBoundary.points.map { $0 * _transform }
    }
}

extension Shape.Component {
    
    fileprivate class Cache {
        
        var spaces: RectCollection?
        var boundary: Rect?
        var area: Double?
        
        init() {
            self.spaces = nil
            self.boundary = nil
            self.area = nil
        }
    }
    
}

extension Shape.Component {
    
    public var spaces : RectCollection {
        if cache.spaces == nil {
            var lastPoint = start
            var bounds: [Rect] = []
            for segment in segments {
                switch segment {
                case let .line(p1):
                    bounds.append(Rect.bound([lastPoint, p1]))
                    lastPoint = p1
                case let .quad(p1, p2):
                    bounds.append(Bezier(lastPoint, p1, p2).boundary)
                    lastPoint = p2
                case let .cubic(p1, p2, p3):
                    bounds.append(Bezier(lastPoint, p1, p2, p3).boundary)
                    lastPoint = p3
                }
            }
            cache.spaces = RectCollection(bounds)
        }
        return cache.spaces!
    }
    
    public var boundary : Rect {
        if cache.boundary == nil {
            var lastPoint = start
            var bound: Rect? = nil
            for segment in segments {
                switch segment {
                case let .line(p1):
                    bound = bound?.union(Rect.bound([lastPoint, p1])) ?? Rect.bound([lastPoint, p1])
                    lastPoint = p1
                case let .quad(p1, p2):
                    bound = bound?.union(Bezier(lastPoint, p1, p2).boundary) ?? Bezier(lastPoint, p1, p2).boundary
                    lastPoint = p2
                case let .cubic(p1, p2, p3):
                    bound = bound?.union(Bezier(lastPoint, p1, p2, p3).boundary) ?? Bezier(lastPoint, p1, p2, p3).boundary
                    lastPoint = p3
                }
            }
            cache.boundary = bound ?? Rect()
        }
        return cache.boundary!
    }
}

extension Shape.Component {
    
    public var area: Double {
        if cache.area == nil {
            var lastPoint = start
            var _area: Double = 0
            for segment in segments {
                switch segment {
                case let .line(p1):
                    _area += Bezier(lastPoint, p1).area
                    lastPoint = p1
                case let .quad(p1, p2):
                    _area += Bezier(lastPoint, p1, p2).area
                    lastPoint = p2
                case let .cubic(p1, p2, p3):
                    _area += Bezier(lastPoint, p1, p2, p3).area
                    lastPoint = p3
                }
            }
            cache.area = _area
        }
        return cache.area!
    }
}

extension Shape.Component : RandomAccessCollection, MutableCollection {
    
    public typealias Indices = CountableRange<Int>
    
    public typealias Index = Int
    
    public var startIndex: Int {
        return segments.startIndex
    }
    
    public var endIndex: Int {
        return segments.endIndex
    }
    
    public subscript(position : Int) -> Shape.Segment {
        get {
            return segments[position]
        }
        set {
            cache = Cache()
            segments[position] = newValue
        }
    }
}

extension Shape.Component : RangeReplaceableCollection {
    
    public mutating func append(_ x: Shape.Segment) {
        cache = Cache()
        segments.append(x)
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        segments.reserveCapacity(minimumCapacity)
    }
    
    public mutating func removeAll(keepingCapacity: Bool = false) {
        cache = Cache()
        segments.removeAll(keepingCapacity: keepingCapacity)
    }
    
    public mutating func replaceSubrange<C : Collection>(_ subRange: Range<Int>, with newElements: C) where C.Iterator.Element == Shape.Segment {
        cache = Cache()
        segments.replaceSubrange(subRange, with: newElements)
    }
}

extension Shape {
    
    public static func Rectangle(origin: Point, size: Size) -> Shape {
        return Rectangle(Rect(origin: origin, size: size))
    }
    public static func Rectangle(x: Double, y: Double, width: Double, height: Double) -> Shape {
        return Rectangle(Rect(x: x, y: y, width: width, height: height))
    }
    public static func Rectangle(_ rect: Rect) -> Shape {
        let points = rect.points
        return [Component(start: points[0], closed: true, segments: [.line(points[1]), .line(points[2]), .line(points[3])])]
    }
}

extension Shape {
    
    public static func Ellipse(_ rect: Rect) -> Shape {
        return Ellipse(center: rect.center, radius: Radius(x: 0.5 * rect.width, y: 0.5 * rect.height))
    }
    public static func Ellipse(center: Point, radius: Double) -> Shape {
        return Ellipse(center: center, radius: Radius(x: radius, y: radius))
    }
    public static func Ellipse(center: Point, radius: Radius) -> Shape {
        let scale = SDTransform.Scale(x: radius.x, y: radius.y)
        let points = BezierCircle.lazy.map { $0 * scale + center }
        let segments: [Shape.Segment] = [.cubic(points[1], points[2], points[3]), .cubic(points[4], points[5], points[6]), .cubic(points[7], points[8], points[9]), .cubic(points[10], points[11], points[12])]
        return [Component(start: points[0], closed: true, segments: segments)]
    }
    public static func Ellipse(x: Double, y: Double, radius: Double) -> Shape {
        return Ellipse(center: Point(x: x, y: y), radius: Radius(x: radius, y: radius))
    }
    public static func Ellipse(x: Double, y: Double, rx: Double, ry: Double) -> Shape {
        return Ellipse(center: Point(x: x, y: y), radius: Radius(x: rx, y: ry))
    }
    
}

extension Shape {
    
    public var originalArea : Double {
        if cache.area == nil {
            cache.area = self.components.reduce(0) { $0 + $1.area }
        }
        return cache.area!
    }
    
    public var area: Double {
        return identity.originalArea
    }
}

extension Shape {
    
    @_transparent
    var cacheTable: [String: Any] {
        get {
            return cache.table
        }
        nonmutating set {
            cache.table = newValue
        }
    }
}

extension Shape : RangeReplaceableCollection {
    
    public mutating func append(_ x: Component) {
        cache = Cache()
        components.append(x)
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        components.reserveCapacity(minimumCapacity)
    }
    
    public mutating func removeAll(keepingCapacity: Bool = false) {
        cache = Cache()
        components.removeAll(keepingCapacity: keepingCapacity)
    }
    
    public mutating func replaceSubrange<C : Collection>(_ subRange: Range<Int>, with newElements: C) where C.Iterator.Element == Component {
        cache = Cache()
        components.replaceSubrange(subRange, with: newElements)
    }
}

extension Shape {
    
    public var identity : Shape {
        if rotate == 0 && scale == 1 && baseTransform == SDTransform.Identity() {
            return self
        }
        if cache.identity == nil {
            let transform = self.transform
            if transform == SDTransform.Identity() {
                let _path = Shape(self.components)
                _path.cache.originalBoundary = cache.originalBoundary
                _path.cache.boundary = cache.boundary
                _path.cache.area = cache.area
                cache.identity = _path
            } else {
                cache.identity = Shape(self.components.map { $0 * transform })
            }
        }
        return cache.identity!
    }
}

public func * <T: SDTransformProtocol>(lhs: Shape.Component, rhs: T) -> Shape.Component {
    return Shape.Component(start: lhs.start * rhs, closed: lhs.isClosed, segments: lhs.segments.map {
        switch $0 {
        case let .line(p1): return .line(p1 * rhs)
        case let .quad(p1, p2): return .quad(p1 * rhs, p2 * rhs)
        case let .cubic(p1, p2, p3): return .cubic(p1 * rhs, p2 * rhs, p3 * rhs)
        }
    })
}
public func *= <T: SDTransformProtocol>(lhs: inout Shape.Component, rhs: T) {
    lhs = lhs * rhs
}
