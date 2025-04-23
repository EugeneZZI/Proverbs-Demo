//
//  ObliquConstructor.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/17/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

protocol ObliqueShape {
    var isShadow:           Bool                { get set }
    var constructor:        ObliqueConstructor? { get set }
}

class ObliqueConstructor {
    
    enum Direction {
        case left
        case right
    }
    
    enum Side {
        case left(direction: Direction)
        case right(direction: Direction)
        case both(leftDirection: Direction, rightDirection: Direction)
    }
    
    // MARK: - Properties
    
    var side    = Side.right(direction: .left)
    var ratio   = GlobalUI.Oblique.ratio
    var radius  = GlobalUI.Oblique.cornerRadius
    
    // MARK: - Life CYcle Methods
    
    init(withSide: Side) {
        self.side = withSide
    }
    
    // MARK: - Public Methods
    
    func addPathToContext(_ ctx: CGContext, withRect rect: CGRect) {
        let obliqueOffset =  rect.size.height * self.ratio
        
        let point1 = self.makeFirstPoint(forRect: rect, obliqueOffset: obliqueOffset)
        let point2 = self.makeSecondPoint(forRect: rect, obliqueOffset: obliqueOffset)
        let point3 = self.makeThirdPoint(forRect: rect, obliqueOffset: obliqueOffset)
        let point4 = self.makeFourthPoint(forRect: rect, obliqueOffset: obliqueOffset)
        
        ctx.beginPath()
        ctx.move(to: point1)
        
        switch self.side {
        case .left(_):
            ctx.addLine(to: point2)
            ctx.addLine(to: point3)
            ctx.addArc(tangent1End: point4, tangent2End: point1, radius: self.radius)
            ctx.addArc(tangent1End: point1, tangent2End: point2, radius: self.radius)
        case .right(_):
            ctx.addArc(tangent1End: point2, tangent2End: point3, radius: self.radius)
            ctx.addArc(tangent1End: point3, tangent2End: point4, radius: self.radius)
            ctx.addLine(to: point4)
            ctx.addLine(to: point1)
        case .both(_,_):
            ctx.addArc(tangent1End: point2, tangent2End: point3, radius: self.radius)
            ctx.addArc(tangent1End: point3, tangent2End: point4, radius: self.radius)
            ctx.addArc(tangent1End: point4, tangent2End: point1, radius: self.radius)
            ctx.addArc(tangent1End: point1, tangent2End: point2, radius: self.radius)
        }
        ctx.closePath()
    }
    
    // MARK: - Private Methods
    
    private func makeFirstPoint(forRect rect: CGRect, obliqueOffset: CGFloat) -> CGPoint {
        let makeDefault = {
            return CGPoint(x: 0.0, y: 0.0)
        }
        let makeOffset = {
            return CGPoint(x: 0.0 + obliqueOffset, y: 0.0)
        }
        
        switch self.side {
        case .left(let direction):
            switch direction {
            case .right: return makeOffset()
            case .left: return makeDefault()
            }
        case .both(let leftDirection, _):
            switch leftDirection {
            case .right: return makeOffset()
            case .left: return makeDefault()
            }
        default:
            return makeDefault()
        }
    }
    
    private func makeSecondPoint(forRect rect: CGRect, obliqueOffset: CGFloat) -> CGPoint {
        let makeDefault = {
            return CGPoint(x: rect.size.width, y: 0.0)
        }
        let makeOffset = {
            return CGPoint(x: rect.size.width - obliqueOffset, y: 0.0)
        }
        
        switch self.side {
        case .right(let direction):
            switch direction {
            case .right: return makeDefault()
            case .left: return makeOffset()
            }
        case .both(_ , let rightDirection):
            switch rightDirection {
            case .right: return makeDefault()
            case .left: return makeOffset()
            }
        default:
            return makeDefault()
        }
    }
    
    private func makeThirdPoint(forRect rect: CGRect, obliqueOffset: CGFloat) -> CGPoint {
        let makeDefault = {
            return CGPoint(x: rect.size.width, y: rect.size.height)
        }
        let makeOffset = {
            return CGPoint(x: rect.size.width - obliqueOffset, y: rect.size.height)
        }
        
        switch self.side {
        case .right(let direction):
            switch direction {
            case .right: return makeOffset()
            case .left: return makeDefault()
            }
        case .both(_, let rightDirection):
            switch rightDirection {
            case .right: return makeOffset()
            case .left: return makeDefault()
            }
        default:
            return makeDefault()
        }
    }
    
    private func makeFourthPoint(forRect rect: CGRect, obliqueOffset: CGFloat) -> CGPoint {
        let makeDefault = {
            return CGPoint(x: 0.0, y: rect.size.height)
        }
        let makeOffset = {
            return CGPoint(x: obliqueOffset, y: rect.size.height)
        }
        
        switch self.side {
        case .left(let direction):
            switch direction {
            case .right: return makeDefault()
            case .left: return makeOffset()
            }
        case .both(let leftDirection, _):
            switch leftDirection {
            case .right: return makeDefault()
            case .left: return makeOffset()
            }
        default:
            return makeDefault()
        }
    }
    
}
