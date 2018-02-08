//
//  ColorSpace.swift
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

import Foundation

@_versioned
protocol _ColorSpaceBaseProtocol {
    
    var iccData: Data? { get }
    
    var localizedName: String? { get }
    
    var cieXYZ: CIEXYZColorSpace { get }
    
    var hashValue: Int { get }
    
    func isEqualTo(_ other: _ColorSpaceBaseProtocol) -> Bool
    
    func _convertToLinear<Model : ColorModelProtocol>(_ color: Model) -> Model
    
    func _convertFromLinear<Model : ColorModelProtocol>(_ color: Model) -> Model
    
    func _convertLinearToXYZ<Model : ColorModelProtocol>(_ color: Model) -> XYZColorModel
    
    func _convertLinearFromXYZ<Model : ColorModelProtocol>(_ color: XYZColorModel) -> Model
    
    func _convertToXYZ<Model : ColorModelProtocol>(_ color: Model) -> XYZColorModel
    
    func _convertFromXYZ<Model : ColorModelProtocol>(_ color: XYZColorModel) -> Model
    
    var _linearTone: _ColorSpaceBaseProtocol { get }
}

extension _ColorSpaceBaseProtocol {
    
    @_versioned
    @_inlineable
    var iccData: Data? {
        return nil
    }
}

extension _ColorSpaceBaseProtocol where Self : Equatable {
    
    @_versioned
    @_inlineable
    func isEqualTo(_ other: _ColorSpaceBaseProtocol) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

@_versioned
protocol ColorSpaceBaseProtocol : _ColorSpaceBaseProtocol, Equatable {
    
    associatedtype Model : ColorModelProtocol
    
    associatedtype LinearTone : _ColorSpaceBaseProtocol = LinearToneColorSpace<Self>
    
    func convertToLinear(_ color: Model) -> Model
    
    func convertFromLinear(_ color: Model) -> Model
    
    func convertLinearToXYZ(_ color: Model) -> XYZColorModel
    
    func convertLinearFromXYZ(_ color: XYZColorModel) -> Model
    
    func convertToXYZ(_ color: Model) -> XYZColorModel
    
    func convertFromXYZ(_ color: XYZColorModel) -> Model
    
    var linearTone: LinearTone { get }
}

extension ColorSpaceBaseProtocol {
    
    @_versioned
    @_inlineable
    func convertToXYZ(_ color: Model) -> XYZColorModel {
        return self.convertLinearToXYZ(self.convertToLinear(color))
    }
    
    @_versioned
    @_inlineable
    func convertFromXYZ(_ color: XYZColorModel) -> Model {
        return self.convertFromLinear(self.convertLinearFromXYZ(color))
    }
}

extension ColorSpaceBaseProtocol {
    
    @_versioned
    @_inlineable
    func _convertToLinear<RModel : ColorModelProtocol>(_ color: RModel) -> RModel {
        return self.convertToLinear(color as! Model) as! RModel
    }
    
    @_versioned
    @_inlineable
    func _convertFromLinear<RModel : ColorModelProtocol>(_ color: RModel) -> RModel {
        return self.convertFromLinear(color as! Model) as! RModel
    }
    
    @_versioned
    @_inlineable
    func _convertLinearToXYZ<RModel : ColorModelProtocol>(_ color: RModel) -> XYZColorModel {
        return self.convertLinearToXYZ(color as! Model)
    }
    
    @_versioned
    @_inlineable
    func _convertLinearFromXYZ<RModel : ColorModelProtocol>(_ color: XYZColorModel) -> RModel {
        return self.convertLinearFromXYZ(color) as! RModel
    }
    
    @_versioned
    @_inlineable
    func _convertToXYZ<RModel : ColorModelProtocol>(_ color: RModel) -> XYZColorModel {
        return self.convertToXYZ(color as! Model)
    }
    
    @_versioned
    @_inlineable
    func _convertFromXYZ<RModel : ColorModelProtocol>(_ color: XYZColorModel) -> RModel {
        return self.convertFromXYZ(color) as! RModel
    }
    
    @_versioned
    @_inlineable
    var _linearTone: _ColorSpaceBaseProtocol {
        return self.linearTone
    }
}

extension ColorSpaceBaseProtocol {
    
    @_versioned
    @_inlineable
    func exteneded(_ x: Double, _ gamma: (Double) -> Double) -> Double {
        return x.sign == .plus ? gamma(x) : -gamma(-x)
    }
}

@_fixed_layout
public struct ColorSpace<Model : ColorModelProtocol> : ColorSpaceProtocol, Hashable {
    
    @_versioned
    let base : _ColorSpaceBaseProtocol
    
    public var chromaticAdaptationAlgorithm: ChromaticAdaptationAlgorithm = .default

    @_versioned
    var cache = Cache<String>()
    
