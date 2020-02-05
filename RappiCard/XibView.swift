//
//  XibView.swift
//  Olimpica
//
//  Created by Rene De Valery on 3/2/16.
//  Copyright © 2017 Grability. All rights reserved.
//

import UIKit

open class XibView: UIView {
    
    open var view: UIView?
    open var xibName: String?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupXib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupXib()
    }
    
    open func setupXib() {
        guard self.view == nil, let mainView = loadViewFromNib() else { return }
        
        translatesAutoresizingMaskIntoConstraints = false
        mainView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainView)
        addConstraintsToFit(view: mainView)
        
        view = mainView
    }
    
    open func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: className(), bundle: Bundle(for: type(of: self)))
        let view = nib.instantiate(withOwner: self, options: nil).compactMap { $0 as? UIView}.first
        return view
    }
    
    open func className() -> String {
        if let xibName = xibName {
            return xibName
        } else {
            return String(describing: type(of: self))
        }
    }
    
    override open func removeFromSuperview() {
        view?.removeFromSuperview()

        super.removeFromSuperview()
    }
    
    func addConstraintsToFit(view: UIView) {
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                                 options: NSLayoutConstraint.FormatOptions(),
                                                                                 metrics: nil,
                                                                                 views: ["view": view])
        addConstraints(verticalConstraints)
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                                   options: NSLayoutConstraint.FormatOptions(),
                                                                                   metrics: nil,
                                                                                   views: ["view": view])
        addConstraints(horizontalConstraints)
    }
}
