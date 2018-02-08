//
//  CollectionExtension.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2018 Susan Cheng. All rights reserved.
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

extension Sequence where Element : Equatable {
    
    /// Return `true` if all of elements in `seq` is `x`.
    ///
    /// - complexity: O(`self.count`).
    @_inlineable
    public func all(_ x: Element) -> Bool {
        
        for item in self where item != x {
            return false
        }
        return true
    }
}

extension Sequence {
    
    /// Return `true` if all of elements in `seq` satisfies `predicate`.
    ///
    /// - complexity: O(`self.count`).
    @_inlineable
    public func all(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        
        for item in self where try !predicate(item) {
            return false
        }
        return true
    }
}

extension Set {
    
    /// Return `true` if all of elements in `seq` is `x`.
    ///
    /// - complexity: O(1).
    @_inlineable
    public func all(_ x: Element) -> Bool {
        
        switch self.count {
        case 0:
            return true
        case 1:
            return self.first == x
        default:
            return false
        }
    }
}

extension Collection {
    
    @_inlineable
    public func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        var counter = 0
        for item in self where try predicate(item) {
            counter = counter + 1
        }
        return counter
    }
}

extension Collection where SubSequence == Self {
    
    @_inlineable
    public mutating func popFirst(_ n: Int) -> SubSequence {
        precondition(n >= 0, "Can't drop a negative number of elements from a collection")
        let result = self.prefix(n)
        self.removeFirst(Swift.min(self.count, n))
        return result
    }
}

extension BidirectionalCollection where SubSequence == Self {
    
    @_inlineable
    public mutating func popLast(_ n: Int) -> SubSequence {
        precondition(n >= 0, "Can't drop a negative number of elements from a collection")
        let result = self.suffix(n)
        self.removeLast(Swift.min(self.count, n))
        return result
    }
}

extension BidirectionalCollection {
    
    /// Returns the last element of the sequence that satisfies the given
    /// predicate or nil if no such element is found.
    ///
    /// - parameter where: A closure that takes an element of the
    ///   sequence as its argument and returns a Boolean value indicating
    ///   whether the element is a match.
    /// - Returns: The last match or `nil` if there was no match.
    @_inlineable
    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try self.reversed().first(where: predicate)
    }
}

extension Collection where Element : Equatable {
    
    @_inlineable
    public func drop(until element: Element) -> SubSequence {
        return self.drop(while: { $0 != element })
    }
    
    @_inlineable
    public func prefix(until element: Element) -> SubSequence {
        return self.prefix(while: { $0 != element })
    }
}

extension BidirectionalCollection where Element : Equatable {
    
    @_inlineable
    public func suffix(until element: Element) -> SubSequence {
        return self.suffix(while: { $0 != element })
    }
}

extension BidirectionalCollection {
    
    @_inlineable
    public func suffix(while predicate: (Element) throws -> Bool) rethrows -> SubSequence {
        return self.suffix(from: try self.reversed().index { try !predicate($0) }?.base ?? self.startIndex)
    }
}

extension RandomAccessCollection where Indices : RandomAccessCollection {
    
    /// Returns first range of `pattern` appear in `self`, or `nil` if not match.
    ///
    /// - complexity: Amortized O(`self.count`)
    @_inlineable
    public func range<C : RandomAccessCollection>(of pattern: C, where isEquivalent: (Element, Element) throws -> Bool) rethrows -> Range<Index>? where C.Element == Element {
        
        let pattern_count = pattern.count
        if count < pattern_count {
            return nil
        }
        let reverse_pattern = pattern.reversed()
        var cursor = self.index(startIndex, offsetBy: pattern_count - 1, limitedBy: endIndex) ?? endIndex
        while cursor < endIndex {
            guard let not_match = try zip(self.indices.prefix(through: cursor).reversed(), reverse_pattern).first(where: { try !isEquivalent(self[$0], $1) }) else {
                let strat = self.index(cursor, offsetBy: 1 - pattern_count)
                let end = self.index(cursor, offsetBy: 1)
                return strat..<end
            }
            let notMatchValue = self[not_match.0]
            if let pos = try reverse_pattern.dropFirst().index(where: { try isEquivalent(notMatchValue, $0) }) {
                cursor = self.index(not_match.0, offsetBy: reverse_pattern.distance(from: reverse_pattern.startIndex, to: pos), limitedBy: endIndex) ?? endIndex
            } else {
                cursor = self.index(not_match.0, offsetBy: pattern_count, limitedBy: endIndex) ?? endIndex
            }
        }
        if try self.reversed().starts(with: reverse_pattern, by: isEquivalent) {
            let strat = self.index(endIndex, offsetBy: -pattern_count)
            return strat..<endIndex
        }
        return nil
    }
}

