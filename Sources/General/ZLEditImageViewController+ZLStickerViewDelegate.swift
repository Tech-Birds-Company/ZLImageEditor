//
//  ZLEditImageViewController+ZLStickerViewDelegate.swift
//  ZLImageEditor
//
//  Created by Musa on 30.05.2023.
//

import UIKit

extension ZLEditImageViewController: ZLStickerViewDelegate {
    func stickerBeginOperation(_ sticker: UIView) {
        setToolView(show: false)
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = false
        var frame = ashbinView.frame
        let diff = view.frame.height - frame.minY
        frame.origin.y += diff
        ashbinView.frame = frame
        frame.origin.y -= diff
        UIView.animate(withDuration: 0.25) {
            self.ashbinView.frame = frame
        }

        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
                (view as? ZLStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }

    func stickerOnOperation(_ sticker: UIView, panGes: UIPanGestureRecognizer) {
        let point = panGes.location(in: view)
        if ashbinView.frame.contains(point) {
            ashbinView.backgroundColor = .zl.ashbinTintBgColor
            ashbinImgView.isHighlighted = true
            if sticker.alpha == 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 0.5
                }
            }
        } else {
            ashbinView.backgroundColor = .zl.ashbinNormalBgColor
            ashbinImgView.isHighlighted = false
            if sticker.alpha != 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 1
                }
            }
        }
    }

    func stickerEndOperation(_ sticker: UIView, panGes: UIPanGestureRecognizer) {
        setToolView(show: true)
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = true

        let point = panGes.location(in: view)
        if ashbinView.frame.contains(point) {
            (sticker as? ZLStickerViewAdditional)?.moveToAshbin()
        }

        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.gesIsEnabled = true
        }
    }

    func stickerDidTap(_ sticker: UIView) {
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
            }
        }
    }

    func sticker(_ textSticker: ZLTextStickerView, editText text: String) {
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.textFont, bgColor: textSticker.bgColor) { [weak self] text, font, textColor, bgColor in
            guard let `self` = self else { return }
            if text.isEmpty {
                textSticker.moveToAshbin()
            } else {
                textSticker.startTimer()
                guard textSticker.text != text || textSticker.textColor != textColor || textSticker.bgColor != bgColor else {
                    return
                }
                textSticker.text = text
                textSticker.textColor = textColor
                textSticker.bgColor = bgColor
                textSticker.textFont = font
                let newSize = ZLTextStickerView.calculateSize(text: text, width: self.view.frame.width, font: font)
                textSticker.changeSize(to: newSize)
            }
        }
    }
}
