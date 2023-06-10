//
//  ZLEditImageViewController+UIGestureRecognizerDelegate.swift
//  ZLImageEditor
//
//  Created by Musa on 30.05.2023.
//

import UIKit

extension ZLEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard imageStickerContainerIsHidden, fontChooserContainerIsHidden else {
            return false
        }
        if gestureRecognizer is UITapGestureRecognizer {
            if bottomToolsContainerView.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                return !bottomToolsContainerView.frame.contains(p)
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            guard let st = selectedTool else {
                return false
            }
            return st == .draw && !isScrolling
        }

        return true
    }
}
