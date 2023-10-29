import UIKit

final class MaskableViewContainer: UIView {

    public var showHideTools: ((Bool) -> Void)?

    var image: UIImage? {
        self.maskableView.image
    }

    var drawingAction: DrawingAction = .erase {
        didSet {
            self.maskableView.drawingAction = drawingAction
        }
    }

    var cirleRadius: CGFloat = 20 {
        didSet {
            self.maskableView.circleRadius = cirleRadius
        }
    }

    private var firstTime = true

    private let backgroundImage: UIImageView = {
        let bImage = UIImageView()
        bImage.contentMode = .scaleAspectFill
        return bImage
    }()

    private lazy var maskableView: MaskableView = {
        let maskView = MaskableView()
        maskView.maskDrawingAlpha = 1.0
        maskView.drawingAction = .erase
        maskView.outerCircleCursorColor = .black
        return maskView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        self.addSubview(backgroundImage)
        self.addSubview(maskableView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.maskableView.frame = self.bounds
        maskableView.updateBounds()
        self.backgroundImage.frame = self.bounds
    }

    func configure(with image: UIImage, and background: UIImage) {
        guard firstTime else { return }
        self.maskableView.imageView.image = image
        self.backgroundImage.image = background
        self.firstTime = false
        self.maskableView.showHideTools = self.showHideTools
    }

}
