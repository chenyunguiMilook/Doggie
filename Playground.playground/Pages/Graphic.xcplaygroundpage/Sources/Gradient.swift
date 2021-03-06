
import Cocoa
import Doggie
import DoggieGP

public func linearGradient(width: Int, height: Int) -> Image<ARGB32ColorPixel> {
    
    let context = ImageContext<ARGB32ColorPixel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    context.transform = SDTransform.scale(x: Double(width) / 300, y: Double(height) / 300)
    
    let stop1 = GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)))
    let stop2 = GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
    
    context.drawLinearGradient(stops: [stop1, stop2], start: Point(x: 50, y: 50), end: Point(x: 250, y: 250), startSpread: .pad, endSpread: .pad)
    
    return context.image
}

public func radialGradient(width: Int, height: Int) -> Image<ARGB32ColorPixel> {
    
    let context = ImageContext<ARGB32ColorPixel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    context.transform = SDTransform.scale(x: Double(width) / 300, y: Double(height) / 300)
    
    let stop1 = GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)))
    let stop2 = GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
    
    context.drawRadialGradient(stops: [stop1, stop2], start: Point(x: 100, y: 150), startRadius: 0, end: Point(x: 150, y: 150), endRadius: 100, startSpread: .pad, endSpread: .pad)
    
    return context.image
}

public func linearGradient2(width: Int, height: Int) -> Image<ARGB32ColorPixel> {
    
    let context = ImageContext<ARGB32ColorPixel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    let gradient = Gradient(type: .linear, start: Point(x: 1.0 / 6.0, y: 1.0 / 6.0), end: Point(x: 5.0 / 6.0, y: 5.0 / 6.0), stops: [
        GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0))),
        GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
        ])
    
    context.draw(shape: Shape(ellipseIn: Rect(x: 20, y: 20, width: width - 40, height: height - 40)), winding: .nonZero, gradient: gradient)
    
    return context.image
}

public func radialGradient2(width: Int, height: Int) -> Image<ARGB32ColorPixel> {
    
    let context = ImageContext<ARGB32ColorPixel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    let gradient = Gradient(type: .radial, start: Point(x: 1.0 / 3.0, y: 0.5), end: Point(x: 0.5, y: 0.5), stops: [
        GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0))),
        GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
        ])
    
    context.draw(shape: Shape(ellipseIn: Rect(x: 20, y: 20, width: width - 40, height: height - 40)), winding: .nonZero, gradient: gradient)
    
    return context.image
}

public func meshGradient(width: Int, height: Int) -> Image<ARGB32ColorPixel> {
    
    let context = ImageContext<ARGB32ColorPixel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    context.transform = SDTransform.scale(x: Double(width) / 300, y: Double(height) / 300)
    
    let patch = CubicBezierPatch(coonsPatch: Point(x: 50, y: 50), Point(x: 100, y: 0), Point(x: 200, y: 100), Point(x: 250, y: 50),
                                 Point(x: 100, y: 100), Point(x: 300, y: 100),
                                 Point(x: 0, y: 200), Point(x: 200, y: 200),
                                 Point(x: 50, y: 250), Point(x: 100, y: 200), Point(x: 200, y: 300), Point(x: 250, y: 250))
    
    context.drawGradient(patch, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)),
                         Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 1, blue: 0)),
                         Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)),
                         Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 1, blue: 1)))
    
    return context.image
}

public func linearGradient_pdf(width: Int, height: Int) -> NSImage? {
    
    let context = PDFContext(width: Double(width), height: Double(height), colorSpace: AnyColorSpace(.sRGB))
    
    context.transform = SDTransform.scale(x: Double(width) / 300, y: Double(height) / 300)
    
    let stop1 = GradientStop(offset: 0, color: AnyColor(red: 1, green: 0, blue: 0))
    let stop2 = GradientStop(offset: 1, color: AnyColor(red: 0, green: 0, blue: 1))
    
    context.drawLinearGradient(stops: [stop1, stop2], start: Point(x: 50, y: 50), end: Point(x: 250, y: 250), startSpread: .pad, endSpread: .pad)
    
    return try? NSImage(data: context.data())
}

public func radialGradient_pdf(width: Int, height: Int) -> NSImage? {
    
    let context = PDFContext(width: Double(width), height: Double(height), colorSpace: AnyColorSpace(.sRGB))
    
    context.transform = SDTransform.scale(x: Double(width) / 300, y: Double(height) / 300)
    
    let stop1 = GradientStop(offset: 0, color: AnyColor(red: 1, green: 0, blue: 0))
    let stop2 = GradientStop(offset: 1, color: AnyColor(red: 0, green: 0, blue: 1))
    
    context.drawRadialGradient(stops: [stop1, stop2], start: Point(x: 100, y: 150), startRadius: 0, end: Point(x: 150, y: 150), endRadius: 100, startSpread: .pad, endSpread: .pad)
    
    return try? NSImage(data: context.data())
}

