//
//  ViewController.swift
//  ScrollAnimationLabel
//
//  Created by SeokSoo on 2021/10/30.
//

import UIKit

class ViewController: UIViewController {
    var animationLabel: ScrollAnimationLabel = {
        let label = ScrollAnimationLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(animationLabel)
        
        animationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 200).isActive = true
        animationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        animationLabel.animate(withAmount: 71691203824789124, isRepeating: true)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(finishAnimation))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func finishAnimation() {
        animationLabel.animate(withAmount: 51281389)
    }
}

