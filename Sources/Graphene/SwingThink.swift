//
//  SwingThink.swift
//  Graphene
//
//  Created by KodamaYoshinori on 2016/11/01.
//
//

import Foundation

public class SwingThink : Think {
    var zones: Zones? = nil
    var pnsLessThan: Int = 0
    
    var swing = 0       // odd to right, even to left
    
    public init (zones: Zones, pnsLessThan: Int) {
        self.zones = zones
        self.pnsLessThan = pnsLessThan
    }
    
    public func think(_ color: Pieces, board: BoardRepresentation, info: Info) -> Hand {
        var retx = 0
        var rety = 0
        let puttables = board.getPuttables(color)
        
        if board.getNumVacant() < pnsLessThan {
            let solver = SimpleProofSolver()
            let answer = solver.solve(board.clone(), forPlayer: color)
            info.say(message: "Solving by PNS search...")
            if ((answer.proof == .blackWin && color == .black) || (answer.proof == .whiteWin && color == .white)) && answer.moves.count > 0 {
                (retx, rety) = answer.moves[0]
                info.say(message: "Found PV! Answer is \(retx), \(rety)")
                return Hand(row: rety, col: retx, color: color)
            }
        }
        
        info.say(message: "No PV found. Doing random.")
        if puttables.count > 0 {
            if let uzones = zones {
                var coords = uzones.getTopNByRandomInPuttables(10, puttables: puttables)
                if coords.count > 0 {
                    if swing % 2 == 0{
                        coords = coords.sorted(by: {$0.0 < $1.0})
                    } else {
                        coords = coords.sorted(by: {$0.0 > $1.0})
                    }
                    swing += 1
                    (retx, rety) = coords[0]
                }
            }
        }
        return Hand(row: rety, col: retx, color: color)
    }
}