public func linearGradient2_pdf(width: Int, height: Int) -> NSImage? {
    
    let context = PDFContext(width: Double(width), height: Double(height), colorSpace: AnyColorSpace(.sRGB))
    
    let gradient = Gradient(type: .linear, start: Point(x: 1.0 / 6.0, y: 1.0 / 6.0), end: Point(x: 5.0 / 6.0, y: 5.0 / 6.0), stops: [
        GradientStop(offset: 0, color: AnyColor(red: 1, green: 0, blue: 0)),
        GradientStop(offset: 1, color: AnyColor(red: 0, green: 0, blue: 1))
        ])
    
    context.draw(shape: Shape(ellipseIn: Rect(x: 20, y: 20, width: width - 40, height: height - 40)), winding: .nonZero, gradient: gradient)
    
    return try? NSImage(data: context.data())
}

public func radialGradient2_pdf(width: Int, height: Int) -> NSImage? {
    
    let context = PDFContext(width: Double(width), height: Double(height), colorSpace: AnyColorSpace(.sRGB))
    
    let gradient = Gradient(type: .radial, start: Point(x: 1.0 / 3.0, y: 0.5), end: Point(x: 0.5, y: 0.5), stops: [
        GradientStop(offset: 0, color: AnyColor(red: 1, green: 0, blue: 0)),
        GradientStop(offset: 1, color: AnyColor(red: 0, green: 0, blue: 1))
        ])
    
    context.draw(shape: Shape(ellipseIn: Rect(x: 20, y: 20, width: width - 40, height: height - 40)), winding: .nonZero, gradient: gradient)
    
    return try? NSImage(data: context.data())
}

public func linearGradient_gp(width: Int, height: Int) throws -> Image<Float32ColorPixel<RGBColorModel>> {
    
    let context = DGImageContext<RGBColorModel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    context.transform = SDTransform.scale(x: Double(width) / 300, y: Double(height) / 300)
    
    let stop1 = GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)))
    let stop2 = GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
    
    context.drawLinearGradient(stops: [stop1, stop2], start: Point(x: 50, y: 50), end: Point(x: 250, y: 250), startSpread: .pad, endSpread: .pad)
    
    try context.render()
    
    return context.image
}

public func radialGradient_gp(width: Int, height: Int) throws -> Image<Float32ColorPixel<RGBColorModel>> {
    
    let context = DGImageContext<RGBColorModel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    context.transform = SDTransform.scale(x: Double(width) / 300, y: Double(height) / 300)
    
    let stop1 = GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0)))
    let stop2 = GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
    
    context.drawRadialGradient(stops: [stop1, stop2], start: Point(x: 100, y: 150), startRadius: 0, end: Point(x: 150, y: 150), endRadius: 100, startSpread: .pad, endSpread: .pad)
    
    try context.render()
    
    return context.image
}

public func linearGradient2_gp(width: Int, height: Int) throws -> Image<Float32ColorPixel<RGBColorModel>> {
    
    let context = DGImageContext<RGBColorModel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    let gradient = Gradient(type: .linear, start: Point(x: 1.0 / 6.0, y: 1.0 / 6.0), end: Point(x: 5.0 / 6.0, y: 5.0 / 6.0), stops: [
        GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0))),
        GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
        ])
    
    context.draw(shape: Shape(ellipseIn: Rect(x: 20, y: 20, width: width - 40, height: height - 40)), winding: .nonZero, gradient: gradient)
    
    try context.render()
    
    return context.image
}

public func radialGradient2_gp(width: Int, height: Int) throws -> Image<Float32ColorPixel<RGBColorModel>> {
    
    let context = DGImageContext<RGBColorModel>(width: width, height: height, colorSpace: ColorSpace.sRGB)
    
    let gradient = Gradient(type: .radial, start: Point(x: 1.0 / 3.0, y: 0.5), end: Point(x: 0.5, y: 0.5), stops: [
        GradientStop(offset: 0, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 1, green: 0, blue: 0))),
        GradientStop(offset: 1, color: Color(colorSpace: context.colorSpace, color: RGBColorModel(red: 0, green: 0, blue: 1)))
        ])
    
    context.draw(shape: Shape(ellipseIn: Rect(x: 20, y: 20, width: width - 40, height: height - 40)), winding: .nonZero, gradient: gradient)
    
    try context.render()
    
    return context.image
}
