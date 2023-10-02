import UIKit
import SnapKit

final class ZLActivityIndicatorView: UIView {

    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white.withAlphaComponent(0.8)
        layer.cornerRadius = 12
        isHidden = true

        addSubview(activityIndicator) { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        isHidden = false
        activityIndicator.startAnimating()
    }

    func stopAnimating() {
        activityIndicator.stopAnimating()
        isHidden = true
    }
}
