//
//  Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

protocol Mockable {
    associatedtype MockType
    
    // A mock of this instance for development purposes.
    static var mock: MockType { get }
    
    // A list of mocks of this instance for development purposes.
    static var mockList: [MockType] { get }
}

extension Mockable {
    // Create a default implementation for 'mockList`,
    // in case we don't want to implement it in some cases.
    static var mockList: [MockType] {
        get { [] }
    }
}
