//
//  ShapeRegion.swift
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

private let ShapeCacheNonZeroRegionKey = "ShapeCacheNonZeroRegionKey"
private let ShapeCacheEvenOddRegionKey = "ShapeCacheEvenOddRegionKey"

private let _boundInset: Double = -1e-8

extension RandomAccessCollection where Index : SignedInteger {
    
    fileprivate func indexMod(_ index: Index) -> Index {
        if startIndex == endIndex {
            return endIndex
        }
        let count = self.count
        let offset = numericCast(index - startIndex) % count
        return self.index(startIndex, offsetBy: offset < 0 ? offset + count : offset)
    }
}

extension Collection where SubSequence : Collection {
    
    fileprivate func rotateZip() -> Zip2Sequence<Self, ConcatCollection<Self.SubSequence, Self.SubSequence>> {
        return zip(self, self.rotated(1))
    }
}

public struct ShapeRegion {
    
    fileprivate let solids: [Solid]
    fileprivate let spacePartition: RectCollection
    
    public let boundary: Rect
    
    fileprivate let cache: Cache
    
    /// Create an empty `ShapeRegion`.
    public init() {
        self.solids = []
        self.spacePartition = RectCollection()
        self.boundary = Rect()
        self.cache = Cache()
    }
    
    public init(solid: ShapeRegion.Solid) {
        self.init(solids: CollectionOfOne(solid))
    }
    
    fileprivate init<S : Sequence>(solids: S) where S.Iterator.Element == ShapeRegion.Solid {
        let solids = solids.filter { !$0.area.almostZero() }
        self.solids = solids
        self.spacePartition = RectCollection(solids.map { $0.bigBound })
        self.boundary = solids.first.map { solids.dropFirst().reduce($0.boundary) { $0.union($1.boundary) } } ?? Rect()
        self.cache = Cache()
    }
}

extension ShapeRegion {
    
    fileprivate class Cache {
        var subtracting: [ObjectIdentifier: ShapeRegion] = [:]
        var intersection: [ObjectIdentifier: ShapeRegion] = [:]
        var union: [ObjectIdentifier: ShapeRegion] = [:]
        var symmetricDifference: [ObjectIdentifier: ShapeRegion] = [:]
    }
}

extension ShapeRegion : RandomAccessCollection {
    
    public typealias Indices = CountableRange<Int>
    
    public var startIndex : Int {
        return solids.startIndex
    }
    public var endIndex : Int {
        return solids.endIndex
    }
    
    public subscript(position: Int) -> Solid {
        return solids[position]
    }
}

extension ShapeRegion {
    
    fileprivate var cacheId: ObjectIdentifier {
        return ObjectIdentifier(cache)
    }
    
    public var area: Double {
        return solids.reduce(0) { $0 + abs($1.area) }
    }
    
    fileprivate var bigBound: Rect {
        return boundary.inset(dx: _boundInset * Swift.max(1, abs(boundary.x), abs(boundary.width)), dy: _boundInset * Swift.max(1, abs(boundary.y), abs(boundary.height)))
    }
    
    public var shape: Shape {
        let _path = Shape(solids.flatMap { $0.components.enumerated().map { $1.area.sign == ($0 == 0 ? .plus : .minus) ? $1 : $1.reversed() } })
        _path.cacheTable[ShapeCacheNonZeroRegionKey] = self
        _path.cacheTable[ShapeCacheEvenOddRegionKey] = self
        return _path
    }
}

extension ShapeRegion {
    
    public struct Solid {
        
        fileprivate let components: [Shape.Component]
        fileprivate let spacePartition: RectCollection
        
        fileprivate let cache: Cache
        
        public let boundary: Rect
        public let area: Double
        
        fileprivate init<S : Sequence>(components: S) where S.Element == Shape.Component {
            self.components = Array(components)
            self.spacePartition = RectCollection(self.components.map { $0.bigBound })
            self.cache = Cache()
            self.boundary = self.components[0].boundary
            self.area = self.components.dropFirst().reduce(abs(self.components[0].area)) { $0 - abs($1.area) }
        }
        
        fileprivate init(solid: Shape.Component) {
            self.components = [solid]
            self.spacePartition = RectCollection(self.components.map { $0.bigBound })
            self.cache = Cache()
            self.boundary = self.components[0].boundary
            self.area = self.components[0].area
        }
    }
}

extension ShapeRegion.Solid {
    
    public typealias Segment = Shape.Component.BezierCollection.Element
    
    fileprivate init?<S : Sequence>(segments: S) where S.Element == Segment {
        
        var segments = Array(segments)
        
        guard segments.count > 0 else { return nil }
        
        if !segments[0].start.almostEqual(segments.last!.end) {
            segments.append(Segment(segments.last!.end, segments[0].start))
        }
        
        self.init(solid: Shape.Component(start: segments[0].start, closed: true, segments: segments.map { $0.segment }))
    }
}

extension ShapeRegion.Solid {
    
    fileprivate class Cache {
        
        var subtracting: [ObjectIdentifier: [ShapeRegion.Solid]] = [:]
        var intersection: [ObjectIdentifier: [ShapeRegion.Solid]] = [:]
        var union: [ObjectIdentifier: ([ShapeRegion.Solid], Bool)] = [:]
        
        var reversed: ShapeRegion.Solid?
        
        var process: [ObjectIdentifier: [ShapeRegion.Solid]] = [:]
        var process_regions: [ObjectIdentifier: (ShapeRegion, ShapeRegion)] = [:]
        var intersect_table: [ObjectIdentifier: IntersectionTable] = [:]
    }
}

extension ShapeRegion.Solid {
    
    public var solid: Shape.Component {
        return components[0]
    }
    
    public var holes: ArraySlice<Shape.Component> {
        return components.dropFirst()
    }
    
    fileprivate var cacheId: ObjectIdentifier {
        return ObjectIdentifier(cache)
    }
    
    fileprivate var bigBound: Rect {
        return boundary.inset(dx: _boundInset * Swift.max(1, abs(boundary.x), abs(boundary.width)), dy: _boundInset * Swift.max(1, abs(boundary.y), abs(boundary.height)))
    }
    
    fileprivate func reversed() -> ShapeRegion.Solid {
        if cache.reversed == nil {
            if solid.area.sign == .plus {
                cache.reversed = ShapeRegion.Solid(components: self.components.enumerated().map { $1.area.sign == ($0 == 0 ? .minus : .plus) ? $1 : $1.reversed() })
            } else {
                cache.reversed = ShapeRegion.Solid(components: self.components.enumerated().map { $1.area.sign == ($0 == 0 ? .plus : .minus) ? $1 : $1.reversed() })
            }
        }
        return cache.reversed!
    }
    
    public var shape: Shape {
        let _path = Shape(self.components.enumerated().map { $1.area.sign == ($0 == 0 ? .plus : .minus) ? $1 : $1.reversed() })
        _path.cacheTable[ShapeCacheNonZeroRegionKey] = ShapeRegion(solid: self)
        _path.cacheTable[ShapeCacheEvenOddRegionKey] = ShapeRegion(solid: self)
        return _path
    }
}

extension ShapeRegion.Solid {
    
