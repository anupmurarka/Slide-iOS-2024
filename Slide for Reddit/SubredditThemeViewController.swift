//
//  SubredditThemeViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/20/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import MKColorPicker
import reddift
import UIKit

class SubredditThemeViewController: UITableViewController, ColorPickerViewDelegate {

    var subs: [String] = []
    var accentChosen: UIColor?
    var colorChosen: UIColor?
    var chosenButtons = [UIBarButtonItem]()
    var regularButtons = [UIBarButtonItem]()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.isLightTheme && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none

        self.tableView.register(SubredditCellView.classForCoder(), forCellReuseIdentifier: "sub")
        self.tableView.isEditing = true
        self.tableView.backgroundColor = UIColor.backgroundColor
        self.tableView.allowsSelectionDuringEditing = true
        self.tableView.allowsMultipleSelectionDuringEditing = true
        subs = Subscriptions.subreddits
        
        self.subs = self.subs.sorted {
            if UserDefaults.standard.colorForKey(key: "color+" + $0) != nil && UserDefaults.standard.colorForKey(key: "color+" + $1) == nil {
                return true
            } else {
                return $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
            }
        }

        tableView.reloadData()

        self.title = "Subreddit themes"

        let sync = UIButton.init(type: .custom)
        sync.setImage(UIImage(sfString: SFSymbol.arrow2Circlepath, overrideString: "sync")!.navIcon(), for: UIControl.State.normal)
        sync.addTarget(self, action: #selector(self.sync(_:)), for: UIControl.Event.touchUpInside)
        sync.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)

