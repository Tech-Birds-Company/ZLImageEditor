import UIKit

// MARK: - tools actions
extension ZLEditImageViewController {

    func magicBackgroundButtonClick() async {
        self.dependency?.analyticService?.logEvent(name: "editor_remove_background")
        guard let image = await self.dependency?.magicBackgroundService?.removeBackground(image: self.editImage) else { return }
        self.backgroundDeleted = true
        self.editImage = image
        resetContainerViewFrame()
    }

    func drawBtnClick() {
        self.dependency?.analyticService?.logEvent(name: "editor_draw")
        let isSelected = selectedTool != .draw
        if isSelected {
            selectedTool = .draw
            self.drawingImageView.isUserInteractionEnabled = true
        } else {
            selectedTool = nil
            self.drawingImageView.isUserInteractionEnabled = false
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
        self.dependency?.analyticService?.logEvent(name: "editor_image_crop")
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

        vc.modalPresentationStyle = .fullScreen
        UIView.performWithoutAnimation {
            showDetailViewController(vc, sender: self)
        }

        // пришлось убрать потому что странной поведение когда открывается через swiftui
        //        present(vc, animated: false) {
        //            self.mainScrollView.alpha = 0
        //            self.headerView.alpha = 0
        //            self.bottomToolsContainerView.alpha = 0
        //            self.self.adjustSlider.alpha = 0
        //        }
    }

    func imageStickerBtnClick() {
        self.dependency?.analyticService?.logEvent(name: "editor_add_clothes")
        ZLImageEditorConfiguration.default().imageStickerContainerView?.show(in: view)
        imageStickerContainerIsHidden = false
    }

    func textStickerBtnClick() {
        self.dependency?.analyticService?.logEvent(name: "editor_image_text")
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
        self.dependency?.analyticService?.logEvent(name: "editor_image_settings")
        if selectedTool == .eraser {
            self.showHideMaskableView(isSelected: false)
            self.saveFromMaskableView()
        }
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

        self.editImageAdjustRef = self.editImage
    }

    func eraserButtonClick() {
        self.dependency?.analyticService?.logEvent(name: "editor_image_eraser")
        filterCollectionView.isHidden = true
        adjustCollectionView.isHidden = true
        self.adjustSlider.isHidden = true
        let isSelected = selectedTool != .eraser
        if isSelected {
            selectedTool = .eraser
        } else {
            selectedTool = nil
        }

        self.showHideMaskableView(isSelected: isSelected)
        if isSelected {
            self.maskableView.configure(with: self.editImage, and: getImage("greyCheckerboard")!)
            self.eraseUsed = true
        } else {
            self.saveFromMaskableView()
        }
    }

    private func showHideMaskableView(isSelected: Bool) {
        self.maskableView.isHidden = !isSelected
        self.masakableControlsContainer.isHidden = !isSelected
    }

    private func saveFromMaskableView() {
        guard let image = self.maskableView.image else { return }
        self.editImage = image
        resetContainerViewFrame()
    }

}

// MARK: - buttons actions
extension ZLEditImageViewController {

    @objc func cancelBtnClick() {
        dismiss(animated: animateDismiss, completion: nil)
    }

    @objc func doneBtnClick() {
        self.dependency?.analyticService?.logEvent(name: "clothes_new_editor_done")
        var textStickers: [(ZLTextStickerState, Int)] = []
        var imageStickers: [(ZLImageStickerState, Int)] = []
        for (index, view) in stickersContainer.subviews.enumerated() {
            if let ts = view as? ZLTextStickerView, ts.label.text != nil {
                textStickers.append((ts.state, index))
            } else if let ts = view as? ZLImageStickerView {
                imageStickers.append((ts.state, index))
            }
        }

        var hasEdit = true
        if drawPaths.isEmpty,
           editRect.size == imageSize,
           angle == 0, imageStickers.isEmpty,
           textStickers.isEmpty,
           currentFilter.applier == nil,
           brightness == 0, contrast == 0,
           saturation == 0,
           !backgroundDeleted,
           !eraseUsed {
            hasEdit = false
        }

        var resImage = originalImage
        var editModel: ZLEditImageModel?
        if hasEdit {
            if selectedTool == .eraser {
                self.eraserButtonClick()
            }
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

        if needDismissAfterEdit {
            dismiss(animated: animateDismiss) { [unowned self] in
                self.editFinishBlock?(self.originalImage, resImage, editModel, self.backgroundDeleted)
            }
        } else {
            self.editFinishBlock?(self.originalImage, resImage, editModel, self.backgroundDeleted)
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