    fileprivate func union(_ other: ShapeRegion.Solid) -> ([ShapeRegion.Solid], Bool) {
        
        if !self.bigBound.isIntersect(other.bigBound) {
            return ([self, other], false)
        }
        
        if cache.union[other.cacheId] == nil && other.cache.union[cacheId] == nil {
            if let union = self._union(other) {
                let self_holes = ShapeRegion(solids: self.holes.flatMap { ShapeRegion.Solid(solid: $0) })
                let other_holes = ShapeRegion(solids: other.holes.flatMap { ShapeRegion.Solid(solid: $0) })
                let a = self_holes.intersection(other_holes).solids
                let b = self_holes.subtracting(ShapeRegion.Solid(solid: other.solid))
                let c = other_holes.subtracting(ShapeRegion.Solid(solid: self.solid))
                cache.union[other.cacheId] = (union.subtracting(ShapeRegion(solids: a.concat(b).concat(c))).solids, true)
            } else {
                cache.union[other.cacheId] = ([self, other], false)
            }
        }
        return cache.union[other.cacheId] ?? other.cache.union[cacheId]!
    }
    fileprivate func intersection(_ other: ShapeRegion.Solid) -> [ShapeRegion.Solid] {
        
        if !self.bigBound.isIntersect(other.bigBound) {
            return []
        }
        
        if cache.intersection[other.cacheId] == nil && other.cache.intersection[cacheId] == nil {
            let intersection = self._intersection(other)
            if intersection.count != 0 {
                let self_holes = ShapeRegion(solids: self.holes.flatMap { ShapeRegion.Solid(solid: $0) })
                let other_holes = ShapeRegion(solids: other.holes.flatMap { ShapeRegion.Solid(solid: $0) })
                cache.intersection[other.cacheId] = intersection.subtracting(self_holes).subtracting(other_holes).solids
            } else {
                cache.intersection[other.cacheId] = []
            }
        }
        return cache.intersection[other.cacheId] ?? other.cache.intersection[cacheId]!
    }
    fileprivate func subtracting(_ other: ShapeRegion.Solid) -> [ShapeRegion.Solid] {
        
        if !self.bigBound.isIntersect(other.bigBound) {
            return [self]
        }
        
        if cache.subtracting[other.cacheId] == nil {
            let (_subtracting, superset) = self._subtracting(other)
            if superset {
                let self_holes = ShapeRegion(solids: self.holes.flatMap { ShapeRegion.Solid(solid: $0) })
                let a = self_holes.union(ShapeRegion(solid: other))
                cache.subtracting[other.cacheId] = [ShapeRegion.Solid(components: [self.solid] + a.solids.map { $0.solid })] + a.solids.flatMap { $0.holes.map { ShapeRegion.Solid(solid: $0) } }
            } else if let subtracting = _subtracting {
                let self_holes = ShapeRegion(solids: self.holes.flatMap { ShapeRegion.Solid(solid: $0) })
                let other_holes = ShapeRegion(solids: other.holes.flatMap { ShapeRegion.Solid(solid: $0) })
                let a = subtracting.concat(other_holes.intersection(ShapeRegion.Solid(solid: self.solid)))
                cache.subtracting[other.cacheId] = self.holes.isEmpty ? Array(a) : ShapeRegion(solids: a).subtracting(self_holes).solids
            } else {
                cache.subtracting[other.cacheId] = [self]
            }
        }
        return cache.subtracting[other.cacheId]!
    }
}

extension ShapeRegion {
    
    public func union(_ other: ShapeRegion) -> ShapeRegion {
        
        if self.isEmpty && other.isEmpty {
            return ShapeRegion()
        }
        if self.isEmpty && !other.isEmpty {
            return other
        }
        if !self.isEmpty && other.isEmpty {
            return self
        }
        if !self.bigBound.isIntersect(other.bigBound) {
            return ShapeRegion(solids: self.solids.concat(other.solids))
        }
        
        if cache.union[other.cacheId] == nil && other.cache.union[cacheId] == nil {
            var result1 = self.solids
            var result2: [ShapeRegion.Solid] = []
            var remain = other.solids
            outer: while let rhs = remain.popLast() {
                for idx in result1.indices {
                    let (union, flag) = result1[idx].union(rhs)
                    if flag {
                        result1.remove(at: idx)
                        remain.append(contentsOf: union)
                        continue outer
                    }
                }
                result2.append(rhs)
            }
            cache.union[other.cacheId] = ShapeRegion(solids: result1.concat(result2))
        }
        return cache.union[other.cacheId] ?? other.cache.union[cacheId]!
    }
    
    fileprivate func intersection(_ other: ShapeRegion.Solid) -> [ShapeRegion.Solid] {
        
        if self.isEmpty || !self.bigBound.isIntersect(other.bigBound) {
            return []
        }
        
        let overlap = self.spacePartition.search(overlap: other.bigBound)
        return overlap.flatMap { solids[$0].intersection(other) }
    }
    
    public func intersection(_ other: ShapeRegion) -> ShapeRegion {
        
        if self.isEmpty || other.isEmpty || !self.bigBound.isIntersect(other.bigBound) {
            return ShapeRegion()
        }
        
        if cache.intersection[other.cacheId] == nil && other.cache.intersection[cacheId] == nil {
            let overlap = self.spacePartition.search(overlap: other.bigBound)
            cache.intersection[other.cacheId] = ShapeRegion(solids: overlap.flatMap { other.intersection(self.solids[$0]) })
        }
        return cache.intersection[other.cacheId] ?? other.cache.intersection[cacheId]!
    }
    fileprivate func subtracting(_ other: ShapeRegion.Solid) -> [ShapeRegion.Solid] {
        
        if self.isEmpty {
            return []
        }
        if !self.bigBound.isIntersect(other.bigBound) {
            return self.solids
        }
        
        let overlap = self.spacePartition.search(overlap: other.bigBound)
        var result: [ShapeRegion.Solid] = []
        result.reserveCapacity(solids.count)
        for (index, solid) in solids.enumerated() {
            if overlap.contains(index) {
                result.append(contentsOf: solid.subtracting(other))
            } else {
                result.append(solid)
            }
        }
        return result
    }
    public func subtracting(_ other: ShapeRegion) -> ShapeRegion {
        
        if self.isEmpty {
            return ShapeRegion()
        }
        if other.isEmpty || !self.bigBound.isIntersect(other.bigBound) {
            return self
        }
        
        if cache.subtracting[other.cacheId] == nil {
            let overlap = self.spacePartition.search(overlap: other.bigBound)
            var result: [Solid] = []
            result.reserveCapacity(solids.count)
            for (index, item) in self.solids.enumerated() {
                if overlap.contains(index) {
                    let overlap2 = other.spacePartition.search(overlap: item.bigBound)
                    result.append(contentsOf: overlap2.reduce([item]) { remains, idx in remains.flatMap { $0.subtracting(other.solids[idx]) } })
                } else {
                    result.append(item)
                }
            }
            cache.subtracting[other.cacheId] = ShapeRegion(solids: result)
        }
        return cache.subtracting[other.cacheId]!
    }
    public func symmetricDifference(_ other: ShapeRegion) -> ShapeRegion {
        
        if self.isEmpty && other.isEmpty {
            return ShapeRegion()
        }
        if self.isEmpty && !other.isEmpty {
            return other
        }
        if !self.isEmpty && other.isEmpty {
            return self
        }
        if !self.bigBound.isIntersect(other.bigBound) {
            return ShapeRegion(solids: self.solids.concat(other.solids))
        }
        
        if cache.symmetricDifference[other.cacheId] == nil && other.cache.symmetricDifference[cacheId] == nil {
            let a = self.subtracting(other).solids
            let b = other.subtracting(self).solids
            cache.symmetricDifference[other.cacheId] = ShapeRegion(solids: a.concat(b))
        }
        return cache.symmetricDifference[other.cacheId] ?? other.cache.symmetricDifference[cacheId]!
    }
}

extension ShapeRegion {
    
    public mutating func formUnion(_ other: ShapeRegion) {
        self = self.union(other)
    }
    public mutating func formIntersection(_ other: ShapeRegion) {
        self = self.intersection(other)
    }
    public mutating func subtract(_ other: ShapeRegion) {
        self = self.subtracting(other)
    }
    public mutating func formSymmetricDifference(_ other: ShapeRegion) {
        self = self.symmetricDifference(other)
    }
}

