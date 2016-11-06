//
//  SimpleBitBoard.swift
//  ReversiTester
//
//  Created by Kodama Yoshinori on 11/19/14.
//  Copyright (c) 2014 Yoshinori Kodama. All rights reserved.
//

import Foundation

public typealias Moves = UInt64

func isEmpty(_ m: Moves) -> Bool {
    return m <= 0
}

//let bsfMagicTable = [
//     0, 47,  1, 56, 48, 27,  2, 60,
//    57, 49, 41, 37, 28, 16,  3, 61,
//    54, 58, 35, 52, 50, 42, 21, 44,
//    38, 32, 29, 23, 17, 11,  4, 62,
//    46, 55, 26, 59, 40, 36, 15, 53,
//    34, 51, 20, 43, 31, 22, 10, 45,
//    25, 39, 14, 33, 19, 30,  9, 24,
//    13, 18,  8, 12,  7,  6,  5, 63
//]

let magic: UInt64 = 0x03f79d71b4cb0a89

//func bitScanForward(b: Moves) -> Int {
//    let binv = (b ^ (b - 1))
//    let bm = binv &* magic
//    let bmShifted = (bm) >> 58
//    let index = Int(bmShifted)
//    return bsfMagicTable[index]
//}

#if os(Linux)
import Intrinsics
#else
@_silgen_name("_bitScanForward")
    func _bitScanForward(_: UInt64) -> UInt
    
@_silgen_name("_bitPop")
    func _bitPop(_: UInt64) -> UInt
#endif

func bitScanForward(_ board: UInt64) -> Int {
    return Int(_bitScanForward(board))
}

func xOrBitWhere(_ b: Moves, nthBit: Int) -> UInt64 {
    return b ^ bitWhere(nthBit)
}

func bitWhere(_ x: Int) -> UInt64 {
    return 1 << UInt64(x)
}

func bitWhere(_ x: Int, y: Int) -> UInt64 {
    return 1 << (UInt64(x) + UInt64(y) * 8)
}

func pop(_ i:UInt64) -> Int {
    return Int(_bitPop(i))
}

public func stringFromBitBoard(_ x: UInt64) -> String {
    var ret = ""
    for iy in 0..<8 {
        for ix in 0..<8 {
            let bitwhere = bitWhere(ix + iy * 8)
            var s = "."
            if bitwhere & x > 0 {
                s = "*"
            }
            ret += " " + s + " "
        }
        ret += "\n"
    }
    return ret
}

let direcs = [1,-1,8,-8,-9,7,9,-7]

public func == (lhs: BitBoard, rhs: BitBoard) -> Bool {
    return lhs.black == rhs.black && lhs.white == rhs.white
}

public struct BitBoard : Hashable, Equatable {
    var black: UInt64 = 0b0100000010 << 27
    var white: UInt64 = 0b1000000001 << 27
    var guide: UInt64 = 0b0
    
    public init () {}

    public var hashValue: Int {
        get {
            let b = Int(black % UInt64(Int.max))
            let w = Int(white % UInt64(Int.max))
            let hash = b &+ w &* 17
            return hash
        }
    }

    public func getBoardForPlayer(_ forPlayer: Pieces) -> UInt64 {
        switch forPlayer {
        case .black:
            return black
        case .white:
            return white
        default:
            fatalError("Please specify black or white!")
        }
    }

    public func height() -> Int {
        return 8
    }
    public func width() -> Int {
        return 8
    }

    public func withinBoard(_ x: Int, y: Int) -> Bool {
        return (0 <= x && x < height() && 0 <= y && y < width())
    }

    public mutating func set(_ color: Pieces, x: Int, y: Int) {
        let bitwhere: UInt64 = 1 << (UInt64(x) + UInt64(y) * 8)
        switch color {
        case .black:
            black = black | bitwhere
            white = white & (~bitwhere)
        case .white:
            white = white | bitwhere
            black = black & (~bitwhere)
        case .guide:
            guide = guide | bitwhere
        case .empty:
            black = black & (~bitwhere)
            white = white & (~bitwhere)
            guide = guide & (~bitwhere)
        default:
            print("Do nothing \(color.toString())")
        }
    }

    public func get(_ x: Int, y: Int) -> Pieces {
        if !withinBoard(x, y: y) {
            return .none
        }

        let bitwhere: UInt64 = 1 << (UInt64(x) + UInt64(y) * 8)
        let blackExists: Bool = black & bitwhere > 0
        let whiteExists: Bool = white & bitwhere > 0

        if blackExists && whiteExists {
            fatalError("Should not reach this code. An cell cannot be occupied by both black and white piece!")
        } else if blackExists && !whiteExists {
            return .black
        } else if !blackExists && whiteExists {
            return .white
        } else if guide & bitwhere > 0 {
            return .guide
        } else {
            return .empty
        }
    }