extension RandomAccessCollection where Indices : RandomAccessCollection, Element : Equatable {
    
    /// Returns first range of `pattern` appear in `self`, or `nil` if not match.
    ///
    /// - complexity: Amortized O(`self.count`)
    @_inlineable
    public func range<C : RandomAccessCollection>(of pattern: C) -> Range<Index>? where C.Element == Element {
        return self.range(of: pattern, where: ==)
    }
}

extension MutableCollection {
    
    @_inlineable
    public mutating func mutateEach(body: (inout Element) throws -> ()) rethrows {
        for idx in self.indices {
            try body(&self[idx])
        }
    }
}

extension Sequence {
    
    @_inlineable
    public func appended(_ newElement: Element) -> ConcatSequence<Self, CollectionOfOne<Element>> {
        return self.concat(CollectionOfOne(newElement))
    }
}

extension Collection {
    
    @_inlineable
    public func appended(_ newElement: Element) -> ConcatCollection<Self, CollectionOfOne<Element>> {
        return self.concat(CollectionOfOne(newElement))
    }
}

extension LazySequenceProtocol {
    
    @_inlineable
    public func appended(_ newElement: Elements.Element) -> LazySequence<ConcatSequence<Elements, CollectionOfOne<Elements.Element>>> {
        return self.elements.appended(newElement).lazy
    }
}

extension LazyCollectionProtocol {
    
    @_inlineable
    public func appended(_ newElement: Elements.Element) -> LazyCollection<ConcatCollection<Elements, CollectionOfOne<Elements.Element>>> {
        return self.elements.appended(newElement).lazy
    }
}

extension Collection where SubSequence : Collection {
    
    @_inlineable
    public func rotated(at index: Index) -> ConcatCollection<SubSequence, SubSequence> {
        return self.suffix(from: index).concat(self.prefix(upTo: index))
    }
}

extension Collection where SubSequence : Collection {
    
    @_inlineable
    public func rotated(_ n: Int) -> ConcatCollection<SubSequence, SubSequence> {
        let count = self.count
        if count == 0 {
            return self[...].concat(self[...])
        }
        if n < 0 {
            let _n = -n % count
            return self.suffix(_n).concat(self.dropLast(_n))
        }
        let _n = n % count
        return self.dropFirst(_n).concat(self.prefix(_n))
    }
}

extension LazyCollectionProtocol where Elements.SubSequence : Collection {
    
    @_inlineable
    public func rotated(_ n: Int) -> LazyCollection<ConcatCollection<Elements.SubSequence, Elements.SubSequence>> {
        return self.elements.rotated(n).lazy
    }
}

extension Sequence where Element : Comparable {
    
    /// Returns the maximal `SubSequence`s of `self`, in order, around elements
    /// match in `separator`.
    ///
    /// - parameters:
    ///   - maxSplits: The maximum number of times to split the sequence, or one
    ///     less than the number of subsequences to return. If `maxSplits + 1`
    ///     subsequences are returned, the last one is a suffix of the original
    ///     sequence containing the remaining elements. `maxSplits` must be
    ///     greater than or equal to zero. The default value is `Int.max`.
    ///   - omittingEmptySubsequences: If `false`, an empty subsequence is
    ///     returned in the result for each pair of consecutive elements
    ///     satisfying the `isSeparator` predicate and for each element at the
    ///     start or end of the sequence satisfying the `isSeparator` predicate.
    ///     If `true`, only nonempty subsequences are returned. The default
    ///     value is `true`.
    /// - Returns: An array of subsequences, split from this sequence's elements.
    @_inlineable
    public func split<S: Sequence>(separator: S, maxSplit: Int = Int.max, omittingEmptySubsequences: Bool = true) -> [SubSequence] where S.Element == Element {
        return self.split(maxSplits: maxSplit, omittingEmptySubsequences: omittingEmptySubsequences) { separator.contains($0) }
    }
}

extension LazySequenceProtocol {
    
