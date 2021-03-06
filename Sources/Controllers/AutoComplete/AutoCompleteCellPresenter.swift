////
///  AutoCompleteCellPresenter.swift
//

public struct AutoCompleteCellPresenter {

    public static func configure(cell: AutoCompleteCell, item: AutoCompleteItem) {
        cell.name.font = UIFont.defaultFont()
        cell.name.textColor = UIColor.whiteColor()
        cell.line.hidden = false
        cell.line.backgroundColor = UIColor.grey3()

        if let resultName = item.result.name {
            switch item.type {
            case .Emoji:
                cell.name.text = ":\(resultName):"
            case .Username:
                cell.name.text = "@\(resultName)"
            case .Location:
                cell.name.text = resultName
            }
        }
        else {
            cell.name.text = ""
        }

        cell.selectionStyle = .None
        if let image = item.result.image {
            cell.avatar.setUserAvatar(image)
        }
        else if let url = item.result.url {
            cell.avatar.setUserAvatarURL(url)
        }
    }
}
