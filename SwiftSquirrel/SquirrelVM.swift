//
//  SquirrelVM.swift
//  SwiftSquirrel
//
//  Created by Egor Chiglintsev on 05.04.15.
//  Copyright (c) 2015  Egor Chiglintsev
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import CSquirrel

public func SQ_SUCCEEDED(result: SQRESULT) -> Bool {
    return result == SQRESULT(SQ_OK)
}

public class SquirrelVM {
    // MARK: - SquirrelVM::constants
    public static let DefaultStackSize = 1024
    
    // MARK: - SquirrelVM::properties
    public let stack: Stack
    public lazy var compiler: Compiler = Compiler(vm: self)
    
    public var rootTable: SQTable {
        get {
            return SQTable(vm: self, object: object.rootTable())
        }
    }
    
    // MARK: - SquirrelVM::initializers
    public init(vm: HSQUIRRELVM) {
        self.vm = vm
        stack = StackImpl(vm: vm)
        vm ~ self
    }
    
    convenience public init(stackSize: Int) {
        let vm = sq_open(SQInteger(stackSize))
        self.init(vm: vm)
    }
    
    convenience public init() {
        self.init(stackSize: SquirrelVM.DefaultStackSize)
    }
    
    public static func associated(#vm: HSQUIRRELVM) -> SquirrelVM {
        if let vm = ~vm {
            return vm
        }
        
        return SquirrelVM(vm: vm)
    }
    
    deinit {
        vm ~ nil
        sq_close(vm)
    }
    
    // MARK: - SquirrelVM::methods
    public func generateKeyValuePairs<T: SQObject where T: SquirrelCollection>(collection obj: T) -> KeyValueGenerator<T> {
        return KeyValueGenerator<T>(vm: self, collection: obj)
    }
    
    public func generateIndexValuePairs<T: SQObject where T: SquirrelCollection>(collection obj: T) -> ArrayGenerator<T> {
        return ArrayGenerator(generator: KeyValueGenerator<T>(vm: self, collection: obj))
    }

    // MARK: - SquirrelVM::internal
    internal let vm: HSQUIRRELVM
    internal lazy var object: SQObjectAPI = ObjectAPIImpl(vm: self.vm)
    internal lazy var container: SQContainerAPI = ContainerAPIImpl(vm: self)
    
    
    // MARK: - SquirrelVM::private
    private func create(createFunc: (HSQUIRRELVM) -> ()) -> HSQOBJECT {
        let top = stack.top
        
        var obj: HSQOBJECT = HSQOBJECT()
        sq_resetobject(&obj)
    
        createFunc(vm)
        sq_getstackobj(vm, -1, &obj)
        
        stack.top = top
        return obj
    }
    
    
    // MARK: - SquirrelVM::private: container API
    private class ContainerAPIImpl : SQContainerAPI {
        init(vm: SquirrelVM) {
            self.vm = vm.vm
            self.stack = vm.stack
        }
        
        // MARK: - SquirrelVM::ContainerAPI::<SQContainerAPI>
        private func count<T: SquirrelCollection>(object: T) -> Int {
            stack << object
            let result = sq_getsize(vm, -1)
            stack.pop(1)
            return Int(result)
        }
        
        private func getSlot(collection: SquirrelCollection, key: SQValue) -> SQValue {
            var result: SQValue = .Null
            
            let top = stack.top
            
            stack << collection
            stack << key
            
            if SQ_SUCCEEDED(sq_get(vm, -2)) {
                result = stack[-1]
            }
            
            stack.top = top
            
            return result
        }
        
        private func newSlot(table: SquirrelCollection, key: SQValue, value: SQValue) -> Bool {
            return collectionSetter(collection: table, key: key, value: value,
                operation: bind(sq_newslot, SQBool(SQFalse)))
        }
        
        private func setSlot(collection: SquirrelCollection, key: SQValue, value: SQValue) -> Bool {
            return collectionSetter(collection: collection, key: key, value: value, operation: sq_set)
        }
        
        // MARK: - SquirrelVM::ContainerAPI::private
        private let vm: HSQUIRRELVM
        private let stack: Stack
        
        private func collectionSetter(#collection: SquirrelCollection, key: SQValue, value: SQValue,
            operation: (HSQUIRRELVM, SQInteger) -> SQRESULT) -> Bool {
                let top = stack.top
                
                stack << collection
                stack << key
                stack << value
                let result = SQ_SUCCEEDED(operation(vm, -3))
                
                stack.top = top
                
                return result
        }
    }
    
    // MARK: - SquirrelVM::private: object API
    private class ObjectAPIImpl: SQObjectAPI {
        init(vm: HSQUIRRELVM) {
            self.vm = vm
        }
        
        // MARK: - SquirrelVM::ObjectAPI::<SQObjectAPI>
        private func retain(inout obj: HSQOBJECT) -> HSQOBJECT {
            sq_addref(vm, &obj)
            return obj
        }
        
        private func release(inout obj: HSQOBJECT) -> HSQOBJECT {
            sq_release(vm, &obj)
            return obj
        }
        
        private func retainCount(inout obj: HSQOBJECT) -> Int {
            return Int(sq_getrefcount(vm, &obj))
        }
        
        private func table() -> HSQOBJECT {
            return create(sq_newtable)
        }
        
        private func rootTable() -> HSQOBJECT {
            return create(sq_pushroottable)
        }
        
        private func array() -> HSQOBJECT {
            return create(bind(sq_newarray, 0))
        }
        
        private func array(#size: Int) -> HSQOBJECT {
            return create(bind(sq_newarray, SQInteger(size)))
        }
        
        private func null() -> HSQOBJECT {
            var result = HSQOBJECT()
            sq_resetobject(&result)
            return result
        }
        
