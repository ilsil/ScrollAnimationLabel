//
//  ScrollAnimationLabel.swift
//  ScrollAnimationLabel
//
//  Created by SeokSoo on 2021/10/30.
//

import UIKit

class ScrollAnimationLabel: UILabel {
    /// 각 문자별 스크롤 애니메이션을 위한 Layer 리스트
    private var scrollLayers: [CAScrollLayer] = []
    /// 각 문자를 표현하고 있는 Layer
    private var textLayers: [CATextLayer] = []
    /// 라벨의 크기
    private var size: CGSize?
    /// 스크롤 애니메이션 반복 여부
    private var isRepeating: Bool = false
    
    /// 라벨에 표현된 텍스트
    var formattedText: String? {
        didSet {
            clear()
        }
    }
    /// 애니메이션 재생 시간
    var duration: TimeInterval = Constants.duration
    
    enum Constants {
        static var moveDownDuration = 0.5
        static var duration = 0.25
        static var repeatDuration = 0.4
        static var interval = 0.1
    }
    
    override var intrinsicContentSize: CGSize {
        return size ?? .zero
    }
    
    func animate(withAmount amount: Int, isRepeating: Bool = false) {
        clear()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        self.formattedText = numberFormatter.string(for: amount)
        self.isRepeating = isRepeating
        makeAnimation()
    }
}

private extension ScrollAnimationLabel {
    
    /// 애니메이션 관련 컴포넌트 초기화
    func clear() {
        isRepeating = false
        scrollLayers.forEach {
            $0.removeAllAnimations()
            $0.removeFromSuperlayer()
        }
        scrollLayers.removeAll()
    }
    
    /// 스크롤 애니메이션 생성
    func makeAnimation() {
        configureAnimationLayer()
        if isRepeating {
            repeatAnimation()
        } else {
            makeFadeInAnimation()
        }
    }
    
    /// 문자를 보여주기 위한 TextLayer생성
    /// - Parameter text: 화면에 표현될 문자
    /// - Returns: 문자를 표현한 TextLayer
    func makeTextLayer(with text: String) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.foregroundColor = textColor.cgColor
        textLayer.alignmentMode = .center
        let size = textLayer.preferredFrameSize()
        textLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height
        )
        return textLayer
    }
    
    func configureAnimationLayer() {
        guard let keywords = formattedText?.map({ String($0) }) else { return }
        var maxX:CGFloat = .zero
        var maxY:CGFloat = .zero
        for keyword in keywords {
            let scrollLayer = CAScrollLayer()
            let textLayer = makeTextLayer(with: keyword)
            
            ///CALayer 속성 중 성능 향상에 도움이 되는 2가지
            /// 1. shouldRasterize[Default - false] : CALayer를 그릴 때 한 번만 렌더링 할 건지에 대한 여부
            /// 2. drawsAsynchronously[Default - false] : CALayer를 그릴 때 필요한 작업을 Background Thread에서 수행해야하는지 여부
            /// 두 속성이 상반되는 옵션인 듯.. 정적으로 한번만 그려도 되는 layer는 shouldRasterize를 사용
            /// 반복 애니메이션 같이 여러번 그릴 때는 drawsAsynchronously 를 사용
            scrollLayer.drawsAsynchronously = true
            
            scrollLayer.frame = .init(
                x: maxX,
                y: .zero,
                width: textLayer.frame.width,
                height: textLayer.frame.height
            )
            scrollLayer.addSublayer(textLayer)
            scrollLayers.append(scrollLayer)
            layer.addSublayer(scrollLayer)
            maxX += textLayer.frame.width
            maxY = max(maxY, textLayer.bounds.maxY)
        }
        size = .init(width: maxX, height: maxY)
    }
    
    func showAnimation() {
        var offset:Double = .zero
        let maxY = Double(size?.height ?? .zero)
        for scrollLayer in scrollLayers {
            let groupAnimation = CAAnimationGroup()
            let currentDuration = duration + offset
            let animation = createAnimation(
                keyPath: "sublayerTransform.translation.y",
                fromValue: -(currentDuration*maxY/duration), // 같은 속력으로 표현될 수 있도록 늘어난 시간만큼 시작 위치 조정
                toValue: 0
            )
            let fadeInAnimation = createAnimation(
                keyPath: "opacity",
                fromValue: 0.0,
                toValue: 1.0
            )
            fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            groupAnimation.animations = [animation, fadeInAnimation]
            groupAnimation.duration = currentDuration
            
            offset += Constants.interval
            scrollLayer.add(groupAnimation, forKey: nil)
        }
    }
    
    func repeatAnimation() {
        CATransaction.begin()
        makeFadeOutAnimation()
        CATransaction.setCompletionBlock { [weak self] in
            self?.makeFadeInAnimation()
        }
        CATransaction.commit()
    }
    
    /// CABaseAnimation 생성
    func createAnimation(
        keyPath: String,
        fromValue: Double,
        toValue: Double
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        return animation
    }
    
    func makeFadeInAnimation() {
        var offset:Double = .zero
        let maxY = Double(size?.height ?? .zero)
        for (index, scrollLayer) in self.scrollLayers.enumerated() {
            let groupAnimation = CAAnimationGroup()
            let currentDuration = self.duration + offset
            let animation = self.createAnimation(
                keyPath: "sublayerTransform.translation.y",
                fromValue: -(currentDuration*maxY/self.duration), // 같은 속력으로 표현될 수 있도록 늘어난 시간만큼 시작 위치 조정
                toValue: 0
            )
            let fadeInAnimation = self.createAnimation(
                keyPath: "opacity",
                fromValue: 0.0,
                toValue: 1.0
            )
            fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            groupAnimation.animations = [animation, fadeInAnimation]
            groupAnimation.duration = currentDuration
            groupAnimation.fillMode = .forwards
            groupAnimation.isRemovedOnCompletion = false
            offset += Constants.interval

            if isRepeating && index == (self.scrollLayers.count-1) {
                groupAnimation.delegate = self
            }
            scrollLayer.add(groupAnimation, forKey: nil)
        }
    }
    
    func makeFadeOutAnimation() {
        let maxY = Double(size?.height ?? .zero)
        let downAnimationGroup = CAAnimationGroup()
        let moveDownAnimation = createAnimation(
            keyPath: "sublayerTransform.translation.y",
            fromValue: 0,
            toValue: maxY
        )
        let fadeOutAnimation = createAnimation(
            keyPath: "opacity",
            fromValue: 1,
            toValue: 0
        )
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        downAnimationGroup.animations = [moveDownAnimation, fadeOutAnimation]
        downAnimationGroup.duration = Constants.moveDownDuration
        downAnimationGroup.fillMode = .forwards
        downAnimationGroup.isRemovedOnCompletion = false
        for scrollLayer in scrollLayers {
            scrollLayer.add(downAnimationGroup, forKey: nil)
        }
    }
}


extension ScrollAnimationLabel: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if isRepeating && flag {
            repeatAnimation()
        }
    }
}
