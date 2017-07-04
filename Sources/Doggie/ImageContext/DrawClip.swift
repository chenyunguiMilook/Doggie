//
//  DrawClip.swift
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

extension ImageContext {
    
    @_inlineable
    public func drawClip<P>(body: (ImageContext<P>) throws -> Void) rethrows where P.Model == GrayColorModel {
        
        if let next = self.next {
            try next.drawClip(body: body)
            return
        }
        
        let width = self.width
        let height = self.height
        
        if width == 0 || height == 0 {
            return
        }
        
        let _clip = ImageContext<P>(width: width, height: height, colorSpace: ColorSpace.calibratedGray(from: colorSpace))
        _clip._antialias = self._antialias
        _clip._transform = self._transform
        _clip._blendMode = self._blendMode
        _clip._compositingMode = self._compositingMode
        _clip._resamplingAlgorithm = self._resamplingAlgorithm
        _clip._renderCullingMode = self._renderCullingMode
        _clip._renderDepthCompareMode = self._renderDepthCompareMode
        _clip._renderingIntent = self._renderingIntent
        _clip._image.colorSpace.chromaticAdaptationAlgorithm = self._image.colorSpace.chromaticAdaptationAlgorithm
        
        try body(_clip)
        
        self.clip = _clip.image.pixel.map { $0.color.white * $0.opacity }
    }
}