//
//  Zones.swift
//  FlatReversi
//
//  Created by Kodama Yoshinori on 10/26/14.
//  Copyright (c) 2014 Yoshinori Kodama. All rights reserved.
//

import Foundation

open class Zones {
    open var zones: [[Double]]

    public init(zones: [[Double]]) {
        self.zones = zones
    }

    public init(width: Int, height: Int, initVal: Double) {
        zones = []
        for _ in 0..<height {
            var row: [Double] = []
            for _ in 0..<width {
                row += [initVal]
            }
            self.zones += [row]
        }
    }

    open func getTopNByRandomInPuttables(_ n: Int, puttables: [(Int, Int)]) -> [(Int, Int)] {
        var arr: [(Double, (Int, Int))] = []
        let n = n > puttables.count ? puttables.count : n
        for (x, y) in puttables {
            let ra: Double = cs_double_random()
            let a = (ra * zones[y][x], (x, y))
            arr += [a]
        }

        // Sort by val
        arr = arr.sorted(by: {
            $0.0 > $1.0
        })

//        NSLog("Eval")
//        for e in arr {
//            NSLog("\(e.1.0), \(e.1.1) - \(e.0)")
//        }

        var ret: [(Int, Int)] = []
        for elem in arr[0..<n] {
            ret += [(elem.1)]
        }

        return ret
    }

    open func toString() -> String {
        var ret = ""
        for row in zones {
            for cell in row {
                ret += String(format: " %.3f ", arguments: [cell])
            }
            ret += "\n"
        }
        return ret
    }
}

open class ZonesFactory {
    open class func createZoneUniform(_ uniformVal: Double) -> Zones {
        let z = Zones(width: 8, height: 8, initVal: uniformVal)
        return z
    }

    //
    // A = Corner
    // B = Neightbor of Corner
    // C = Edge 8 zones
    // D = Center 4 x 4 zones
    open class func createZoneTypical4(_ aVal: Double, bVal: Double, cVal: Double, dVal: Double) -> Zones {
        let z = Zones(width: 8, height: 8, initVal: dVal)
        for y in 0..<8 {
            for x in 0..<8 {
                if (x == 0 || x == 8) && (y == 0 || y == 7) {
                    z.zones[y][x] = aVal
                }
                if ((x == 0 || x == 7) && (y == 1 || y == 6)) || ((x == 1 || x == 6) && (y == 0 || y == 1 || y == 6 || y == 7)) {
                    z.zones[y][x] = bVal
                }
                if (x == 0 || x == 1 || x == 6 || x == 7) && (2 <= y && y <= 5) {
                    z.zones[y][x] = cVal
                }
                if (2 <= x && x <= 5) && (y == 0 || y == 1 || y == 6 || y == 7) {
                    z.zones[y][x] = cVal
                }
            }
        }
        return z
    }

    open class func createZoneTypical7(_ aVal: Double, bVal: Double, cVal: Double, dVal: Double, eVal: Double, fVal: Double, gVal: Double) -> Zones{
        let zones: [[Double]] = [
            [aVal, bVal, cVal, dVal, dVal, cVal, bVal, aVal, ],
            [bVal, cVal, eVal, fVal, eVal, eVal, cVal, bVal, ],
            [cVal, eVal, fVal, gVal, gVal, fVal, eVal, cVal, ],
            [dVal, eVal, gVal, gVal, gVal, gVal, eVal, dVal, ],
            [dVal, eVal, gVal, gVal, gVal, gVal, eVal, dVal, ],
            [cVal, eVal, fVal, gVal, gVal, fVal, eVal, cVal, ],
            [bVal, cVal, eVal, eVal, eVal, eVal, cVal, bVal, ],
            [aVal, bVal, cVal, dVal, dVal, cVal, bVal, aVal, ],
        ]

        let z = Zones(zones: zones)
        return z
    }

    open class func createZoneTypical8(_ aVal: Double, bVal: Double, cVal: Double, dVal: Double, eVal: Double, fVal: Double, gVal: Double, hVal: Double) -> Zones{
        let zones: [[Double]] = [
            [aVal, bVal, dVal, eVal, eVal, dVal, bVal, aVal, ],
            [bVal, cVal, fVal, fVal, fVal, fVal, cVal, bVal, ],
            [dVal, fVal, gVal, hVal, hVal, gVal, fVal, dVal, ],
            [eVal, fVal, hVal, hVal, hVal, hVal, fVal, eVal, ],
            [eVal, fVal, hVal, hVal, hVal, hVal, fVal, eVal, ],
            [dVal, fVal, gVal, hVal, hVal, gVal, fVal, dVal, ],
            [bVal, cVal, fVal, fVal, fVal, fVal, cVal, bVal, ],
            [aVal, bVal, dVal, eVal, eVal, dVal, bVal, aVal, ],
        ]

        let z = Zones(zones: zones)
        return z
    }
}