        private func equal(left: HSQOBJECT, _ right: HSQOBJECT) -> Bool {
            return (compare(left, right) == 0)
        }
        
        private func compare(left: HSQOBJECT, _ right: HSQOBJECT) -> Int {
            let top = sq_gettop(vm)
            sq_pushobject(vm, left)
            sq_pushobject(vm, right)
            
            let result = sq_cmp(vm)
            
            sq_settop(vm, top)
            
            return Int(result)
        }
        
        private func create(creationFunc: (HSQUIRRELVM) -> ()) -> HSQOBJECT {
            var result = null()
            
            let top = sq_gettop(vm)
            
            creationFunc(vm)
            sq_getstackobj(vm, -1, &result)
            sq_addref(vm, &result)
            
            sq_settop(vm, top)
            
            return result
        }
        
        // MARK: - SquirrelVM::ObjectAPI::private
        private let vm: HSQUIRRELVM
    }
    
    // MARK: - SquirrleVM::private: stack
    private class StackImpl: Stack {
        // MARK: - SquirrelVM::StackImpl::<VMStack>
        private var top: Int {
            get {
                return Int(sq_gettop(vm))
            }
            
            set(value) {
                sq_settop(vm, SQInteger(value))
            }
        }
        
        private func pop(count: Int) {
            sq_pop(vm, SQInteger(count))
        }
        
        private func push(x: SQValueConvertible) {
            switch (x.asSQValue) {
            case let .Int(value):
                sq_pushinteger(vm, SQInteger(value))
                
            case let .Float(value):
                sq_pushfloat(vm, SQFloat(value))
                
            case let .Bool(value):
                sq_pushbool(vm, (value == true) ? SQBool(SQTrue) : SQBool(SQFalse))
                
            case let .String(value):
                let (length, cString) = value.toSquirrelString()
                sq_pushstring(vm, cString, SQInteger(length))
                
            case let .Object(value):
                sq_pushobject(vm, value.obj)
                
            case .Null:
                sq_pushnull(vm)
            }
        }
        
        private subscript(position: Int) -> SQValue {
            switch (sq_gettype(vm, SQInteger(position)).value) {
                
            case OT_INTEGER.value:
                var value: SQInteger = 0
                sq_getinteger(vm, SQInteger(position), &value)
                return .Int(Int(value))
                
            case OT_FLOAT.value:
                var value: SQFloat = 0
                sq_getfloat(vm, SQInteger(position), &value)
                return .Float(Double(value))
                
            case OT_BOOL.value:
                var value: SQBool = 0
                sq_getbool(vm, SQInteger(position), &value)
                return (value == SQBool(SQTrue)) ? .Bool(true) : .Bool(false)
                
            case OT_STRING.value:
                var cString: UnsafePointer<SQChar> = nil
                sq_getstring(vm, SQInteger(position), &cString)
                if let string = String.fromCString(cString) {
                    return .String(string)
                }
                else {
                    return .Null
                }
                
            case OT_TABLE.value:
                return valueWithStackObject(at: position) { SQTable(vm: $0, object: $1) }
                
            case OT_ARRAY.value:
                return valueWithStackObject(at: position) { SQArray(vm: $0, object: $1) }
                
            case OT_CLOSURE.value:
                return valueWithStackObject(at: position) { SQClosure(vm: $0, object: $1) }
                
            default:
                return .Null
            }
        }
        
        private func valueWithStackObject(at position: Int, constructor:(SquirrelVM, HSQOBJECT) -> SQObject) -> SQValue {
            var obj: HSQOBJECT = HSQOBJECT()
            sq_resetobject(&obj)
            sq_getstackobj(vm, SQInteger(position), &obj)
            return .Object(constructor(SquirrelVM.associated(vm: vm), obj))
        }
        
        private func integer(at position: Int) -> Int? {
            return self[position].asInt
        }
        
        private func float(at position: Int) -> Double? {
            return self[position].asFloat
        }
        
        private func bool(at position: Int) -> Bool? {
            return self[position].asBool
        }
        
        private func string(at position: Int) -> String? {
            return self[position].asString
        }
        
        private func object(at position: Int) -> SQObject? {
            return self[position].asObject
        }
        
        private func table(at position: Int) -> SQTable? {
            return self[position].asTable
        }
        
        private func array(at position: Int) -> SQArray? {
            return self[position].asArray
        }
        
        private func closure(at position: Int) -> SQClosure? {
            return self[position].asClosure
        }

        // MARK: - SquirrelVM::StackImpl::initializers
        private init(vm: HSQUIRRELVM) {
            self.vm = vm
        }
        
        // MARK: - SquirrelVM::StackImpl::private
        private let vm: HSQUIRRELVM
    }
}

infix operator ~ { associativity left precedence 140 }
prefix operator ~ {}

private func ~ (sqvm: HSQUIRRELVM, vm: SquirrelVM?) {
    if let vm = vm {
        var foreignPtr = UnsafeMutablePointer<Weak<SquirrelVM>>.alloc(1)
        foreignPtr.initialize(Weak(value: vm))
        sq_setforeignptr(sqvm, foreignPtr)
    }
    else {
        let foreignPtr = sq_getforeignptr(sqvm)
        if foreignPtr != nil {
            foreignPtr.destroy()
            foreignPtr.dealloc(1)
        }
    }
}

private prefix func ~ (vm: HSQUIRRELVM) -> SquirrelVM? {
    let ptr = sq_getforeignptr(vm)
    
    if ptr != nil {
        if let vm = UnsafeMutablePointer<Weak<SquirrelVM>>(ptr).memory.value {
            return vm;
        }
    }
    return nil
}