    @_versioned
    @_inlineable
    init(base : _ColorSpaceBaseProtocol) {
        self.base = base
    }
}

extension ColorSpace {
    
    @_inlineable
    public var hashValue: Int {
        return base.hashValue
    }
    
    @_inlineable
    public static func ==(lhs: ColorSpace<Model>, rhs: ColorSpace<Model>) -> Bool {
        return lhs.chromaticAdaptationAlgorithm == rhs.chromaticAdaptationAlgorithm && (lhs.cache.identifier == rhs.cache.identifier || lhs.base.isEqualTo(rhs.base))
    }
}

extension ColorSpace {
    
    @_inlineable
    public var localizedName: String? {
        return base.localizedName
    }
}

extension ColorSpace : CustomStringConvertible {
    
    @_inlineable
    public var description: String {
        return localizedName.map { "\(ColorSpace.self)(localizedName: \($0))" } ?? "\(ColorSpace.self)"
    }
}

extension ColorSpace {
    
    @_inlineable
    public var iccData: Data? {
        return base.iccData
    }
}

extension ColorSpace {
    
    @_inlineable
    public var cieXYZ: ColorSpace<XYZColorModel> {
        return ColorSpace<XYZColorModel>(base: self.base.cieXYZ)
    }
    
    @_inlineable
    public func convertToLinear(_ color: Model) -> Model {
        return self.base._convertToLinear(color)
    }
    
    @_inlineable
    public func convertFromLinear(_ color: Model) -> Model {
        return self.base._convertFromLinear(color)
    }
    
    @_inlineable
    public func convertLinearToXYZ(_ color: Model) -> XYZColorModel {
        return self.base._convertLinearToXYZ(color)
    }
    
    @_inlineable
    public func convertLinearFromXYZ(_ color: XYZColorModel) -> Model {
        return self.base._convertLinearFromXYZ(color)
    }
    
    @_inlineable
    public func convertToXYZ(_ color: Model) -> XYZColorModel {
        return self.base._convertToXYZ(color)
    }
    
    @_inlineable
    public func convertFromXYZ(_ color: XYZColorModel) -> Model {
        return self.base._convertFromXYZ(color)
    }
}

extension ColorSpace {
    
    @_inlineable
    public func convertToLinear<S: ColorPixelProtocol>(_ color: S) -> S where S.Model == Model {
        return S(color: self.convertToLinear(color.color), opacity: color.opacity)
    }
    
    @_inlineable
    public func convertFromLinear<S: ColorPixelProtocol>(_ color: S) -> S where S.Model == Model {
        return S(color: self.convertFromLinear(color.color), opacity: color.opacity)
    }
    
    @_inlineable
    public func convertLinearToXYZ<S: ColorPixelProtocol, T: ColorPixelProtocol>(_ color: S) -> T where S.Model == Model, T.Model == XYZColorModel {
        return T(color: self.convertLinearToXYZ(color.color), opacity: color.opacity)
    }
    
    @_inlineable
    public func convertLinearFromXYZ<S: ColorPixelProtocol, T: ColorPixelProtocol>(_ color: T) -> S where S.Model == Model, T.Model == XYZColorModel {
        return S(color: self.convertLinearFromXYZ(color.color), opacity: color.opacity)
    }
    
    @_inlineable
    public func convertToXYZ<S: ColorPixelProtocol, T: ColorPixelProtocol>(_ color: S) -> T where S.Model == Model, T.Model == XYZColorModel {
        return T(color: self.convertToXYZ(color.color), opacity: color.opacity)
    }
    
    @_inlineable
    public func convertFromXYZ<S: ColorPixelProtocol, T: ColorPixelProtocol>(_ color: T) -> S where S.Model == Model, T.Model == XYZColorModel {
        return S(color: self.convertFromXYZ(color.color), opacity: color.opacity)
    }
}

extension ColorSpace {
    
    @_inlineable
    public func convertToLinear<C : Collection, R : RangeReplaceableCollection>(_ color: C) -> R where C.Element == Model, C.Element == R.Element {
        return R(color.lazy.map(self.convertToLinear))
    }
    
    @_inlineable
    public func convertToLinear<C : Collection, R : RangeReplaceableCollection>(_ color: C) -> R where C.Element: ColorPixelProtocol, C.Element.Model == Model, C.Element == R.Element {
        return R(color.lazy.map(self.convertToLinear))
    }
}

extension ColorSpace {
    
    @_inlineable
    public func convertFromLinear<C : Collection, R : RangeReplaceableCollection>(_ color: C) -> R where C.Element == Model, C.Element == R.Element {
        return R(color.lazy.map(self.convertFromLinear))
    }
    