    /// Return a `Sequence` containing tuples satisfies `predicate` with each elements of two `sources`.
    @_inlineable
    public func merge<S>(with: S, where predicate: @escaping (Elements.Element, S.Element) -> Bool) -> LazySequence<FlattenSequence<LazyMapSequence<Elements, LazyMapSequence<LazyFilterSequence<S>, (Elements.Element, S.Element)>>>> {
        return self.flatMap { lhs in with.lazy.filter { rhs in predicate(lhs, rhs) }.map { (lhs, $0) } }
    }
}

extension LazyCollectionProtocol {
    
    /// Return a `Collection` containing tuples satisfies `predicate` with each elements of two `sources`.
    @_inlineable
    public func merge<C>(with: C, where predicate: @escaping (Elements.Element, C.Element) -> Bool) -> LazyCollection<FlattenCollection<LazyMapCollection<Elements, LazyMapCollection<LazyFilterCollection<C>, (Elements.Element, C.Element)>>>> {
        return self.flatMap { lhs in with.lazy.filter { rhs in predicate(lhs, rhs) }.map { (lhs, $0) } }
    }
}

extension Sequence {
    
    /// Return an `Array` containing tuples satisfies `predicate` with each elements of two `sources`.
    @_inlineable
    public func merge<S : Sequence>(with: S, where predicate: (Element, S.Element) throws -> Bool) rethrows -> [(Element, S.Element)] {
        var result = ContiguousArray<(Element, S.Element)>()
        for lhs in self {
            for rhs in with where try predicate(lhs, rhs) {
                result.append((lhs, rhs))
            }
        }
        return Array(result)
    }
}

extension Sequence {
    /// Returns the minimum element in `self` or `nil` if the sequence is empty.
    ///
    /// - complexity: O(`elements.count`).
    @_inlineable
    public func min<R : Comparable>(by: (Element) throws -> R) rethrows -> Element? {
        return try self.min { try by($0) < by($1) }
    }
    /// Returns the maximum element in `self` or `nil` if the sequence is empty.
    ///
    /// - complexity: O(`elements.count`).
    @_inlineable
    public func max<R : Comparable>(by: (Element) throws -> R) rethrows -> Element? {
        return try self.max { try by($0) < by($1) }
    }
}

extension MutableCollection where Self : RandomAccessCollection {
    
    @_inlineable
    public mutating func sort<R : Comparable>(by: (Element) -> R) {
        self.sort { by($0) < by($1) }
    }
}
extension Sequence {
    
    @_inlineable
    public func sorted<R : Comparable>(by: (Element) -> R) -> [Element] {
        return self.sorted { by($0) < by($1) }
    }
}

extension Comparable {
    
    @_inlineable
    public func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

extension Strideable where Stride : SignedInteger {
    
    @_inlineable
    public func clamped(to range: Range<Self>) -> Self {
        return self.clamped(to: ClosedRange(range))
    }
}

extension RangeReplaceableCollection {
    
    @_inlineable
    public mutating func replace<C : Collection>(with newElements: C) where Element == C.Element {
        self.replaceSubrange(startIndex..<endIndex, with: newElements)
    }
}

extension BidirectionalCollection where Self : MutableCollection {
    
    @_inlineable
    public mutating func reverseSubrange(_ range: Indices.SubSequence) {
        for (lhs, rhs) in zip(range, range.reversed()) {
            if lhs < rhs {
                swapAt(lhs, rhs)
            } else {
                break
            }
        }
    }
}
extension BidirectionalCollection where Self : MutableCollection, Indices : BidirectionalCollection {
    
    @_inlineable
    public func nextPermute(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Self {
        var _self = self
        if !_self.isEmpty {
            if let k = try _self.indices.dropLast().last(where: { try areInIncreasingOrder(_self[$0], _self[_self.index(after: $0)]) }) {
                let range = _self.indices.suffix(from: _self.index(after: k))
                _self.swapAt(k, try range.last { try areInIncreasingOrder(_self[k], _self[$0]) }!)
                _self.reverseSubrange(range)
            } else {
                _self.reverse()
            }
        }
        return _self
    }
}
extension BidirectionalCollection where Self : MutableCollection, Indices : BidirectionalCollection, Element : Comparable {
    
    @_inlineable
    public func nextPermute() -> Self {
        return nextPermute(by: <)
    }
}

// MARK: LazySliceSequence

extension RandomAccessCollection {
    
