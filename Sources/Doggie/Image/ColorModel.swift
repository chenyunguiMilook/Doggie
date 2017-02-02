//
//  ColorModel.swift
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

public protocol ColorModelProtocol {
    
}

public protocol ColorBlendProtocol : ColorModelProtocol {
    
    func blend(operation: (Double) -> Double) -> Self
    func blend(source: Self, operation: (Double, Double) -> Double) -> Self
}

public protocol ColorVectorConvertible : ColorModelProtocol {
    
    init(_ vector: Vector)
    
    var vector: Vector { get set }
}

extension ColorBlendProtocol where Self : ColorVectorConvertible {
    
    public func blend(operation: (Double) -> Double) -> Self {
        let v = self.vector
        return Self(Vector(x: operation(v.x), y: operation(v.y), z: operation(v.z)))
    }
    public func blend(source: Self, operation: (Double, Double) -> Double) -> Self {
        let d = self.vector
        let s = source.vector
        return Self(Vector(x: operation(d.x, s.x), y: operation(d.y, s.y), z: operation(d.z, s.z)))
    }
}

public func * <C: ColorVectorConvertible, T: MatrixProtocol>(lhs: C, rhs: T) -> Vector {
    return lhs.vector * rhs
}

public func *= <C: ColorVectorConvertible, T: MatrixProtocol>(lhs: inout C, rhs: T) {
    lhs.vector *= rhs
}

public struct RGBColorModel : ColorModelProtocol {
    
    public var red: Double
    public var green: Double
    public var blue: Double
    
    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

extension RGBColorModel : ColorVectorConvertible {
    
    public init(_ vector: Vector) {
        self.red = vector.x
        self.green = vector.y
        self.blue = vector.z
    }
    
    public var vector: Vector {
        get {
            return Vector(x: red, y: green, z: blue)
        }
        set {
            self.red = newValue.x
            self.green = newValue.y
            self.blue = newValue.z
        }
    }
}

extension RGBColorModel : CustomStringConvertible {
    
    public var description: String {
        return "RGBColorModel(red: \(red), green: \(green), blue: \(blue))"
    }
}

extension RGBColorModel {
    
    public init(_ hex: UInt32) {
        self.red = Double((hex >> 16) & 0xFF) / 255
        self.green = Double((hex >> 8) & 0xFF) / 255
        self.blue = Double(hex & 0xFF) / 255
    }
}

extension RGBColorModel {
    
    public init(_ cmyk: CMYKColorModel) {
        let _k = 1 - cmyk.black
        let _cyan = cmyk.cyan * _k + cmyk.black
        let _magenta = cmyk.magenta * _k + cmyk.black
        let _yellow = cmyk.yellow * _k + cmyk.black
        self.red = 1 - _cyan
        self.green = 1 - _magenta
        self.blue = 1 - _yellow
    }
}

extension RGBColorModel {
    
    public init(hue: Double, saturation: Double, brightness: Double) {
        let _hue = positive_mod(hue, 1) * 6
        let __hue = Int(_hue)
        let c = brightness * saturation
        let x = c * (1 - abs(positive_mod(_hue, 2) - 1))
        let m = brightness - c
        switch __hue {
        case 0:
            self.red = c + m
            self.green = x + m
            self.blue = m
        case 1:
            self.red = x + m
            self.green = c + m
            self.blue = m
        case 2:
            self.red = m
            self.green = c + m
            self.blue = x + m
        case 3:
            self.red = m
            self.green = x + m
            self.blue = c + m
        case 4:
            self.red = x + m
            self.green = m
            self.blue = c + m
        default:
            self.red = c + m
            self.green = m
            self.blue = x + m
        }
    }
}

extension RGBColorModel {
    
    public var hue: Double {
        get {
            let _max = max(red, green, blue)
            let _min = min(red, green, blue)
            let c = _max - _min
            if c == 0 {
                return 0
            }
            switch _max {
            case red: return positive_mod((green - blue) / (6 * c), 1)
            case green: return positive_mod((blue - red) / (6 * c) + 2 / 6, 1)
            case blue: return positive_mod((red - green) / (6 * c) + 4 / 6, 1)
            default: return 0
            }
        }
        set {
            let _max = max(red, green, blue)
            let _min = min(red, green, blue)
            self = RGBColorModel(hue: newValue, saturation: _max == 0 ? 0 : (_max - _min) / _max, brightness: _max)
        }
    }
    
    public var saturation: Double {
        get {
            let _max = max(red, green, blue)
            let _min = min(red, green, blue)
            return _max == 0 ? 0 : (_max - _min) / _max
        }
        set {
            self = RGBColorModel(hue: hue, saturation: newValue, brightness: brightness)
        }
    }
    
    public var brightness: Double {
        get {
            return max(red, green, blue)
        }
        set {
            self = RGBColorModel(hue: hue, saturation: saturation, brightness: newValue)
        }
    }
}

public struct CMYKColorModel : ColorModelProtocol {
    
    public var cyan: Double
    public var magenta: Double
    public var yellow: Double
    public var black: Double
    
    public init(cyan: Double, magenta: Double, yellow: Double, black: Double) {
        self.cyan = cyan
        self.magenta = magenta
        self.yellow = yellow
        self.black = black
    }
}

extension CMYKColorModel : CustomStringConvertible {
    
