//
//  ZLEditImageViewController+ButtonsAction.swift
//  ZLImageEditor
//
//  Created by Musa on 25.06.2023.
//

import Foundation

// MARK: - buttons actions
extension ZLEditImageViewController {
    @objc func cancelBtnClick() {
        dismiss(animated: animateDismiss, completion: nil)
    }

    func drawBtnClick() {
        let isSelected = selectedTool != .draw
        if isSelected {
            selectedTool = .draw
        } else {
            selectedTool = nil
        }
        drawColorCollectionView.isHidden = !isSelected
        self.revokeRedoContainer.isHidden = !isSelected
        revokeBtn.isEnabled = !drawPaths.isEmpty
        redoBtn.isEnabled = drawPaths.count != redoDrawPaths.count
        filterCollectionView.isHidden = true
        adjustCollectionView.isHidden = true
        self.adjustSlider.isHidden = true
    }

    func clipBtnClick() {
        var currentEditImage = editImage
        autoreleasepool {
            currentEditImage = buildImage()
        }

        let vc = ZLClipImageViewController(image: currentEditImage, editRect: editRect, angle: angle, selectRatio: selectRatio)
        let rect = mainScrollView.convert(containerView.frame, to: view)
        vc.presentAnimateFrame = rect
        vc.presentAnimateImage = currentEditImage.zl.clipImage(angle: angle, editRect: editRect, isCircle: selectRatio?.isCircle ?? false)
        vc.modalPresentationStyle = .fullScreen

        vc.clipDoneBlock = { [weak self] angle, editFrame, selectRatio in
            guard let `self` = self else { return }
            let oldAngle = self.angle
            let oldContainerSize = self.stickersContainer.frame.size
            if self.angle != angle {
                self.angle = angle
                self.rotationImageView()
            }
            self.editRect = editFrame
            self.selectRatio = selectRatio
            self.resetContainerViewFrame()
            self.reCalculateStickersFrame(oldContainerSize, oldAngle, angle)
        }

        vc.cancelClipBlock = { [weak self] () in
            self?.resetContainerViewFrame()
        }

        present(vc, animated: false) {
            self.mainScrollView.alpha = 0
            self.headerView.alpha = 0
            self.bottomToolsContainerView.alpha = 0
            self.self.adjustSlider.alpha = 0
        }
    }

    func imageStickerBtnClick() {
        ZLImageEditorConfiguration.default().imageStickerContainerView?.show(in: view)
        imageStickerContainerIsHidden = false
    }

    func textStickerBtnClick() {
        if let fontChooserContainerView = ZLImageEditorConfiguration.default().fontChooserContainerView {
            fontChooserContainerView.show(in: view)
            fontChooserContainerIsHidden = false
        } else {
            showInputTextVC { [weak self] text, _, textColor, bgColor in
                self?.addTextStickersView(text, textColor: textColor, bgColor: bgColor)
            }
        }
    }

    func filterBtnClick() {
        let isSelected = selectedTool != .filter
        if isSelected {
            selectedTool = .filter
        } else {
            selectedTool = nil
        }

        drawColorCollectionView.isHidden = true
        self.revokeRedoContainer.isHidden = true
        filterCollectionView.isHidden = !isSelected
        adjustCollectionView.isHidden = true
        self.adjustSlider.isHidden = true
    }

    func adjustBtnClick() {
        let isSelected = selectedTool != .adjust
        if isSelected {
            selectedTool = .adjust
        } else {
            selectedTool = nil
        }

        drawColorCollectionView.isHidden = true
        self.revokeRedoContainer.isHidden = true
        filterCollectionView.isHidden = true
        adjustCollectionView.isHidden = !isSelected
        self.adjustSlider.isHidden = !isSelected

        self.editImageAdjustRef = self.editImageWithoutAdjust
    }

    @objc func doneBtnClick() {
        var textStickers: [(ZLTextStickerState, Int)] = []
        var imageStickers: [(ZLImageStickerState, Int)] = []
        for (index, view) in stickersContainer.subviews.enumerated() {
            if let ts = view as? ZLTextStickerView, let _ = ts.label.text {
                textStickers.append((ts.state, index))
            } else if let ts = view as? ZLImageStickerView {
                imageStickers.append((ts.state, index))
            }
        }

        var hasEdit = true
        if drawPaths.isEmpty, editRect.size == imageSize, angle == 0, imageStickers.isEmpty, textStickers.isEmpty, currentFilter.applier == nil, brightness == 0, contrast == 0, saturation == 0 {
            hasEdit = false
        }

        var resImage = originalImage
        var editModel: ZLEditImageModel?
        if hasEdit {
            autoreleasepool {
                let hud = ZLProgressHUD(style: ZLImageEditorUIConfiguration.default().hudStyle)
                hud.show()

                resImage = buildImage()
                resImage = resImage.zl.clipImage(angle: angle, editRect: editRect, isCircle: selectRatio?.isCircle ?? false) ?? resImage
                if let oriDataSize = originalImage.jpegData(compressionQuality: 1)?.count {
                    resImage = resImage.zl.compress(to: oriDataSize)
                }

                hud.hide()
            }

            editModel = ZLEditImageModel(
                drawPaths: drawPaths,
                editRect: editRect,
                angle: angle,
                brightness: brightness,
                contrast: contrast,
                saturation: saturation,
                selectRatio: selectRatio,
                selectFilter: currentFilter,
                textStickers: textStickers,
                imageStickers: imageStickers
            )
        }

        dismiss(animated: animateDismiss) {
            self.editFinishBlock?(resImage, editModel)
        }
    }

    @objc func revokeBtnClick() {
        if selectedTool == .draw {
            guard !drawPaths.isEmpty else {
                return
            }
            drawPaths.removeLast()
            revokeBtn.isEnabled = !drawPaths.isEmpty
            self.redoBtn.isEnabled = drawPaths.count != redoDrawPaths.count
            drawLine()
        }
    }

    @objc func redoBtnClick() {
        if selectedTool == .draw {
            guard drawPaths.count < redoDrawPaths.count else {
                return
            }
            let path = redoDrawPaths[drawPaths.count]
            drawPaths.append(path)
            revokeBtn.isEnabled = !drawPaths.isEmpty
            self.redoBtn.isEnabled = drawPaths.count != redoDrawPaths.count
            drawLine()
        }
    }
}