extension ShapeRegion {
    
    public init(center: Point, radius: Radius) {
        let scale = SDTransform.scale(x: radius.x, y: radius.y)
        let point = BezierCircle.map { $0 * scale + center }
        let segments: [ShapeRegion.Solid.Segment] = [
            ShapeRegion.Solid.Segment(point[0], point[1], point[2], point[3]),
            ShapeRegion.Solid.Segment(point[3], point[4], point[5], point[6]),
            ShapeRegion.Solid.Segment(point[6], point[7], point[8], point[9]),
            ShapeRegion.Solid.Segment(point[9], point[10], point[11], point[12])
        ]
        self.init(solid: ShapeRegion.Solid(segments: segments)!)
    }
    
    public init(rect: Rect) {
        let points = rect.points
        let segments: [ShapeRegion.Solid.Segment] = [
            ShapeRegion.Solid.Segment(points[0], points[1]),
            ShapeRegion.Solid.Segment(points[1], points[2]),
            ShapeRegion.Solid.Segment(points[2], points[3]),
            ShapeRegion.Solid.Segment(points[3], points[0])
        ]
        self.init(solid: ShapeRegion.Solid(segments: segments)!)
    }
}

extension ShapeRegion {
    
    public init(_ path: Shape, winding: Shape.WindingRule) {
        self.init()
        let cacheKey: String
        switch winding {
        case .nonZero: cacheKey = ShapeCacheNonZeroRegionKey
        case .evenOdd: cacheKey = ShapeCacheEvenOddRegionKey
        }
        if let region = path.identity.cacheTable[cacheKey] as? ShapeRegion {
            self = region
        } else {
            if let region = path.cacheTable[cacheKey] as? ShapeRegion {
                self = region
            } else {
                switch winding {
                case .nonZero: self.addLoopWithNonZeroWinding(loops: path.breakLoop())
                case .evenOdd: self.addLoopWithEvenOddWinding(loops: path.breakLoop())
                }
                path.cacheTable[cacheKey] = self
            }
            self *= path.transform
            path.identity.cacheTable[cacheKey] = self
        }
    }
    
    fileprivate mutating func addLoopWithNonZeroWinding(loops: [ShapeRegion.Solid]) {
        
        var positive: [ShapeRegion] = []
        var negative: [ShapeRegion] = []
        
        for loop in loops {
            var remain = ShapeRegion(solid: loop)
            if loop.area.sign == .minus {
                for index in negative.indices {
                    (negative[index], remain) = (negative[index].union(remain), negative[index].intersection(remain))
                    if remain.isEmpty {
                        break
                    }
                }
                if !remain.isEmpty {
                    negative.append(remain)
                }
            } else {
                for index in positive.indices {
                    (positive[index], remain) = (positive[index].union(remain), positive[index].intersection(remain))
                    if remain.isEmpty {
                        break
                    }
                }
                if !remain.isEmpty {
                    positive.append(remain)
                }
            }
        }
        for n_index in negative.indices.reversed() {
            for p_index in positive.indices.reversed() {
                (positive[p_index], negative[n_index]) = (positive[p_index].subtracting(negative[n_index]), negative[n_index].subtracting(positive[p_index]))
                if positive[p_index].isEmpty {
                    positive.removeLast()
                }
                if negative[n_index].isEmpty {
                    break
                }
            }
        }
        self = ShapeRegion(solids: OptionOneCollection(positive.first?.solids).concat(OptionOneCollection(negative.first?.solids)).joined())
    }
    
    fileprivate mutating func addLoopWithEvenOddWinding(loops: [ShapeRegion.Solid]) {
        
        self = loops.reduce(ShapeRegion()) { $0.symmetricDifference(ShapeRegion(solid: $1)) }
    }
}

extension Shape.Component {
    
    fileprivate var bigBound: Rect {
        return boundary.inset(dx: _boundInset * Swift.max(1, abs(boundary.x), abs(boundary.width)), dy: _boundInset * Swift.max(1, abs(boundary.y), abs(boundary.height)))
    }
}

public func * (lhs: ShapeRegion, rhs: SDTransform) -> ShapeRegion {
    return rhs.determinant.almostZero() ? ShapeRegion() : ShapeRegion(solids: lhs.solids.map { ShapeRegion.Solid(components: $0.components.map { $0 * rhs }) })
}
public func *= (lhs: inout ShapeRegion, rhs: SDTransform) {
    lhs = lhs * rhs
}

extension ShapeRegion.Solid.Segment {
    
    fileprivate init(_ p0: Point, _ p1: Point) {
        self.init(start: p0, segment: .line(p1))
    }
    fileprivate init(_ p0: Point, _ p1: Point, _ p2: Point) {
        if cross(p1 - p0, p2 - p0).almostZero() {
            self.init(start: p0, segment: .line(p2))
        } else {
            self.init(start: p0, segment: .quad(p1, p2))
        }
    }
    fileprivate init(_ p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) {
        if cross(p1 - p0, p2 - p0).almostZero() && cross(p1 - p0, p3 - p0).almostZero() && cross(p2 - p0, p3 - p0).almostZero() {
            self.init(start: p0, segment: .line(p3))
        } else {
            self.init(start: p0, segment: .cubic(p1, p2, p3))
        }
    }
}

private func split_check(_ t: Double) -> Double? {
    if t.almostZero() {
        return 0
    } else if (t - 1).almostZero() {
        return 1
    } else if 0...1 ~= t {
        return t
    }
    return nil
}
private func split_check(_ t: (Double?, Double?)) -> (Double, Double)? {
    if let lhs = t.0, let rhs = t.1 {
        return (lhs, rhs)
    }
    return nil
}
private func split_check(_ t: (Double?, Double)) -> (Double, Double)? {
    if let lhs = t.0, let rhs = split_check(t.1) {
        return (lhs, rhs)
    }
    return nil
}
private func split_check(_ t: (Double, Double?)) -> (Double, Double)? {
    if let lhs = split_check(t.0), let rhs = t.1 {
        return (lhs, rhs)
    }
    return nil
}

extension ShapeRegion.Solid.Segment {
    
    fileprivate var isPoint: Bool {
        switch self.segment {
        case let .line(p1): return start.almostEqual(p1)
        default: return false
        }
    }
    
    fileprivate func point(_ t: Double) -> Point {
        switch self.segment {
        case let .line(p1): return Bezier(start, p1).eval(t)
        case let .quad(p1, p2): return Bezier(start, p1, p2).eval(t)
        case let .cubic(p1, p2, p3): return Bezier(start, p1, p2, p3).eval(t)
        }
    }
    
    fileprivate var bigBound: Rect {
        return boundary.inset(dx: _boundInset * Swift.max(1, abs(boundary.x), abs(boundary.width)), dy: _boundInset * Swift.max(1, abs(boundary.y), abs(boundary.height)))
    }
    
    fileprivate func fromPoint(_ p: Point) -> Double? {
        switch self.segment {
        case let .line(p1):
            return Bezier(start, p1).closest(p).lazy.flatMap(split_check).first { p.almostEqual(self.point($0)) }
        case let .quad(p1, p2):
            return Bezier(start, p1, p2).closest(p).lazy.flatMap(split_check).first { p.almostEqual(self.point($0)) }
        case let .cubic(p1, p2, p3):
            return Bezier(start, p1, p2, p3).closest(p).lazy.flatMap(split_check).first { p.almostEqual(self.point($0)) }
        }
    }
    
