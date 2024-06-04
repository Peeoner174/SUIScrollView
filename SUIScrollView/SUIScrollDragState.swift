//
//  SUIScrollDragState.swift
//  SUIScrollView
//
//  Created by Pavel Kochenda on 04/06/2024.
//

/// Состояние жеста вертикального скролла
enum SUIScrollDragState: Equatable {
    /// Действий не произошло
    case none
    /// Событие начала жеста
    case draggingStart
    /// Событие окончания жеста
    /// `isDescending` направление по вертикали(вверх/вниз)
    case draggingEnded(isDescending: Bool)
}
