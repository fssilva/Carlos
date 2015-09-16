import Foundation
import Quick
import Nimble
import Carlos

private struct KeyTransformationsSharedExamplesContext {
  static let CacheToTest = "cache"
  static let InternalCache = "internalCache"
  static let Transformer = "transformer"
}

class KeyTransformationSharedExamplesConfiguration: QuickConfiguration {
  override class func configure(configuration: Configuration) {
    sharedExamples("a fetch closure with transformed keys") { (sharedExampleContext: SharedExampleContext) in
      var cache: BasicCache<Int, Int>!
      var internalCache: CacheLevelFake<String, Int>!
      var transformer: OneWayTransformationBox<Int, String>!
      
      beforeEach {
        cache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.CacheToTest] as? BasicCache<Int, Int>
        internalCache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.InternalCache] as? CacheLevelFake<String, Int>
        transformer = sharedExampleContext()[KeyTransformationsSharedExamplesContext.Transformer] as? OneWayTransformationBox<Int, String>
      }
      
      context("when calling get") {
        context("when the transformation closure returns a value") {
          let key = 12
          var successValue: Int?
          var failureValue: ErrorType?
          var fakeRequest: CacheRequest<Int>!
          
          beforeEach {
            fakeRequest = CacheRequest<Int>()
            internalCache.cacheRequestToReturn = fakeRequest
            
            cache.get(key).onSuccess { successValue = $0 }.onFailure { failureValue = $0 }
          }
          
          it("should forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledGet).to(equal(1))
          }
          
          it("should transform the key first") {
            expect(internalCache.didGetKey).to(equal(transformer.transform(key)))
          }
          
          context("when the request succeeds") {
            let value = 101
            
            beforeEach {
              fakeRequest.succeed(value)
            }
            
            it("should call the original success closure") {
              expect(successValue).to(equal(value))
            }
          }
          
          context("when the request fails") {
            let errorCode = TestError.AnotherError
            
            beforeEach {
              fakeRequest.fail(errorCode)
            }
            
            it("should call the original failure closure") {
              expect(failureValue as? TestError).to(equal(errorCode))
            }
          }
        }
        
        context("when the transformation closure returns nil") {
          let key = -12
          var successValue: Int?
          var failureValue: ErrorType?
          var fakeRequest: CacheRequest<Int>!
          
          beforeEach {
            fakeRequest = CacheRequest<Int>()
            internalCache.cacheRequestToReturn = fakeRequest
            
            cache.get(key).onSuccess { successValue = $0 }.onFailure { failureValue = $0 }
          }
          
          it("should not forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledGet).to(equal(0))
          }
          
          it("should not call the original success closure") {
            expect(successValue).to(beNil())
          }
          
          it("should call the original failure closure") {
            expect(failureValue).notTo(beNil())
          }
          
          it("should pass the right error code") {
            expect(failureValue as? FetchError).to(equal(FetchError.KeyTransformationFailed))
          }
        }
      }
    }
    
    sharedExamples("a cache with transformed keys") { (sharedExampleContext: SharedExampleContext) in
      var cache: BasicCache<Int, Int>!
      var internalCache: CacheLevelFake<String, Int>!
      var transformer: OneWayTransformationBox<Int, String>!
      
      beforeEach {
        cache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.CacheToTest] as? BasicCache<Int, Int>
        internalCache = sharedExampleContext()[KeyTransformationsSharedExamplesContext.InternalCache] as? CacheLevelFake<String, Int>
        transformer = sharedExampleContext()[KeyTransformationsSharedExamplesContext.Transformer] as? OneWayTransformationBox<Int, String>
      }
      
      itBehavesLike("a fetch closure with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
      
      context("when calling set") {
        context("when the transformation closure returns a value") {
          let key = 10
          let value = 222
          
          beforeEach {
            cache.set(value, forKey: key)
          }
          
          it("should forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledSet).to(equal(1))
          }
          
          it("should transform the key first") {
            expect(internalCache.didSetKey).to(equal(transformer.transform(key)))
          }
          
          it("should pass the right value") {
            expect(internalCache.didSetValue).to(equal(value))
          }
        }
        
        context("when the transformation closure fails") {
          let key = -10
          let value = 222
          
          beforeEach {
            cache.set(value, forKey: key)
          }
          
          it("should not forward the call to the internal cache") {
            expect(internalCache.numberOfTimesCalledSet).to(equal(0))
          }
        }
      }
      
      context("when calling clear") {
        beforeEach {
          cache.clear()
        }
        
        it("should forward the call to the internal cache") {
          expect(internalCache.numberOfTimesCalledClear).to(equal(1))
        }
      }
      
      context("when calling onMemoryWarning") {
        beforeEach {
          cache.onMemoryWarning()
        }
        
        it("should forward the call to the internal cache") {
          expect(internalCache.numberOfTimesCalledOnMemoryWarning).to(equal(1))
        }
      }
    }
  }
}

class KeyTransformationTests: QuickSpec {
  override func spec() {
    var cache: BasicCache<Int, Int>!
    var internalCache: CacheLevelFake<String, Int>!
    var transformer: OneWayTransformationBox<Int, String>!
    let transformationClosure: Int -> String? = {
      if $0 > 0 {
        return "\($0 + 1)"
      } else {
        return nil
      }
    }
    
    describe("Key transformation using a transformer and a cache, with the global function") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformKeys(transformer, cache: internalCache)
      }
      
      itBehavesLike("a cache with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformer and a cache, with the instance function") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = internalCache.transformKeys(transformer)
      }
      
      itBehavesLike("a cache with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformer and a cache, with the operator") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformer =>> internalCache
      }
      
      itBehavesLike("a cache with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformation closure and a cache, with the global function") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformKeys(transformationClosure, cache: internalCache)
      }
      
      itBehavesLike("a cache with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformation closure and a cache, with the instance function") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = internalCache.transformKeys(transformationClosure)
      }
      
      itBehavesLike("a cache with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformation closure and a cache, with the operator") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformationClosure =>> internalCache
      }
      
      itBehavesLike("a cache with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformation closure and a fetch closure, with the global function") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        let fetchClosure = internalCache.get
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformKeys(transformationClosure, fetchClosure: fetchClosure)
      }
      
      itBehavesLike("a fetch closure with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformation closure and a fetch closure, with the operator") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        let fetchClosure = internalCache.get
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformationClosure =>> fetchClosure
      }
      
      itBehavesLike("a fetch closure with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformer and a fetch closure, with the global function") {
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        let fetchClosure = internalCache.get
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformKeys(transformer, fetchClosure: fetchClosure)
      }
      
      itBehavesLike("a fetch closure with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
    
    describe("Key transformation using a transformer and a fetch closure, with the operator") {
      
      beforeEach {
        internalCache = CacheLevelFake<String, Int>()
        let fetchClosure = internalCache.get
        transformer = OneWayTransformationBox(transform: transformationClosure)
        cache = transformer =>> fetchClosure
      }
      
      itBehavesLike("a fetch closure with transformed keys") {
        [
          KeyTransformationsSharedExamplesContext.CacheToTest: cache,
          KeyTransformationsSharedExamplesContext.InternalCache: internalCache,
          KeyTransformationsSharedExamplesContext.Transformer: transformer
        ]
      }
    }
  }
}