    fileprivate func split(_ t: Double) -> (ShapeRegion.Solid.Segment, ShapeRegion.Solid.Segment) {
        switch self.segment {
        case let .line(p1):
            let _split = Bezier(start, p1).split(t)
            return (ShapeRegion.Solid.Segment(_split.0[0], _split.0[1]), ShapeRegion.Solid.Segment(_split.1[0], _split.1[1]))
        case let .quad(p1, p2):
            let _split = Bezier(start, p1, p2).split(t)
            return (ShapeRegion.Solid.Segment(_split.0[0], _split.0[1], _split.0[2]), ShapeRegion.Solid.Segment(_split.1[0], _split.1[1], _split.1[2]))
        case let .cubic(p1, p2, p3):
            let _split = Bezier(start, p1, p2, p3).split(t)
            return (ShapeRegion.Solid.Segment(_split.0[0], _split.0[1], _split.0[2], _split.0[3]), ShapeRegion.Solid.Segment(_split.1[0], _split.1[1], _split.1[2], _split.1[3]))
        }
    }
    fileprivate func split(_ t: [Double]) -> [ShapeRegion.Solid.Segment] {
        switch self.segment {
        case let .line(p1): return Bezier(start, p1).split(t).map { ShapeRegion.Solid.Segment($0[0], $0[1]) }
        case let .quad(p1, p2): return Bezier(start, p1, p2).split(t).map { ShapeRegion.Solid.Segment($0[0], $0[1], $0[2]) }
        case let .cubic(p1, p2, p3): return Bezier(start, p1, p2, p3).split(t).map { ShapeRegion.Solid.Segment($0[0], $0[1], $0[2], $0[3]) }
        }
    }
    
    fileprivate func intersect(_ q0: Point, _ q1: Point) -> [Double]? {
        switch self.segment {
        case let .line(p1): return LinesIntersect(start, p1, q0, q1).flatMap { fromPoint($0) }.map { [$0] }
        case let .quad(p1, p2): return QuadBezierLineIntersect(start, p1, p2, q0, q1)?.sorted { $0 }
        case let .cubic(p1, p2, p3): return CubicBezierLineIntersect(start, p1, p2, p3, q0, q1)?.sorted { $0 }
        }
    }
    fileprivate func intersect(_ other: ShapeRegion.Solid.Segment) -> [(Double, Double)]? {
        var result: [(Double, Double)]? = nil
        switch self.segment {
        case let .line(p1):
            switch other.segment {
            case let .line(q1):
                if let p = LinesIntersect(start, p1, other.start, q1) {
                    result = [(fromPoint(p), other.fromPoint(p))].flatMap(split_check)
                }
            case let .quad(q1, q2):
                if let t = QuadBezierLineIntersect(other.start, q1, q2, start, p1) {
                    result = t.map { (fromPoint(Bezier(other.start, q1, q2).eval($0)), $0) }.flatMap(split_check).sorted { $0.0 }
                }
            case let .cubic(q1, q2, q3):
                if let t = CubicBezierLineIntersect(other.start, q1, q2, q3, start, p1) {
                    result = t.map { (fromPoint(Bezier(other.start, q1, q2, q3).eval($0)), $0) }.flatMap(split_check).sorted { $0.0 }
                }
            }
        case let .quad(p1, p2):
            switch other.segment {
            case let .line(q1):
                if let t = QuadBezierLineIntersect(start, p1, p2, other.start, q1) {
                    result = t.map { ($0, other.fromPoint(Bezier(start, p1, p2).eval($0))) }.flatMap(split_check).sorted { $0.0 }
                }
            case let .quad(q1, q2):
                if let t = QuadBeziersIntersect(start, p1, p2, other.start, q1, q2) {
                    result = t.map { ($0, other.fromPoint(Bezier(start, p1, p2).eval($0))) }.flatMap(split_check).sorted { $0.0 }
                }
            case let .cubic(q1, q2, q3):
                if let t = CubicQuadBezierIntersect(other.start, q1, q2, q3, start, p1, p2) {
                    result = t.map { (fromPoint(Bezier(other.start, q1, q2, q3).eval($0)), $0) }.flatMap(split_check).sorted { $0.0 }
                }
            }
        case let .cubic(p1, p2, p3):
            switch other.segment {
            case let .line(q1):
                if let t = CubicBezierLineIntersect(start, p1, p2, p3, other.start, q1) {
                    result = t.map { ($0, other.fromPoint(Bezier(start, p1, p2, p3).eval($0))) }.flatMap(split_check).sorted { $0.0 }
                }
            case let .quad(q1, q2):
                if let t = CubicQuadBezierIntersect(start, p1, p2, p3, other.start, q1, q2) {
                    result = t.map { ($0, other.fromPoint(Bezier(start, p1, p2, p3).eval($0))) }.flatMap(split_check).sorted { $0.0 }
                }
            case let .cubic(q1, q2, q3):
                if let t = CubicBeziersIntersect(start, p1, p2, p3, other.start, q1, q2, q3) {
                    result = t.map { ($0, other.fromPoint(Bezier(start, p1, p2, p3).eval($0))) }.flatMap(split_check).sorted { $0.0 }
                }
            }
        }
        if result == nil {
            let check_1 = self.fromPoint(other.start)
            let check_2 = self.fromPoint(other.end)
            let check_3 = other.fromPoint(self.start)
            let check_4 = other.fromPoint(self.end)
            if check_1 == 0 {
                if check_2 != nil && check_2 != 0 { return nil }
                if check_4 != nil && check_4 != 0 { return nil }
            } else if check_2 == 0 {
                if check_1 != nil && check_1 != 0 { return nil }
                if check_4 != nil && check_4 != 1 { return nil }
            } else if check_3 == 0 {
                if check_4 != nil && check_4 != 0 { return nil }
                if check_2 != nil && check_2 != 0 { return nil }
            } else if check_4 == 0 {
                if check_3 != nil && check_3 != 0 { return nil }
                if check_2 != nil && check_2 != 1 { return nil }
            } else if check_1 == 1 {
                if check_2 != nil && check_2 != 1 { return nil }
                if check_3 != nil && check_3 != 0 { return nil }
            } else if check_2 == 1 {
                if check_1 != nil && check_1 != 1 { return nil }
                if check_3 != nil && check_3 != 1 { return nil }
            } else if check_3 == 1 {
                if check_4 != nil && check_4 != 1 { return nil }
                if check_1 != nil && check_1 != 0 { return nil }
            } else if check_4 == 1 {
                if check_3 != nil && check_3 != 1 { return nil }
                if check_1 != nil && check_1 != 1 { return nil }
            } else if check_1 != nil && check_2 != nil && check_3 == nil && check_4 == nil { return nil
            } else if check_1 == nil && check_2 == nil && check_3 != nil && check_4 != nil { return nil
            }
        }
        return result ?? []
    }
}

extension Shape.Component {
    
