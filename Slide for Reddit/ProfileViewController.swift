//
//  SubredditsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import MaterialComponents.MaterialSnackbar

class ProfileViewController:  UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIToolbarDelegate, ColorPickerDelegate {
    var content : [UserContent] = []
    var name: String = ""
    var isReload = false
    var session: Session? = nil
    var vCs : [UIViewController] = [ClearVC()]

    


    func valueChanged(_ value: CGFloat, accent: Bool) {
            self.navigationController?.navigationBar.barTintColor = UIColor.init(cgColor: GMPalette.allCGColor()[Int(value * CGFloat(GMPalette.allCGColor().count))])
        
    }

    func pickColor(){
        let alertController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 120)
        let customView = ColorPicker(frame: rect)
        customView.delegate = self
        
        customView.backgroundColor = ColorUtil.backgroundColor
        alertController.view.addSubview(customView)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            ColorUtil.setColorForUser(name: self.name, color: (self.navigationController?.navigationBar.barTintColor)!)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            self.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForUser(name: self.name)
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        present(alertController, animated: true, completion: nil)
    }
    
    func tagUser(){
        let alertController = UIAlertController(title: "Tag /u/\(name)", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "Set", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                print("Setting tag \(field.text!)")
                ColorUtil.setTagForUser(name: self.name, tag: field.text!)
            } else {
                // user did not fill field
            }
        }
        
        if(!ColorUtil.getTagForUser(name: name).isEmpty){
        let removeAction = UIAlertAction(title: "Remove tag", style: .default) { (_) in
            ColorUtil.removeTagForUser(name: self.name)
        }
            alertController.addAction(removeAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Tag"
            textField.text = ColorUtil.getTagForUser(name: self.name)
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        alertController.modalPresentationStyle = .popover
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        self.present(alertController, animated: true, completion: nil)

    }

    init(name: String){
        self.name = name
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        if let n = (session?.token.flatMap { (token) -> String? in
            return token.name
            }) as String? {
            if(name == n){
                self.content = UserContent.cases
            } else {
                self.content = ProfileViewController.doDefault()
            }
        } else {
            self.content = ProfileViewController.doDefault()
        }
        
        for place in content {
            self.vCs.append(ContentListingViewController.init(dataSource: ProfileContributionLoader.init(name: name, whereContent: place)))
        }
        tabBar = MDCTabBar()
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func doDefault() -> [UserContent]{
        return [UserContent.overview, UserContent.comments, UserContent.submitted, UserContent.gilded]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    var moreB: UIBarButtonItem?
    var sortB: UIBarButtonItem?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        self.title = name
        navigationController?.navigationBar.tintColor = .white
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if(navigationController != nil){
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForUser(name: name)
        }
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
         sortB = UIBarButtonItem.init(customView: sort)
        
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "info")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
         moreB = UIBarButtonItem.init(customView: more)
        
        if(navigationController != nil){
            navigationItem.rightBarButtonItems = [ moreB!, sortB!]
        }
        
    }
    
    func showMenu(user: Account){
        let alrController = UIAlertController(title: user.name + "\n\n\n\n", message: "\(user.linkKarma) post karma\n\(user.commentKarma) comment karma\nRedditor for \("todo")", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 8.0
        let rect = CGRect.init(x: margin, y: margin + 23, width: alrController.view.bounds.size.width - margin * 4.0, height:75)
        let scrollView = UIScrollView(frame: rect)
        scrollView.backgroundColor = UIColor.clear
        
        //todo add trophies
        do {
            try session?.getTrophies(user.name, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let trophies):
                    var i = 0
                    DispatchQueue.main.async {
                        for trophy in trophies {
                            let b = self.generateButtons(trophy: trophy)
                            b.frame = CGRect.init(x: i * 75, y: 0, width: 70, height: 70)
                            scrollView.addSubview(b)
                            i += 1
                        }
                        scrollView.contentSize = CGSize.init(width: i * 75, height: 70)
                    }
                }
            })
        } catch {
            
        }
        scrollView.delaysContentTouches = false
        
    
        alrController.view.addSubview(scrollView)
        if(AccountController.isLoggedIn){
            alrController.addAction(UIAlertAction.init(title: "Private message", style: .default, handler: { (action) in
                //todo send
            }))
            if(user.isFriend){
                alrController.addAction(UIAlertAction.init(title: "Unfriend", style: .default, handler: { (action) in
                    do {
                        try self.session?.unfriend(user.name, completion: { (result) in
                            DispatchQueue.main.async {
                                let message = MDCSnackbarMessage()
                                message.text = "Unfriended /u/\(user.name)"
                                MDCSnackbarManager.show(message)
                            }
                        })
                    } catch {
                        
                    }
                }))
            } else {
                alrController.addAction(UIAlertAction.init(title: "Friend", style: .default, handler: { (action) in
                    do {
                        try self.session?.friend(user.name, completion: { (result) in
                            if(result.error != nil){
                                print(result.error!)
                            }
                            DispatchQueue.main.async {
                                let message = MDCSnackbarMessage()
                                message.text = "Friended /u/\(user.name)"
                                MDCSnackbarManager.show(message)
                            }
                        })
                    } catch {
                        
                    }
                }))
            }
        }
        alrController.addAction(UIAlertAction.init(title: "Change color", style: .default, handler: { (action) in
            self.pickColor()
        }))
        let tag = ColorUtil.getTagForUser(name: name)
        alrController.addAction(UIAlertAction.init(title: "Tag user\((!(tag.isEmpty)) ? " (currently \(tag))" : "")", style: .default, handler: { (action) in
            self.tagUser()
        }))
        
        alrController.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (action) in
        }))

        alrController.modalPresentationStyle = .popover
        if let presenter = alrController.popoverPresentationController {
            presenter.sourceView = (moreB!.value(forKey: "view") as! UIView)
            presenter.sourceRect = (moreB!.value(forKey: "view") as! UIView).bounds
        }

        
        self.present(alrController, animated: true, completion:{})
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.splitViewController?.maximumPrimaryColumnWidth = 375
        self.splitViewController?.preferredPrimaryColumnWidthFraction = 0.5
    }

    
    func generateButtons(trophy: Trophy) -> UIImageView {
        let more = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 70, height: 70))
        more.sd_setImage(with: trophy.icon70!)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.trophyTapped(_:)))
        singleTap.numberOfTapsRequired = 1
        
        more.isUserInteractionEnabled = true
        more.addGestureRecognizer(singleTap)
        
        return more
    }
    
    func trophyTapped(_ sender: AnyObject){
    }
    
    func close(){
        navigationController?.popViewController(animated: true)
    }
    
    var tabBar: MDCTabBar
    
    override func viewDidLoad() {
       
        view.backgroundColor = ColorUtil.backgroundColor
        var items: [String] = []
        for i in content {
            items.append(i.title)
        }
        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: -8, width: self.view.frame.size.width, height: 45))
        tabBar.backgroundColor = ColorUtil.getColorForUser(name: name)
        tabBar.itemAppearance = .titles
        // 2
        tabBar.items = content.enumerated().map { index, source in
            return UITabBarItem(title: source.title, image: nil, tag: index)
        }
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        
        // 3
        tabBar.selectedItem = tabBar.items[0]
        // 4
        tabBar.delegate = self
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: "NONE")
        // 5
        tabBar.sizeToFit()
        
        self.view.addSubview(tabBar)
        self.edgesForExtendedLayout = []
        
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        
        self.navigationController?.view.backgroundColor = UIColor.clear
        let firstViewController = vCs[1]
        
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)
    }
    
    var currentVc = UIViewController()
    
    func showSortMenu(_ sender: AnyObject){
        (self.currentVc as? SubredditLinkViewController)?.showMenu(sender)
    }
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard vCs.count > previousIndex else {
            return nil
        }
        
        return vCs[previousIndex]
    }
    

    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = vCs.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return vCs[nextIndex]
    }

    func showMenu(_ sender: AnyObject){
        do {
            try session?.getUserProfile(self.name, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let account):
                    self.showMenu(user: account)
                }
            })
        } catch {
            
        }
    }
    var selected = false
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        if(!selected){
            let page = vCs.index(of: self.viewControllers!.first!)
            tabBar.setSelectedItem(tabBar.items[page! - 1], animated: true)
        } else {
            selected = false
        }
        currentVc =  self.viewControllers!.first!
    }

}
extension ProfileViewController: MDCTabBarDelegate {
    
    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = vCs[tabBar.items.index(of: item)! + 1]
        
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        
    }
    
}