    public mutating func put(_ color: Pieces, x: Int, y: Int, guides: Bool) -> Moves {
        if !withinBoard(x, y: y) {
            return 0x0
        }

        var r: UInt64 = 0
        for direc in direcs {
            let pd = getBitReversible(color, x: x, y: y, direc: direc)
            r |= pd
        }

        if r <= 0 {
            return 0x0
        }

        let putAt = bitWhere(x, y: y)

        switch color {
        case .black:
            black = black ^ (putAt | r)
            white = white ^ r
        case .white:
            black = black ^ r
            white = white ^ (putAt | r)
        default:
            assertionFailure("Should not reach this code!")
        }

        return r
    }

    public func isPieceAt(_ piece: Pieces, x: Int, y: Int) -> Bool {
        switch piece {
        case .black:
            return bitWhere(x, y: y) & black > 0
        case .white:
            return bitWhere(x, y: y) & white > 0
        case .guide:
            return bitWhere(x, y: y) & guide > 0
        case .empty:
            return bitWhere(x, y: y) & (black | white) > 0
        default:
            return false
        }
    }

    public func isEmpty(_ x: Int, y: Int) -> Bool {
        return (black & white) & bitWhere(x, y: y) > 0
    }

    public func isAnyPuttable(_ color: Pieces) -> Bool {
        for direc in direcs {
            if getBitPuttables(color, direc: direc) > 0 {
                return true
            }
        }

        return false
    }

    public func getNumBlack() -> Int {
        return pop(black)
    }

    public func getNumWhite() -> Int {
        return pop(white)
    }

    public func getNumVacant() -> Int {
        return 64 - getNumBlack() - getNumWhite()
    }