    fileprivate func breakLoop() -> [ShapeRegion.Solid] {
        
        var intersects: [(IntersectionTable.Split, IntersectionTable.Split)] = []
        for (index1, segment1) in bezier.enumerated() {
            for (index2, segment2) in bezier.suffix(from: index1 + 1).indexed() {
                if !segment2.boundary.inset(dx: -1e-6, dy: -1e-6).isIntersect(segment1.boundary.inset(dx: -1e-6, dy: -1e-6)) {
                    continue
                }
                if let _intersects = segment1.intersect(segment2) {
                    for _intersect in _intersects {
                        let _l_idx = _intersect.0 == 1 ? self.indexMod(index1 + 1) : index1
                        let _r_idx = _intersect.1 == 1 ? self.indexMod(index2 + 1) : index2
                        let _t1 = _intersect.0 == 1 ? 0 : _intersect.0
                        let _t2 = _intersect.1 == 1 ? 0 : _intersect.1
                        if _l_idx == _r_idx && _t1 == 0 && _t2 == 0 {
                            continue
                        }
                        if intersects.contains(where: { $0.0.index == _l_idx && $0.0.split.almostEqual(_t1) && $0.1.index == _r_idx && $0.1.split.almostEqual(_t2) }) {
                            continue
                        }
                        if intersects.contains(where: { $0.1.index == _l_idx && $0.1.split.almostEqual(_t1) && $0.0.index == _r_idx && $0.0.split.almostEqual(_t2) }) {
                            continue
                        }
                        intersects.append((IntersectionTable.Split(index: _l_idx, split: _t1), IntersectionTable.Split(index: _r_idx, split: _t2)))
                    }
                } else {
                    if let a = segment2.fromPoint(segment1.end) {
                        let _l_idx = self.indexMod(index1 + 1)
                        let _r_idx = a == 1 ? self.indexMod(index2 + 1) : index2
                        let _t2 = a == 1 ? 0 : a
                        if _l_idx == _r_idx && _t2 == 0 {
                            continue
                        }
                        if intersects.contains(where: { $0.0.index == _l_idx && $0.0.split.almostEqual(0) && $0.1.index == _r_idx && $0.1.split.almostEqual(_t2) }) {
                            continue
                        }
                        if intersects.contains(where: { $0.1.index == _l_idx && $0.1.split.almostEqual(0) && $0.0.index == _r_idx && $0.0.split.almostEqual(_t2) }) {
                            continue
                        }
                        intersects.append((IntersectionTable.Split(index: _l_idx, split: 0), IntersectionTable.Split(index: _r_idx, split: _t2)))
                    }
                    if let b = segment1.fromPoint(segment2.start) {
                        let _l_idx = b == 1 ? self.indexMod(index1 + 1) : index1
                        let _r_idx = index2
                        let _t1 = b == 1 ? 0 : b
                        if _l_idx == _r_idx && _t1 == 0 {
                            continue
                        }
                        if intersects.contains(where: { $0.0.index == _l_idx && $0.0.split.almostEqual(_t1) && $0.1.index == _r_idx && $0.1.split.almostEqual(0) }) {
                            continue
                        }
                        if intersects.contains(where: { $0.1.index == _l_idx && $0.1.split.almostEqual(_t1) && $0.0.index == _r_idx && $0.0.split.almostEqual(0) }) {
                            continue
                        }
                        intersects.append((IntersectionTable.Split(index: _l_idx, split: _t1), IntersectionTable.Split(index: _r_idx, split: 0)))
                    }
                }
            }
        }
        return breakLoop(intersects.filter { !$0.0.almostEqual($0.1) })
    }
    
    fileprivate func breakLoop(_ points: [(IntersectionTable.Split, IntersectionTable.Split)]) -> [ShapeRegion.Solid] {
        
        if points.count == 0 {
            return Array(OptionOneCollection(ShapeRegion.Solid(segments: self.bezier)))
        }
        
        var result: [ShapeRegion.Solid] = []
        
        var graph = Graph<Int, [(IntersectionTable.Split, IntersectionTable.Split)]>()
        
        let _points = points.enumerated().flatMap { [($0.0, $0.1.0), ($0.0, $0.1.1)] }.sorted { $0.1.ordering($1.1) }
        
        for (left, right) in _points.rotateZip() {
            if left.0 == right.0 {
                result.append(contentsOf: OptionOneCollection(ShapeRegion.Solid(segments: self.splitPath(left.1, right.1))))
            } else {
                if var splits = graph[from: left.0, to: right.0] {
                    splits.append((left.1, right.1))
                    graph[from: left.0, to: right.0] = splits
                } else {
                    graph[from: left.0, to: right.0] = [(left.1, right.1)]
                }
            }
        }
        while let graph_first = graph.first {
            var path: [Int] = [graph_first.from, graph_first.to]
            while let last = path.last, let node = graph.nodes(from: last).first?.0 {
                if let i = path.index(where: { $0 == node }) {
                    let loop = path.suffix(from: i)
                    var segments: [ShapeRegion.Solid.Segment] = []
                    for (left, right) in loop.rotateZip() {
                        if let split = graph[from: left, to: right]?.last {
                            segments.append(contentsOf: self.splitPath(split.0, split.1))
                            if var splits = graph[from: left, to: right], splits.count != 1 {
                                splits.removeLast()
                                graph[from: left, to: right] = splits
                            } else {
                                graph[from: left, to: right] = nil
                            }
                        }
                    }
                    result.append(contentsOf: OptionOneCollection(ShapeRegion.Solid(segments: segments)))
                    if i == 0 {
                        break
                    }
                    path.removeSubrange(path.index(after: i)..<path.endIndex)
                } else {
                    path.append(node)
                }
            }
        }
        return result.filter { !$0.area.almostZero() }
    }
}

extension Shape {
    
    fileprivate func breakLoop() -> [ShapeRegion.Solid] {
        
        var solids: [ShapeRegion.Solid] = []
        
        for item in self {
            var path: [ShapeRegion.Solid.Segment] = []
            var last = item.start
            loop: for segment in item {
                
                switch segment {
                    
                case let .line(point):
                    path.append(ShapeRegion.Solid.Segment(last, point))
                    
                    last = point
                    
                case let .quad(p1, p2):
                    path.append(ShapeRegion.Solid.Segment(last, p1, p2))
                    
                    last = p2
                    
                case let .cubic(p1, p2, p3):
                    if last.almostEqual(p3) {
                        solids.append(ShapeRegion.Solid(segments: CollectionOfOne(ShapeRegion.Solid.Segment(last, p1, p2, p3)))!)
                    } else {
                        
                        var segment = ShapeRegion.Solid.Segment(last, p1, p2, p3)
                        if let (_a, _b) = CubicBezierSelfIntersect(last, p1, p2, p3) {
                            
                            let a = Swift.min(_a, _b)
                            let b = Swift.max(_a, _b)
                            
                            let check_1 = a.almostZero()
                            let check_2 = !check_1 && a > 0
                            let check_3 = (b - 1).almostZero()
                            let check_4 = !check_3 && b < 1
                            
                            if check_1 && check_4 {
                                
                                let split = Bezier(last, p1, p2, p3).split(b)
                                solids.append(ShapeRegion.Solid(segments: CollectionOfOne(ShapeRegion.Solid.Segment(split.0[0], split.0[1], split.0[2], split.0[3])))!)
                                segment = ShapeRegion.Solid.Segment(split.1[0], split.1[1], split.1[2], split.1[3])
                                
                            } else if check_2 && check_3 {
                                
                                let split = Bezier(last, p1, p2, p3).split(a)
                                solids.append(ShapeRegion.Solid(segments: CollectionOfOne(ShapeRegion.Solid.Segment(split.1[0], split.1[1], split.1[2], split.1[3])))!)
                                segment = ShapeRegion.Solid.Segment(split.0[0], split.0[1], split.0[2], split.0[3])
                                
                            } else if check_2 && check_4 {
                                
                                let split = Bezier(last, p1, p2, p3).split([a, b]).map { ShapeRegion.Solid.Segment($0[0], $0[1], $0[2], $0[3]) }
                                solids.append(ShapeRegion.Solid(segments: CollectionOfOne(split[1]))!)
                                path.append(split[0])
                                segment = split[2]
                            }
                        }
                        path.append(segment)
                        
                    }
                    
                    last = p3
                    
                }
            }
            if path.count != 0 {
                path.append(ShapeRegion.Solid.Segment(last, item.start))
                solids.append(contentsOf: OptionOneCollection(ShapeRegion.Solid(segments: path)))
            }
        }
        
        return solids.flatMap { $0.solid.breakLoop() }
    }
}

private struct IntersectionTable {
    
    var graph: Graph<Int, [(Type, Split, Split)]> = Graph()
    var overlap: Overlap = .none
    var looping_left: [(Split, Split)] = []
    var looping_right: [(Split, Split)] = []
    