    @_inlineable
    public func slice(by maxLength: Int) -> [SubSequence] {
        return Array(self.lazy.slice(by: maxLength))
    }
}

@_fixed_layout
public struct LazySliceSequence<Base : RandomAccessCollection> : IteratorProtocol, LazySequenceProtocol {
    
    @_versioned
    let base: Base
    
    @_versioned
    let maxLength: Int
    
    @_versioned
    var currentIndex: Base.Index
    
    @_versioned
    @_inlineable
    init(base: Base, maxLength: Int, currentIndex: Base.Index) {
        self.base = base
        self.maxLength = maxLength
        self.currentIndex = currentIndex
    }
    
    @_inlineable
    public mutating func next() -> Base.SubSequence? {
        if currentIndex != base.endIndex {
            let nextIndex = base.index(currentIndex, offsetBy: maxLength, limitedBy: base.endIndex) ?? base.endIndex
            let result = base[currentIndex..<nextIndex]
            currentIndex = nextIndex
            return result
        }
        return nil
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return base.underestimatedCount / Int(maxLength)
    }
}

extension LazyCollectionProtocol where Elements : RandomAccessCollection {
    
    @_inlineable
    public func slice(by maxLength: Int) -> LazySliceSequence<Elements> {
        precondition(maxLength != 0, "Sliced by zero-length.")
        return LazySliceSequence(base: elements, maxLength: maxLength, currentIndex: elements.startIndex)
    }
}

// MARK: LazyScanSequence

extension Sequence {
    /// Returns an array containing the results of
    ///
    ///   p.reduce(initial, combine: combine)
    ///
    /// for each prefix `p` of `self`, in order from shortest to
    /// longest.  For example:
    ///
    ///     (1..<6).scan(0, +) // [0, 1, 3, 6, 10, 15]
    ///
    /// - complexity: O(N)
    @_inlineable
    public func scan<R>(_ initial: R, _ combine: (R, Element) throws -> R) rethrows -> [R] {
        var last = initial
        var result = [initial]
        result.reserveCapacity(self.underestimatedCount + 1)
        for x in self {
            let next = try combine(last, x)
            result.append(next)
            last = next
        }
        return result
    }
}

@_fixed_layout
public struct LazyScanIterator<Base: IteratorProtocol, Element> : IteratorProtocol, Sequence {
    
    @_versioned
    var nextElement: Element?
    
    @_versioned
    var base: Base
    
    @_versioned
    let combine: (Element, Base.Element) -> Element
    
    @_versioned
    @_inlineable
    init(nextElement: Element?, base: Base, combine: @escaping (Element, Base.Element) -> Element) {
        self.nextElement = nextElement
        self.base = base
        self.combine = combine
    }
    
    @_inlineable
    public mutating func next() -> Element? {
        return nextElement.map { result in
            nextElement = base.next().map { combine(result, $0) }
            return result
        }
    }
}

public struct LazyScanSequence<Base: Sequence, Element> : LazySequenceProtocol {
    
    public let initial: Element
    
    public let base: Base
    
    public let combine: (Element, Base.Element) -> Element
    
    @_inlineable
    public init(initial: Element, base: Base, combine: @escaping (Element, Base.Element) -> Element) {
        self.initial = initial
        self.base = base
        self.combine = combine
    }
    
    @_inlineable
    public func makeIterator() -> LazyScanIterator<Base.Iterator, Element> {
        return LazyScanIterator(nextElement: initial, base: base.makeIterator(), combine: combine)
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return base.underestimatedCount + 1
    }
}

extension LazySequenceProtocol {
    /// Returns a sequence containing the results of
    ///
    ///   p.reduce(initial, combine: combine)
    ///
    /// for each prefix `p` of `self`, in order from shortest to
    /// longest.  For example:
    ///
    ///     Array((1..<6).lazy.scan(0, +)) // [0, 1, 3, 6, 10, 15]
    ///
    /// - complexity: O(1)
    @_inlineable
    public func scan<R>(_ initial: R, _ combine: @escaping (R, Elements.Element) -> R) -> LazyScanSequence<Elements, R> {
        return LazyScanSequence(initial: initial, base: self.elements, combine: combine)
    }
}

// MARK: GatheringCollection

@_fixed_layout
public struct GatheringIterator<C: Collection, I: IteratorProtocol> : IteratorProtocol, Sequence where C.Index == I.Element {
    