        let add = UIButton.init(type: .custom)
        add.setImage(UIImage(named: "palette")!.navIcon(), for: UIControl.State.normal)
        add.addTarget(self, action: #selector(self.add(_:)), for: UIControl.Event.touchUpInside)
        add.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let addB = UIBarButtonItem.init(customView: add)

        let delete = UIButton.init(type: .custom)
        delete.setImage(UIImage(named: "nocolors")!.navIcon(), for: UIControl.State.normal)
        delete.addTarget(self, action: #selector(self.remove(_:)), for: UIControl.Event.touchUpInside)
        delete.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let deleteB = UIBarButtonItem.init(customView: delete)

        let all = UIButton.init(type: .custom)
        all.setImage(UIImage(named: "selectall")!.navIcon(), for: UIControl.State.normal)
        all.addTarget(self, action: #selector(self.all(_:)), for: UIControl.Event.touchUpInside)
        all.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let allB = UIBarButtonItem.init(customView: all)

        regularButtons = [allB]
        chosenButtons = [deleteB, addB]
        
        self.navigationItem.rightBarButtonItems = regularButtons
        
        self.tableView.tableFooterView = UIView()
    }

    @objc public func all(_ selector: AnyObject) {
        for row in 0..<subs.count {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
        self.navigationItem.setRightBarButtonItems(chosenButtons, animated: true)
    }
    
    @objc public func add(_ selector: AnyObject) {
        var selected: [String] = []
        if tableView.indexPathsForSelectedRows != nil {
            for i in tableView.indexPathsForSelectedRows! {
                selected.append(subs[i.row])
            }
            self.edit(selected, sender: selector as! UIButton)
        }
    }

    @objc public func remove(_ selector: AnyObject) {
        if tableView.indexPathsForSelectedRows != nil {
            for i in tableView.indexPathsForSelectedRows! {
                doDelete(subs[i.row])
            }
            self.subs = self.subs.sorted {
                if UserDefaults.standard.colorForKey(key: "color+" + $0) != nil && UserDefaults.standard.colorForKey(key: "color+" + $1) == nil {
                    return true
                } else {
                    return $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                }
            }
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItems = regularButtons
        }
    }

    public static var changed = false

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    var alertController: UIAlertController?
    var count = 0

    @objc func sync(_ selector: AnyObject) { // TODO - Is this really needed anymore? We do it by default now
        let defaults = UserDefaults.standard
        alertController = UIAlertController(title: "Syncing colors...\n\n\n", message: nil, preferredStyle: .alert)

        let spinnerIndicator = UIActivityIndicatorView(style: .large)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.fontColor
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)

        var toReturn: [String] = []
        defaults.set(true, forKey: "sc" + AccountController.currentName)
        defaults.synchronize()
        do {
            if !AccountController.isLoggedIn {
                try (UIApplication.shared.delegate as! AppDelegate).session!.getSubreddit(.default, paginator: Paginator(), completion: { (result) in
                    switch result {
                    case .failure:
                        slideLog(result.error!)
                    case .success(let listing):
                        let subs = listing.children.compactMap({ $0 as? Subreddit })
                        for sub in subs {
                            if sub.keyColor.hexString() != "#FFFFFF" {
                                toReturn.append(sub.displayName)
                                let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                                if UserDefaults.standard.colorForKey(key: "color+" + sub.displayName) == nil && color != .black {
                                    defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                    self.count += 1
                                }
                            }
                        }

                    }
                    DispatchQueue.main.async(execute: { () in
                        self.complete()
                    })
                })

            } else {
                Subscriptions.getSubscriptionsFully(session: (UIApplication.shared.delegate as! AppDelegate).session!, completion: { (subs, multis) in
                    for sub in subs {
                        if sub.keyColor.hexString() != "#FFFFFF" {
                            toReturn.append(sub.displayName)
                            let color = ColorUtil.getClosestColor(hex: sub.keyColor.hexString())
                            if UserDefaults.standard.colorForKey(key: "color+" + sub.displayName) == nil && color.hexString() != "#000000" {
                                defaults.setColor(color: color, forKey: "color+" + sub.displayName)
                                self.count += 1
                            }
                        }
                    }
                    for m in multis {
                        toReturn.append("/m/" + m.displayName)
                        let color = (UIColor.init(hexString: m.keyColor))
                        if UserDefaults.standard.colorForKey(key: "color+" + m.displayName) == nil && color.hexString() != "#000000" {
                            defaults.setColor(color: color, forKey: "color+" + m.displayName)
                            self.count += 1
                        }
                    }

                    toReturn = toReturn.sorted {
                        $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                    }
                    toReturn.insert("all", at: 0)
                    toReturn.insert("frontpage", at: 0)
                    DispatchQueue.main.async(execute: { () in
                        self.complete()
                    })
                })
            }
        } catch {
            slideLog(error)
            self.complete()
        }

    }

    func complete() {
        alertController!.dismiss(animated: true, completion: nil)
        BannerUtil.makeBanner(text: "\(count) subs colored", seconds: 5, context: self)
        count = 0
        self.subs = self.subs.sorted {
            if UserDefaults.standard.colorForKey(key: "color+" + $0) != nil && UserDefaults.standard.colorForKey(key: "color+" + $1) == nil {
                return true
            } else {
                return $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
            }
        }
        tableView.reloadData()
    }

    // MARK: – Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = subs[indexPath.row]
        var cell: SubredditCellView?
        let c = tableView.dequeueReusableCell(withIdentifier: "sub", for: indexPath) as! SubredditCellView
        c.setSubreddit(subreddit: thing, nav: nil)
        cell = c
        cell?.backgroundColor = UIColor.foregroundColor
        cell?.sideView.isHidden = UserDefaults.standard.colorForKey(key: "color+" + thing) == nil
        return cell!
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    var savedView = UIView()
    var selected = false
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !selected {
            self.navigationItem.setRightBarButtonItems(chosenButtons, animated: true)
            selected = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.indexPathsForSelectedRows == nil || tableView.indexPathsForSelectedRows!.isEmpty {
            selected = false
            self.navigationItem.setRightBarButtonItems(regularButtons, animated: true)
        }
    }

    var editSubs: [String] = []

    public func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        if isAccent {
            accentChosen = colorPickerView.colors[indexPath.row]
        } else {
            colorChosen = colorPickerView.colors[indexPath.row]
        }
    }

    func edit(_ sub: [String], sender: UIButton) {
        editSubs = sub
        
        if #available(iOS 14, *) {
            let vc = SubredditThemeEditViewController(subreddit: editSubs.count == 1 ? editSubs.first! : "Multiple subreddits", delegate: self)
            VCPresenter.presentModally(viewController: vc, self, CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: 300))
        } else {
            let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

            isAccent = false
            let margin: CGFloat = 10.0
            let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0 : alertController.view.bounds.size.width - margin * 4.0, height: 150)
            let MKColorPicker = ColorPickerView.init(frame: rect)
            MKColorPicker.delegate = self
            MKColorPicker.colors = GMPalette.allColor()
            MKColorPicker.selectionStyle = .check
            MKColorPicker.scrollDirection = .vertical

