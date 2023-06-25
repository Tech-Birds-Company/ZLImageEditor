//
//  ZLEditImageViewController + StickersOperation.swift
//  ZLImageEditor
//
//  Created by Musa on 25.06.2023.
//

import Foundation
import UIKit

extension ZLEditImageViewController {
    func showInputTextVC(
        _ text: String? = nil,
        textColor: UIColor? = nil,
        font: UIFont? = nil,
        bgColor: UIColor? = nil,
        completion: @escaping (String, UIFont, UIColor, UIColor) -> Void
    ) {
        var bgImage: UIImage?
        autoreleasepool {
            // Calculate image displayed frame on the screen.
            var r = mainScrollView.convert(view.frame, to: containerView)
            r.origin.x += mainScrollView.contentOffset.x / mainScrollView.zoomScale
            r.origin.y += mainScrollView.contentOffset.y / mainScrollView.zoomScale
            let scale = imageSize.width / imageView.frame.width
            r.origin.x *= scale
            r.origin.y *= scale
            r.size.width *= scale
            r.size.height *= scale

            let isCircle = selectRatio?.isCircle ?? false
            bgImage = buildImage()
                .zl.clipImage(angle: angle, editRect: editRect, isCircle: isCircle)?
                .zl.clipImage(angle: 0, editRect: r, isCircle: isCircle)
        }

        let vc = ZLInputTextViewController(
            image: bgImage,
            text: text, font:
                font, textColor:
                textColor, bgColor:
                bgColor
        )

        vc.endInput = { text, font, textColor, bgColor in
            completion(text, font, textColor, bgColor)
        }

        vc.modalPresentationStyle = .fullScreen
        showDetailViewController(vc, sender: nil)
    }

    func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let scale = mainScrollView.zoomScale
        // Calculate the display rect of container view.
        let x = (mainScrollView.contentOffset.x - containerView.frame.minX) / scale
        let y = (mainScrollView.contentOffset.y - containerView.frame.minY) / scale
        let w = view.frame.width / scale
        let h = view.frame.height / scale
        // Convert to text stickers container view.
        let r = containerView.convert(CGRect(x: x, y: y, width: w, height: h), to: stickersContainer)
        let originFrame = CGRect(x: r.minX + (r.width - size.width) / 2, y: r.minY + (r.height - size.height) / 2, width: size.width, height: size.height)
        return originFrame
    }

    /// Add image sticker
    func addImageStickerView(_ image: UIImage) {
        let scale = mainScrollView.zoomScale
        let size = ZLImageStickerView.calculateSize(image: image, width: view.frame.width)
        let originFrame = getStickerOriginFrame(size)

        let imageSticker = ZLImageStickerView(image: image, originScale: 1 / scale, originAngle: -angle, originFrame: originFrame)
        stickersContainer.addSubview(imageSticker)
        imageSticker.frame = originFrame
        view.layoutIfNeeded()

        configImageSticker(imageSticker)
    }

    /// Add text sticker
    func addTextStickersView(_ text: String, textColor: UIColor, font: UIFont? = nil, bgColor: UIColor) {
        guard !text.isEmpty else { return }
        let scale = mainScrollView.zoomScale
        let size = ZLTextStickerView.calculateSize(text: text, width: view.frame.width, font: font)
        let originFrame = getStickerOriginFrame(size)

        let textSticker = ZLTextStickerView(text: text, textColor: textColor, font: font, bgColor: bgColor, originScale: 1 / scale, originAngle: -angle, originFrame: originFrame)
        stickersContainer.addSubview(textSticker)
        textSticker.frame = originFrame

        configTextSticker(textSticker)
    }

    func configTextSticker(_ textSticker: ZLTextStickerView) {
        textSticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: textSticker.pinchGes)
        mainScrollView.panGestureRecognizer.require(toFail: textSticker.panGes)
        panGes.require(toFail: textSticker.panGes)
    }

    func configImageSticker(_ imageSticker: ZLImageStickerView) {
        imageSticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: imageSticker.pinchGes)
        mainScrollView.panGestureRecognizer.require(toFail: imageSticker.panGes)
        panGes.require(toFail: imageSticker.panGes)
    }

    func reCalculateStickersFrame(_ oldSize: CGSize, _ oldAngle: CGFloat, _ newAngle: CGFloat) {
        let currSize = stickersContainer.frame.size
        let scale: CGFloat
        if Int(newAngle - oldAngle) % 180 == 0 {
            scale = currSize.width / oldSize.width
        } else {
            scale = currSize.height / oldSize.width
        }

        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.addScale(scale)
        }
    }
}
