//
//  PlyReader.swift
//  miniply-swift
//
//  Created by Daniel Perry on 4/30/24.
//

import Foundation

public enum PlyElementType : String {
    case VertexElement = "vertex"
    case FaceElement = "face"
}

public typealias PlyPropertyType = miniply.PLYPropertyType

public class PlyReader {
    
    private static let InvalidIndex: UInt32 = 0xFFFFFFFF
    
    private let reader: miniply.PLYReader
    
    public init(fromFilePath path: String) {
        self.reader = miniply.PLYReader.create(path)
    }
    
    deinit {
        miniply.PLYReader.destroy(self.reader)
    }
    
    public func isValid() -> Bool { self.reader.valid() }
    
    public func hasElement() -> Bool { self.reader.has_element() }
    
    public func nextElement() { self.reader.next_element() }
    
    public func currentElementIs(ofType type: PlyElementType) -> Bool {
        let typeString = type.rawValue
        return self.reader.element_is(typeString)
    }
    
    public func loadElement() -> Bool { self.reader.load_element() }
    
    /// Returns the index for the named property in the current element, or `nil` if it can't be found.
    public func findPropertyIndex(forProperty propertyName: String) -> UInt32? {
        let foundIndex = self.reader.find_property(propertyName)
        
        guard foundIndex != Self.InvalidIndex else {
            print("PLYReader: Error - Did not find property named \(propertyName)")
            return nil
        }
        
        return foundIndex
    }
    
    /// Returns the indices for the named properties in the current element, or `nil` if one or more
    /// of the given named properties can't be found in the current element.
    ///
    /// This function only retrieves the indexes for the given properties, not the actual data associated with them.
    /// Use `retrieveProperties(forIndices:ofType)`with the indices returned from this
    /// function to retrieve data from the ply file.
    ///
    /// Example:
    ///
    ///     reader.findPropertyIndices(forProperties: ["x", "y", "z"])
    public func findPropertyIndices(forProperties propertyNames: [String]) -> [UInt32]? {
        var indexes: [UInt32] = []
        
        for propertyName in propertyNames {
            guard let foundIndex = findPropertyIndex(forProperty: propertyName) else { return nil }
            indexes.append(foundIndex)
        }
        
        return indexes
    }
    
    /// Returns the number of rows the current element has.
    public func numRows() -> UInt32 { self.reader.num_rows() }
    
    /// Copy the data for the specified properties into `output`, which must be an array
    /// with at least enough space to hold all of the extracted column data. In other words,
    /// `output` must be an array of at least `numRows()` length.
    ///
    /// `T` is a container type for the returned data. All members of `T` must be of type `propertyType`.
    ///
    /// If you need to retrieve multiple types of properties, you will either need to use multiple
    /// distinct calls to `retrieveProperties` (at least one call per type) or use
    /// `retrieveProperties(forIndices:ofType:withOffset:withStride:output:)`.
    public func retrieveProperties<T> (
        forIndices indices: [UInt32],
        ofType propertyType: PlyPropertyType,
        output: UnsafeMutablePointer<T>) {
            self.reader.extract_properties(
                indices,
                UInt32(indices.count),
                propertyType,
                output)
        }
    
    /// The same as `retrieveProperties(forIndices:ofType:output:)`, but does not require
    /// the output type `T` to be of all the same type.
    ///
    /// - Parameter withOffset: The number of bytes to skip at the start of the data pointer.
    /// - Parameter withStride: The number of bytes between the start of one row and another.
    ///
    /// Example usage:
    ///
    ///     struct MyData {
    ///         var integerProperty1: Int32 = 0
    ///         var integerProperty2: Int32 = 0
    ///
    ///         var floatProperty1: Float = 0.0
    ///         var floatProperty2: Float = 0.0
    ///      }
    ///
    ///     let reader = PlyReader(fromFilePath: "/path/to/file.ply")
    ///
    ///     reader.load_element() // Assuming first element in the file is MyData
    ///     let elementCount = reader.numRows()
    ///
    ///     let dataArray: [MyData] = .init(repeating: .init(), count: elementCount)
    ///
    ///     let intIndices = reader.findPropertyIndexes(forProperties: ["int1", "int2"])
    ///     let floatIndices = reader.findPropertyIndexes(forProperties: ["float1", "float2"])
    ///
    ///     // Populate the integer properties
    ///     reader.retrieveProperties<MyData>(
    ///         forIndices: intIndices,
    ///         ofType: .Int,
    ///         withOffset: 0,
    ///         withStride: MemoryLayout<MyData>.stride,
    ///         output: dataArray)
    ///
    ///     // Populate the float properties
    ///     reader.retrieveProperties<MyData>(
    ///         forIndices: floatIndices,
    ///         ofType: .Float,
    ///         withOffset: 2 * MemoryLayout<Int32>.size,
    ///         withStride: MemoryLayout<MyData>.stride,
    ///         output: dataArray)
    ///
    public func retrieveProperties (
        forIndices indices: [UInt32],
        ofType propertyType: PlyPropertyType,
        withOffset offset: UInt32,
        withStride stride: UInt32,
        output: UnsafeMutableRawPointer) {
            
            // TODO: Untested, needs to be checked
            self.reader.extract_properties_with_stride(
                indices,
                UInt32(indices.count),
                propertyType,
                output.advanced(by: Int(offset)),
                stride)
        }
    
    /// Retrieves the data for the specified properties and returns it as an array. The array will
    /// always be of length `numRows()`.
    ///
    /// `T` is a container type for the returned data. All members of `T` must be of type `propertyType`.
    ///
    /// If you need to retrieve multiple types of properties, you will either need to use multiple
    /// distinct calls to `retrieveProperties` (at least one call per type) or use
    /// `retrieveProperties(forIndices:ofType:withOffset:withStride:output:)`.
    public func retrieveProperties<T> (
    forIndices indices: [UInt32],
    ofType propertyType: PlyPropertyType) -> [T]? {
        // Create an array of empty objects for extract_properties to write to
        let typeSize = MemoryLayout<T>.stride
        let count = Int(numRows())
        
        // Create the data buffer
        var dataArray = Data(count: count * typeSize)
        let extractSuccessful = dataArray.withUnsafeMutableBytes { (mutableRawBufferPointer: UnsafeMutableRawBufferPointer) in
            self.reader.extract_properties(
                indices,
                UInt32(indices.count),
                propertyType,
                mutableRawBufferPointer.baseAddress)
        }
        
        guard extractSuccessful else {
            print("PLYReader: Error - Property extraction returned failure")
            return nil
        }
        
        // Convert the data buffer to a list
        var outputArray: [T] = []
        dataArray.withUnsafeBytes { rawBufferPointer in
            outputArray = Array(rawBufferPointer.bindMemory(to: T.self))
        }
        
        return outputArray
    }
}
