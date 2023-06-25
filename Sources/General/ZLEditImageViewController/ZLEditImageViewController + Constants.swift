//
//  ZLEditImageViewController + Constants.swift
//  ZLImageEditor
//
//  Created by Musa on 25.06.2023.
//

import UIKit

extension ZLEditImageViewController {
    struct Constants {
        static let maxDrawLineImageWidth: CGFloat = 600

        static let shadowColorFrom = UIColor.black.withAlphaComponent(0.35).cgColor

        static let shadowColorTo = UIColor.clear.cgColor

        static let drawColViewH: CGFloat = 50

        static let filterColViewH: CGFloat = 80

        static let adjustColViewH: CGFloat = 60

        static let ashbinSize = CGSize(width: 160, height: 80)
    }
}
