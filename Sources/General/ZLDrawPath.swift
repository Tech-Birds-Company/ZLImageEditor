import UIKit

// MARK: Draw path

public final class ZLDrawPath: NSObject {

    public let pathColor: UIColor

    public let path: UIBezierPath

    public let ratio: CGFloat

    public let shapeLayer: CAShapeLayer

    public init(
        pathColor: UIColor,
        path: UIBezierPath,
        ratio: CGFloat,
        shapeLayer: CAShapeLayer
    ) {
        self.pathColor = pathColor
        self.path = path
        self.ratio = ratio
        self.shapeLayer = shapeLayer
    }

    public init(
        pathColor: UIColor,
        pathWidth: CGFloat,
        ratio: CGFloat,
        startPoint: CGPoint
    ) {
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
