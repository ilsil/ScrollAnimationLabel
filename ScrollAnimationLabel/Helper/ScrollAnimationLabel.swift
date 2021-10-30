//
//  ScrollAnimationLabel.swift
//  ScrollAnimationLabel
//
//  Created by SeokSoo on 2021/10/30.
//

import UIKit

class ScrollAnimationLabel: UILabel {
    /// 글자가 입력된 layer를 만들기 위한 라벨
    private var childLabels: [UILabel] = []
    /// 애니메이션 라벨
    private var scrollLayers: [CAScrollLayer] = []
    /// 라벨의 크기
    private var size: CGSize?
    /// 라벨에 표현된 텍스트
    var formattedText: String? {
        didSet {
            clear()
        }
    }
    /// 애니메이션 재생 시간
    var duration: TimeInterval = Constants.duration
    
    enum Constants {
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
        makeAnimation(isRepeating: isRepeating)
    }
}

private extension ScrollAnimationLabel {
    
    /// 애니메이션 관련 컴포넌트 초기화
    func clear() {
        scrollLayers.forEach {
            $0.removeAllAnimations()
            $0.removeFromSuperlayer()
        }
        scrollLayers.removeAll()
        childLabels.removeAll()
    }
    
    /// 스크롤 애니메이션 생성
    func makeAnimation(isRepeating: Bool) {
        configureAnimationLayer()
        if isRepeating {
            showRepeatingAnimation()
        } else {
            showAnimation()
        }
    }
    
    /// 부모 Label에 설정된 Text 관련 속성 정보를 바탕으로 라벨을 새로 생성
    /// - Parameter text: Label에 표현할 문자
    /// - Returns: 입력된 문자열에 맞게 크기가 셋팅된 Label
    func makeLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.sizeToFit()
        return label
    }
    
    func configureAnimationLayer() {
        guard let keywords = formattedText?.map({ String($0) }) else { return }
        var maxX:CGFloat = .zero
        var maxY:CGFloat = .zero
        for keyword in keywords {
            let keywordLabel = makeLabel(with: keyword)
            let scrollLayer = CAScrollLayer()
            scrollLayer.scrollMode = .vertically
            scrollLayer.addSublayer(keywordLabel.layer)
            layer.addSublayer(scrollLayer)
            scrollLayer.frame = .init(
                x: maxX,
                y: .zero,
                width: keywordLabel.frame.width,
                height: keywordLabel.frame.height
            )
            scrollLayers.append(scrollLayer)
            childLabels.append(keywordLabel)
            maxX += keywordLabel.frame.width
            maxY = max(maxY, keywordLabel.bounds.maxY)
        }
        size = .init(width: maxX, height: maxY)
    }
    
    private func showAnimation() {
        var offset:Double = .zero
        let maxY = Double(size?.height ?? .zero)
        for scrollLayer in scrollLayers {
            let currentDuration = duration + offset
            let animation = createAnimation(
                keyPath: "sublayerTransform.translation.y",
                fromValue: -(currentDuration*maxY/duration), // 같은 속력으로 표현될 수 있도록 늘어난 시간만큼 시작 위치 조정
                toValue: 0,
                duration: currentDuration
            )
            let fadeInAnimation = createAnimation(
                keyPath: "opacity",
                fromValue: 0.0,
                toValue: 1.0,
                duration: currentDuration
            )
            offset += Constants.interval
            scrollLayer.add(fadeInAnimation, forKey: nil)
            scrollLayer.add(animation, forKey: nil)
        }
    }
    
    private func showRepeatingAnimation() {
        var offset:Double = .zero
        let maxY = Double(size?.height ?? .zero)
        let noAnimationLayersOffset = formattedText?
            .enumerated()
            .filter ({ $0.element == ","})
            .map { $0.offset } ?? []
        for (index, scrollLayer) in scrollLayers.enumerated() {
            if noAnimationLayersOffset.contains(index) { continue }
            scrollLayer.isHidden = true
            let animation = createAnimation(
                keyPath: "sublayerTransform.translation.y",
                fromValue: -maxY,
                toValue: maxY,
                duration: Constants.repeatDuration
            )
            animation.repeatCount = .infinity
            DispatchQueue.main.asyncAfter(deadline: .now()+offset) {
                scrollLayer.isHidden = false
                scrollLayer.add(animation, forKey: nil)
            }
            offset += Constants.interval
        }
    }
    
    func createAnimation(
        keyPath: String,
        fromValue: Double,
        toValue: Double,
        duration: TimeInterval
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        return animation
    }
}
