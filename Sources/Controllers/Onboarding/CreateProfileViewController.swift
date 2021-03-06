////
///  CreateProfileViewController.swift
//

public class CreateProfileViewController: UIViewController, HasAppController {
    var mockScreen: CreateProfileScreenProtocol?
    var screen: CreateProfileScreenProtocol { return mockScreen ?? (self.view as! CreateProfileScreenProtocol) }
    var parentAppController: AppViewController?
    var currentUser: User?

    public var onboardingViewController: OnboardingViewController?
    public var onboardingData: OnboardingData!
    var didSetName = false
    var didSetBio = false
    var didSetLinks = false
    var linksAreValid = false
    var debouncedLinksValidator = debounce(0.5)
    var didUploadCoverImage = false
    var didUploadAvatarImage = false
    var profileIsValid: Bool {
        return (didSetName ||
            didSetBio ||
            didSetLinks ||
            didUploadCoverImage ||
            didUploadAvatarImage) && (!didSetLinks || linksAreValid)
    }

    override public func loadView() {
        let screen = CreateProfileScreen()
        screen.delegate = self
        self.view = screen
    }
}

extension CreateProfileViewController: CreateProfileDelegate {
    func presentController(controller: UIViewController) {
        presentViewController(controller, animated: true, completion: nil)
    }

    func dismissController() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func assignName(name: String?) -> ValidationState {
        onboardingData.name = name
        didSetName = (name?.isEmpty == false)
        onboardingViewController?.canGoNext = profileIsValid
        return didSetName ? .OKSmall : .None
    }

    func assignBio(bio: String?) -> ValidationState {
        onboardingData.bio = bio
        didSetBio = (bio?.isEmpty == false)
        onboardingViewController?.canGoNext = profileIsValid
        return didSetBio ? .OKSmall : .None
    }

    func assignLinks(links: String?) -> ValidationState {
        if let links = links where Validator.hasValidLinks(links) {
            onboardingData.links = links
            didSetLinks = true
            linksAreValid = true
        }
        else {
            onboardingData.links = nil
            if links == nil || links == "" {
                didSetLinks = false
            }
            else {
                didSetLinks = true
            }
            linksAreValid = false
        }
        onboardingViewController?.canGoNext = profileIsValid

        debouncedLinksValidator { [weak self] in
            guard let sself = self else { return }
            sself.screen.linksValid = sself.didSetLinks ? sself.linksAreValid : nil
        }
        return linksAreValid ? .OKSmall : .None
    }

    func assignCoverImage(image: ImageRegionData) {
        didUploadCoverImage = true
        onboardingData.coverImage = image
        onboardingViewController?.canGoNext = profileIsValid
    }
    func assignAvatar(image: ImageRegionData) {
        didUploadAvatarImage = true
        onboardingData.avatarImage = image
        onboardingViewController?.canGoNext = profileIsValid
    }
}

extension CreateProfileViewController: OnboardingStepController {
    public func onboardingStepBegin() {
        didSetName = (onboardingData.name?.isEmpty == false)
        didSetBio = (onboardingData.bio?.isEmpty == false)
        if let links = onboardingData.links {
            didSetLinks = !links.isEmpty
            linksAreValid = Validator.hasValidLinks(links)
        }
        else {
            didSetLinks = false
            linksAreValid = false
        }
        didUploadAvatarImage = (onboardingData.avatarImage != nil)
        didUploadCoverImage = (onboardingData.coverImage != nil)
        onboardingViewController?.hasAbortButton = true
        onboardingViewController?.canGoNext = profileIsValid

        screen.name = onboardingData.name
        screen.bio = onboardingData.bio
        screen.links = onboardingData.links
        screen.coverImage = onboardingData.coverImage
        screen.avatarImage = onboardingData.avatarImage
    }

    public func onboardingWillProceed(abort: Bool, proceedClosure: (success: OnboardingViewController.OnboardingProceed) -> Void) {
        var properties: [String: AnyObject] = [:]
        if let name = onboardingData.name where didSetName {
            Tracker.sharedTracker.enteredOnboardName()
            properties["name"] = name
        }

        if let bio = onboardingData.bio where didSetBio {
            Tracker.sharedTracker.enteredOnboardBio()
            properties["unsanitized_short_bio"] = bio
        }

        if let links = onboardingData.links where didSetLinks {
            Tracker.sharedTracker.enteredOnboardLinks()
            properties["external_links"] = links
        }

        let avatarImage: ImageRegionData? = didUploadAvatarImage ? onboardingData.avatarImage : nil
        if avatarImage != nil {
            Tracker.sharedTracker.uploadedOnboardAvatar()
        }

        let coverImage: ImageRegionData? = didUploadCoverImage ? onboardingData.coverImage : nil
        if coverImage != nil {
            Tracker.sharedTracker.uploadedOnboardCoverImage()
        }

        guard avatarImage != nil || coverImage != nil || !properties.isEmpty else {
            goToNextStep(abort, proceedClosure: proceedClosure)
            return
        }

        ProfileService().updateUserImages(
            avatarImage: avatarImage, coverImage: coverImage,
            properties: properties,
            success: { _avatarURL, _coverImageURL, user in
                self.parentAppController?.currentUser = user
                self.goToNextStep(abort, proceedClosure: proceedClosure) },
            failure: { error, _ in
                proceedClosure(success: .Error)
                let message: String
                if let elloError = error.elloError, messages = elloError.messages {
                    if elloError.attrs?["links"] != nil {
                        self.screen.linksValid = false
                    }
                    message = messages.joinWithSeparator("\n")
                }
                else {
                    message = InterfaceString.GenericError
                }
                let alertController = AlertViewController(error: message)
                self.parentAppController?.presentViewController(alertController, animated: true, completion: nil)
            })
    }

    func goToNextStep(abort: Bool, proceedClosure: (success: OnboardingViewController.OnboardingProceed) -> Void) {
        guard let
            presenter = onboardingViewController?.parentAppController
        where !abort else {
            proceedClosure(success: .Abort)
            return
        }

        Tracker.sharedTracker.inviteFriendsTapped()
        AddressBookController.promptForAddressBookAccess(fromController: self,
            completion: {result in
            switch result {
            case let .Success(addressBook):
                Tracker.sharedTracker.contactAccessPreferenceChanged(true)

                let vc = InviteFriendsViewController(addressBook: addressBook)
                vc.currentUser = self.currentUser
                vc.onboardingViewController = self.onboardingViewController
                self.onboardingViewController?.inviteFriendsController = vc

                proceedClosure(success: .Continue)
            case let .Failure(addressBookError):
                guard addressBookError != .Cancelled else {
                    proceedClosure(success: .Error)
                    return
                }

                Tracker.sharedTracker.contactAccessPreferenceChanged(false)
                let message = addressBookError.rawValue
                let alertController = AlertViewController(error: NSString.localizedStringWithFormat(InterfaceString.Friends.ImportErrorTemplate, message) as String)
                presenter.presentViewController(alertController, animated: true, completion: .None)
            }
        },
            cancelCompletion: {
                guard let onboardingView = self.onboardingViewController?.view else { return }
                ElloHUD.hideLoadingHudInView(onboardingView)
        })
    }
}