    init(_ left: Shape.Component, _ right: Shape.Component) {
        
        struct SplitData {
            
            let data: Data
            let data2: Data?
            
            struct Data {
                fileprivate let left: IntersectionTable.Split
                fileprivate let right: IntersectionTable.Split
                let point: Point
            }
        }
        
        let left_spaces = left.spaces
        let right_spaces = right.spaces
        
        var _data: [SplitData.Data] = []
        var overlaps_index: [(Int, Int)] = []
        var overlap_r_index: Set<Int> = []
        var overlap_l_index: Set<Int> = []
        for r_idx in right_spaces.search(overlap: left.bigBound) {
            let r_segment = right.bezier[r_idx]
            for l_idx in left_spaces.search(overlap: r_segment.bigBound) {
                let l_segment = left.bezier[l_idx]
                if let intersect = l_segment.intersect(r_segment) {
                    for (t1, t2) in intersect {
                        let _t1 = t1 == 1 ? 0 : t1
                        let _t2 = t2 == 1 ? 0 : t2
                        let _l_idx = t1 == 1 ? left.indexMod(l_idx + 1) : l_idx
                        let _r_idx = t2 == 1 ? right.indexMod(r_idx + 1) : r_idx
                        if _data.contains(where: { $0.left.index == _l_idx && $0.left.split.almostEqual(_t1) && $0.right.index == _r_idx && $0.right.split.almostEqual(_t2) }) {
                            continue
                        }
                        _data.append(SplitData.Data(left: Split(index: _l_idx, split: _t1), right: Split(index: _r_idx, split: _t2), point: l_segment.point(t1)))
                    }
                } else {
                    overlap_l_index.insert(l_idx)
                    overlap_r_index.insert(r_idx)
                    overlaps_index.append((l_idx, r_idx))
                }
            }
        }
        if !overlap_l_index.isStrictSubset(of: 0..<left.count) && !overlap_r_index.isStrictSubset(of: 0..<right.count) {
            overlap = .equal
            return
        }
        
        for (index, item) in _data.enumerated() {
            looping_left.append(contentsOf: _data.suffix(from: index + 1).filter { item.right.almostEqual($0.right) }.map { (item.left, $0.left) })
            looping_right.append(contentsOf: _data.suffix(from: index + 1).filter { item.left.almostEqual($0.left) }.map { (item.right, $0.right) })
        }
        if looping_left.count != 0 || looping_right.count != 0 {
            return
        }
        if _data.count < 2 {
            if left._overlap(right, hint: Set(0..<right.count).subtracting(overlap_r_index)) {
                overlap = .superset
            } else if right._overlap(left, hint: Set(0..<left.count).subtracting(overlap_l_index)) {
                overlap = .subset
            }
            return
        }
        
        func signCheck(_ p0: Point, _ p1: Point, _ q: Point) -> FloatingPointSign {
            
            let p0u = p0.unit
            let p1u = p1.unit
            let qu = q.unit
            let _p = cross(p0u, p1u)
            let _q = cross(p0u, qu)
            let _s = dot(p0u, p1u)
            let _t = dot(p0u, qu)
            
            if _p.almostZero() || _p.sign != _q.sign || (_s.sign == .minus && _t.sign == .plus) {
                return _q.sign
            }
            if _s.sign == .plus && _t.sign == .minus {
                if _q.sign == .plus {
                    return .minus
                }
                return .plus
            }
            if (_s.sign == .plus) == (abs(_p) > abs(_q)) {
                return _q.sign
            }
            if _q.sign == .plus {
                return .minus
            }
            return .plus
        }
        func distancePoints(_ x: SplitData.Data) -> (Point, Point, Point, Point) {
            
            let lesser_left_index: Int
            let lesser_right_index: Int
            
            var lesser_left: Double
            var lesser_right: Double
            
            if x.left.split == 0 {
                lesser_left_index = left.indexMod(x.left.index - 1)
                lesser_left = _data.lazy.filter { lesser_left_index == $0.left.index }.max { $0.left.ordering($1.left) }?.left.split ?? 0
                lesser_left = 0.5 * (lesser_left + 1)
            } else {
                lesser_left_index = x.left.index
                lesser_left = _data.lazy.filter { lesser_left_index == $0.left.index && !x.left.split.almostEqual($0.left.split) && x.left.split > $0.left.split }.max { $0.left.ordering($1.left) }?.left.split ?? 0
                lesser_left = 0.5 * (lesser_left + x.left.split)
            }
            if x.right.split == 0 {
                lesser_right_index = right.indexMod(x.right.index - 1)
                lesser_right = _data.lazy.filter { lesser_right_index == $0.right.index }.max { $0.right.ordering($1.right) }?.right.split ?? 0
                lesser_right = 0.5 * (lesser_right + 1)
            } else {
                lesser_right_index = x.right.index
                lesser_right = _data.lazy.filter { lesser_right_index == $0.right.index && !x.right.split.almostEqual($0.right.split) && x.right.split > $0.right.split }.max { $0.right.ordering($1.right) }?.right.split ?? 0
                lesser_right = 0.5 * (lesser_right + x.right.split)
            }
            
            var greater_left = _data.lazy.filter { x.left.index == $0.left.index && !x.left.split.almostEqual($0.left.split) && x.left.split < $0.left.split }.min { $0.left.ordering($1.left) }?.left.split ?? 1
            var greater_right = _data.lazy.filter { x.right.index == $0.right.index && !x.right.split.almostEqual($0.right.split) && x.right.split < $0.right.split }.min { $0.right.ordering($1.right) }?.right.split ?? 1
            
            greater_left = 0.5 * (greater_left + x.left.split)
            greater_right = 0.5 * (greater_right + x.right.split)
            
            let lesser_left_segment = left.bezier[lesser_left_index]
            let lesser_right_segment = right.bezier[lesser_right_index]
            
            let greater_left_segment = left.bezier[x.left.index]
            let greater_right_segment = right.bezier[x.right.index]
            
            if let intersect = greater_right_segment.intersect(x.point, greater_left_segment.point(greater_left)) {
                if let t = intersect.lazy.filter({ !$0.almostEqual(x.right.split) && $0 > x.right.split && ($0.almostEqual(greater_right) || $0 < greater_right) }).first {
                    greater_right = 0.5 * (t + x.right.split)
                }
                if x.left.index == lesser_left_index && x.right.index == lesser_right_index {
                    if let t = intersect.lazy.filter({ !$0.almostEqual(x.right.split) && $0 < x.right.split && ($0.almostEqual(lesser_right) || $0 > lesser_right) }).last {
                        lesser_right = 0.5 * (t + x.right.split)
                    }
                }
            }
            if x.left.index != lesser_left_index || x.right.index != lesser_right_index, let intersect = lesser_left_segment.intersect(x.point, lesser_right_segment.point(lesser_left)) {
                if let t = intersect.lazy.filter({ !$0.almostEqual(x.right.split) && $0 < x.right.split && ($0.almostEqual(lesser_right) || $0 > lesser_right) }).last {
                    lesser_right = 0.5 * (t + x.right.split)
                }
            }
            return (lesser_left_segment.point(lesser_left), greater_left_segment.point(greater_left), lesser_right_segment.point(lesser_right), greater_right_segment.point(greater_right))
        }
        
        _data.sort { $0.left.ordering($1.left) }
        var uncheck = Set(0..<_data.count)
        var _data2: [SplitData] = []
        while let index = uncheck.popFirst() {
            let split = _data[index]
            
            let _left_index_m1 = split.left.split == 0 ? left.indexMod(split.left.index - 1) : split.left.index
            let _right_index_m1 = split.right.split == 0 ? right.indexMod(split.right.index - 1) : split.right.index
            if !overlaps_index.contains(where: { (split.left.index == $0.0 || _left_index_m1 == $0.0) && (split.right.index == $0.1 || _right_index_m1 == $0.1) }) {
                let points = distancePoints(split)
                if signCheck(points.0 - split.point, points.1 - split.point, points.2 - split.point) != signCheck(points.0 - split.point, points.1 - split.point, points.3 - split.point) {
                    _data2.append(SplitData(data: split, data2: nil))
                }
                continue
            }
            
            func check(_ index: Int) -> Bool {
                let split = _data[index]
                let left_index_m1 = split.left.split == 0 ? left.indexMod(split.left.index - 1) : split.left.index
                let right_index_m1 = split.right.split == 0 ? right.indexMod(split.right.index - 1) : split.right.index
                return (overlaps_index.contains(where: { split.left.index == $0.0 && split.right.index == $0.1 }) && overlaps_index.contains(where: { left_index_m1 == $0.0 && right_index_m1 == $0.1 }))
                    || (overlaps_index.contains(where: { split.left.index == $0.0 && right_index_m1 == $0.1 }) && overlaps_index.contains(where: { left_index_m1 == $0.0 && split.right.index == $0.1 }))
            }
            
            var start = index
            while check(start) {
                start = _data.indexMod(start - 1)
            }
            var end = index
            while check(end) {
                end = _data.indexMod(end + 1)
            }
            
            let start_split = _data[start]
            let end_split = _data[end]
            
            if overlaps_index.contains(where: { end_split.left.index == $0.0 && end_split.right.index == $0.1 }) {
                _data2.append(SplitData(data: end_split, data2: start_split))
            } else {
                let start_points = distancePoints(start_split)
                let end_points = distancePoints(end_split)
                if signCheck(start_points.0 - start_split.point, start_points.1 - start_split.point, start_points.2 - start_split.point) != signCheck(end_points.0 - end_split.point, end_points.1 - end_split.point, end_points.3 - end_split.point) {
                    _data2.append(SplitData(data: end_split, data2: nil))
                }
            }
            
            if start <= end {
                uncheck.subtract(start...end)
            } else {
                uncheck.subtract(start..<_data.count)
                uncheck.subtract(0...end)
            }
            
        }
        if _data2.count < 2 {
            if left._overlap(right, hint: Set(0..<right.count).subtracting(overlap_r_index)) {
                overlap = .superset
            } else if right._overlap(left, hint: Set(0..<left.count).subtracting(overlap_l_index)) {
                overlap = .subset
            }
            return
        }
        
        var table: [[SplitData]] = []
        for item in _data2 {
            if let idx = table.index(where: { $0.contains { $0.data.point.almostEqual(item.data.point) } }) {
                table[idx].append(item)
            } else {
                table.append([item])
            }
        }
        
        let _l_list = table.enumerated().flatMap { arg in arg.1.map { (arg.0, $0) } }.sorted { $0.1.data.left.ordering($1.1.data.left) }
        let _r_list = table.enumerated().flatMap { arg in arg.1.map { (arg.0, $0) } }.sorted { $0.1.data.right.ordering($1.1.data.right) }
        
        var counter = table.count
        
        for ((start_idx, start), (end_idx, end)) in _l_list.rotateZip() {
            
            let _s: Split
            let _e: Split
            let _s_idx: Int
            let _e_idx: Int
            if let data2 = start.data2, !data2.left.ordering(start.data.left) {
                _s = data2.left
                _s_idx = table.index(where: { $0.contains { $0.data.point.almostEqual(data2.point) } }) ?? counter
                counter += 1
            } else {
                _s = start.data.left
                _s_idx = start_idx
            }
            if let data2 = end.data2, data2.left.ordering(end.data.left) {
                _e = data2.left
                _e_idx = table.index(where: { $0.contains { $0.data.point.almostEqual(data2.point) } }) ?? counter
                counter += 1
            } else {
                _e = end.data.left
                _e_idx = end_idx
            }
            
            if var list = graph[from: _s_idx, to: _e_idx] {
                list.append((.left, _s, _e))
                graph[from: _s_idx, to: _e_idx] = list
            } else {
                graph[from: _s_idx, to: _e_idx] = [(.left, _s, _e)]
            }
        }
        for ((start_idx, start), (end_idx, end)) in _r_list.rotateZip() {
            
            let _s: Split
            let _e: Split
            let _s_idx: Int
            let _e_idx: Int
            if let data2 = start.data2, !data2.right.ordering(start.data.right) {
                _s = data2.right
                _s_idx = table.index(where: { $0.contains { $0.data.point.almostEqual(data2.point) } }) ?? counter
                counter += 1
            } else {
                _s = start.data.right
                _s_idx = start_idx
            }
            if let data2 = end.data2, data2.right.ordering(end.data.right) {
                _e = data2.right
                _e_idx = table.index(where: { $0.contains { $0.data.point.almostEqual(data2.point) } }) ?? counter
                counter += 1
            } else {
                _e = end.data.right
                _e_idx = end_idx
            }
            
            if var list = graph[from: _s_idx, to: _e_idx] {
                list.append((.right, _s, _e))
                graph[from: _s_idx, to: _e_idx] = list
            } else {
                graph[from: _s_idx, to: _e_idx] = [(.right, _s, _e)]
            }
        }
    }
}

