//
//  File.swift
//  
//
//  Created by Musa on 25.08.2023.
//

import Foundation
import UIKit

class MaskableViewContainer: UIView {

    var image: UIImage? {
        self.maskableView.image
    }

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

    override func layoutSubviews() {
        super.layoutSubviews()
        self.maskableView.frame = self.bounds
        self.maskableView.updateBounds()
        self.backgroundImage.frame = self.bounds
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with image: UIImage, and background: UIImage) {
        self.maskableView.image = image
        self.backgroundImage.image = background
    }

}
