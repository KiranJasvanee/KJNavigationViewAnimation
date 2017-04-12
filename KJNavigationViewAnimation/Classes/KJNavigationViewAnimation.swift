//
//  KJNavigationViewAnimation.swift
//  TopbarAnimation
//
//  Created by MAC241 on 12/04/17.
//  Copyright © 2017 KiranJasvanee. All rights reserved.
//

import UIKit

enum ScrollPosition {
    case none, down, up
}

// enum of minimumSpace
enum minimumSpace{
    case none, statusBar, custom
}


protocol KJNavigaitonViewScrollviewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
}

class KJNavigationViewAnimation: UIView {

    public var scrollviewMethod: KJNavigaitonViewScrollviewDelegate?
    
    // global variants
    fileprivate var heightOfNavigationView: Float = 64
    fileprivate var minimumHeightOfNavigationView: Float = 0
    
    
    // height constraint of topbar
    fileprivate var constraintHeightOfNavigationView: NSLayoutConstraint = NSLayoutConstraint()
    
    // holding count of down and up scrolling values
    fileprivate var countOfDidScrollUp: Int = 0
    fileprivate var countOfDidScrollDown: Float = 0.0
    
    // view controller instance for animation effects requred with layoutIfNeeded.
    fileprivate var viewControllerInstance: UIViewController = UIViewController()
    
    /*
     When there is really low content size to scroll down, then it won't be possible to reduce topbar and show again. So unfortunately for lower cotentsize we have only one option to don't scroll till we have enough space to scroll down with topbar animation.
     */
    // allow animation.
    fileprivate var heightOfScrollView: CGFloat = 0
    fileprivate var isAllowTopbarAnimation: Bool = true
    
    // blurr
    fileprivate var isBlurRequired: Bool = false
    fileprivate var viewBlurrOne: UIVisualEffectView = UIVisualEffectView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Implement KJTopBarScrollviewDelegate to self.
        self.scrollviewMethod = self
    }
    
    private var topbarMinimumSpacePrivate: minimumSpace = .none
    public var topbarMinimumSpace: minimumSpace {
        get{
            return self.topbarMinimumSpacePrivate
        }
        set{
            if newValue == .none {
                minimumHeightOfNavigationView = 0
                topbarMinimumSpacePrivate = .none
            }else if newValue == .statusBar {
                minimumHeightOfNavigationView = 20
                topbarMinimumSpacePrivate = .statusBar
            }else{
                minimumHeightOfNavigationView = 0
                topbarMinimumSpacePrivate = .custom
            }
        }
    }
    
    public var topbarMinimumSpaceCustomValue: Float {
        get{
            return self.topbarMinimumSpaceCustomValue
        }
        set{
            if topbarMinimumSpace == .custom {
                minimumHeightOfNavigationView = newValue
            }else{
                minimumHeightOfNavigationView = 0
            }
        }
    }
    
    public var isBlurrBackground: Bool {
        get{
            return self.isBlurrBackground
        }
        set{
            if newValue {
                isBlurRequired = true
            }else{
                isBlurRequired = false
            }
        }
    }
    
    func setupFor(Tableview tableview: UITableView, viewController: UIViewController) {
        self.initSetupMethod(bounds: tableview.bounds, viewController: viewController)
    }
    func setupFor(CollectionView collectionview: UITableView, viewController: UIViewController) {
        self.initSetupMethod(bounds: collectionview.bounds, viewController: viewController)
    }
    func setupFor(Scrollview scrollview: UIScrollView, viewController: UIViewController) {
        self.initSetupMethod(bounds: scrollview.bounds, viewController: viewController)
    }
    
    func initSetupMethod(bounds: CGRect,viewController viewControllerParam: UIViewController){
        
        // print("Top bar bounds area: \(self.bounds)")
        // print("Tableview bounds area: \(tableview.bounds)")
        heightOfScrollView = bounds.size.height // Height of tableview
        print(self.constraints)
        
        viewControllerInstance = viewControllerParam // assigning superview controller instance, so we can have animation using layoutIfNeeded.
        
        // blurr effect
        var blurreffect = UIBlurEffect()
        if #available(iOS 10.0, *) {
            let blurreffect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        } else {
            // Fallback on earlier versions
            let blurreffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        }
        viewBlurrOne = UIVisualEffectView(effect: blurreffect)
        viewBlurrOne.frame = self.bounds
        viewBlurrOne.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewBlurrOne.alpha = 0.0
        self.addSubview(viewBlurrOne)
    }
    
    
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        for constraint in self.constraints{
            
            // print("yes it does have height")
            if constraint.firstAttribute == .height {
                constraintHeightOfNavigationView = constraint               // assign height constraint to constraintHeightOfTopbar, If there is no height constraint we have to add it manually from here.
                
                heightOfNavigationView = Float(constraint.constant) // assign height constraint constant value to countOfDidScrollDown, so we can operate with it.
                countOfDidScrollDown = heightOfNavigationView
                
                
                // if height of topbar less than minimum bar, keep minimum value to 0
                if heightOfNavigationView <= minimumHeightOfNavigationView{
                    minimumHeightOfNavigationView = 0
                }
            }
        }
    }
    
    // scrollview delegates
    fileprivate var lastScrolledContentOffsetY: Float = 0.0     // holds a value of last scrolled Yth content offset
    fileprivate var enumScrollPosition: ScrollPosition = .none  // holds scrolling direction position of tableview scrollview

}


extension KJNavigationViewAnimation: KJNavigaitonViewScrollviewDelegate {
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // print("scrollview did scroll to \(scrollView.contentOffset.y)")
        
