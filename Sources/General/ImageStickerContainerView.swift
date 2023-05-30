import UIKit

public class ImageStickerContainerView: UIView, ZLImageStickerContainerDelegate {

    static let baseViewH: CGFloat = 400

    var baseView: UIView!

    var collectionView: UICollectionView!

    public var selectImageBlock: ((UIImage) -> Void)?

    public var hideBlock: (() -> Void)?

    let datas = (1...18).map { "imageSticker\($0)" }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.frame.width, height: ImageStickerContainerView.baseViewH), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 8, height: 8))
        self.baseView.layer.mask = nil
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        self.baseView.layer.mask = maskLayer
    }

    func setupUI() {
        self.baseView = UIView()
        self.addSubview(self.baseView)
        self.baseView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.baseView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.baseView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.baseView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: ImageStickerContainerView.baseViewH),
            self.baseView.heightAnchor.constraint(equalToConstant: ImageStickerContainerView.baseViewH)
        ])

        let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.baseView.addSubview(visualView)
        visualView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualView.topAnchor.constraint(equalTo: self.baseView.topAnchor),
            visualView.leftAnchor.constraint(equalTo: self.baseView.leftAnchor),
            visualView.rightAnchor.constraint(equalTo: self.baseView.rightAnchor),
            visualView.bottomAnchor.constraint(equalTo: self.baseView.bottomAnchor)
        ])

        let toolView = UIView()
        toolView.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        self.baseView.addSubview(toolView)
        toolView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolView.topAnchor.constraint(equalTo: self.baseView.topAnchor),
            toolView.leftAnchor.constraint(equalTo: self.baseView.leftAnchor),
            toolView.rightAnchor.constraint(equalTo: self.baseView.rightAnchor),
            toolView.heightAnchor.constraint(equalToConstant: 50)
        ])

        let hideBtn = UIButton(type: .custom)
        hideBtn.setImage(UIImage(named: "close"), for: .normal)
        hideBtn.backgroundColor = .clear
        hideBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        hideBtn.addTarget(self, action: #selector(hideBtnClick), for: .touchUpInside)
        toolView.addSubview(hideBtn)
        hideBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hideBtn.centerYAnchor.constraint(equalTo: toolView.centerYAnchor),
            hideBtn.rightAnchor.constraint(equalTo: toolView.rightAnchor, constant: -20),
            hideBtn.widthAnchor.constraint(equalToConstant: 40),
            hideBtn.heightAnchor.constraint(equalToConstant: 40)
        ])

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.baseView.addSubview(self.collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: toolView.bottomAnchor),
            self.collectionView.leftAnchor.constraint(equalTo: self.baseView.leftAnchor),
            self.collectionView.rightAnchor.constraint(equalTo: self.baseView.rightAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.baseView.bottomAnchor)
        ])

        self.collectionView.register(ImageStickerCell.self, forCellWithReuseIdentifier: ImageStickerCell.reuseIdentifier)

        let tap = UITapGestureRecognizer(target: self, action: #selector(hideBtnClick))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }

    @objc func hideBtnClick() {
        self.hide()
    }

    public func show(in view: UIView) {
        if self.superview !== view {
            self.removeFromSuperview()

            view.addSubview(self)
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.topAnchor.constraint(equalTo: view.topAnchor),
                self.leftAnchor.constraint(equalTo: view.leftAnchor),
                self.rightAnchor.constraint(equalTo: view.rightAnchor),
                self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            view.layoutIfNeeded()
        }

        self.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.baseView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            view.layoutIfNeeded()
        }
    }

    func hide() {
        self.hideBlock?()
        UIView.animate(withDuration: 0.25) {
            self.baseView.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: ImageStickerContainerView.baseViewH
            ).isActive = true
            self.superview?.layoutIfNeeded()
        } completion: { (_) in
            self.isHidden = true
        }
    }

}


extension ImageStickerContainerView: UIGestureRecognizerDelegate {

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        return !self.baseView.frame.contains(location)
    }

}


extension ImageStickerContainerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let column: CGFloat = 4
        let spacing: CGFloat = 20 + 5 * (column - 1)
        let w = (collectionView.frame.width - spacing) / column
        return CGSize(width: w, height: w)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int)
    -> Int {
        self.datas.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageStickerCell.reuseIdentifier, for: indexPath) as! ImageStickerCell

        cell.imageView.image = UIImage(named: self.datas[indexPath.row])

        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let image = UIImage(named: self.datas[indexPath.row]) else {
            return
        }
        self.selectImageBlock?(image)
        self.hide()
    }

}


class ImageStickerCell: UICollectionViewCell {

    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }

    var imageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