    @_inlineable
    public func convertFromLinear<C : Collection, R : RangeReplaceableCollection>(_ color: C) -> R where C.Element: ColorPixelProtocol, C.Element.Model == Model, C.Element == R.Element {
        return R(color.lazy.map(self.convertFromLinear))
    }
}

extension CIEXYZColorSpace {
    
    @_versioned
    @inline(__always)
    func _intentMatrix(to other: CIEXYZColorSpace, chromaticAdaptationAlgorithm: ChromaticAdaptationAlgorithm, intent: RenderingIntent) -> Matrix {
        switch intent {
        case .perceptual: return self.chromaticAdaptationMatrix(to: other, chromaticAdaptationAlgorithm)
        case .absoluteColorimetric: return Matrix.identity
        case .relativeColorimetric: return CIEXYZColorSpace(white: self.white).chromaticAdaptationMatrix(to: CIEXYZColorSpace(white: other.white), chromaticAdaptationAlgorithm)
        }
    }
}

extension ColorSpace {
    
    @_versioned
    @inline(__always)
    func _convert<C : Collection, R>(_ color: C, to other: ColorSpace<R>, intent: RenderingIntent) -> LazyMapCollection<C, R> where C.Element == Model {
        let matrix = self.base.cieXYZ._intentMatrix(to: other.base.cieXYZ, chromaticAdaptationAlgorithm: chromaticAdaptationAlgorithm, intent: intent)
        return color.lazy.map { other.convertFromXYZ(self.convertToXYZ($0) * matrix) }
    }
    
    @_versioned
    @inline(__always)
    func _convert<C : Collection, R: ColorPixelProtocol>(_ color: C, to other: ColorSpace<R.Model>, intent: RenderingIntent) -> LazyMapCollection<C, R> where C.Element: ColorPixelProtocol, C.Element.Model == Model {
        let matrix = self.base.cieXYZ._intentMatrix(to: other.base.cieXYZ, chromaticAdaptationAlgorithm: chromaticAdaptationAlgorithm, intent: intent)
        return color.lazy.map { R(color: other.convertFromXYZ(self.convertToXYZ($0.color) * matrix), opacity: $0.opacity) }
    }
    
    @_inlineable
    public func convert<R>(_ color: Model, to other: ColorSpace<R>, intent: RenderingIntent = .default) -> R {
        return self._convert(CollectionOfOne(color), to: other, intent: intent)[0]
    }
    
    @_inlineable
    public func convert<S: ColorPixelProtocol, R: ColorPixelProtocol>(_ color: S, to other: ColorSpace<R.Model>, intent: RenderingIntent = .default) -> R where S.Model == Model {
        return self._convert(CollectionOfOne(color), to: other, intent: intent)[0]
    }
    
    @_inlineable
    public func convert<C : Collection, R : RangeReplaceableCollection>(_ color: C, to other: ColorSpace<R.Element>, intent: RenderingIntent = .default) -> R where C.Element == Model {
        return R(self._convert(color, to: other, intent: intent))
    }
    
    @_inlineable
    public func convert<C : Collection, R : RangeReplaceableCollection>(_ color: C, to other: ColorSpace<R.Element.Model>, intent: RenderingIntent = .default) -> R where C.Element: ColorPixelProtocol, C.Element.Model == Model, R.Element: ColorPixelProtocol {
        return R(self._convert(color, to: other, intent: intent))
    }
    
    @_versioned
    @inline(__always)
    func convert<C : Collection, R>(_ color: C, to other: ColorSpace<R.Model>, intent: RenderingIntent = .default, option: MappedBufferOption = .default) -> MappedBuffer<R> where C.Element: ColorPixelProtocol, C.Element.Model == Model, R: ColorPixelProtocol {
        return MappedBuffer<R>(self._convert(color, to: other, intent: intent), option: option)
    }
}

extension ColorSpace {
    
    @_inlineable
    public var linearTone: ColorSpace {
        return ColorSpace(base: base._linearTone)
    }
    
    @_inlineable
    public var referenceWhite: XYZColorModel {
        return base.cieXYZ.white
    }
    
    @_inlineable
    public var referenceBlack: XYZColorModel {
        return base.cieXYZ.black
    }
    
    @_inlineable
    public var luminance: Double {
        return base.cieXYZ.luminance
    }
}

extension ColorSpace {
    
    @_inlineable
    public static var numberOfComponents: Int {
        return Model.numberOfComponents
    }
    
    @_inlineable
    public var numberOfComponents: Int {
        return Model.numberOfComponents
    }
    
    @_inlineable
    public static func rangeOfComponent(_ i: Int) -> ClosedRange<Double> {
        return Model.rangeOfComponent(i)
    }
    
    @_inlineable
    public func rangeOfComponent(_ i: Int) -> ClosedRange<Double> {
        return Model.rangeOfComponent(i)
    }
}

