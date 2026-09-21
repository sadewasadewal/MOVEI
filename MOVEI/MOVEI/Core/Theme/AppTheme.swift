//
//  AppTheme.swift
//  MOVEI
//

import SwiftUI

public enum AppTheme {
    // Dynamic semantic colors for full light/dark mode support
    public static let ink = Color(uiColor: .label)
    public static let muted = Color(uiColor: .secondaryLabel)
    public static let tertiary = Color(uiColor: .tertiaryLabel)
    public static let canvas = Color(uiColor: .systemGroupedBackground)
    public static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    public static let surfaceElevated = Color(uiColor: .tertiarySystemGroupedBackground)

    // Fixed deep dark colors for authentic cinema pass cards (always dark with white text)
    public static let passBackground = Color(red: 0.08, green: 0.09, blue: 0.10)
    public static let passCard = Color(red: 0.12, green: 0.13, blue: 0.15)

    // Brand colors
    public static let lime = Color(red: 0.73, green: 0.91, blue: 0.38)
    public static let brand = Color.blue
    public static let accent = Color(red: 0.98, green: 0.42, blue: 0.22)
    public static let danger = Color(red: 0.92, green: 0.25, blue: 0.25)
    public static let warning = Color(red: 0.96, green: 0.65, blue: 0.14)
    public static let success = Color(red: 0.22, green: 0.78, blue: 0.42)
}