    public let base : C
    
    @_versioned
    var indices: I
    
    @_versioned
    @_inlineable
    init(base: C, indices: I) {
        self.base = base
        self.indices = indices
    }
    
    public typealias Element = C.Element
    
    @_inlineable
    public mutating func next() -> Element? {
        return indices.next().map { base[$0] }
    }
}

@_fixed_layout
public struct GatheringSequence<C : Collection, I : Sequence> : Sequence where C.Index == I.Element {
    
    public typealias Iterator = GatheringIterator<C, I.Iterator>
    
    public let base: C
    
    @_versioned
    let indices: I
    
    @_versioned
    @_inlineable
    init(base: C, indices: I) {
        self.base = base
        self.indices = indices
    }
    
    @_inlineable
    public func makeIterator() -> Iterator {
        return GatheringIterator(base: base, indices: indices.makeIterator())
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return indices.underestimatedCount
    }
}

@_fixed_layout
public struct GatheringCollection<C : Collection, I : Collection> : Collection where C.Index == I.Element {
    
    public typealias Iterator = GatheringIterator<C, I.Iterator>
    
    public let base: C
    
    @_versioned
    let _indices: I
    
    @_versioned
    @_inlineable
    init(base: C, indices: I) {
        self.base = base
        self._indices = indices
    }
    
    @_inlineable
    public subscript(position: I.Index) -> C.Element {
        return base[_indices[position]]
    }
    
    @_inlineable
    public var startIndex : I.Index {
        return _indices.startIndex
    }
    @_inlineable
    public var endIndex : I.Index {
        return _indices.endIndex
    }
    
    @_inlineable
    public var indices: I.Indices {
        return _indices.indices
    }
    
    @_inlineable
    public func index(after i: I.Index) -> I.Index {
        return _indices.index(after: i)
    }
    
    @_inlineable
    public func index(_ i: I.Index, offsetBy n: Int) -> I.Index {
        return _indices.index(i, offsetBy: n)
    }
    
    @_inlineable
    public func index(_ i: I.Index, offsetBy n: Int, limitedBy limit: I.Index) -> I.Index? {
        return _indices.index(i, offsetBy: n, limitedBy: limit)
    }
    
    @_inlineable
    public func distance(from start: I.Index, to end: I.Index) -> Int {
        return _indices.distance(from: start, to: end)
    }
    
    @_inlineable
    public var count : Int {
        return _indices.count
    }
    
    @_inlineable
    public func makeIterator() -> Iterator {
        return GatheringIterator(base: base, indices: _indices.makeIterator())
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return _indices.underestimatedCount
    }
}

extension GatheringCollection : BidirectionalCollection where I : BidirectionalCollection {
    
    @_inlineable
    public func index(before i: I.Index) -> I.Index {
        return _indices.index(before: i)
    }
    
}

extension GatheringCollection : RandomAccessCollection where I : RandomAccessCollection {
    
}

extension Collection {
    
    @_inlineable
    public func collect<I>(_ indices: I) -> GatheringSequence<Self, I> {
        return GatheringSequence(base: self, indices: indices)
    }
    
    @_inlineable
    public func collect<I>(_ indices: I) -> GatheringCollection<Self, I> {
        return GatheringCollection(base: self, indices: indices)
    }
}

extension LazyCollectionProtocol {
    
    @_inlineable
    public func collect<I>(_ indices: I) -> LazySequence<GatheringSequence<Elements, I>> {
        return self.elements.collect(indices).lazy
    }
    
    @_inlineable
    public func collect<I>(_ indices: I) -> LazyCollection<GatheringCollection<Elements, I>> {
        return self.elements.collect(indices).lazy
    }
}

// MARK: OptionOneCollection

public struct OptionOneCollection<T> : RandomAccessCollection {
    
    public typealias Indices = Range<Int>
    
    public let value: T?
    
    @_inlineable
    public init(_ value: T?) {
        self.value = value
    }
    
    @_inlineable
    public var startIndex : Int {
        return 0
    }
    @_inlineable
    public var endIndex : Int {
        return value == nil ? 0 : 1
    }
    @_inlineable
    public var count : Int {
        return value == nil ? 0 : 1
    }
    