            MKColorPicker.style = .circle

            alertController.view.addSubview(MKColorPicker)

            alertController.addAction(image: UIImage(named: "colors"), title: "Accent color", color: ColorUtil.baseAccent, style: .default) { _ in
                if self.colorChosen != nil {
                    for sub in self.editSubs {
                        ColorUtil.setColorForSub(sub: sub, color: self.colorChosen!)
                    }
                }
                self.pickAccent(sub, sender: sender)
            }

            alertController.addAction(image: nil, title: "Save", color: ColorUtil.baseAccent, style: .default) { _ in
                if self.colorChosen != nil {
                    for sub in self.editSubs {
                        ColorUtil.setColorForSub(sub: sub, color: self.colorChosen!)
                    }
                }
                self.tableView.reloadData()
                self.navigationItem.rightBarButtonItems = self.regularButtons
            }

            alertController.addCancelButton()
            alertController.modalPresentationStyle = .popover
            if let presenter = alertController.popoverPresentationController {
                presenter.sourceView = savedView
                presenter.sourceRect = savedView.bounds
            }

            present(alertController, animated: true, completion: nil)
        }
    }

    var isAccent = false
    func pickAccent(_ sub: [String], sender: UIButton) {
        isAccent = true
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: UIScreen.main.traitCollection.userInterfaceIdiom == .pad ? 314 - margin * 4.0 : alertController.view.bounds.size.width - margin * 4.0, height: 150)
        let MKColorPicker = ColorPickerView.init(frame: rect)
        MKColorPicker.delegate = self
        MKColorPicker.colors = GMPalette.allColorAccent()
        MKColorPicker.selectionStyle = .check
        self.isAccent = true
        MKColorPicker.scrollDirection = .vertical

        MKColorPicker.style = .circle

        alertController.view.addSubview(MKColorPicker)

        alertController.addAction(image: UIImage(named: "palette"), title: "Primary color", color: ColorUtil.baseAccent, style: .default) { _ in
            if self.accentChosen != nil {
                for sub in self.editSubs {
                    ColorUtil.setAccentColorForSub(sub: sub, color: self.accentChosen!)
                }
            }
            self.edit(sub, sender: sender)
            self.tableView.reloadData()
        }

        alertController.addAction(image: nil, title: "Save", color: ColorUtil.baseAccent, style: .default) { _ in
            if self.accentChosen != nil {
                for sub in self.editSubs {
                    ColorUtil.setAccentColorForSub(sub: sub, color: self.accentChosen!)
                }
            }
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItems = self.regularButtons
        }

        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = savedView
            presenter.sourceRect = savedView.bounds
        }

        alertController.addCancelButton()

        present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.foregroundColor
    }

    func doDelete(_ sub: String) {
        UserDefaults.standard.removeObject(forKey: "color+" + sub)
        UserDefaults.standard.removeObject(forKey: "accent+" + sub)
        UserDefaults.standard.synchronize()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            doDelete(subs[indexPath.row])
        }
    }

}

extension SubredditThemeViewController: SubredditThemeEditViewControllerDelegate {
    func didClear() -> Bool {
        for sub in self.editSubs {
            UserDefaults.standard.removeObject(forKey: "color+" + sub)
            UserDefaults.standard.removeObject(forKey: "accent+" + sub)
            UserDefaults.standard.synchronize()
        }
        return true
    }
    
    func didChangeColors(_ isAccent: Bool, color: UIColor) {
        if isAccent {
            for sub in self.editSubs {
                ColorUtil.setAccentColorForSub(sub: sub, color: color)
            }
        } else {
            for sub in self.editSubs {
                ColorUtil.setColorForSub(sub: sub, color: color)
            }
        }
        self.tableView.reloadData()
    }
}
