import UIKit

enum DrawingAction: Int {
    case erase = 0
    case draw = 1
}

final class MaskableView: UIView {

    public var drawingAction: DrawingAction = .erase
    public var circleRadius: CGFloat = 20
    public var maskDrawingAlpha: CGFloat = 1.0
    public var image: UIImage? {
        guard let renderer = renderer else { return nil}
        let result = renderer.image { context in
            return layer.render(in: context.cgContext)
        }
        return result
    }

    var showHideTools: ((Bool) -> Void)?

    let imageView = UIImageView()

    /// This color is used to draw the "cursor" around the circle shape being drawn onto the mask layer. By default the color is nil (no cursor)
    /// Set a color if you want to stroke the circle being drawn.
    public var circleCursorColor: UIColor? {
        didSet { shapeLayer.strokeColor = circleCursorColor?.cgColor }
    }

    /// This color is used to draw an outer circle around the  circle shape being drawn onto the mask layer. By default the color is nil (no cursor)
    /// Use a outerCircleCursorColor that contrasts with the  circleCursorColor
    /// (e.g. use a dark outerCircleCursorColor for a light circleCursorColor)
    public var outerCircleCursorColor: UIColor? {
        didSet { outerShapeLayer.strokeColor = outerCircleCursorColor?.cgColor }
    }

    // MARK: - Private vars

    private var maskImage: UIImage?
    private var maskLayer = CALayer()
    private var shapeLayer = CAShapeLayer()
    private var outerShapeLayer = CAShapeLayer()
    private var renderer: UIGraphicsImageRenderer?
    private var panGestureRecognizer = TouchDownPanGestureRecognizer()

    private var firstTime = true

    // MARK: - Public functions

    public func updateBounds() {
        maskLayer.frame = layer.bounds
        shapeLayer.frame = layer.frame
        outerShapeLayer.frame = layer.frame
        self.imageView.frame = self.bounds

        if firstTime {
            let traitCollection = UITraitCollection(displayScale: 1.0)
            let rendererFormat = UIGraphicsImageRendererFormat(for: traitCollection)
            renderer = UIGraphicsImageRenderer(bounds: self.bounds, format: rendererFormat)
            installSampleMask()
            layer.superlayer?.addSublayer(shapeLayer)
            layer.superlayer?.addSublayer(outerShapeLayer)
            firstTime = false
        } else {
            guard let renderer = renderer else { return }
            let image = renderer.image { (_) in
                if let maskImage = maskImage {
                    maskImage.draw(in: bounds)
                }
            }
            maskImage = image
            maskLayer.contents = maskImage?.cgImage
        }
    }

    private func installSampleMask() {
        guard let renderer = renderer else { return }
        let image = renderer.image { (ctx) in
            ctx.fill(bounds, blendMode: .normal)
        }
        maskImage = image
        maskLayer.contents = maskImage?.cgImage
    }

    private func drawCircleAtPoint(point: CGPoint) {
        guard let renderer = renderer else { return }
        let image = renderer.image { (context) in
            if let maskImage = maskImage {
                maskImage.draw(in: bounds)
                 let rect = CGRect(origin: point, size: CGSize.zero).insetBy(dx: -circleRadius/2, dy: -circleRadius/2)
                let color = UIColor.black.cgColor
                context.cgContext.setFillColor(color)
                let blendMode: CGBlendMode
                let alpha: CGFloat
                if drawingAction == .erase {
                    // This is what I worked out to reduce the alpha of the mask by maskDrawingAlpha in the drawing area
                    blendMode = .sourceIn
                    alpha = 1 - maskDrawingAlpha
                } else {
                    // In normal drawing mode the new drawing alpha is added to the alpha of the existing area.
                    blendMode = .normal
                    alpha = maskDrawingAlpha
                }

                if circleCursorColor != nil {
                    let circlePath = UIBezierPath(ovalIn: rect)
                    circlePath.fill(with: blendMode, alpha: alpha)
                    shapeLayer.path = circlePath.cgPath
                }

                if outerCircleCursorColor != nil {
                    let outerRect = rect.insetBy(dx: -2, dy: -2)
                    let outerCirclePath = UIBezierPath(ovalIn: outerRect)
                    outerCirclePath.fill(with: blendMode, alpha: alpha)
                    outerShapeLayer.path = outerCirclePath.cgPath
                }
            }
        }
        maskImage = image
        maskLayer.contents = maskImage?.cgImage
    }

    // MARK: - IBAction methods

    // Erase/un-erase the point from the tap/pan gesture recognzier
    @objc func gestureRecognizerUpdate(_ sender: UIGestureRecognizer) {
        let point = sender.location(in: self)
        if sender.state != .ended {
            drawCircleAtPoint(point: point)
            self.showHideTools?(true)
        } else {
            self.shapeLayer.path = nil
            self.outerShapeLayer.path = nil
            self.showHideTools?(false)
        }
    }

    // MARK: - Object lifecycle methods

    override init(frame: CGRect) {
        super.init(frame: frame)
        doInitSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        doInitSetup()
    }

    func doInitSetup() {
        self.addSubview(self.imageView)
        shapeLayer.strokeColor = circleCursorColor?.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clear.cgColor
        outerShapeLayer.strokeColor = outerCircleCursorColor?.cgColor
        outerShapeLayer.lineWidth = 1
        outerShapeLayer.fillColor = UIColor.clear.cgColor

        layer.mask = maskLayer

        // Set up a pan gesture recognizer to erase/un-erase a series of circles as the user drags over the image.
        panGestureRecognizer.addTarget(self, action: #selector(gestureRecognizerUpdate(_:)))
        self.addGestureRecognizer(panGestureRecognizer)
    }

}
