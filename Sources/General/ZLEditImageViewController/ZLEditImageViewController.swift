import UIKit
import SnapKit

public typealias ZLEditFinishBlock = (
    _ orifinal: UIImage,
    _ result: UIImage,
    _ editModel: ZLEditImageModel?,
    _ isMagicBackgroundApplied: Bool
) -> Void

open class ZLEditImageViewController: UIViewController {

    open lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .init(white: 245/255, alpha: 1.0)
        view.minimumZoomScale = 1
        view.maximumZoomScale = 3
        view.delegate = self
        return view
    }()

    open lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    lazy var maskableView: MaskableViewContainer = {
        let maskCont = MaskableViewContainer()
        maskCont.isHidden = true
        maskCont.showHideTools = { [weak self] hide in
            self?.masakableControlsContainer.isHidden = hide
        }
        return maskCont
    }()

    lazy var masakableControlsContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .white
        return view
    }()

    lazy var maskableRadiusSlider: UISlider = {
       let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 100
        slider.value = 20
        slider.tintColor = .zl.editDoneBtnBgColor
        slider.addTarget(self, action: #selector(self.handleCircleRadiusSlider(_:)), for: .valueChanged)
        return slider
    }()

    lazy var maskableSegmentControl: UISegmentedControl = {
        // Create a segmented control
        let segmentedControl = UISegmentedControl(items: ["Erase", "Reveal"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(self.handleEraseRevealControl(_:)), for: .valueChanged)
        return segmentedControl
    }()

    // Show image.
    open lazy var imageView: UIImageView = {
        let view = UIImageView(image: originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .clear
        return view
    }()

    open lazy var headerView = {
        let view = UIView()
        view.backgroundColor = .init(white: 249/255, alpha: 1.0)
        view.layer.masksToBounds = false
        view.layer.shadowRadius = 0
        view.layer.shadowOpacity = 1
        view.layer.shadowColor =  UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        return view
    }()

    open lazy var bottomToolsContainerView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    open lazy var cancelBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(getImage("zl_close")?.withTintColor(.zl.editDoneBtnBgColor), for: .normal)
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        btn.enlargeInset = 30
        return btn
    }()

    open lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = ZLImageEditorLayout.bottomToolTitleFont
        btn.backgroundColor = .zl.editDoneBtnBgColor
        btn.setTitle(localLanguageTextValue(.editFinish), for: .normal)
        btn.setTitleColor(.zl.editDoneBtnTitleColor, for: .normal)
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = ZLImageEditorLayout.bottomToolBtnCornerRadius
        return btn
    }()

    lazy var revokeRedoContainer: UIView = {
        let btnsView = UIView()
        btnsView.backgroundColor = .zl.editDoneBtnBgColor
        btnsView.isHidden = true
        btnsView.layer.cornerRadius = 10
        btnsView.layer.masksToBounds = true
        return btnsView
    }()
    open lazy var revokeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(getImage("zl_revoke_disable"), for: .disabled)
        btn.setImage(getImage("zl_revoke"), for: .normal)
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(revokeBtnClick), for: .touchUpInside)
        return btn
    }()
    open lazy var redoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(getImage("zl_redo_disable"), for: .disabled)
        btn.setImage(getImage("zl_redo"), for: .normal)
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(redoBtnClick), for: .touchUpInside)
        return btn
    }()

    open lazy var editToolCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 40, height: 40)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .init(white: 241/255, alpha: 1.0)
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        view.layer.cornerRadius = 10.0
        view.layer.masksToBounds = true
        ZLEditToolCell.zl.register(view)
        return view
    }()

    open lazy var drawColorCollectionView: UICollectionView = {
        let drawColorLayout = UICollectionViewFlowLayout()
        let drawColorItemWidth: CGFloat = 30
        drawColorLayout.itemSize = CGSize(width: drawColorItemWidth, height: drawColorItemWidth)
        drawColorLayout.minimumLineSpacing = 15
        drawColorLayout.minimumInteritemSpacing = 15
        drawColorLayout.scrollDirection = .horizontal
        let drawColorTopBottomInset = (Constants.drawColViewH - drawColorItemWidth) / 2
        drawColorLayout.sectionInset = UIEdgeInsets(top: drawColorTopBottomInset, left: 8, bottom: drawColorTopBottomInset, right: 8)

        let drawCV = UICollectionView(frame: .zero, collectionViewLayout: drawColorLayout)
        drawCV.backgroundColor = .zl.editDoneBtnBgColor
        drawCV.delegate = self
        drawCV.dataSource = self
        drawCV.isHidden = true
        drawCV.showsHorizontalScrollIndicator = false
        drawCV.layer.cornerRadius = 10.0
        drawCV.layer.masksToBounds = true
        ZLDrawColorCell.zl.register(drawCV)
        return drawCV
    }()

    open lazy var filterCollectionView: UICollectionView = {
        if let applier = currentFilter.applier {
            let image = applier(originalImage)
            editImage = image
            editImageWithoutAdjust = image
            filterImages[currentFilter.name] = image
        }

        let filterLayout = UICollectionViewFlowLayout()
        filterLayout.itemSize = CGSize(width: Constants.filterColViewH - 20, height: Constants.filterColViewH)
        filterLayout.minimumLineSpacing = 15
        filterLayout.minimumInteritemSpacing = 15
        filterLayout.scrollDirection = .horizontal
        filterLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        let filterCV = UICollectionView(frame: .zero, collectionViewLayout: filterLayout)
        filterCV.backgroundColor = .zl.editDoneBtnBgColor
        filterCV.delegate = self
        filterCV.dataSource = self
        filterCV.isHidden = true
        filterCV.showsHorizontalScrollIndicator = false
        filterCV.layer.cornerRadius = 10.0
        filterCV.layer.masksToBounds = true

        ZLFilterImageCell.zl.register(filterCV)
        return filterCV
    }()

    open lazy var adjustCollectionView: UICollectionView = {
        let adjustLayout = UICollectionViewFlowLayout()
        adjustLayout.itemSize = UICollectionViewFlowLayout.automaticSize
        adjustLayout.estimatedItemSize = CGSize(width: 100, height: Constants.adjustColViewH)
        adjustLayout.minimumLineSpacing = 10
        adjustLayout.minimumInteritemSpacing = 10
        adjustLayout.scrollDirection = .horizontal
        adjustLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        let adjustCV = UICollectionView(frame: .zero, collectionViewLayout: adjustLayout)

        adjustCV.backgroundColor = .zl.editDoneBtnBgColor
        adjustCV.delegate = self
        adjustCV.dataSource = self
        adjustCV.isHidden = true
        adjustCV.showsHorizontalScrollIndicator = false
        adjustCV.layer.cornerRadius = 10.0
        adjustCV.layer.masksToBounds = true

        ZLAdjustToolCell.zl.register(adjustCV)
        return adjustCV
    }()

    open lazy var ashbinView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.ashbinNormalBgColor
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    open lazy var ashbinImgView = UIImageView(image: getImage("zl_ashbin"), highlightedImage: getImage("zl_ashbin_open"))

    lazy var adjustSlider: ZLAdjustSlider = {
        let slider = ZLAdjustSlider()
        slider.beginAdjust = {}
        slider.valueChanged = { [weak self] value in
            self?.adjustValueChanged(value)
        }
        slider.endAdjust = { [weak self] in
            self?.hasAdjustedImage = true
        }
        slider.isHidden = true
        return slider
    }()

    var animateDismiss = true
    var needDismissAfterEdit = false

    var originalImage: UIImage

    // The frame after first layout, used in dismiss animation.
    var originalFrame: CGRect = .zero

    var editRect: CGRect

    let tools: [ZLImageEditorConfiguration.EditTool]

    let adjustTools: [ZLImageEditorConfiguration.AdjustTool]

    var selectRatio: ZLImageClipRatio?

    var editImage: UIImage

    var editImageWithoutAdjust: UIImage

    var editImageAdjustRef: UIImage?

    // Show draw lines.
    lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        return view
    }()

    // Show text and image stickers.
    lazy var stickersContainer = UIView()

    var selectedTool: ZLImageEditorConfiguration.EditTool?

    var selectedAdjustTool: ZLImageEditorConfiguration.AdjustTool?

    let drawColors: [UIColor]

    var currentDrawColor = ZLImageEditorConfiguration.default().defaultDrawColor

    var drawPaths: [ZLDrawPath]

    var redoDrawPaths: [ZLDrawPath]

    var drawLineWidth: CGFloat = 5

    var thumbnailFilterImages: [UIImage] = []

    // Cache the filter image of original image
    var filterImages: [String: UIImage] = [:]

    var currentFilter: ZLFilter

    var stickers: [UIView] = []

    var isScrolling = false

    var shouldLayout = true

    var imageStickerContainerIsHidden = true

    var fontChooserContainerIsHidden = true

    var angle: CGFloat

    var brightness: Float

    var contrast: Float

    var saturation: Float

    var panGes: UIPanGestureRecognizer!

    var imageSize: CGSize {
        if angle == -90 || angle == -270 {
            return CGSize(width: originalImage.size.height, height: originalImage.size.width)
        }
        return originalImage.size
    }

    let canRedo = ZLImageEditorConfiguration.default().canRedo

    var hasAdjustedImage = false

    var backgroundDeleted = false
    var eraseUsed = false

    @objc public var editFinishBlock: ZLEditFinishBlock?

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    let dependency: EditorDependency?

    deinit {
        debugPrint("ZLEditImageViewController deinit")
    }

