//
//  Rational.swift
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

public struct Rational: Comparable {
    
    public let numerator: Int64
    public let denominator: Int64
    
    @_transparent
    public init<T: BinaryInteger>(_ numerator: T) {
        self.numerator = Int64(numerator)
        self.denominator = 1
    }
    
    @_transparent
    public init<T: UnsignedInteger>(_ numerator: T, _ denominator: T) {
        
        if numerator == 0 || denominator == 0 || numerator == 1 || denominator == 1 {
            
            self.numerator = Int64(numerator)
            self.denominator = Int64(denominator)
            
        } else {
            
            let common = gcd(numerator, denominator)
            
            self.numerator = Int64(numerator / common)
            self.denominator = Int64(denominator / common)
        }
    }
    
    @_transparent
    public init<T: SignedInteger>(_ numerator: T, _ denominator: T) {
        
        if numerator == 0 || denominator == 0 || numerator == 1 || denominator == 1 {
            
            self.numerator = Int64(numerator)
            self.denominator = Int64(denominator)
            
        } else {
            
            let common = gcd(Swift.abs(numerator), Swift.abs(denominator))
            
            if denominator < 0 {
                self.numerator = Int64(-numerator / common)
                self.denominator = Int64(-denominator / common)
            } else {
                self.numerator = Int64(numerator / common)
                self.denominator = Int64(denominator / common)
            }
        }
    }
    
    @_transparent
    public init<T: BinaryFloatingPoint>(_ value: T) {
        
        if value.isZero {
            
            self.init(0)
            
        } else if value.isFinite {
            
            let bias = 1 << T.significandBitCount
            let exponent = value.exponent
            
            let n = Int(value.significandBitPattern) | bias
            self.init(value.sign == .plus ? n : -n, bias)
            
            self *= exponent > 0 ? Rational(1 << exponent, 1) : Rational(1, 1 << -exponent)
            
        } else {
            self.init(0, 0)
        }
    }
}

extension Rational: ExpressibleByFloatLiteral {
    
    @_transparent
    public init(integerLiteral value: Int64) {
        self.init(value)
    }
    
    @_transparent
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension Rational: CustomStringConvertible {
    
    @_transparent
    public var description: String {
        return "\(doubleValue)"
    }
}

extension Rational: Hashable {
    
    @_transparent
    public var hashValue: Int {
        return hash_combine(numerator, denominator)
    }
}

extension Rational: SignedNumeric {
    
    @_transparent
    public init?<T>(exactly source: T) where T : BinaryInteger {
        guard let value = Int64(exactly: source) else { return nil }
        self.init(value)
    }
    
    public typealias Magnitude = Rational
    
    @_transparent
    public static func abs(_ x: Rational) -> Rational {
        return x.magnitude
    }
    
    @_transparent
    public var magnitude: Rational {
        return Rational(Swift.abs(numerator), denominator)
    }
}

extension Rational {
    
    @_transparent
    public var floatValue: Float {
        return Float(doubleValue)
    }
    
    @_transparent
    public var doubleValue: Double {
        return Double(numerator) / Double(denominator)
    }
}

extension Rational : Divisive, ScalarMultiplicative {
    
    public typealias Scalar = Rational
    
    @_transparent
    public init() {
        self.init(0)
    }
}

@_transparent
public func ==(lhs: Rational, rhs: Rational) -> Bool {
    return lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
}

@_transparent
public func <(lhs: Rational, rhs: Rational) -> Bool {
    return lhs.numerator * rhs.denominator < lhs.denominator * rhs.numerator
}

@_transparent
public prefix func +(x: Rational) -> Rational {
    return x
}

@_transparent
public prefix func -(x: Rational) -> Rational {
    return Rational(-x.numerator, x.denominator)
}

@_transparent
public func +(lhs: Rational, rhs: Rational) -> Rational {
    return lhs.denominator == rhs.denominator ? Rational(lhs.numerator + rhs.numerator, lhs.denominator) : Rational(lhs.numerator * rhs.denominator + lhs.denominator * rhs.numerator, lhs.denominator * rhs.denominator)
}

@_transparent
public func -(lhs: Rational, rhs: Rational) -> Rational {
    return lhs.denominator == rhs.denominator ? Rational(lhs.numerator - rhs.numerator, lhs.denominator) : Rational(lhs.numerator * rhs.denominator - lhs.denominator * rhs.numerator, lhs.denominator * rhs.denominator)
}

@_transparent
public func *(lhs: Rational, rhs: Rational) -> Rational {
    return Rational(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)
}

@_transparent
public func /(lhs: Rational, rhs: Rational) -> Rational {
    return Rational(lhs.numerator * rhs.denominator, lhs.denominator * rhs.numerator)
}

@_transparent
public func +=(lhs: inout Rational, rhs: Rational) {
    lhs = lhs + rhs
}

@_transparent
public func -=(lhs: inout Rational, rhs: Rational) {
    lhs = lhs - rhs
}

@_transparent
public func *=(lhs: inout Rational, rhs: Rational) {
    lhs = lhs * rhs
}

@_transparent
public func /=(lhs: inout Rational, rhs: Rational) {
    lhs = lhs / rhs
}