        // if scrollview content offset Yth position movin to minus indicates end of tableview at top-wise scrolling, will cancel any update on animation.
        
        // Scroll view reached to top
        if scrollView.contentOffset.y <= 0.0 {
            self.scrollToUp(scrollView)
            return
        }
        
        // Scroll view reached to bottom
        let scrollOffset = scrollView.contentOffset.y
        let scrollViewHeight = scrollView.frame.size.height
        if (scrollOffset + scrollViewHeight) >= scrollView.contentSize.height{
            return
        }
        
        
        // print("calculate end of scrollview: \(scrollOffset + scrollViewHeight)")
        
        /*
         Checked based on last holded value in - lastScrolledContentOffsetY
         */
        print("\(self.lastScrolledContentOffsetY) - \(scrollView.contentOffset.y)")
        if lastScrolledContentOffsetY <= Float(scrollView.contentOffset.y){
            self.scrollToDown(scrollView)
        }else{
            self.scrollToUp(scrollView)
        }
        lastScrolledContentOffsetY = Float(scrollView.contentOffset.y)
    }
    
    func scrollToDown(_ scrollView: UIScrollView) {
        // print("scroll down")
        // first check do we have enough scroll contentsize to scroll up.
        
        // top bar shouldn't be allowed to scroll in certain circumstances. please check this instance declaration for more information.
        guard isAllowTopbarAnimation else{
            return
        }
        
        // For down scrolling.
        countOfDidScrollDown -= 4.0
        
        UIView.animate(withDuration: 0.3, animations: {
            if self.countOfDidScrollDown >= self.minimumHeightOfNavigationView {
                self.constraintHeightOfNavigationView.constant = CGFloat(self.countOfDidScrollDown)
            }
            
            // if blurr is ON.
            if self.isBlurRequired {
                // print("blue effect in percentage: \((heightOfTopbar-countOfDidScrollDown)/100)")
                self.viewBlurrOne.alpha = CGFloat((self.heightOfNavigationView-self.countOfDidScrollDown)/100.0)
            }
            
            self.viewControllerInstance.view.layoutIfNeeded()
        })
        
        enumScrollPosition = .down // set scroll position direction
        countOfDidScrollUp = 0
    }
    func scrollToUp(_ scrollView: UIScrollView) {
        // print("scroll up")
        
        // top bar shouldn't be allowed to scroll in certain circumstances. please check this instance declaration for more information.
        guard isAllowTopbarAnimation else{
            return
        }
        
        countOfDidScrollUp += 1
        // Reason of keeping this above 2, it's when scroll up called up at least two times and more then and then only bring topbar down. Because sometimes when there are small content size to scroll down, it will produce a error of not allowing to watch few last content of scrollview.
        if countOfDidScrollUp > 1 {
            /*
             Checked based on last holded value in - lastScrolledContentOffsetY
             */
            if constraintHeightOfNavigationView.constant != CGFloat(heightOfNavigationView) {
                UIView.animate(withDuration: 0.2, animations: {
                    self.constraintHeightOfNavigationView.constant = CGFloat(self.heightOfNavigationView)
                    self.viewControllerInstance.view.layoutIfNeeded()
                    
                    // if blurr is ON.
                    if self.isBlurRequired {
                        self.viewBlurrOne.alpha = 0.0
                    }
                    
                }, completion: { (isAnimated) in
                    self.countOfDidScrollDown = self.heightOfNavigationView
                })
            }
            
            enumScrollPosition = .up // set scroll position direction
        }
    }
    
    internal func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // print("scrollview begin dragging")
        // print("content size height: \(scrollView.contentSize.height)")
        
        /*
         This will check is that we should allow topbar animation?, Do we have enough contentSize in scrollview below it's bounds to settle it with topbar.
         Ofcourse we need doble of topbar height after bounds of scrollview to go down so topbar can be animated perfectly.
         */
        let differenceBetweenContentSizeAndBounds = scrollView.contentSize.height - heightOfScrollView
        if (Float(differenceBetweenContentSizeAndBounds)) > (heightOfNavigationView + heightOfNavigationView) {
            isAllowTopbarAnimation = true
        }else{
            isAllowTopbarAnimation = false
        }
    }
    
    internal func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // print("scrollview did end dragging")
        
        // top bar shouldn't be allowed to scroll in certain circumstances. please check this instance declaration for more information.
        guard isAllowTopbarAnimation else{
            return
        }
        /*
         scrollview .isDecelerating is checking that after end dragging still scrollview auto scrolling or not.
         if it's not scrolling and height of constant still in middle of animation completion, complete it.
         
         */
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // if scrolling not contenious.
            if !scrollView.isDecelerating{
                if self.enumScrollPosition == .down {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.endYourDownScrollMethod()
                    })
                }
            }
        }
    }
    
    internal func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // print("scrollview end decelerating")
        
        // top bar shouldn't be allowed to scroll in certain circumstances. please check this instance declaration for more information.
        guard isAllowTopbarAnimation else{
            return
        }
        
        if self.enumScrollPosition == .down {
            UIView.animate(withDuration: 0.1, animations: {
                self.endYourDownScrollMethod()
            })
        }
    }
    
    /*
     If your scroll didn't end properly, scrollViewDidEndDragging and scrollViewDidEndDecelerating delegates will handle it to scroll down perfectly.
     */
    func endYourDownScrollMethod() {
        constraintHeightOfNavigationView.constant = CGFloat(minimumHeightOfNavigationView)
        countOfDidScrollDown = minimumHeightOfNavigationView
        
        // if blurr is ON.
        if isBlurRequired {
            viewBlurrOne.alpha = 1.0
        }
        
        viewControllerInstance.view.layoutIfNeeded()
    }
}