//    @objc public class func showEditImageVC(
//        parentVC: UIViewController?,
//        animate: Bool = true,
//        image: UIImage,
//        editModel: ZLEditImageModel? = nil,
//        completion: ((UIImage, ZLEditImageModel?) -> Void)?
//    ) {
//        let tools = ZLImageEditorConfiguration.default().tools
//        if ZLImageEditorConfiguration.default().showClipDirectlyIfOnlyHasClipTool, tools.count == 1, tools.contains(.clip) {
//            let vc = ZLClipImageViewController(
//                image: image,
//                editRect: editModel?.editRect,
//                angle: editModel?.angle ?? 0,
//                selectRatio: editModel?.selectRatio
//            )
//            vc.clipDoneBlock = { angle, editRect, ratio in
//                let m = ZLEditImageModel(
//                    drawPaths: [],
//                    editRect: editRect,
//                    angle: angle, brightness: 0,
//                    contrast: 0,
//                    saturation: 0,
//                    selectRatio: ratio,
//                    selectFilter: .normal,
//                    textStickers: nil,
//                    imageStickers: nil
//                )
//                completion?(image.zl.clipImage(angle: angle, editRect: editRect, isCircle: ratio.isCircle) ?? image, m)
//            }
//            vc.animateDismiss = animate
//            vc.modalPresentationStyle = .fullScreen
//            parentVC?.present(vc, animated: animate, completion: nil)
//        } else {
//            let vc = ZLEditImageViewController(image: image, editModel: editModel)
//            vc.editFinishBlock = { ei, editImageModel in
//                completion?(ei, editImageModel)
//            }
//            vc.animateDismiss = animate
//            vc.modalPresentationStyle = .fullScreen
//            parentVC?.present(vc, animated: animate, completion: nil)
//        }
//    }

    public init(image: UIImage, editModel: ZLEditImageModel? = nil, dependency: EditorDependency? = nil) {
        self.dependency = dependency
        var image = image
        if image.scale != 1,
           let cgImage = image.cgImage {
            image = image.zl.resize_vI(
                CGSize(width: cgImage.width, height: cgImage.height),
                scale: 1
            ) ?? image
        }

        originalImage = image.zl.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        editRect = editModel?.editRect ?? CGRect(origin: .zero, size: image.size)
        drawColors = ZLImageEditorConfiguration.default().drawColors
        currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        redoDrawPaths = drawPaths
        angle = editModel?.angle ?? 0
        brightness = editModel?.brightness ?? 0
        contrast = editModel?.contrast ?? 0
        saturation = editModel?.saturation ?? 0
        selectRatio = editModel?.selectRatio

        var ts = ZLImageEditorConfiguration.default().tools
        if ts.contains(.imageSticker), ZLImageEditorConfiguration.default().imageStickerContainerView == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        tools = ts
        adjustTools = ZLImageEditorConfiguration.default().adjustTools
        selectedAdjustTool = adjustTools.first

        super.init(nibName: nil, bundle: nil)

        if !drawColors.contains(currentDrawColor) {
            currentDrawColor = drawColors.first!
        }

        let teStic = editModel?.textStickers ?? []
        let imStic = editModel?.imageStickers ?? []

        var stickers: [UIView?] = Array(repeating: nil, count: teStic.count + imStic.count)
        teStic.forEach { cache in
            let v = ZLTextStickerView(from: cache.state)
            stickers[cache.index] = v
        }
        imStic.forEach { cache in
            let v = ZLImageStickerView(from: cache.state)
            stickers[cache.index] = v
        }

        self.stickers = stickers.compactMap { $0 }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        rotationImageView()
        if tools.contains(.filter) {
            generateFilterImages()
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else {
            return
        }

        shouldLayout = false
        debugPrint("edit image layout subviews")

        resetContainerViewFrame()

        if canRedo {
            redoBtn.frame = CGRect(x: view.zl.width - 15 - 35, y: 30, width: 35, height: 30)
            revokeBtn.frame = CGRect(x: redoBtn.zl.left - 10 - 35, y: 30, width: 35, height: 30)
        } else {
            revokeBtn.frame = CGRect(x: view.zl.width - 15 - 35, y: 30, width: 35, height: 30)
        }

        ashbinView.frame = CGRect(
            x: (view.zl.width - Constants.ashbinSize.width) / 2,
            y: view.zl.height - Constants.ashbinSize.height - self.bottomToolsContainerView.frame.height - 16,
            width: Constants.ashbinSize.width,
            height: Constants.ashbinSize.height
        )
        ashbinImgView.frame = CGRect(
            x: (Constants.ashbinSize.width - 25) / 2,
            y: 15,
            width: 25,
            height: 25
        )

        if !drawPaths.isEmpty {
            drawLine()
        }

        if let index = drawColors.firstIndex(where: { $0 == self.currentDrawColor }) {
            drawColorCollectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }

    func generateFilterImages() {
        let size: CGSize
        let ratio = (originalImage.size.width / originalImage.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = originalImage.zl.resize(size) ?? originalImage

        DispatchQueue.global().async {
            self.thumbnailFilterImages = ZLImageEditorConfiguration.default().filters.map { $0.applier?(thumbnailImage) ?? thumbnailImage }

            DispatchQueue.main.async {
                self.filterCollectionView.reloadData()
                self.filterCollectionView.performBatchUpdates {} completion: { _ in
                    if let index = ZLImageEditorConfiguration.default().filters.firstIndex(where: { $0 == self.currentFilter }) {
                        self.filterCollectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
                    }
                }
            }
        }
    }

    func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editImage

        let editSize = editRect.size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2), y: max(0, (scrollViewSize.height - h) / 2), width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size

        if selectRatio?.isCircle == true {
            let mask = CAShapeLayer()
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            mask.path = path.cgPath
            containerView.layer.mask = mask
        } else {
            containerView.layer.mask = nil
        }

        let scaleImageOrigin = CGPoint(x: -editRect.origin.x * ratio, y: -editRect.origin.y * ratio)
        let scaleImageSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        drawingImageView.frame = imageView.frame
        stickersContainer.frame = imageView.frame

        // Optimization for long pictures.
        if (editRect.height / editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let widthScale = view.frame.width / w
            mainScrollView.maximumZoomScale = widthScale
            mainScrollView.zoomScale = widthScale
            mainScrollView.contentOffset = .zero
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / h)
        }

        originalFrame = view.convert(containerView.frame, from: mainScrollView)
        isScrolling = false
    }

    func setupUI() {
        self.setupMainUI()
        self.setupDrawToolsUI()
        self.setupFilterToolsUI()
        self.setupAdjustToolsUI()
        self.setupAshbinViewUI()
        self.setupImageSticker()
        self.setupTextSticker()
        self.setupEraserToolUI()

        panGes = UIPanGestureRecognizer(target: self, action: #selector(drawAction(_:)))
        panGes.maximumNumberOfTouches = 1
        panGes.delegate = self
        view.addGestureRecognizer(panGes)
        mainScrollView.panGestureRecognizer.require(toFail: panGes)

        stickers.forEach { view in
            self.stickersContainer.addSubview(view)
            if let tv = view as? ZLTextStickerView {
                tv.frame = tv.originFrame
                self.configTextSticker(tv)
            } else if let iv = view as? ZLImageStickerView {
                iv.frame = iv.originFrame
                self.configImageSticker(iv)
            }
        }
    }

    func rotationImageView() {
        let transform = CGAffineTransform(rotationAngle: angle.zl.toPi)
        imageView.transform = transform
        drawingImageView.transform = transform
        stickersContainer.transform = transform
    }

    func changeAdjustTool(_ tool: ZLImageEditorConfiguration.AdjustTool) {
        selectedAdjustTool = tool

        switch tool {
        case .brightness:
            self.adjustSlider.value = brightness

        case .contrast:
            self.adjustSlider.value = contrast

        case .saturation:
            self.adjustSlider.value = saturation
        }
    }

    @objc func drawAction(_ pan: UIPanGestureRecognizer) {
        if selectedTool == .draw {
            let point = pan.location(in: drawingImageView)
            if pan.state == .began {

                let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
                let ratio = min(mainScrollView.frame.width / editRect.width, mainScrollView.frame.height / editRect.height)
                let scale = ratio / originalRatio
                // Zoom to original size
                var size = drawingImageView.frame.size
                size.width /= scale
                size.height /= scale
                if angle == -90 || angle == -270 {
                    swap(&size.width, &size.height)
                }

                var toImageScale = Constants.maxDrawLineImageWidth / size.width
                if editImage.size.width / editImage.size.height > 1 {
                    toImageScale = Constants.maxDrawLineImageWidth / size.height
                }

                let path = ZLDrawPath(pathColor: currentDrawColor, pathWidth: drawLineWidth / mainScrollView.zoomScale, ratio: ratio / originalRatio / toImageScale, startPoint: point)
                drawPaths.append(path)
                redoDrawPaths = drawPaths
            } else if pan.state == .changed {
                let path = drawPaths.last
                path?.addLine(to: point)
                drawLine()
            } else if pan.state == .cancelled || pan.state == .ended {
                revokeBtn.isEnabled = !drawPaths.isEmpty
                self.redoBtn.isEnabled = false
            }
        }
    }

    func adjustValueChanged(_ value: Float) {
        guard let selectedAdjustTool = selectedAdjustTool, let editImageAdjustRef = editImageAdjustRef else {
            return
        }
        var resultImage: UIImage?

        switch selectedAdjustTool {
        case .brightness:
            if brightness == value {
                return
            }
            brightness = value
            resultImage = editImageAdjustRef.zl.adjust(brightness: value, contrast: contrast, saturation: saturation)

        case .contrast:
            if contrast == value {
                return
            }
            contrast = value
            resultImage = editImageAdjustRef.zl.adjust(brightness: brightness, contrast: value, saturation: saturation)

        case .saturation:
            if saturation == value {
                return
            }
            saturation = value
            resultImage = editImageAdjustRef.zl.adjust(brightness: brightness, contrast: contrast, saturation: value)
        }

        guard let resultImage = resultImage else {
            return
        }
        editImage = resultImage
        imageView.image = editImage
    }

    func endAdjust() {
        hasAdjustedImage = false
    }

    func drawLine() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(mainScrollView.frame.width / editRect.width, mainScrollView.frame.height / editRect.height)
        let scale = ratio / originalRatio
        // Zoom to original size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if angle == -90 || angle == -270 {
            swap(&size.width, &size.height)
        }
        var toImageScale = Constants.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = Constants.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale

        UIGraphicsBeginImageContextWithOptions(size, false, editImage.scale)
        let context = UIGraphicsGetCurrentContext()

        context?.setAllowsAntialiasing(true)
        context?.setShouldAntialias(true)
        for path in drawPaths {
            path.drawPath()
        }
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    func buildImage() -> UIImage {
        let imageSize = originalImage.size

        UIGraphicsBeginImageContextWithOptions(editImage.size, false, editImage.scale)
        editImage.draw(at: .zero)

        drawingImageView.image?.draw(in: CGRect(origin: .zero, size: imageSize))

        if !stickersContainer.subviews.isEmpty, let context = UIGraphicsGetCurrentContext() {
            let scale = self.imageSize.width / stickersContainer.frame.width
            stickersContainer.subviews.forEach { view in
                (view as? ZLStickerViewAdditional)?.resetState()
            }
            context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
            stickersContainer.layer.render(in: context)
            context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
        }

        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgi = temp?.cgImage else {
            return editImage
        }
        return UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
    }

    func finishClipDismissAnimate() {
        mainScrollView.alpha = 1
        UIView.animate(withDuration: 0.1) {
            self.headerView.alpha = 1
            self.bottomToolsContainerView.alpha = 1
            self.self.adjustSlider.alpha = 1
        }
    }

}

