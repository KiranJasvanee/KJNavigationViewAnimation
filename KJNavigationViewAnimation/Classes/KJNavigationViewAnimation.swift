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
public enum MinimumSpace{
    case none, statusBar
    case custom(height: Float)
}


public protocol KJNavigaitonViewScrollviewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
}

public class KJNavigationViewAnimation: UIView {

    public var scrollviewMethod: KJNavigaitonViewScrollviewDelegate?
    
    
    
    fileprivate var HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION: Float = 64
    fileprivate var HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION: Float = 0

    fileprivate var constraintHeightOfNavigationView: NSLayoutConstraint = NSLayoutConstraint()     // Height constraint of custom view.
    fileprivate var viewController: UIViewController = UIViewController()                           // view controller instance for animation effects requred with layoutIfNeeded.
    
    
    
    // holding count of down and up scrolling values
    fileprivate var countOfDidScrollUp: Int = 0
    fileprivate var countOfDidScrollDown: Float = 0.0
    
    
    /*
     When there is really low content size to scroll down, then it won't be possible to reduce topbar and show again. So unfortunately for lower cotentsize we have only one option to don't scroll till we have enough space to scroll down with topbar animation.
     */
    // allow animation.
    fileprivate var HEIGHT_OF_SCROLLVIEW: CGFloat = 0
    fileprivate var isAllowTopbarAnimation: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Implement KJTopBarScrollviewDelegate to self.
        self.scrollviewMethod = self
    }
    
    
    
    
    // MARK: Public properties --------------------------------
    
    // Setup functions.
    
    public func setupFor(Tableview tableview: UITableView, viewController: UIViewController) {
        self.initSetupMethod(bounds: tableview.bounds, viewController: viewController)
    }
    public func setupFor(CollectionView collectionview: UICollectionView, viewController: UIViewController) {
        self.initSetupMethod(bounds: collectionview.bounds, viewController: viewController)
    }
    public func setupFor(Scrollview scrollview: UIScrollView, viewController: UIViewController) {
        self.initSetupMethod(bounds: scrollview.bounds, viewController: viewController)
    }
    
    
    // Minimum topbar space
    public var topbarMinimumSpace: MinimumSpace = .none {
        didSet{
            switch self.topbarMinimumSpace {
            case .none:
                HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION = 0
                break
            case .statusBar:
                HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION = 20
                break
            case .custom(let height):
                HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION = height
                break
            }
        }
    }
    
    // blurr
    fileprivate var isBlurRequired: Bool = false
    fileprivate var viewBlurrOne: UIVisualEffectView = UIVisualEffectView()
    public var isBlurrBackground: Bool = false{
        didSet{
            if self.isBlurrBackground {
                isBlurRequired = true
            }else{
                isBlurRequired = false
            }
        }
    }
    
    // Appearance/Disappearance objects
    fileprivate var instancesAffectsForDisappearance: [UIView] = [UIView]()
    public func disappearanceObjects(instances: [UIView]) {
        self.instancesAffectsForDisappearance = instances
    }
    fileprivate var instancesAffectsForAppearance: [UIView] = [UIView]()
    public func appearanceObjects(instances: [UIView]) {
        self.instancesAffectsForAppearance = instances
    }
    //----------------------------------------------------------
    

    
    
    
    func initSetupMethod(bounds: CGRect,viewController: UIViewController){
        
        // print("Top bar bounds area: \(self.bounds)")
        // print("Tableview bounds area: \(tableview.bounds)")
        HEIGHT_OF_SCROLLVIEW = bounds.size.height // Height of tableview
        // print(self.constraints)
        
        self.viewController = viewController // assigning superview controller instance, so we can have animation using layoutIfNeeded.
        
        self.addBlurr()
    }
    
    func addBlurr() {
        // blurr effect
        let blurreffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        viewBlurrOne = UIVisualEffectView(effect: blurreffect)
        viewBlurrOne.frame = self.bounds
        viewBlurrOne.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewBlurrOne.alpha = 0.0
        self.addSubview(viewBlurrOne)
    }
    
    
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override public func draw(_ rect: CGRect) {
        // Drawing code
        for constraint in self.constraints{
            
            if constraint.firstAttribute == .height {
                
                constraintHeightOfNavigationView = constraint               // assign height constraint to constraintHeightOfTopbar, If there is no height constraint we have to add it manually from here.
                
                HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION = Float(constraint.constant) // assign height constraint constant value to countOfDidScrollDown, so we can operate with it.
                countOfDidScrollDown = HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION
                
                
                // if height of topbar less than minimum bar, keep minimum value to 0
                if case let MinimumSpace.custom(height) = self.topbarMinimumSpace{
                    if HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION <= height{
                        HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION = 0
                    }
                }
            }
        }
    }
    
    // scrollview delegates
    fileprivate var lastScrolledContentOffsetY: Float = 0.0     // holds a value of last scrolled Yth content offset
    fileprivate var enumScrollPosition: ScrollPosition = .none  // holds scrolling direction position of tableview scrollview

}