    @_inlineable
    public subscript(position: Int) -> T {
        return value!
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return value == nil ? 0 : 1
    }
}

// MARK: ConcatCollection

@_fixed_layout
public struct ConcatIterator<G1: IteratorProtocol, G2: IteratorProtocol> : IteratorProtocol, Sequence where G1.Element == G2.Element {
    
    @_versioned
    var base1: G1
    
    @_versioned
    var base2: G2
    
    @_versioned
    var flag: Int
    
    @_versioned
    @_inlineable
    init(base1: G1, base2: G2, flag: Int) {
        self.base1 = base1
        self.base2 = base2
        self.flag = flag
    }
    
    @_inlineable
    public mutating func next() -> G1.Element? {
        while true {
            switch flag {
            case 0:
                if let val = base1.next() {
                    return val
                }
                flag = 1
            case 1:
                if let val = base2.next() {
                    return val
                }
                flag = 2
            default: return nil
            }
        }
    }
}

@_fixed_layout
public struct ConcatSequence<S1 : Sequence, S2 : Sequence> : Sequence where S1.Element == S2.Element {
    
    @_versioned
    let base1: S1
    
    @_versioned
    let base2: S2
    
    @_versioned
    @_inlineable
    init(base1: S1, base2: S2) {
        self.base1 = base1
        self.base2 = base2
    }
    
    @_inlineable
    public func makeIterator() -> ConcatIterator<S1.Iterator, S2.Iterator> {
        return ConcatIterator(base1: base1.makeIterator(), base2: base2.makeIterator(), flag: 0)
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return base1.underestimatedCount + base2.underestimatedCount
    }
    
    @_inlineable
    public func _copyToContiguousArray() -> ContiguousArray<S1.Element> {
        var result = ContiguousArray<Element>()
        result.reserveCapacity(underestimatedCount)
        
        result.append(contentsOf: base1)
        result.append(contentsOf: base2)
        
        return result
    }
    
}

@_fixed_layout
public struct ConcatCollectionIndex<I1 : Comparable, I2 : Comparable> : Comparable {
    
    @_versioned
    let currect1: I1
    
    @_versioned
    let currect2: I2
    
    @_versioned
    @_inlineable
    init(currect1: I1, currect2: I2) {
        self.currect1 = currect1
        self.currect2 = currect2
    }
    
}

extension ConcatCollectionIndex : Hashable where I1 : Hashable, I2 : Hashable {
    
    @_inlineable
    public var hashValue: Int {
        return hash_combine(currect1, currect2)
    }
}

@_inlineable
public func < <I1, I2>(lhs: ConcatCollectionIndex<I1, I2>, rhs: ConcatCollectionIndex<I1, I2>) -> Bool {
    return (lhs.currect1, lhs.currect2) < (rhs.currect1, rhs.currect2)
}

@_fixed_layout
public struct ConcatCollection<S1 : Collection, S2 : Collection> : Collection where S1.Element == S2.Element {
    
    public typealias Iterator = ConcatIterator<S1.Iterator, S2.Iterator>
    
    public typealias Index = ConcatCollectionIndex<S1.Index, S2.Index>
    
    @_versioned
    let base1: S1
    
    @_versioned
    let base2: S2
    
    @_versioned
    @_inlineable
    init(base1: S1, base2: S2) {
        self.base1 = base1
        self.base2 = base2
    }
    
    @_inlineable
    public var startIndex : Index {
        return ConcatCollectionIndex(currect1: base1.startIndex, currect2: base2.startIndex)
    }
    
    @_inlineable
    public var endIndex : Index {
        return ConcatCollectionIndex(currect1: base1.endIndex, currect2: base2.endIndex)
    }
    
    @_inlineable
    public var count : Int {
        return base1.count + base2.count
    }
    
    @_inlineable
    public func index(after i: Index) -> Index {
        if i.currect1 != base1.endIndex {
            return ConcatCollectionIndex(currect1: base1.index(after: i.currect1), currect2: i.currect2)
        }
        return ConcatCollectionIndex(currect1: i.currect1, currect2: base2.index(after: i.currect2))
    }
    
    @_inlineable
    public subscript(position: Index) -> S1.Element {
        return position.currect1 != base1.endIndex ? base1[position.currect1] : base2[position.currect2]
    }
    