    public func isTerminal() -> Bool {
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

    public func canPut(_ color: Pieces, x: Int, y: Int) -> Bool {
        if (black | white) & bitWhere(x, y: y) > 0 {
            return false
        }

        for direc in direcs {
            if getBitPuttables(color, direc: direc) & bitWhere(x, y: y) > 0 {
                return true
            }
        }

        return false
    }

    public func getBitPuttables(_ color: Pieces, direc: Int) -> UInt64 {
        var mask: UInt64

        if direc == 1 || direc == -1 {
            mask = 0x7e7e7e7e7e7e7e7e
        } else if direc == 8 || direc == -8 {
            mask = 0x00ffffffffffff00
        } else if direc == 7 || direc == -9 {
            mask = 0x7e7e7e7e7e7e7e7e
        } else if direc == 9 || direc == -7 {
            mask = 0x7e7e7e7e7e7e7e7e
        } else {
            fatalError("Should not reach this code!")
        }

        var attacker: UInt64
        var attackee: UInt64

        switch color {
        case .black:
            attacker = black
            attackee = white & mask
        case .white:
            attacker = white
            attackee = black & mask
        default:
            fatalError("Should not reach this code!")
        }

        var t: UInt64 = 0
        if direc >= 0 {
            let ui64_direc: UInt64 = UInt64(direc)
            t = attackee & (attacker >> ui64_direc)
            t |= attackee & (t >> ui64_direc)
            t |= attackee & (t >> ui64_direc)
            t |= attackee & (t >> ui64_direc)
            t |= attackee & (t >> ui64_direc)
            t |= attackee & (t >> ui64_direc)
            t = (t >> ui64_direc)
        } else {
            let ui64_direc: UInt64 = UInt64(-direc)
            t = attackee & (attacker << ui64_direc)
            t |= attackee & (t << ui64_direc)
            t |= attackee & (t << ui64_direc)
            t |= attackee & (t << ui64_direc)
            t |= attackee & (t << ui64_direc)
            t |= attackee & (t << ui64_direc)
            t = (t << ui64_direc)
        }

        let blank: UInt64 = ~(black | white)
        let ret = blank & t
        
        return ret
    }

    public func getPuttables(_ color: Pieces) -> Moves {
        var r: UInt64 = 0
        for direc in direcs {
            r |= getBitPuttables(color, direc: direc)
        }
        return r
    }

    public func getBitReversible(_ color: Pieces, x: Int, y: Int, direc: Int) -> UInt64 {
        var attacker: UInt64
        var attackee: UInt64

        var mask: UInt64

        if direc == 1 || direc == -1 {
            mask = 0x7e7e7e7e7e7e7e7e
        } else if direc == 8 || direc == -8 {
            mask = 0x00ffffffffffff00
        } else if direc == 7 || direc == -9 {
            mask = 0x7e7e7e7e7e7e7e7e
        } else if direc == 9 || direc == -7 {
            mask = 0x7e7e7e7e7e7e7e7e
        } else {
            fatalError("Should not reach this code!")
        }

        switch color {
        case .black:
            attacker = black
            attackee = white & mask
        case .white:
            attacker = white
            attackee = black & mask
        default:
            fatalError("Should not reach this code!")
        }

        var m1: UInt64
        var m2: UInt64
        var m3: UInt64
        var m4: UInt64
        var m5: UInt64
        var m6: UInt64
        var m7: UInt64

        let pos: UInt64 = 1 << (UInt64(x) + UInt64(y) * 8)

        var ui64_direc: UInt64
        if direc >= 0 {
            ui64_direc = UInt64(direc)
            m1 = pos >> ui64_direc
            m2 = m1 >> ui64_direc
            m3 = m2 >> ui64_direc
            m4 = m3 >> ui64_direc
            m5 = m4 >> ui64_direc
            m6 = m5 >> ui64_direc
            m7 = m6 >> ui64_direc
        } else {
            ui64_direc = UInt64(-direc)
            m1 = pos << ui64_direc
            m2 = m1 << ui64_direc
            m3 = m2 << ui64_direc
            m4 = m3 << ui64_direc
            m5 = m4 << ui64_direc
            m6 = m5 << ui64_direc
            m7 = m6 << ui64_direc
        }

        var rev: UInt64 = 0

        if (m1 & attackee) != 0 {
            if (m2 & attackee) == 0 {
                if (m2 & attacker) != 0 {
                    rev = m1
                }
            } else if (m3 & attackee) == 0 {
                if (m3 & attacker) != 0 {
                    rev = m1 | m2
                }
            } else if (m4 & attackee) == 0 {
                if (m4 & attacker) != 0 {
                    rev = m1 | m2 | m3
                }
            } else if (m5 & attackee) == 0 {
                if (m5 & attacker) != 0 {
                    rev = m1 | m2 | m3 | m4
                }
            } else if (m6 & attackee) == 0 {
                if (m6 & attacker) != 0 {
                    rev = m1 | m2 | m3 | m4 | m5
                }
            } else {
                if (m7 & attacker) != 0 {
                    rev = m1 | m2 | m3 | m4 | m5 | m6
                }
            }
        }
        
        return rev
    }

    public func getReversible(_ color: Pieces, x: Int, y: Int) -> Moves {
        var r: UInt64 = 0
        for direc in direcs {
            let pd = getBitReversible(color, x: x, y: y, direc: direc)
            r |= pd
        }

        return r
    }

    public func numPeripherals(_ color: Pieces, x: Int, y: Int) -> Int {
        var peripherals_x: UInt64 = 0
        var peripherals_xs : UInt64 = 0
        switch x {
        case 0:
            peripherals_x = 0b00000011
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        case 1:
            peripherals_x = 0b00000111
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        case 2:
            peripherals_x = 0b00001110
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        case 3:
            peripherals_x = 0b00011100
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        case 4:
            peripherals_x = 0b00111000
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        case 5:
            peripherals_x = 0b01110000
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        case 6:
            peripherals_x = 0b11100000
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        case 7:
            peripherals_x = 0b11000000
            peripherals_xs = peripherals_x << 16 + peripherals_x << 8 + peripherals_x
        default:
            assertionFailure("Should not reach this code!")
        }

        switch y {
        case 0:
            peripherals_xs = peripherals_x << 8 + peripherals_x
        case 1:
            peripherals_xs = peripherals_xs * 1
        case 2:
            peripherals_xs = peripherals_xs << (8 * 1)
        case 3:
            peripherals_xs = peripherals_xs << (8 * 2)
        case 4:
            peripherals_xs = peripherals_xs << (8 * 3)
        case 5:
            peripherals_xs = peripherals_xs << (8 * 4)
        case 6:
            peripherals_xs = peripherals_xs << (8 * 5)
        case 7:
            peripherals_xs = peripherals_xs << (8 * 6)
        default:
            assertionFailure("Should not reach this code!")
        }

        let peripherals = peripherals_xs & (bitWhere(x, y: y) ^ 0xFFFFFFFFFFFFFFFF)

        switch color {
        case .black:
            return pop(black & peripherals)
        case .white:
            return pop(white & peripherals)
        case .empty:
            let empty_cells = (black | white) ^ 0xFFFFFFFFFFFFFFFF
            return pop(empty_cells & peripherals)
        default:
            return 0
        }
    }
}

open class SimpleBitBoard: FastBitBoard {
    var bb: BitBoard = BitBoard()

    var _height = 8
    var _width = 8

