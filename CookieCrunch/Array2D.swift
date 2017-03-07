//
//  Array2D.swift
//  CookieCrunch
//
//  Created by Andrews, George on 2/21/17.
//  Copyright © 2017 Andrews, George. All rights reserved.
//

import Foundation

struct Array2D<T> {
  
  let columns: Int
  let rows: Int
  
  fileprivate var array: Array<T?>
  
  init(columns: Int, rows: Int) {
    self.columns = columns
    self.rows = rows
    array = Array<T?>(repeating: nil, count: rows * columns)
  }
  
  subscript(column: Int, row: Int) -> T? {
    get {
      return array[row * columns + column]
    }
    set {
      array[row * columns + column] = newValue
    }
  }
  
}