    @_inlineable
    public func makeIterator() -> ConcatIterator<S1.Iterator, S2.Iterator> {
        return ConcatIterator(base1: base1.makeIterator(), base2: base2.makeIterator(), flag: 0)
    }
    
    @_inlineable
    public func _copyToContiguousArray() -> ContiguousArray<S1.Element> {
        var result = ContiguousArray<Element>()
        result.reserveCapacity(underestimatedCount)
        
        result.append(contentsOf: base1)
        result.append(contentsOf: base2)
        
        return result
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return base1.underestimatedCount + base2.underestimatedCount
    }
}

extension ConcatCollection : BidirectionalCollection where S1 : BidirectionalCollection, S2 : BidirectionalCollection {
    
    @_inlineable
    public func index(before i: Index) -> Index {
        if i.currect2 != base2.startIndex {
            return ConcatCollectionIndex(currect1: i.currect1, currect2: base2.index(before: i.currect2))
        }
        return ConcatCollectionIndex(currect1: base1.index(before: i.currect1), currect2: i.currect2)
    }
    
}

extension Sequence {
    
    @_inlineable
    public func concat<S>(_ with: S) -> ConcatSequence<Self, S> {
        return ConcatSequence(base1: self, base2: with)
    }
}

extension Collection {
    
    @_inlineable
    public func concat<S>(_ with: S) -> ConcatCollection<Self, S> {
        return ConcatCollection(base1: self, base2: with)
    }
}

extension LazySequenceProtocol {
    
    @_inlineable
    public func concat<S>(_ with: S) -> LazySequence<ConcatSequence<Elements, S>> {
        return ConcatSequence(base1: self.elements, base2: with).lazy
    }
}

extension LazyCollectionProtocol {
    
    @_inlineable
    public func concat<S>(_ with: S) -> LazyCollection<ConcatCollection<Elements, S>> {
        return ConcatCollection(base1: self.elements, base2: with).lazy
    }
}

// MARK: IndexedCollection

@_fixed_layout
public struct IndexedIterator<C : Collection> : IteratorProtocol {
    
    public let base: C
    
    @_versioned
    var indices: C.Indices.Iterator
    
    @_versioned
    @_inlineable
    init(base: C, indices: C.Indices.Iterator) {
        self.base = base
        self.indices = indices
    }
    
    @_inlineable
    public mutating func next() -> (index: C.Index, element: C.Element)? {
        if let index = indices.next() {
            return (index, base[index])
        }
        return nil
    }
}

public struct IndexedCollection<C : Collection> : Collection {
    
    public let base: C
    
    @_inlineable
    public init(base: C) {
        self.base = base
    }
    
    @_inlineable
    public var startIndex: C.Index {
        return base.startIndex
    }
    @_inlineable
    public var endIndex: C.Index {
        return base.endIndex
    }
    
    @_inlineable
    public var count : Int {
        return base.count
    }
    
    @_inlineable
    public func index(after i: C.Index) -> C.Index {
        return base.index(after: i)
    }
    
    @_inlineable
    public func index(_ i: C.Index, offsetBy n: Int) -> C.Index {
        return base.index(i, offsetBy: n)
    }
    
    @_inlineable
    public func index(_ i: C.Index, offsetBy n: Int, limitedBy limit: C.Index) -> C.Index? {
        return base.index(i, offsetBy: n, limitedBy: limit)
    }
    
    @_inlineable
    public func distance(from start: C.Index, to end: C.Index) -> Int {
        return base.distance(from: start, to: end)
    }
    
    @_inlineable
    public var indices: C.Indices {
        return base.indices
    }
    
    @_inlineable
    public subscript(i: C.Index) -> (index: C.Index, element: C.Element) {
        return (i, base[i])
    }
    
    @_inlineable
    public func makeIterator() -> IndexedIterator<C> {
        return IndexedIterator(base: base, indices: base.indices.makeIterator())
    }
    
    @_inlineable
    public var underestimatedCount: Int {
        return base.underestimatedCount
    }
}

extension IndexedCollection : BidirectionalCollection where C : BidirectionalCollection {
    
    @_inlineable
    public func index(before i: C.Index) -> C.Index {
        return base.index(before: i)
    }
    
}

extension IndexedCollection : RandomAccessCollection where C : RandomAccessCollection {
    
}

extension Collection {
    
    @_inlineable
    public func indexed() -> IndexedCollection<Self> {
        return IndexedCollection(base: self)
    }
}