extension IntersectionTable {
    
    fileprivate enum Overlap {
        case none, equal, superset, subset
    }
    
    fileprivate enum `Type` {
        case left
        case right
    }
    
    fileprivate struct Split {
        let index: Int
        let split: Double
    }
}

extension IntersectionTable.Split {
    
    fileprivate func almostEqual(_ other: IntersectionTable.Split) -> Bool {
        return self.index == other.index && self.split.almostEqual(other.split)
    }
    
    fileprivate func ordering(_ other: IntersectionTable.Split) -> Bool {
        return (self.index, self.split) < (other.index, other.split)
    }
}

extension Shape.Component {
    
    fileprivate func splitPath(_ start: IntersectionTable.Split, _ end: IntersectionTable.Split) -> [ShapeRegion.Solid.Segment] {
        
        if start.index == end.index && start.split.almostEqual(end.split) {
            return []
        }
        if start.index == end.index {
            let splits = self.bezier[start.index].split([start.split, end.split])
            if start.split < end.split {
                return [splits[1]]
            } else {
                let a = OptionOneCollection(start.split == 1 ? nil : splits[2])
                let b = self.bezier.suffix(from: start.index)
                let c = self.bezier.prefix(upTo: start.index)
                let d = OptionOneCollection(end.split == 0 ? nil : splits[0])
                return Array(a.concat(b.concat(c).dropFirst()).concat(d))
            }
        } else if start.index < end.index {
            let a = CollectionOfOne(self.bezier[start.index].split(start.split).1)
            let b = self.bezier[start.index..<end.index]
            let c = OptionOneCollection(self.bezier[end.index].split(end.split).0)
            return Array(a.concat(b.dropFirst()).concat(c))
        } else {
            let a = CollectionOfOne(self.bezier[start.index].split(start.split).1)
            let b = self.bezier.suffix(from: start.index)
            let c = self.bezier.prefix(upTo: end.index)
            let d = OptionOneCollection(self.bezier[end.index].split(end.split).0)
            return Array(a.concat(b.concat(c).dropFirst()).concat(d))
        }
    }
}

extension Shape.Component {
    
