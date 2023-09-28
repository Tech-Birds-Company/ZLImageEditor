import UIKit

public protocol MagicBackgroundService {
    func removeBackground(image: UIImage) async -> UIImage
}

public protocol ZLAnalyticService {
    func logEvent(name: String)
}

public struct EditorDependency {
    public let magicBackgroundService: MagicBackgroundService?
    public let analyticService: ZLAnalyticService?

    public init(
        magicBackgroundService: MagicBackgroundService?,
        analyticService: ZLAnalyticService?
    ) {
        self.magicBackgroundService = magicBackgroundService
        self.analyticService = analyticService
    }
}