    override public init() {
        self.bb = BitBoard()
    }

    public init(bitBoard: BitBoard) {
        self.bb = bitBoard
    }

    override open func getUnsafeBitBoard() -> BitBoard {
        return bb
    }

    override open func height() -> Int {
        return _height
    }
    override open func width() -> Int {
        return _width
    }

    override open func initialize(_ width: Int, height: Int) {
        // ignors width and height
    }

    override open func withinBoard(_ x: Int, y: Int) -> Bool {
        return (0 <= x && x < width() && 0 <= y && y < height())
    }

    override open func set(_ color: Pieces, x: Int, y: Int) {
        bb.set(color, x: x, y: y)
    }

    override open func get(_ x: Int, y: Int) -> Pieces {
        return bb.get(x, y: y)
    }

    func boardForAll(_ mapfun: ((Pieces) -> Pieces)) {
        for y in 0..<height() {
            for x in 0..<width() {
                let p = get(x, y: y)
                set(mapfun(p), x: x, y: y)
            }
        }
    }

    func boardForAll(_ mapfun: ((Int, Int) -> Pieces)) {
        for y in 0..<height() {
            for x in 0..<width() {
                set(mapfun(x, y), x: x, y: y)
            }
        }
    }

    override open func updateGuides(_ color: Pieces) -> Int {
        // Clear exising guides first
        boardForAll({
            (x: Pieces) -> Pieces in if(x == Pieces.guide) { return Pieces.empty } else { return x }
        })

        var ret = 0
        boardForAll({
            (x: Int, y: Int) -> Pieces in if(self.canPut(color, x: x, y: y)) { ret += 1; return Pieces.guide } else { return self.get(x, y: y) }
        })

        return ret
    }

    override open func put(_ color: Pieces, x: Int, y: Int, guides: Bool, returnChanges: Bool) -> [(Int, Int)] {
        if !withinBoard(x, y: y) {
            return []
        }

        let retMoves = bb.put(color, x: x, y: y, guides: guides)

        return returnChanges ? listFromBitBoard(retMoves) : []
    }

    override open func isPieceAt(_ piece: Pieces, x: Int, y: Int) -> Bool {
        return bb.isPieceAt(piece, x: x, y: y)
    }

    // MARK: Query functoverride ions
    override open func getNumBlack() -> Int {
        return bb.getNumBlack()
    }

    override open func getNumWhite() -> Int {
        return bb.getNumWhite()
    }

    override open func canPut(_ color: Pieces, x: Int, y: Int) -> Bool {
        return bb.canPut(color, x: x, y: y)
    }

    override open func getPuttables(_ color: Pieces) -> [(Int, Int)] {
        return listFromBitBoard(bb.getPuttables(color))
    }

    override open func isAnyPuttable(_ color: Pieces) -> Bool {
        return bb.isAnyPuttable(color)
    }

    fileprivate func listFromBitBoard(_ bits: UInt64) -> [(Int, Int)] {
        var ret: [(Int, Int)] = []
        for iy in 0..<height() {
            for ix in 0..<width() {
                let bitwhere: UInt64 = 1 << (UInt64(ix) + UInt64(iy) * 8)
                if bits & bitwhere > 0 {
                    ret.append((ix, iy))
                }
            }
        }
        return ret
    }

    override open func getReversible(_ color: Pieces, x: Int, y: Int) -> [(Int, Int)] {
        return listFromBitBoard(bb.getReversible(color, x: x, y: y))
    }

    override open func isEmpty(_ x: Int, y: Int) -> Bool {
        return bb.isEmpty(x, y: y)
    }

    override open func numPeripherals(_ color: Pieces, x: Int, y: Int) -> Int {
        return bb.numPeripherals(color, x: x, y: y)
    }

    override func isTerminal() -> Bool {
        return bb.isTerminal()
    }

    override open func hashValue() -> Int {
        return bb.hashValue
    }

    // MARK: Bitwise operations


    // MARK: Utility functions
    override open func clone() -> Board {
        let bb = self.bb
        let ret = SimpleBitBoard()
        ret.bb = bb
        ret._height = self.height()
        ret._width = self.width()

        return ret
    }

    override func cloneBitBoard() -> FastBitBoard {
        let bb = self.bb
        let ret = SimpleBitBoard()
        ret.bb = bb
        ret._height = self.height()
        ret._width = self.width()

        return ret
    }

    override open func toString() -> String {
        var ret = ""
        for y in 0..<self.height() {
            for x in 0..<self.width() {
                let p = get(x, y: y)
                let s = p.toString()
                ret += " " + s + " "
            }
            ret += "\n"
        }
        
        return ret
    }
}
