//
//  SUIScrollView.swift
//  SUIScrollView
//
//  Created by Pavel Kochenda on 04/06/2024.
//

import SwiftUI
import SnapKit
import os

/// SwiftUI обертка над китовым ScrollView
struct SUIScrollView<Content: View>: UIViewRepresentable {
    typealias OnRefreshAction = () -> Void
    
    // MARK: - Public properties

    /// Тип, который описывает "содержимое" ScrollView
    var content: () -> Content
    /// Возможные направления скролла
    let axes: Axis.Set
    /// Показ полос прокрутки
    let showIndicators: Bool
    
    // MARK: - Init

    /// Инициализатор включает в себя содержимое и преднастройки внешнего вида скролла
    /// - Parameter axes: Возможные направления скролла
    /// - Parameter showIndicators: Показ полос прокрутки
    /// - Parameter content: "содержимое" ScrollView
    init(
        _ axes: Axis.Set = .vertical,
        showIndicators: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axes = axes
        self.showIndicators = showIndicators
        self.content = content
    }
    
    // MARK: - UIViewRepresentable
    
    /// Конфигурирование scrollView
    /// - Parameter context: Текущий контекст вьюхи. Доступ к Coordinator, Environment, Transaction
    /// - Returns: Китовый UIScrollView, который будет использоваться под оберткой
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = createScrollView(context: context)
        configureRefreshControl(scrollView: scrollView, context: context)
        configureScrollIndicator(scrollView: scrollView)
        let hostView = addHostingController(scrollView: scrollView)
        setScrollAxisConstraints(hostView: hostView, scrollView: scrollView)
        return scrollView
    }

    /// Обновление UIView, если связанный state изменится
    /// - Parameter uiView: Китовая вьюха, используемая под SUI-оберткой
    /// - Parameter context: Текущий контекст вьюхи. Доступ к Coordinator, Environment, Transaction
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        makeAnimatedContentOffsetIfNeeded(uiView, context: context)
        updateContentIfNeeded(uiView, context: context)
    }

    /// Создаем кастомный координатор для управления делегатскими методами UIScrollView
    /// - Returns: Coordinator, который реализует методы UIScrollViewDelegate
    func makeCoordinator() -> Coordinator {
        Coordinator(
            isDragging: isDragging,
            isRefreshing: isRefreshing,
            offset: offset,
            onRefresh: onRefresh
        )
    }
    
    // MARK: - Environments

    /// Отслеживание жестов пользователя
    @Environment(\.isDragging) private var isDragging: Binding<SUIScrollDragState>
    /// Отслеживание состояния PullToRefresh
    @Environment(\.isRefreshing) private var isRefreshing: Binding<Bool>
    /// Отслеживание текущего оффсета контента
    @Environment(\.offset) private var offset: Binding<CGPoint>
    /// Запуск анимированного скролла на заданный оффсет
    @Environment(\.animatedOffset) private var animatedOffset: Binding<AnimatedOffset?>
    /// Действие на срабатывание PullToRefresh
    @Environment(\.onRefreshAction) private var onRefresh: OnRefreshAction?
    
    // MARK: - Private methods
    
    /// Создает и возвращает UIScrollView, устанавливает его делегата.
    /// - Parameter context: Контекст, содержащий координатор для связи с SwiftUI.
    /// - Returns: Настраиваемый UIScrollView.
    private func createScrollView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.scrollsToTop = false
        return scrollView
    }

    /// Конфигурирует UIRefreshControl для UIScrollView, если обработчик обновления предоставлен.
    /// - Parameters:
    ///   - scrollView: UIScrollView, к которому следует добавить UIRefreshControl.
    ///   - context: Контекст, для связывания обработчика с координатором.
    private func configureRefreshControl(scrollView: UIScrollView, context: Context) {
        guard self.onRefresh != nil else { return }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl), for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }

    // Устанавливает индикаторы прокрутки для UIScrollView в соответствии с выбранными осями.
    /// - Parameter scrollView: UIScrollView, для которого необходимо сконфигурировать индикаторы прокрутки.
    private func configureScrollIndicator(scrollView: UIScrollView) {
        scrollView.showsVerticalScrollIndicator = axes.contains(.vertical) && showIndicators
        scrollView.showsHorizontalScrollIndicator = axes.contains(.horizontal) && showIndicators
    }

    /// Добавляет UIHostingController с SwiftUI view в UIScrollView и настраивает бэкграунд.
    /// - Parameter scrollView: UIScrollView, в который необходимо добавить UIHostingController.
    /// - Returns: Возвращает view UIHostingController'a, добавленного в UIScrollView.
    private func addHostingController(scrollView: UIScrollView) -> UIView {
        let hostingController = UIHostingController(rootView: self.content())
        hostingController.view.backgroundColor = .clear
        scrollView.addSubview(hostingController.view)
        return hostingController.view
    }

    /// Настраивает ограничения для view, содержащегося в UIScrollView, в соответствии с выбранными осями прокрутки.
    /// - Parameters:
    ///   - hostView: View которое содержит SwiftUI content и отображается в UIScrollView.
    ///   - scrollView: UIScrollView, в который добавлена view.
    private func setScrollAxisConstraints(hostView: UIView, scrollView: UIScrollView) {
        switch axes {
        case .vertical:
            hostView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.width.equalTo(scrollView)
            }
        case .horizontal:
            hostView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(scrollView)
            }
        default:
            hostView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    /// Обновление содержимого(content) scrollView, если это необходимо
    /// - Parameters:
    ///   - uiView: актуальный scrollView
    ///   - context: переданный context вьюхи
    private func updateContentIfNeeded(_ uiView: UIScrollView, context: Context) {
        guard
            let animatedOffset = animatedOffset.wrappedValue,
            context.coordinator.needsUpdate else
        { return }

        DispatchQueue.main.async {
            // Удаляем старый контент перед установкой нового
            uiView.removeFromSuperview()

            // Добавляем UIHostingController с обновленным контентом в UIScrollView
            let hostView = addHostingController(scrollView: uiView)

            // Настраиваем ограничения для hostView, основанные на оси скролла
            setScrollAxisConstraints(hostView: hostView, scrollView: uiView)

            // Сброс флага обновления контента
            context.coordinator.needsUpdate = false
        }
    }
    
    /// Анимированный скролл к актуальному значению `animatedOffset`, если это необходимо
    /// - Parameters:
    ///   - uiView: актуальный scrollView
    ///   - context: переданный context вьюхи
    private func makeAnimatedContentOffsetIfNeeded(_ uiView: UIScrollView, context: Context) {
        guard  let animatedOffset = animatedOffset.wrappedValue else { return }

        UIView.animate(withDuration: animatedOffset.duration) {
            uiView.setContentOffset(animatedOffset.point, animated: false)
        } completion: { _ in
            self.animatedOffset.wrappedValue = nil
            context.coordinator.needsUpdate = true
        }
    }
}