extension KJNavigationViewAnimation: KJNavigaitonViewScrollviewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let scrollViewContentOffset =  scrollView.contentOffset.y
        
        
        /*
            Return -> When scrollview goes beyong top
            While scrolling, If scrollview content offset Yth position movin to minus indicates end of scrollview contentSize. Developer can stop or continue animation based on their requirement.
        */
        if scrollViewContentOffset <= 0.0 {
            self.scrollUpWayToBeforeAnimationLayout(scrollView)
            return
        }
        
        // Return -> When scrollview goes beyong bottom
        /*
                           ~~~   *---------------------------    ~~~
                            |    |                          |     |
                            |    |                          |     |
                            |    |                          |     |  Above ScrollView's ContentOffset
                            |    |                          |     |
                            |    |                          |     |
                            |    @--------------------------|    ~~~
                            |    |##########################|
                            |    |##########################|
            ScrollView's -->|    |### ScrollView's Frame ###|
            ContentSize     |    |##########################|
                            |    |##########################|
                            |    |--------------------------|    ~~~
                            |    |                          |     |
                            |    |                          |     |  Below ScrollView's ContentOffset
                            |    |                          |     |
                           ~~~   ----------------------------    ~~~
         
            @ - Origin of ScrollView.
            * - ContentOffset origin value, starting from 0.0
        */
        if (scrollViewContentOffset + scrollView.frame.size.height) >= scrollView.contentSize.height{
            return
        }
        
    
        
        /*
            Scrollview animation tie up calls.
        */
        
        if self.lastScrolledContentOffsetY <= Float(scrollViewContentOffset){
            // When scroll goes upwards, Above contentOffset value will be in incremented state, because we are moving towards lower part of contentSize scrollView
            self.scrollUpWayToAfterAnimationLayout(scrollView)
        }else{
            // When scroll goes downwards, Above contentOffset value will be in decremented state, because we are moving towards above part of contentSize scrollView
            self.scrollUpWayToBeforeAnimationLayout(scrollView)
        }
        
        lastScrolledContentOffsetY = Float(scrollView.contentOffset.y)      // Store last ContentOffset value. We are comparing this with latest one to check that scroll movin upwards or downwards.
    }
    
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        /*
         This will check is that we should allow topbar animation?, Do we have enough below contentSize of scrollview to settle in replaced of customview.
         
         So will check scrollView's ContentSize >= (Height of custom view before animation - Height of custom view after animation) + height of scrollview, that's the exact contentSize we requires to scrollUp.
        
                         ----------------------------
                         |                          |
                         |                          |
                   ~~~   |--------------------------| <----- Custom view after animation
                    |    |                          |
                    |    |                          |
                    |    |            +             |
                    |    |                          |
        ContentSize |    |                          |
        Needed to   |    |--------------------------| <----- Custom view before animation
        Scroll      |    |                          |    ~~~
                    |    |                          |     |
                    |    |                          |     |
                    |    |            +             |     | TableView (ScrollView)
                    |    |                          |     |
                    |    |                          |     |
                   ~~~   ----------------------------    ~~~
         */
        
        if (Float(scrollView.contentSize.height)) >= ((HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION - HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION) + Float(scrollView.frame.size.height)) {
            isAllowTopbarAnimation = true
        }else{
            isAllowTopbarAnimation = false
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
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
                if self.enumScrollPosition == .up {
                    UIView.animate(withDuration: 0.1, animations: {
                        self.upCustomView()
                    })
                }
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // This delegate will be called, when user reaches at the end of scrollview content size. This will up custom view up to after animation step, if it remains undone.
        
        // top bar shouldn't be allowed to scroll in certain circumstances. please check this instance declaration for more information.
        guard isAllowTopbarAnimation else{
            return
        }
        
        if self.enumScrollPosition == .up {
            UIView.animate(withDuration: 0.1, animations: {
                self.upCustomView()
            })
        }
    }
    
    
    /*
     If your scroll didn't end properly, scrollViewDidEndDragging and scrollViewDidEndDecelerating delegates will handle it to scroll down perfectly.
     */
    func upCustomView() {
        
        constraintHeightOfNavigationView.constant = CGFloat(HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION)
        countOfDidScrollDown = HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION
        
        // if blurr is ON.
        if isBlurRequired {
            viewBlurrOne.alpha = 1.0
        }
        
        self.setDisappearanceVisibilityOfAffectedByInstances()
        self.setAppearanceVisibilityOfAffectedByInstances()
        
        self.viewController.view.layoutIfNeeded()
    }
}




