//
//  ZLEditImageModel.swift
//  ZLImageEditor
//
//  Created by Musa on 30.05.2023.
//

import UIKit

public class ZLEditImageModel: NSObject {
    public let drawPaths: [ZLDrawPath]

    public let editRect: CGRect?

    public let angle: CGFloat

    public let brightness: Float

    public let contrast: Float

    public let saturation: Float

    public let selectRatio: ZLImageClipRatio?

    public let selectFilter: ZLFilter?

    public let textStickers: [(state: ZLTextStickerState, index: Int)]?

    public let imageStickers: [(state: ZLImageStickerState, index: Int)]?

    public init(
        drawPaths: [ZLDrawPath],
        editRect: CGRect?,
        angle: CGFloat,
        brightness: Float,
        contrast: Float,
        saturation: Float,
        selectRatio: ZLImageClipRatio?,
        selectFilter: ZLFilter,
        textStickers: [(state: ZLTextStickerState, index: Int)]?,
        imageStickers: [(state: ZLImageStickerState, index: Int)]?
    ) {
        self.drawPaths = drawPaths
        self.editRect = editRect
        self.angle = angle
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.selectRatio = selectRatio
        self.selectFilter = selectFilter
        self.textStickers = textStickers
        self.imageStickers = imageStickers
        super.init()
    }
}
