//
//  ZLDrawPath.swift
//  ZLImageEditor
//
//  Created by Musa on 30.05.2023.
//

import UIKit

// MARK: Draw path

public class ZLDrawPath: NSObject {
    let pathColor: UIColor

    let path: UIBezierPath

    let ratio: CGFloat

    let shapeLayer: CAShapeLayer

    init(pathColor: UIColor, pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint) {
        self.pathColor = pathColor
        path = UIBezierPath()
        path.lineWidth = pathWidth / ratio
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio))

        shapeLayer = CAShapeLayer()
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.lineWidth = pathWidth / ratio
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = pathColor.cgColor
        shapeLayer.path = path.cgPath

        self.ratio = ratio

        super.init()
    }

    func addLine(to point: CGPoint) {
        path.addLine(to: CGPoint(x: point.x / ratio, y: point.y / ratio))
        shapeLayer.path = path.cgPath
    }

    func drawPath() {
        pathColor.set()
        path.stroke()
    }
}