// MARK: - maskable handle actions
extension ZLEditImageViewController {

    @objc func handleEraseRevealControl(_ sender: UISegmentedControl) {
        if let drawingAction  = DrawingAction(rawValue: sender.selectedSegmentIndex) {
            maskableView.drawingAction = drawingAction
        }
    }

    @objc func handleCircleRadiusSlider(_ sender: UISlider) {
        maskableView.cirleRadius = CGFloat(sender.value)
    }

}

// MARK: - setup UI
private extension ZLEditImageViewController {

    func setupMainUI() {
        self.view.addSubview(headerView) { make in
            make.top.leading.trailing.equalToSuperview()
            let window = UIApplication.shared.keyWindow
            let topSafeArea = window?.safeAreaInsets.top ?? 0.0
            make.height.equalTo(60 + topSafeArea)
        }
        headerView.addSubview(cancelBtn) { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
        }

        self.view.addSubview(mainScrollView) { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(stickersContainer)
        containerView.addSubview(drawingImageView)

        self.view.addSubview(bottomToolsContainerView) { make in
            make.top.equalTo(mainScrollView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        bottomToolsContainerView.addSubview(editToolCollectionView) { make in
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.centerX.equalToSuperview()
            make.width.equalTo(self.tools.count * 60 + 16)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(50)
        }
        bottomToolsContainerView.addSubview(doneBtn) { make in
            make.top.equalTo(self.editToolCollectionView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.height.equalTo(52)
        }
    }

    func setupTextSticker() {
        if tools.contains(.textSticker) {
            ZLImageEditorConfiguration.default().fontChooserContainerView?.hideBlock = { [weak self] in
                self?.fontChooserContainerIsHidden = true
            }

            ZLImageEditorConfiguration.default().fontChooserContainerView?.selectFontBlock = { [weak self] font in
                self?.showInputTextVC(font: font) { [weak self] text, font, textColor, bgColor in
                    self?.addTextStickersView(text, textColor: textColor, font: font, bgColor: bgColor)
                }
            }
        }
    }

    func setupImageSticker() {
        if tools.contains(.imageSticker) {
            ZLImageEditorConfiguration.default().imageStickerContainerView?.hideBlock = { [weak self] in
                self?.imageStickerContainerIsHidden = true
            }

            ZLImageEditorConfiguration.default().imageStickerContainerView?.selectImageBlock = { [weak self] image in
                self?.addImageStickerView(image)
            }
        }
    }

    func setupDrawToolsUI() {
        if tools.contains(.draw) {
            self.view.addSubview(self.drawColorCollectionView) { make in
                make.leading.equalToSuperview().inset(16)
                make.bottom.equalTo(self.bottomToolsContainerView.snp.top).offset(-8)
                make.height.equalTo(Constants.drawColViewH)
            }
            self.revokeRedoContainer.addSubview(self.revokeBtn) { make in
                make.leading.equalToSuperview().offset(4)
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(40)
            }
            self.revokeRedoContainer.addSubview(self.redoBtn) { make in
                make.trailing.equalToSuperview().inset(4)
                make.top.bottom.equalToSuperview()
                make.width.equalTo(40)
                make.leading.equalTo(self.revokeBtn.snp.trailing)
            }

            self.view.addSubview(self.revokeRedoContainer) { make in
                make.height.equalTo(Constants.drawColViewH)
                make.leading.equalTo(self.drawColorCollectionView.snp.trailing).offset(8)
                make.trailing.equalToSuperview().inset(16)
                make.centerY.equalTo(self.drawColorCollectionView.snp.centerY)
            }
        }
    }

    func setupFilterToolsUI() {
        if tools.contains(.filter) {
            self.view.addSubview(self.filterCollectionView) { make in
                make.horizontalEdges.equalToSuperview().inset(16)
                make.bottom.equalTo(self.bottomToolsContainerView.snp.top).offset(-8)
                make.height.equalTo(Constants.filterColViewH)
            }
        }
    }

    func setupAdjustToolsUI() {
        if tools.contains(.adjust) {
            editImage = editImage.zl.adjust(brightness: brightness, contrast: contrast, saturation: saturation) ?? editImage

            self.view.addSubview(self.adjustCollectionView) { make in
                make.centerX.equalToSuperview()
                make.horizontalEdges.greaterThanOrEqualToSuperview().inset(16)
                make.bottom.equalTo(self.bottomToolsContainerView.snp.top).offset(-8)
                make.height.equalTo(Constants.adjustColViewH)
            }

            if let selectedAdjustTool = selectedAdjustTool {
                changeAdjustTool(selectedAdjustTool)
            }

            view.addSubview(adjustSlider) { make in
                make.width.equalTo(60)
                make.height.equalTo(200)
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        }
    }

    func setupAshbinViewUI() {
        view.addSubview(ashbinView)
        ashbinView.addSubview(ashbinImgView)

        let asbinTipLabel = UILabel(
            frame: CGRect(
                x: 0,
                y: Constants.ashbinSize.height - 34,
                width: Constants.ashbinSize.width,
                height: 34
            )
        )
        asbinTipLabel.font = UIFont.systemFont(ofSize: 12)
        asbinTipLabel.textAlignment = .center
        asbinTipLabel.textColor = .white
        asbinTipLabel.text = localLanguageTextValue(.textStickerRemoveTips)
        asbinTipLabel.numberOfLines = 2
        asbinTipLabel.lineBreakMode = .byCharWrapping
        ashbinView.addSubview(asbinTipLabel)
    }

    func setupEraserToolUI() {
        if tools.contains(.eraser) {
            containerView.addSubview(maskableView) { make in
                make.edges.equalToSuperview()
            }

            self.view.addSubview(masakableControlsContainer) { make in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.bottom.equalTo(self.bottomToolsContainerView.snp.top)
                make.height.equalTo(Constants.drawColViewH)
            }

            self.masakableControlsContainer.addSubview(self.maskableSegmentControl) { make in
                make.leading.equalToSuperview().offset(16)
                make.bottom.equalToSuperview()
                make.top.equalToSuperview().offset(8)
            }
            self.masakableControlsContainer.addSubview(self.maskableRadiusSlider) { make in
                make.leading.equalTo(self.maskableSegmentControl.snp.trailing).offset(16)
                make.trailing.equalToSuperview().offset(-16)
                make.bottom.equalToSuperview()
                make.top.equalToSuperview().offset(8)
            }
        }
    }

}