extension KJNavigationViewAnimation {
    
    func scrollUpWayToAfterAnimationLayout(_ scrollView: UIScrollView) {
        
        guard isAllowTopbarAnimation else{
            return
        }
        
        // Scrolling to upwards.
        countOfDidScrollDown -= 4.0
        
        UIView.animate(withDuration: 0.3, animations: {
            
            if self.countOfDidScrollDown >= self.HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION {
                self.constraintHeightOfNavigationView.constant = CGFloat(self.countOfDidScrollDown)
            }
            
            // if blurr is ON.
            if self.isBlurRequired {
                // print("blue effect in percentage: \((heightOfTopbar-countOfDidScrollDown)/100)")
                self.viewBlurrOne.alpha = CGFloat((self.HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION-self.countOfDidScrollDown)/100.0)
            }
            
            self.setDisappearanceVisibilityOfAffectedByInstances()
            self.setAppearanceVisibilityOfAffectedByInstances()
            
            self.viewController.view.layoutIfNeeded()
        })
        
        enumScrollPosition = .up // set scroll position direction
        countOfDidScrollUp = 0
    }
    func scrollUpWayToBeforeAnimationLayout(_ scrollView: UIScrollView) {
        
        guard isAllowTopbarAnimation else{
            return
        }
        
        countOfDidScrollUp += 1
        // Reason of keeping this above 2, it's when scroll up called up at least two times and more then and then only bring topbar down. Because sometimes when there are small content size to scroll down, it will produce a error of not allowing to watch few last content of scrollview.
        if countOfDidScrollUp > 1 {
            /*
             Checked based on last holded value in - lastScrolledContentOffsetY
             */
            if constraintHeightOfNavigationView.constant != CGFloat(HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION) {
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.constraintHeightOfNavigationView.constant = CGFloat(self.HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION)
                    self.viewController.view.layoutIfNeeded()
                    
                    // if blurr is ON.
                    if self.isBlurRequired {
                        self.viewBlurrOne.alpha = 0.0
                    }
                    
                    self.setDisappearanceVisibilityOfAffectedByInstances()
                    self.setAppearanceVisibilityOfAffectedByInstances()
                    
                }, completion: { (isAnimated) in
                    self.countOfDidScrollDown = self.HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION
                })
            }
            
            enumScrollPosition = .down // set scroll position direction
        }
    }
    
    func setDisappearanceVisibilityOfAffectedByInstances() {
        
        let progressUpTo = self.HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION-self.HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION
        let progressReached = Float(self.constraintHeightOfNavigationView.constant)-self.HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION
        let alphaForDisappearance = progressReached/progressUpTo
        for view in self.instancesAffectsForDisappearance {
            view.alpha = CGFloat(alphaForDisappearance)
        }
    }
    
    func setAppearanceVisibilityOfAffectedByInstances() {
        
        let progressUpTo = self.HEIGHT_OF_CUSTOMVIEW_BEFORE_ANIMATION-self.HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION
        let progressReached = Float(self.constraintHeightOfNavigationView.constant)-self.HEIGHT_OF_CUSTOMVIEW_AFTER_ANIMATION
        let alphaForAppearance = 1.0-(progressReached/progressUpTo)
        print(alphaForAppearance)
        for view in self.instancesAffectsForAppearance {
            view.alpha = CGFloat(alphaForAppearance)
        }
    }
}

