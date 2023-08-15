//
//  ZLEditImageViewController + UICollectionView.swift
//  ZLImageEditor
//
//  Created by Musa on 30.05.2023.
//

import UIKit

extension ZLEditImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == editToolCollectionView {
            return tools.count
        } else if collectionView == drawColorCollectionView {
            return drawColors.count
        } else if collectionView == filterCollectionView {
            return thumbnailFilterImages.count
        } else {
            return adjustTools.count
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == editToolCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLEditToolCell.zl.identifier, for: indexPath) as! ZLEditToolCell

            let toolType = tools[indexPath.row]
            cell.icon.isHighlighted = false
            cell.toolType = toolType
            cell.icon.isHighlighted = toolType == selectedTool

            return cell
        } else if collectionView == drawColorCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawColorCell.zl.identifier, for: indexPath) as! ZLDrawColorCell

            let c = drawColors[indexPath.row]
            cell.color = c
            if c == currentDrawColor {
                cell.bgWhiteView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
            } else {
                cell.bgWhiteView.layer.transform = CATransform3DIdentity
            }

            return cell
        } else if collectionView == filterCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLFilterImageCell.zl.identifier, for: indexPath) as! ZLFilterImageCell

            let image = thumbnailFilterImages[indexPath.row]
            let filter = ZLImageEditorConfiguration.default().filters[indexPath.row]

            cell.nameLabel.text = filter.name
            cell.imageView.image = image

            if currentFilter === filter {
                cell.nameLabel.textColor = .zl.toolTitleTintColor
            } else {
                cell.nameLabel.textColor = .zl.toolTitleNormalColor
            }

            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLAdjustToolCell.zl.identifier, for: indexPath) as! ZLAdjustToolCell

            let tool = adjustTools[indexPath.row]

            cell.imageView.isHighlighted = false
            cell.adjustTool = tool
            let isSelected = tool == selectedAdjustTool
            cell.imageView.isHighlighted = isSelected

            if isSelected {
                cell.nameLabel.textColor = .zl.toolTitleTintColor
            } else {
                cell.nameLabel.textColor = .zl.toolTitleNormalColor
            }

            return cell
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == editToolCollectionView {
            let toolType = tools[indexPath.row]
            switch toolType {
            case .draw:
                self.drawBtnClick()
            case .clip:
                clipBtnClick()
            case .imageSticker:
                imageStickerBtnClick()
            case .textSticker:
                textStickerBtnClick()
            case .filter:
                filterBtnClick()
            case .adjust:
                adjustBtnClick()
            case .magicBackground:
                Task(priority: .userInitiated) {
                    await self.magicBackgroundButtonClick()
                }
            }
        } else if collectionView == drawColorCollectionView {
            currentDrawColor = drawColors[indexPath.row]
        } else if collectionView == filterCollectionView {
            currentFilter = ZLImageEditorConfiguration.default().filters[indexPath.row]
            func adjustImage(_ image: UIImage) -> UIImage {
                guard tools.contains(.adjust), brightness != 0 || contrast != 0 || saturation != 0 else {
                    return image
                }
                return image.zl.adjust(brightness: brightness, contrast: contrast, saturation: saturation) ?? image
            }
            if let image = filterImages[currentFilter.name] {
                editImage = adjustImage(image)
                editImageWithoutAdjust = image
            } else {
                let image = currentFilter.applier?(originalImage) ?? originalImage
                editImage = adjustImage(image)
                editImageWithoutAdjust = image
                filterImages[currentFilter.name] = image
            }
            imageView.image = editImage
        } else {
            let tool = adjustTools[indexPath.row]
            if tool != selectedAdjustTool {
                changeAdjustTool(tool)
            }
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
    }
}
