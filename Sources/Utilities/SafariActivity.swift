////
///  SafariActivity.swift
//

class SafariActivity: UIActivity {
    var url: NSURL?

    override func activityType() -> String {
        return "SafariActivity"
    }

    override func activityTitle() -> String {
        return InterfaceString.App.OpenInSafari
    }

    override func activityImage() -> UIImage? {
        return UIImage(named: "openInSafari")
    }

    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        for item in activityItems {
            if let url = item as? NSURL where UIApplication.sharedApplication().canOpenURL(url) {
                return true
            }
        }
        return false
    }

    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        for item in activityItems {
            if let url = item as? NSURL {
                self.url = url
                break
            }
        }
    }

    override func performActivity() {
        var completed = false
        if let url = url {
            completed = UIApplication.sharedApplication().openURL(url)
        }
        activityDidFinish(completed)
    }

}
