# UnionTabBar

A beautiful glass-effect tab bar package for iOS 26+ built with SwiftUI and UIKit.

## Installation

Add this package to your Xcode project using Swift Package Manager.

## Public API

### Ready-to-Use Components

#### `CustomTabBarWithOverlay`
A glass-effect tab bar with overlay icons and text. Perfect for most use cases.

```swift
CustomTabBarWithOverlay(
    activeTab: $activeTab,
    activeTint: .blue,
    inactiveTint: .primary
)
.frame(height: 55)
```

#### `StyledImageTabBar`
An image-rendered tab bar with custom styling using `ImageGlassTabBar` internally.

```swift
StyledImageTabBar(
    activeTab: $activeTab,
    activeTint: .blue,
    barTint: .gray.opacity(0.15)
)
.frame(height: 55)
```

#### `FloatingTabBar`
A floating circular indicator that shows the active tab icon with blur fade animation.

```swift
FloatingTabBar(
    activeTab: $activeTab,
    activeTint: .blue,
    inactiveTint: .primary
)
```

#### `CompactTabBar`
Combines `CustomTabBarWithOverlay` and `FloatingTabBar` in a horizontal layout.

```swift
CompactTabBar(
    activeTab: $activeTab,
    activeTint: .blue,
    inactiveTint: .primary
)
```

### Advanced Components

#### `ImageGlassTabBar`
For full customization, use the generic `ImageGlassTabBar` with a custom `tabItemView` closure.

```swift
GeometryReader { geometry in
    ImageGlassTabBar(
        size: geometry.size,
        activeTint: .blue,
        barTint: .gray.opacity(0.15),
        activeTab: $activeTab
    ) { tab in
        VStack(spacing: 3) {
            Image(systemName: tab.symbol)
                .font(.title3)
            
            Text(tab.rawValue)
                .font(.system(size: 10))
                .fontWeight(.medium)
        }
    }
    .glassEffect(.regular.interactive(), in: .capsule)
}
```

### Data Types

#### `CustomTab`
The enum representing tab items.

```swift
public enum CustomTab: String, CaseIterable {
    case home
    case search
    case profile
    
    var symbol: String // SF Symbol for filled state
    var actionSymbol: String // SF Symbol for outline state
    var index: Int // Index in allCases
}
```

### Extensions

#### `View.blurFade(_:)`
Applies a blur and fade animation effect.

```swift
view.blurFade(isActive)
```

## Example Usage

```swift
import SwiftUI
import UnionTabBar

struct ContentView: View {
    @State private var activeTab: CustomTab = .home
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                CustomTabBarWithOverlay(activeTab: $activeTab)
                    .frame(height: 55)
                
                FloatingTabBar(activeTab: $activeTab)
            }
            .padding(.horizontal, 20)
        }
    }
}
```

## Requirements

- iOS 18.0+ (symbols available on iOS 26+)
- Swift 6.2+
- Xcode 16+

## License

MIT


