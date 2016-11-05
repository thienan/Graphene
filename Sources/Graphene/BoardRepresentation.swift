//
//  BoardRepresentation.swift
//  MyFirstSpriteKit
//
//  Created by Kodama Yoshinori on 10/17/14.
//  Copyright (c) 2014 Yoshinori Kodama. All rights reserved.
//

import Foundation

open class BoardRepresentation {
    open var boardMediator: BoardMediator

    public init(boardMediator: BoardMediator) {
        self.boardMediator = boardMediator
    }

    open func height() -> Int {
        return self.boardMediator.height()
    }

    open func width() -> Int {
        return self.boardMediator.width()
    }

    open func withinBoard(_ x: Int, y: Int) -> Bool {
        return self.boardMediator.withinBoard(x, y: y)
    }

    open func get(_ x: Int, y: Int) -> Pieces {
        return self.boardMediator.get(x, y: y)
    }

    open func isPieceAt(_ piece: Pieces, x: Int, y: Int) -> Bool {
        return self.boardMediator.isPieceAt(piece, x: x, y: y)
    }

    open func isEmpty(_ x: Int, y: Int) -> Bool {
        return self.boardMediator.isEmpty(x, y: y)
    }

    open func canPut(_ color: Pieces, x: Int, y: Int) -> Bool {
        return (get(x, y: y) != .white && get(x, y: y) != .black) && getReversible(color, x: x, y: y).count > 0;
    }

    open func getPuttables(_ color: Pieces) -> [(Int, Int)] {
        return self.boardMediator.getPuttables(color)
    }

    // Only diag or horizontal/vertical lines can change by putting piece at x,y
    open func getReversible(_ color: Pieces, x: Int, y: Int) -> [(Int, Int)] {
        return boardMediator.getReversible(color, x: x, y: y)
    }

    open func isAnyPuttable(_ color: Pieces) -> Bool {
        return boardMediator.isAnyPuttable(color)
    }

    open func getNumBlack() -> Int {
        return boardMediator.getNumBlack()
    }

    open func getNumWhite() -> Int {
        return boardMediator.getNumWhite()
    }

    open func getNumVacant() -> Int {
        return 64 - getNumBlack() - getNumWhite()
    }

    open func isTerminal() -> Bool {
        if getNumVacant() == 0 {
            return true
        }

        if isAnyPuttable(.black) {
            return false
        }

        if isAnyPuttable(.white) {
            return false
        }

        return true
    }

    open func numPeripherals(_ color: Pieces, x: Int, y: Int) -> Int {
        return self.boardMediator.numPeripherals(color, x: x, y: y)
    }

    open func hashValue() -> Int {
        return self.boardMediator.hashValue()
    }

    open func toString() -> String {
        return self.boardMediator.toString()
    }

    open func clone() -> BoardRepresentation {
        let bm = self.boardMediator.clone()
        let newBR = BoardRepresentation(boardMediator: bm)

        return newBR
    }
}
