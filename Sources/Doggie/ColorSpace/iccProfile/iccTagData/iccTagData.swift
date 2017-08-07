//
//  iccTagData.swift
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

extension iccProfile {
    
    struct TagData {
        
        let rawData: Data
        
        init(rawData: Data) {
            self.rawData = rawData
        }
        
        var type: TagType {
            return rawData.withUnsafeBytes { $0.pointee }
        }
        
        var data: Data {
            return rawData.advanced(by: 8)
        }
    }
}

extension iccProfile.TagData {
    
    private var _obj: Any? {
        
        switch type {
        case .uInt16Array: return uInt16Array
        case .uInt32Array: return uInt32Array
        case .uInt64Array: return uInt64Array
        case .uInt8Array: return uInt8Array
        case .s15Fixed16Array: return s15Fixed16Array
        case .u16Fixed16Array: return u16Fixed16Array
        case .XYZArray: return XYZArray
        case .curve, .parametricCurve: return curve
        case .namedColor2: return namedColor
        case .text: return text
        case .multiLocalizedUnicode: return multiLocalizedUnicode
        case .lut8, .lut16, .lutAtoB, .lutBtoA: return transform
        default: return nil
        }
    }
}

extension iccProfile.TagData {
    
    var uInt16Array: [BEUInt16]? {
        
        return type == .uInt16Array ? data.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0, count: data.count / MemoryLayout<BEUInt16>.stride)) } : nil
    }
    
    var uInt32Array: [BEUInt32]? {
        
        return type == .uInt32Array ? data.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0, count: data.count / MemoryLayout<BEUInt32>.stride)) } : nil
    }
    
    var uInt64Array: [BEUInt64]? {
        
        return type == .uInt64Array ? data.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0, count: data.count / MemoryLayout<BEUInt64>.stride)) } : nil
    }
    
    var uInt8Array: [UInt8]? {
        
        return type == .uInt8Array ? data.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0, count: data.count / MemoryLayout<UInt8>.stride)) } : nil
    }
}

extension iccProfile.TagData {
    
    var s15Fixed16Array: [Fixed16Number<BEInt32>]? {
        
        return type == .s15Fixed16Array ? data.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0, count: data.count / MemoryLayout<Fixed16Number<BEInt32>>.stride)) } : nil
    }
    
    var u16Fixed16Array: [Fixed16Number<BEUInt32>]? {
        
        return type == .u16Fixed16Array ? data.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0, count: data.count / MemoryLayout<Fixed16Number<BEUInt32>>.stride)) } : nil
    }
}

extension iccProfile.TagData {
    
    var XYZArray: [iccXYZNumber]? {
        
        return type == .XYZArray ? data.withUnsafeBytes { Array(UnsafeBufferPointer(start: $0, count: data.count / MemoryLayout<iccXYZNumber>.stride)) } : nil
    }
}

extension iccProfile.TagData {
    
    var multiLocalizedUnicode: iccMultiLocalizedUnicode? {
        var data = self.rawData
        return type == .multiLocalizedUnicode ? try? iccMultiLocalizedUnicode(from: &data) : nil
    }
}

extension iccProfile.TagData {
    
    var curve: iccCurve? {
        var data = self.rawData
        return type == .curve || type == .parametricCurve ? try? iccCurve(from: &data) : nil
    }
}

extension iccProfile.TagData {
    
    var namedColor: iccNamedColor? {
        var data = self.rawData
        return type == .namedColor2 ? try? iccNamedColor(from: &data) : nil
    }
}

extension iccProfile.TagData {
    
    var transform: iccTransform? {
        var data = self.rawData
        return type == .lut8 || type == .lut16 || type == .lutAtoB || type == .lutBtoA ? try? iccTransform(from: &data) : nil
    }
}

extension iccProfile.TagData {
    
    var text: String? {
        
        return type == .text ? String(bytes: data, encoding: .ascii) : nil
    }
}

extension iccProfile.TagData {
    
    var textDescription: iccTextDescription? {
        var data = self.rawData
        return type == .textDescription ? try? iccTextDescription(from: &data) : nil
    }
}

