//
//  CIELabColorSpace.swift
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

public struct CIELabColorSpace : ColorSpaceProtocol {
    
    public typealias Model = LabColorModel
    
    public private(set) var cieXYZ: CIEXYZColorSpace
    
    @_inlineable
    public init(white: Point, chromaticAdaptationAlgorithm: ChromaticAdaptationAlgorithm = .default) {
        self.cieXYZ = CIEXYZColorSpace(white: white, chromaticAdaptationAlgorithm: chromaticAdaptationAlgorithm)
    }
    @_inlineable
    public init(white: XYZColorModel, black: XYZColorModel = XYZColorModel(x: 0, y: 0, z: 0), chromaticAdaptationAlgorithm: ChromaticAdaptationAlgorithm = .default) {
        self.cieXYZ = CIEXYZColorSpace(white: white, black: black, chromaticAdaptationAlgorithm: chromaticAdaptationAlgorithm)
    }
    @_inlineable
    public init(_ cieXYZ: CIEXYZColorSpace) {
        self.cieXYZ = cieXYZ
    }
    
    @_inlineable
    public var chromaticAdaptationAlgorithm: ChromaticAdaptationAlgorithm {
        get {
            return cieXYZ.chromaticAdaptationAlgorithm
        }
        set {
            cieXYZ.chromaticAdaptationAlgorithm = newValue
        }
    }
}

extension CIELabColorSpace {
    
    @_inlineable
    public func convertToLinear(_ color: Model) -> Model {
        return color
    }
    
    @_inlineable
    public func convertFromLinear(_ color: Model) -> Model {
        return color
    }
    
    @_inlineable
    public func convertLinearToXYZ(_ color: Model) -> XYZColorModel {
        let s = 216.0 / 24389.0
        let t = 27.0 / 24389.0
        let st = 216.0 / 27.0
        let fy = (color.lightness + 16) / 116
        let fx = 0.002 * color.a + fy
        let fz = fy - 0.005 * color.b
        let fx3 = fx * fx * fx
        let fz3 = fz * fz * fz
        let x = fx3 > s ? fx3 : t * (116 * fx - 16)
        let y = color.lightness > st ? fy * fy * fy : t * color.lightness
        let z = fz3 > s ? fz3 : t * (116 * fz - 16)
        let _white = XYZColorModel(luminance: 1, point: cieXYZ.normalized.white.point)
        return XYZColorModel(x: x * _white.x, y: y * _white.y, z: z * _white.z)
    }
    
    @_inlineable
    public func convertLinearFromXYZ(_ color: XYZColorModel) -> Model {
        let s = 216.0 / 24389.0
        let t = 24389.0 / 27.0
        let _white = XYZColorModel(luminance: 1, point: cieXYZ.normalized.white.point)
        let x = color.x / _white.x
        let y = color.y / _white.y
        let z = color.z / _white.z
        let fx = x > s ? cbrt(x) : (t * x + 16) / 116
        let fy = y > s ? cbrt(y) : (t * y + 16) / 116
        let fz = z > s ? cbrt(z) : (t * z + 16) / 116
        return LabColorModel(lightness: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz))
    }
}
