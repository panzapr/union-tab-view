//
//  AdaptiveTabBar.swift
//  UnionTabView
//
//  Created by Union St on 11/28/25.
//

import SwiftUI

/// An adaptive tab bar that renders a Liquid Glass floating tab bar on iOS 26+ for `TabItem` conforming types.
///
/// This is an alternative to `UnionTabView` that works with the `TabItem` protocol instead of a raw `[Tab]` array.
/// It automatically iterates over all cases of your tab enum.
///
/// For most use cases, prefer `UnionTabView` which has a simpler API that doesn't require `CaseIterable` conformance.
///
/// ```swift
/// enum MyTab: String, CaseIterable, TabItem {
///     case home = "Home"
///     case settings = "Settings"
///     
///     var symbol: String { ... }
///     var actionSymbol: String { ... }
/// }
///
/// struct ContentView: View {
///     @State private var selectedTab: MyTab = .home
///
///     var body: some View {
///         AdaptiveTabBar(selection: $selectedTab) {
///             HomeView()
///                 .glassTabBarContentPadding()
///                 .tabItem { Label("Home", systemImage: "house") }
///                 .tag(MyTab.home)
///             SettingsView()
///                 .glassTabBarContentPadding()
///                 .tabItem { Label("Settings", systemImage: "gear") }
///                 .tag(MyTab.settings)
///         }
///     }
/// }
/// ```
public struct AdaptiveTabBar<Tab: TabItem, Content: View, TabItemContent: View>: View {
    @Binding public var selection: Tab
    public var activeTint: Color
    public var inactiveTint: Color
    public var barTint: Color
    public var tabBarHeight: CGFloat
    public var content: () -> Content
    public var tabItemView: (Tab, Bool) -> TabItemContent
    
    /// Creates an adaptive tab bar with custom tab item rendering.
    ///
    /// - Parameters:
    ///   - selection: A binding to the currently selected tab.
    ///   - activeTint: The color for selected tab items. Defaults to `.primary`.
    ///   - inactiveTint: The color for unselected tab items. Defaults to `.secondary`.
    ///   - barTint: The tint color for the sliding selection indicator. Defaults to a subtle gray.
    ///   - tabBarHeight: The height of the tab bar. Defaults to 55 points.
    ///   - content: A view builder for the tab content. Apply `.glassTabBarContentPadding()` and `.tag()` to each.
    ///   - tabItemView: A view builder closure called for each tab, receiving the tab value and whether it's selected.
    public init(
        selection: Binding<Tab>,
        activeTint: Color = .primary,
        inactiveTint: Color = .secondary,
        barTint: Color = .gray.opacity(0.15),
        tabBarHeight: CGFloat = 55,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder tabItemView: @escaping (Tab, Bool) -> TabItemContent
    ) {
        self._selection = selection
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.barTint = barTint
        self.tabBarHeight = tabBarHeight
        self.content = content
        self.tabItemView = tabItemView
    }
    
    public var body: some View {
        if #available(iOS 26, *) {
            iOS26TabBar
        } else {
            legacyTabBar
        }
    }
    
    @available(iOS 26, *)
    private var iOS26TabBar: some View {
        TabView(selection: $selection) {
            content()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GlassTabBar(
                activeTab: $selection,
                activeTint: activeTint,
                barTint: barTint
            ) { tab, isSelected in
                tabItemView(tab, isSelected)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var legacyTabBar: some View {
        TabView(selection: $selection) {
            content()
        }
    }
}

public extension AdaptiveTabBar where TabItemContent == DefaultTabItemView<Tab> {
    /// Creates an adaptive tab bar with the default icon + label tab item layout.
    ///
    /// - Parameters:
    ///   - selection: A binding to the currently selected tab.
    ///   - activeTint: The color for selected tab items. Defaults to `.primary`.
    ///   - inactiveTint: The color for unselected tab items. Defaults to `.secondary`.
    ///   - barTint: The tint color for the sliding selection indicator. Defaults to a subtle gray.
    ///   - tabBarHeight: The height of the tab bar. Defaults to 55 points.
    ///   - content: A view builder for the tab content.
    init(
        selection: Binding<Tab>,
        activeTint: Color = .primary,
        inactiveTint: Color = .secondary,
        barTint: Color = .gray.opacity(0.15),
        tabBarHeight: CGFloat = 55,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._selection = selection
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.barTint = barTint
        self.tabBarHeight = tabBarHeight
        self.content = content
        self.tabItemView = { tab, isSelected in
            DefaultTabItemView(
                tab: tab,
                isSelected: isSelected,
                activeTint: activeTint,
                inactiveTint: inactiveTint
            )
        }
    }
}

/// The default tab item view showing an icon and label.
///
/// Used automatically by `AdaptiveTabBar` when no custom `tabItemView` is provided.
public struct DefaultTabItemView<Tab: TabItem>: View {
    let tab: Tab
    let isSelected: Bool
    let activeTint: Color
    let inactiveTint: Color
    
    public init(
        tab: Tab,
        isSelected: Bool,
        activeTint: Color,
        inactiveTint: Color
    ) {
        self.tab = tab
        self.isSelected = isSelected
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? tab.symbol : tab.actionSymbol)
                .font(.title3)
            Text(tab.rawValue)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(isSelected ? activeTint : inactiveTint)
    }
}

/// An invisible spacer that reserves space for the glass tab bar in the safe area.
///
/// Use inside `.safeAreaBar(edge: .bottom)` to push content above the floating tab bar.
@available(iOS 26, *)
public struct GlassTabBarSpacer: View {
    public var height: CGFloat
    
    /// Creates a spacer with the specified height.
    ///
    /// - Parameter height: The height to reserve. Defaults to the system tab bar height.
    public init(height: CGFloat? = nil) {
        self.height = height ?? Self.systemTabBarHeight
    }
    
    public var body: some View {
        Text(".")
            .blendMode(.destinationOver)
            .frame(height: height)
    }
    
    private static var systemTabBarHeight: CGFloat {
        if #available(iOS 26, *) {
            return 49
        } else {
            let tabBar = UITabBar()
            tabBar.sizeToFit()
            return tabBar.frame.height
        }
    }
}

