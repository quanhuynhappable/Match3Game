//
//  Array2D.swift
//  Match3Game
//
//  Created by Appable on 6/14/16.
//  Copyright © 2016 Appable. All rights reserved.
//

import Foundation
struct Array2D<T> {
  let columns: Int
  let rows: Int
  private var array: Array<T?>
  
  init(columns: Int, rows: Int) {
    self.columns = columns
    self.rows = rows
    array = Array<T?>(count: rows*columns, repeatedValue: nil)
  }
  
  subscript(column: Int, row: Int) -> T? {
    get {
      return array[row*columns + column]
    }
    set {
      array[row*columns + column] = newValue
    }
  }
}