    fileprivate func _overlap(_ other: Shape.Component, hint: Set<Int> = []) -> Bool {
        
        if !self.bigBound.contains(other.boundary) {
            return false
        }
        if abs(self.area) < abs(other.area) {
            return false
        }
        
        for index in hint {
            return self.winding(other.bezier[index].point(0.5)) != 0
        }
        
        let self_spaces = self.spaces
        let other_spaces = other.spaces
        
        loop: for index in 0..<other.count {
            let overlap = self_spaces.search(overlap: other_spaces[index])
            if overlap.count == 0 {
                return self.winding(other.bezier[index].point(0.5)) != 0
            }
            var t: [Double] = [0, 1]
            for index2 in overlap {
                if let intersect = self.bezier[index2].intersect(other.bezier[index]) {
                    t += intersect.map { $0.1 }
                } else {
                    continue loop
                }
            }
            t.sort()
            for (u, v) in zip(t.dropLast(), t.dropFirst()) {
                return self.winding(other.bezier[index].point(0.5 * (u + v))) != 0
            }
        }
        
        return false
    }
}

extension ShapeRegion.Solid {
    
    fileprivate func intersectTable(_ other: ShapeRegion.Solid) -> IntersectionTable {
        if cache.intersect_table[other.cacheId] == nil {
            cache.intersect_table[other.cacheId] = IntersectionTable(self.solid, other.solid)
        }
        return cache.intersect_table[other.cacheId]!
    }
    
    private enum ProcessResult {
        case overlap(IntersectionTable.Overlap)
        case regions(ShapeRegion, ShapeRegion)
        case segments([ShapeRegion.Solid])
    }
    
    private func createSegments(_ other: ShapeRegion.Solid, _ graph: Graph<Int, [(IntersectionTable.`Type`, IntersectionTable.Split, IntersectionTable.Split)]>) -> [ShapeRegion.Solid] {
        
        var result: [ShapeRegion.Solid] = []
        
        var graph = graph
        
        for node in graph.nodes {
            if let splits = graph[from: node, to: node] {
                for split in splits {
                    switch split.0 {
                    case .left: result.append(contentsOf: OptionOneCollection(ShapeRegion.Solid(segments: self.solid.splitPath(split.1, split.2))))
                    case .right: result.append(contentsOf: OptionOneCollection(ShapeRegion.Solid(segments: other.solid.splitPath(split.1, split.2))))
                    }
                }
                graph[from: node, to: node] = nil
            }
        }
        while let graph_first = graph.first {
            
            var path = [graph_first.from, graph_first.to]
            var flag = [(0, graph_first.2[0].0)]
            
            while let last = path.last, let node = graph.nodes(from: last).first(where: { $0.1.contains { $0.0 != flag.last!.1 } }) ?? graph.nodes(from: last).first {
                let segments_idx = node.1.index(where: { $0.0 != flag.last!.1 }) ?? 0
                if let i = path.index(where: { $0 == node.0 }) {
                    let loop = path.suffix(from: i)
                    var segments: [ShapeRegion.Solid.Segment] = []
                    for ((_idx, _), (left, right)) in zip(flag.suffix(loop.count).appended((segments_idx, node.1[segments_idx].0)), loop.rotateZip()) {
                        if var splits = graph[from: left, to: right] {
                            let split = splits[_idx]
                            switch split.0 {
                            case .left: segments.append(contentsOf: self.solid.splitPath(split.1, split.2))
                            case .right: segments.append(contentsOf: other.solid.splitPath(split.1, split.2))
                            }
                            splits.remove(at: _idx)
                            graph[from: left, to: right] = splits.count == 0 ? nil : splits
                        }
                    }
                    result.append(contentsOf: OptionOneCollection(ShapeRegion.Solid(segments: segments)))
                    if i == 0 {
                        break
                    }
                    let range = path.index(after: i)..<path.endIndex
                    path.removeSubrange(range)
                    flag.removeLast(range.count)
                } else {
                    path.append(node.0)
                    flag.append((segments_idx, node.1[segments_idx].0))
                }
            }
        }
        
        return result
    }
    
    private func process(_ other: ShapeRegion.Solid) -> ProcessResult {
        
        if cache.process[other.cacheId] == nil && other.cache.process[cacheId] == nil {
            
            let intersectTable = self.intersectTable(other)
            
            if intersectTable.looping_left.count != 0 || intersectTable.looping_right.count != 0 {
                if cache.process_regions[other.cacheId] == nil && other.cache.process_regions[cacheId] == nil {
                    cache.process_regions[other.cacheId] = (ShapeRegion(solids: self.solid.breakLoop(intersectTable.looping_left).map { ShapeRegion.Solid(solid: $0.solid) }), ShapeRegion(solids: other.solid.breakLoop(intersectTable.looping_right).map { ShapeRegion.Solid(solid: $0.solid) }))
                }
                return .regions(cache.process_regions[other.cacheId]?.0 ?? other.cache.process_regions[cacheId]!.1, cache.process_regions[other.cacheId]?.1 ?? other.cache.process_regions[cacheId]!.0)
            }
            if intersectTable.graph.count == 0 {
                return .overlap(intersectTable.overlap)
            } else {
                cache.process[other.cacheId] = createSegments(other, intersectTable.graph)
            }
        }
        return .segments(cache.process[other.cacheId] ?? other.cache.process[cacheId]!)
    }
    
    fileprivate func _union(_ other: ShapeRegion.Solid) -> ShapeRegion? {
        
        let other = self.area.sign == other.area.sign ? other : other.reversed()
        
        switch process(other) {
        case let .overlap(overlap):
            switch overlap {
            case .equal, .superset: return ShapeRegion(solid: ShapeRegion.Solid(solid: self.solid))
            case .subset: return ShapeRegion(solid: ShapeRegion.Solid(solid: other.solid))
            case .none: return nil
            }
        case let .regions(left, right): return left.union(right)
        case let .segments(loops):
            let forward = loops.filter { !$0.area.almostZero() && self.area.sign == $0.area.sign }
            let backward = loops.filter { !$0.area.almostZero() && self.area.sign != $0.area.sign }
            return ShapeRegion(solids: forward.enumerated().filter { arg in !forward.enumerated().contains { $0.0 != arg.0 && $0.1.solid._overlap(arg.1.solid) } }.map { arg in ShapeRegion.Solid(components: [arg.1.solid] + backward.filter { arg.1.solid._overlap($0.solid) }.map { $0.solid }) })
        }
    }
    fileprivate func _intersection(_ other: ShapeRegion.Solid) -> ShapeRegion {
        
        let other = self.area.sign == other.area.sign ? other : other.reversed()
        
        switch process(other) {
        case let .overlap(overlap):
            switch overlap {
            case .equal, .subset: return ShapeRegion(solid: ShapeRegion.Solid(solid: self.solid))
            case .superset: return ShapeRegion(solid: ShapeRegion.Solid(solid: other.solid))
            case .none: return ShapeRegion()
            }
        case let .regions(left, right): return left.intersection(right)
        case let .segments(loops):
            let forward = loops.filter { !$0.area.almostZero() && self.area.sign == $0.area.sign }
            return ShapeRegion(solids: forward.enumerated().filter { arg in forward.enumerated().contains { $0.0 != arg.0 && $0.1.solid._overlap(arg.1.solid) } }.map { ShapeRegion.Solid(solid: $0.1.solid) })
        }
    }
    fileprivate func _subtracting(_ other: ShapeRegion.Solid) -> (ShapeRegion?, Bool) {
        
        let other = self.area.sign == other.area.sign ? other.reversed() : other
        
        switch process(other) {
        case let .overlap(overlap):
            switch overlap {
            case .equal, .subset: return (ShapeRegion(), false)
            case .superset: return (nil, true)
            case .none: return (nil, false)
            }
        case let .regions(left, right): return (left.subtracting(right), false)
        case let .segments(loops): return (ShapeRegion(solids: loops.filter { !$0.area.almostZero() && self.area.sign == $0.area.sign }.map { ShapeRegion.Solid(solid: $0.solid) }), false)
        }
    }
}