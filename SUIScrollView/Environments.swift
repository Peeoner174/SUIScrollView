//
//  Environments.swift
//  SUIScrollView
//
//  Created by Pavel Kochenda on 04/06/2024.
//

import SwiftUI

struct IsDraggingKey: EnvironmentKey {
    static let defaultValue: Binding<SUIScrollDragState> = .constant(.none)
}

struct IsRefreshingKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

struct OffsetKey: EnvironmentKey {
    static let defaultValue: Binding<CGPoint> = .constant(.zero)
}

struct AnimatedOffsetKey: EnvironmentKey {
    static let defaultValue: Binding<AnimatedOffset?> = .constant(nil)
}

struct OnRefreshActionKey: EnvironmentKey {
    static let defaultValue: SUIScrollView.OnRefreshAction? = nil
}

extension EnvironmentValues {
    var isDragging: Binding<SUIScrollDragState> {
        get { self[IsDraggingKey.self] }
        set { self[IsDraggingKey.self] = newValue }
    }
    
    var isRefreshing: Binding<Bool> {
        get { self[IsRefreshingKey.self] }
        set { self[IsRefreshingKey.self] = newValue }
    }
    
    var offset: Binding<CGPoint> {
        get { self[OffsetKey.self] }
        set { self[OffsetKey.self] = newValue }
    }
    
    var animatedOffset: Binding<AnimatedOffset?> {
        get { self[AnimatedOffsetKey.self] }
        set { self[AnimatedOffsetKey.self] = newValue }
    }

    var onRefreshAction: SUIScrollView.OnRefreshAction? {
        get { self[OnRefreshActionKey.self] }
        set { self[OnRefreshActionKey.self] = newValue }
    }
}
