import UIKit

public protocol MagicBackgroundService {
    func removeBackground(image: UIImage) async -> UIImage
}

public struct EditorDependency {
    public let magicBackgroundService: MagicBackgroundService?

    public init(magicBackgroundService: MagicBackgroundService?) {
        self.magicBackgroundService = magicBackgroundService
    }
}
