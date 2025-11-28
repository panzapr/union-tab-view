//
//  GlassTabBar.swift
//  UnionTabView
//
//  Created by Union St on 11/28/25.
//

import SwiftUI
import UIKit

/// A protocol for tab items that provide icon symbols and can be iterated.
///
/// Conform your tab enum to this protocol when using `AdaptiveTabBar`, `GlassTabBar`, or related components
/// that need to iterate over all tabs and display icons.
///
/// ```swift
/// enum MyTab: String, CaseIterable, TabItem {
///     case home = "Home"
///     case settings = "Settings"
///
///     var symbol: String {
///         switch self {
///         case .home: "house.fill"
///         case .settings: "gearshape.fill"
///         }
///     }
///
///     var actionSymbol: String {
///         switch self {
///         case .home: "house"
///         case .settings: "gearshape"
///         }
///     }
/// }
/// ```
public protocol TabItem: Hashable, CaseIterable, RawRepresentable where RawValue == String, AllCases: RandomAccessCollection {
    /// The SF Symbol name for the selected state (typically filled variant).
    var symbol: String { get }
    /// The SF Symbol name for the unselected state (typically outline variant).
    var actionSymbol: String { get }
    /// The zero-based index of this tab in the `allCases` collection.
    var index: Int { get }
}

public extension TabItem {
    var index: Int {
        Self.allCases.firstIndex(of: self).map { Self.allCases.distance(from: Self.allCases.startIndex, to: $0) } ?? 0
    }
}

/// A sample tab enum demonstrating `TabItem` conformance.
public enum CustomTab: String, CaseIterable, TabItem, Sendable {
    case home = "Home"
    case notifications = "Notifications"
    case settings = "Settings"

    public var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .notifications: return "bell.fill"
        case .settings: return "gearshape.fill"
        }
    }

    public var actionSymbol: String {
        switch self {
        case .home: return "house"
        case .notifications: return "bell"
        case .settings: return "gearshape"
        }
    }
}

/// A UIKit segmented control wrapped for SwiftUI that provides the native sliding selection animation.
///
/// This component renders an invisible `UISegmentedControl` to get the native iOS sliding indicator
/// animation. The actual tab item views are rendered on top with hit testing disabled, allowing
/// touch events to pass through to the underlying control.
@MainActor
public struct SegmentedControlTabBar<Tab: TabItem>: UIViewRepresentable {
    public var size: CGSize
    public var barTint: Color
    @Binding public var activeTab: Tab

    public init(size: CGSize, barTint: Color = .gray.opacity(0.15), activeTab: Binding<Tab>) {
        self.size = size
        self.barTint = barTint
        self._activeTab = activeTab
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> UISegmentedControl {
        let items = Tab.allCases.compactMap { _ in "" }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = activeTab.index

        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }

        control.selectedSegmentTintColor = UIColor(barTint)
        control.backgroundColor = .clear

        control.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.tabSelected(_:)),
            for: .valueChanged
        )
        return control
    }

    public func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        if uiView.selectedSegmentIndex != activeTab.index {
            uiView.selectedSegmentIndex = activeTab.index
        }
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return size
    }

    public class Coordinator: NSObject {
        var parent: SegmentedControlTabBar

        init(parent: SegmentedControlTabBar) {
            self.parent = parent
        }

        @MainActor @objc func tabSelected(_ control: UISegmentedControl) {
            let allCases = Array(Tab.allCases)
            if control.selectedSegmentIndex < allCases.count {
                parent.activeTab = allCases[control.selectedSegmentIndex]
            }
        }
    }
}

/// A standalone Liquid Glass tab bar with custom tab item rendering.
///
/// Use this when you need just the glass tab bar component without the full `UnionTabView` wrapper.
/// Requires iOS 26+.
///
/// ```swift
/// @available(iOS 26, *)
/// struct TabBarView: View {
///     @Binding var activeTab: MyTab
///
///     var body: some View {
///         GlassTabBar(activeTab: $activeTab) { tab, isSelected in
///             VStack(spacing: 4) {
///                 Image(systemName: isSelected ? tab.symbol : tab.actionSymbol)
///                 Text(tab.rawValue)
///                     .font(.caption2)
///             }
///             .foregroundStyle(isSelected ? .primary : .secondary)
///         }
///         .padding(.horizontal, 20)
///     }
/// }
/// ```
@available(iOS 26, *)
public struct GlassTabBar<Tab: TabItem, TabItemContent: View>: View {
    @Binding public var activeTab: Tab
    public var activeTint: Color
    public var barTint: Color
    public var itemWidth: CGFloat
    public var itemHeight: CGFloat
    public var tabItemView: (Tab, Bool) -> TabItemContent

    /// Creates a glass tab bar with custom tab item rendering.
    ///
    /// - Parameters:
    ///   - activeTab: A binding to the currently selected tab.
    ///   - activeTint: The color for selected tab items. Defaults to `.primary`.
    ///   - barTint: The tint color for the sliding selection indicator. Defaults to a subtle gray.
    ///   - itemWidth: The width of each tab item. Defaults to 86 points.
    ///   - itemHeight: The height of each tab item. Defaults to 58 points.
    ///   - tabItemView: A view builder closure called for each tab, receiving the tab value and whether it's selected.
    public init(
        activeTab: Binding<Tab>,
        activeTint: Color = .primary,
        barTint: Color = .gray.opacity(0.15),
        itemWidth: CGFloat = 86,
        itemHeight: CGFloat = 58,
        @ViewBuilder tabItemView: @escaping (Tab, Bool) -> TabItemContent
    ) {
        self._activeTab = activeTab
        self.activeTint = activeTint
        self.barTint = barTint
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.tabItemView = tabItemView
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                tabItemView(tab, activeTab == tab)
                    .frame(width: itemWidth, height: itemHeight)
            }
        }
        .background {
            GeometryReader { geometry in
                SegmentedControlTabBar(size: geometry.size, barTint: barTint, activeTab: $activeTab)
            }
        }
        .padding(4)
        .glassEffect(.regular.interactive(), in: .capsule)
        .contentShape(Rectangle())
    }
}

