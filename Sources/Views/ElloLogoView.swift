////
///  ElloLogoView.swift
//

import QuartzCore
import FLAnimatedImage
import CoreGraphics

public class ElloLogoView: UIImageView {

    public enum Config {
        case Normal
        case Grey

        var image: UIImage {
            switch self {
            case .Normal: return InterfaceImage.ElloLogo.normalImage
            case .Grey: return InterfaceImage.ElloLogoGrey.normalImage
            }
        }
    }

    struct Size {
        static let Natural = CGSize(width: 60, height: 60)
    }

    private var wasAnimating = false
    private var config: ElloLogoView.Config = .Normal

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience public init() {
        self.init(frame: .zero)
    }

    convenience public init(config: ElloLogoView.Config) {
        self.init(frame: .zero)
        self.config = config
        self.image = self.config.image
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.image = self.config.image
        self.contentMode = .ScaleAspectFit
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && wasAnimating {
            animateLogo()
        }
    }

    func animateLogo() {
        wasAnimating = true

        self.layer.removeAnimationForKey("logo-spin")
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        let angle = layer.valueForKeyPath("transform.rotation.z") as! NSNumber
        rotate.fromValue = angle
        rotate.toValue = 2 * M_PI
        rotate.duration = 0.35
        rotate.repeatCount = 1_000_000
        self.layer.addAnimation(rotate, forKey: "logo-spin")
    }

    func stopAnimatingLogo() {
        wasAnimating = false

        self.layer.removeAllAnimations()

        let endAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        if let layer = self.layer.presentationLayer() {
            let angle = layer.valueForKeyPath("transform.rotation.z") as! NSNumber
            endAnimation.fromValue = angle.floatValue
            endAnimation.toValue = 0
            endAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            endAnimation.duration = 0.25
        }
        self.layer.addAnimation(endAnimation, forKey: "logo-spin")
    }
}
