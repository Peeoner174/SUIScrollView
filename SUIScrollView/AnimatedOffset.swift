//
//  AnimatedOffset.swift
//  SUIScrollView
//
//  Created by Pavel Kochenda on 04/06/2024.
//

import Foundation

/// Дата-класс, используемый для анимированного смещение позиции скролла
struct AnimatedOffset: Equatable {
    /// Финальная точка смещения
    let point: CGPoint
    /// Продолжительность анимации смещения в секундах
    var duration = TimeInterval(0.3)
}
