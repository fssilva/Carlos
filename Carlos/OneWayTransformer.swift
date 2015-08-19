import Foundation

/// Abstract an object that can transform values to another type
public protocol OneWayTransformer {
  /// The input type of the transformer
  typealias TypeIn
  
  /// The output type of the transformer
  typealias TypeOut
  
  /**
  Apply the transformation from A to B
  
  - parameter val: The value to transform
  
  - returns: The transformed value, or .None if the transformation failed
  */
  func transform(val: TypeIn) -> TypeOut?
}

/// Simple implementation of the TwoWayTransformer protocol
public final class OneWayTransformationBox<I, O>: OneWayTransformer {
  /// The input type of the transformation box
  public typealias TypeIn = I
  
  /// The output type of the transformation box
  public typealias TypeOut = O
  
  private let transformClosure: I -> O?
  
  /**
  Initializes a 1-way transformation box with the given closure
  
  - parameter transform: The transformation closure to convert a value of type TypeIn into a value of type TypeOut
  */
  public init(transform: (I -> O?)) {
    self.transformClosure = transform
  }
  
  /**
  Transforms a value of type TypeIn into a value of type TypeOut
  
  - parameter val: The value to convert
  
  - returns: The converted value
  */
  public func transform(val: TypeIn) -> TypeOut? {
    return transformClosure(val)
  }
}