// MARK: - SUI Coordinator

extension SUIScrollView {
    /// Координатор отслеживает состояние прокрутки
    final class Coordinator: NSObject, UIScrollViewDelegate {
        /// Состояние оффсета на начало жеста, позволяет определить направление жеста
        private var onStartDraggingOffset = CGPoint.zero
        /// Флаговое свойство, которое говорит о необходимости обновить содержимое
        var needsUpdate = false
        /// Жесты пользователя
        var isDragging: Binding<SUIScrollDragState>
        /// Состояние PullToRefresh
        var isRefreshing: Binding<Bool>
        /// Текущий оффсет
        var offset: Binding<CGPoint>
        /// Действие на срабатывание PullToRefresh
        var onRefresh: OnRefreshAction?
        
        private var snapshotWindow: UIWindow?

        init(
            isDragging: Binding<SUIScrollDragState>,
            isRefreshing: Binding<Bool>,
            offset: Binding<CGPoint>,
            onRefresh: OnRefreshAction?
        ) {
            self.isDragging = isDragging
            self.isRefreshing = isRefreshing
            self.offset = offset
            self.onRefresh = onRefresh
        }

        // MARK: - Методы UIScrollViewDelegate

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            let onEndDraggingOffset = scrollView.contentOffset

            let isDescending = onEndDraggingOffset.y > onStartDraggingOffset.y
            isDragging.wrappedValue = .draggingEnded(isDescending: isDescending)
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isDragging.wrappedValue = .draggingStart
            onStartDraggingOffset = scrollView.contentOffset
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.offset.wrappedValue = scrollView.contentOffset
            }
        }

        @objc func handleRefreshControl(sender: UIRefreshControl) {
            isRefreshing.wrappedValue = true
            onRefresh?()
            sender.endRefreshing()
        }
    }
}
