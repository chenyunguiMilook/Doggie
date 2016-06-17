//
//  SDObserver.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2016 Susan Cheng. All rights reserved.
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

private final class SDObserverBase : NSObject {
    
    var callback: (([NSKeyValueChangeKey : AnyObject]) -> Void)? = nil
    
    let object: NSObject
    let keyPath: String
    var token = 0
    
    init(object: NSObject, keyPath: String, options: NSKeyValueObservingOptions) {
        self.object = object
        self.keyPath = keyPath
        super.init()
        object.addObserver(self, forKeyPath: keyPath, options: options, context: &token)
    }
    
    deinit {
        object.removeObserver(self, forKeyPath: keyPath, context: &token)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        if context == &token {
            if change != nil {
                callback?(change!)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

public class SDObserver<T> : SDSink<T> {
    
    private let base: SDObserverBase
    
    private init(object: NSObject, keyPath: String, options: NSKeyValueObservingOptions) {
        self.base = SDObserverBase(object: object, keyPath: keyPath, options: options)
        super.init()
        self.base.callback = { [weak self] in self?.callback($0) }
    }
    
    private func callback(_ change: [NSKeyValueChangeKey : AnyObject]) {
        
    }
}

public extension NSObject {
    
    public func bind(keyPath: String) -> SDObserver<[NSKeyValueChangeKey : AnyObject]> {
        
        final class ChangeSDObserver : SDObserver<[NSKeyValueChangeKey : AnyObject]> {
            
            init(object: NSObject, keyPath: String) {
                super.init(object: object, keyPath: keyPath, options: [.new, .old, .initial, .prior])
            }
            
            override func callback(_ change: [NSKeyValueChangeKey : AnyObject]) {
                self.put(change)
            }
        }
        
        return ChangeSDObserver(object: self, keyPath: keyPath)
    }
    
    public func willSet(keyPath: String) -> SDObserver<AnyObject> {
        
        final class WillSetSDObserver : SDObserver<AnyObject> {
            
            init(object: NSObject, keyPath: String) {
                super.init(object: object, keyPath: keyPath, options: .prior)
            }
            
            override func callback(_ change: [NSKeyValueChangeKey : AnyObject]) {
                if let old = change[.oldKey] {
                    self.put(old)
                }
            }
        }
        
        return WillSetSDObserver(object: self, keyPath: keyPath)
    }
    
    public func didSet(keyPath: String) -> SDObserver<(old: AnyObject, new: AnyObject)> {
        
        final class DidSetSDObserver : SDObserver<(old: AnyObject, new: AnyObject)> {
            
            init(object: NSObject, keyPath: String) {
                super.init(object: object, keyPath: keyPath, options: [.new, .old])
            }
            
            override func callback(_ change: [NSKeyValueChangeKey : AnyObject]) {
                if let old = change[.oldKey], new = change[.newKey] {
                    self.put(old: old, new: new)
                }
            }
        }
        
        return DidSetSDObserver(object: self, keyPath: keyPath)
    }
}