/// A glass tab bar with a default icon + label layout.
///
/// Provides a ready-to-use tab bar with icon and label for each tab. For custom layouts, use `GlassTabBar` instead.
@available(iOS 26, *)
public struct SimpleGlassTabBar<Tab: TabItem>: View {
    @Binding public var activeTab: Tab
    public var activeTint: Color
    public var inactiveTint: Color
    public var barTint: Color

    public init(
        activeTab: Binding<Tab>,
        activeTint: Color = .primary,
        inactiveTint: Color = .secondary,
        barTint: Color = .gray.opacity(0.15)
    ) {
        self._activeTab = activeTab
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.barTint = barTint
    }

    public var body: some View {
        GlassTabBar(
            activeTab: $activeTab,
            activeTint: activeTint,
            barTint: barTint
        ) { tab, isSelected in
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.symbol : tab.actionSymbol)
                    .font(.title3)
                    .foregroundStyle(isSelected ? activeTint : inactiveTint)
                
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? activeTint : inactiveTint)
            }
        }
    }
}

/// A glass tab bar showing only icons without labels.
///
/// A compact variant for apps that prefer a minimal tab bar appearance.
@available(iOS 26, *)
public struct IconOnlyGlassTabBar<Tab: TabItem>: View {
    @Binding public var activeTab: Tab
    public var activeTint: Color
    public var inactiveTint: Color
    public var barTint: Color
    public var iconSize: Font

    public init(
        activeTab: Binding<Tab>,
        activeTint: Color = .primary,
        inactiveTint: Color = .secondary,
        barTint: Color = .gray.opacity(0.15),
        iconSize: Font = .title2
    ) {
        self._activeTab = activeTab
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.barTint = barTint
        self.iconSize = iconSize
    }

    public var body: some View {
        GlassTabBar(
            activeTab: $activeTab,
            activeTint: activeTint,
            barTint: barTint,
            itemWidth: 70,
            itemHeight: 50
        ) { tab, isSelected in
            Image(systemName: isSelected ? tab.symbol : tab.actionSymbol)
                .font(iconSize)
                .foregroundStyle(isSelected ? activeTint : inactiveTint)
        }
    }
}

/// A floating circular indicator that displays the active tab's icon.
///
/// Can be used alongside a tab bar or as a standalone indicator showing which tab is currently selected.
public struct FloatingTabIndicator<Tab: TabItem>: View {
    @Binding public var activeTab: Tab
    public var activeTint: Color
    public var size: CGFloat

    public init(
        activeTab: Binding<Tab>,
        activeTint: Color = .primary,
        size: CGFloat = 55
    ) {
        self._activeTab = activeTab
        self.activeTint = activeTint
        self.size = size
    }

    public var body: some View {
        ZStack {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                Image(systemName: tab.symbol)
                    .font(.title)
                    .foregroundStyle(activeTint)
                    .blurFade(activeTab == tab)
            }
        }
        .frame(width: size, height: size)
        .background(.ultraThinMaterial, in: Circle())
        .animation(.smooth(duration: 0.3), value: activeTab)
    }
}

#if DEBUG
@available(iOS 26, *)
#Preview("Simple Glass Tab Bar") {
    @Previewable @State var activeTab: CustomTab = .home
    
    VStack {
        Spacer()
        SimpleGlassTabBar(activeTab: $activeTab)
            .padding(.horizontal, 20)
    }
    .background(Color.gray.opacity(0.2))
}

@available(iOS 26, *)
#Preview("Icon Only Glass Tab Bar") {
    @Previewable @State var activeTab: CustomTab = .home
    
    VStack {
        Spacer()
        IconOnlyGlassTabBar(activeTab: $activeTab)
            .padding(.horizontal, 20)
    }
    .background(Color.gray.opacity(0.2))
}

@available(iOS 26, *)
#Preview("Custom Glass Tab Bar") {
    @Previewable @State var activeTab: CustomTab = .home
    
    VStack {
        Spacer()
        GlassTabBar(activeTab: $activeTab) { tab, isSelected in
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.symbol : tab.actionSymbol)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .gray)
                
                Circle()
                    .fill(isSelected ? .blue : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 60, height: 50)
        }
        .padding(.horizontal, 20)
    }
    .background(Color.gray.opacity(0.2))
}

#Preview("Floating Tab Indicator") {
    @Previewable @State var activeTab: CustomTab = .home
    
    VStack {
        FloatingTabIndicator(activeTab: $activeTab)
        
        HStack(spacing: 20) {
            ForEach(Array(CustomTab.allCases), id: \.self) { tab in
                Button(tab.rawValue) {
                    activeTab = tab
                }
            }
        }
        .padding(.top, 20)
    }
}
#endif