    public var description: String {
        return "CMYKColorModel(cyan: \(cyan), magenta: \(magenta), yellow: \(yellow), black: \(black))"
    }
}

extension CMYKColorModel : ColorBlendProtocol {
    
    public func blend(operation: (Double) -> Double) -> CMYKColorModel {
        return CMYKColorModel(cyan: operation(cyan), magenta: operation(magenta), yellow: operation(yellow), black: operation(black))
    }
    public func blend(source: CMYKColorModel, operation: (Double, Double) -> Double) -> CMYKColorModel {
        return CMYKColorModel(cyan: operation(cyan, source.cyan), magenta: operation(magenta, source.magenta), yellow: operation(yellow, source.yellow), black: operation(black, source.black))
    }
}

extension CMYKColorModel {
    
    public init(_ rgb: RGBColorModel) {
        let _cyan = 1 - rgb.red
        let _magenta = 1 - rgb.green
        let _yellow = 1 - rgb.blue
        self.black = min(_cyan, _magenta, _yellow)
        if black == 1 {
            self.cyan = 0
            self.magenta = 0
            self.yellow = 0
        } else {
            let _k = 1 / (1 - black)
            self.cyan = _k * (_cyan - black)
            self.magenta = _k * (_magenta - black)
            self.yellow = _k * (_yellow - black)
        }
    }
}

public struct LabColorModel : ColorModelProtocol {
    
    /// The lightness dimension.
    public var lightness: Double
    /// The a color component.
    public var a: Double
    /// The b color component.
    public var b: Double
    
    public init(lightness: Double, a: Double, b: Double) {
        self.lightness = lightness
        self.a = a
        self.b = b
    }
    public init(lightness: Double, chroma: Double, hue: Double) {
        self.lightness = lightness
        self.a = chroma * cos(2 * Double.pi * hue)
        self.b = chroma * sin(2 * Double.pi * hue)
    }
}

extension LabColorModel : CustomStringConvertible {
    
    public var description: String {
        return "LabColorModel(lightness: \(lightness), a: \(a), b: \(b))"
    }
}

extension LabColorModel {
    
    public var hue: Double {
        get {
            return positive_mod(0.5 * atan2(b, a) / Double.pi, 1)
        }
        set {
            self = LabColorModel(lightness: lightness, chroma: chroma, hue: newValue)
        }
    }
    
    public var chroma: Double {
        get {
            return sqrt(a * a + b * b)
        }
        set {
            self = LabColorModel(lightness: lightness, chroma: newValue, hue: hue)
        }
    }
}

public struct LuvColorModel : ColorModelProtocol {
    
    /// The lightness dimension.
    public var lightness: Double
    /// The u color component.
    public var u: Double
    /// The v color component.
    public var v: Double
    
    public init(lightness: Double, u: Double, v: Double) {
        self.lightness = lightness
        self.u = u
        self.v = v
    }
    public init(lightness: Double, chroma: Double, hue: Double) {
        self.lightness = lightness
        self.u = chroma * cos(2 * Double.pi * hue)
        self.v = chroma * sin(2 * Double.pi * hue)
    }
}

extension LuvColorModel : CustomStringConvertible {
    
    public var description: String {
        return "LuvColorModel(lightness: \(lightness), u: \(u), v: \(v))"
    }
}

extension LuvColorModel {
    
    public var hue: Double {
        get {
            return positive_mod(0.5 * atan2(v, u) / Double.pi, 1)
        }
        set {
            self = LuvColorModel(lightness: lightness, chroma: chroma, hue: newValue)
        }
    }
    
    public var chroma: Double {
        get {
            return sqrt(u * u + v * v)
        }
        set {
            self = LuvColorModel(lightness: lightness, chroma: newValue, hue: hue)
        }
    }
}

public struct XYZColorModel : ColorModelProtocol {
    
    public var x: Double
    public var y: Double
    public var z: Double
    
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(luminance: Double, x: Double, y: Double) {
        let _y = 1 / y
        self.x = x * _y * luminance
        self.y = luminance
        self.z = (1 - x - y) * _y * luminance
    }
}

extension XYZColorModel {
    
    public var luminance: Double {
        get {
            return y
        }
        set {
            let _p = self.point
            self = XYZColorModel(luminance: newValue, x: _p.x, y: _p.y)
        }
    }
    
    public var point: Point {
        get {
            return Point(x: x, y: y) / (x + y + z)
        }
        set {
            self = XYZColorModel(luminance: luminance, x: newValue.x, y: newValue.y)
        }
    }
}

extension XYZColorModel : ColorVectorConvertible {
    
    public init(_ vector: Vector) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }
    
    public var vector: Vector {
        get {
            return Vector(x: x, y: y, z: z)
        }
        set {
            self.x = newValue.x
            self.y = newValue.y
            self.z = newValue.z
        }
    }
}

extension XYZColorModel : CustomStringConvertible {
    
    public var description: String {
        return "XYZColorModel(x: \(x), y: \(y), z: \(z))"
    }
}

public struct GrayColorModel : ColorModelProtocol {
    
    public var white: Double
    
    public init(white: Double) {
        self.white = white
    }
}

extension GrayColorModel : ColorBlendProtocol {
    
    public func blend(operation: (Double) -> Double) -> GrayColorModel {
        return GrayColorModel(white: operation(white))
    }
    public func blend(source: GrayColorModel, operation: (Double, Double) -> Double) -> GrayColorModel {
        return GrayColorModel(white: operation(white, source.white))
    }
}