public extension View {
    /// Adds safe area padding for the glass tab bar and hides the system tab bar.
    ///
    /// Apply this modifier to each tab's content when using `AdaptiveTabBar`. On iOS 26+, it adds spacing
    /// so content doesn't overlap the floating glass tab bar. On earlier versions, it does nothing.
    ///
    /// ```swift
    /// AdaptiveTabBar(selection: $selectedTab) {
    ///     HomeView()
    ///         .glassTabBarContentPadding()
    ///         .tabItem { Label("Home", systemImage: "house") }
    ///         .tag(MyTab.home)
    /// }
    /// ```
    ///
    /// - Parameter height: Custom height for the padding. Defaults to the system tab bar height.
    @ViewBuilder
    func glassTabBarContentPadding(height: CGFloat? = nil) -> some View {
        if #available(iOS 26, *) {
            self.safeAreaBar(edge: .bottom, spacing: 0) {
                GlassTabBarSpacer(height: height)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        } else {
            self
        }
    }
}

@available(iOS 26, *)
extension View {
    /// Adds content to the safe area inset of the specified edge.
    ///
    /// A convenience wrapper around `safeAreaInset(edge:spacing:content:)`.
    ///
    /// - Parameters:
    ///   - edge: The edge to add the safe area inset to.
    ///   - spacing: Optional spacing between the inset content and the main view.
    ///   - content: The content to display in the safe area inset.
    public func safeAreaBar<Content: View>(
        edge: VerticalEdge,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        self.safeAreaInset(edge: edge, spacing: spacing, content: content)
    }
}

#if DEBUG
@available(iOS 26, *)
#Preview("Adaptive Tab Bar - Default") {
    @Previewable @State var selectedTab: CustomTab = .home
    
    AdaptiveTabBar(selection: $selectedTab) {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(1...50, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.red.gradient)
                        .frame(height: 50)
                }
            }
            .padding(15)
        }
        .glassTabBarContentPadding()
        .tabItem { Label("Home", systemImage: "house") }
        .tag(CustomTab.home)
        
        Text("Notifications Content")
            .glassTabBarContentPadding()
            .tabItem { Label("Notifications", systemImage: "bell") }
            .tag(CustomTab.notifications)
        
        Text("Settings Content")
            .glassTabBarContentPadding()
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(CustomTab.settings)
    }
}

@available(iOS 26, *)
#Preview("Adaptive Tab Bar - Custom") {
    @Previewable @State var selectedTab: CustomTab = .home
    
    AdaptiveTabBar(selection: $selectedTab) {
        Text("Home Content")
            .glassTabBarContentPadding()
            .tabItem { Label("Home", systemImage: "house") }
            .tag(CustomTab.home)
        
        Text("Notifications Content")
            .glassTabBarContentPadding()
            .tabItem { Label("Notifications", systemImage: "bell") }
            .tag(CustomTab.notifications)
        
        Text("Settings Content")
            .glassTabBarContentPadding()
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(CustomTab.settings)
    } tabItemView: { tab, isSelected in
        VStack(spacing: 2) {
            Image(systemName: isSelected ? tab.symbol : tab.actionSymbol)
                .font(.title2)
            Circle()
                .fill(isSelected ? .blue : .clear)
                .frame(width: 4, height: 4)
        }
        .foregroundStyle(isSelected ? .blue : .gray)
    }
}
#endif
