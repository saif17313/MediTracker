//
//  DoseBadge.swift
//  MediReminder
//
//  Created for MediReminder App
//

import SwiftUI

/// A color-coded badge indicating dose status (Taken / Skipped / Missed).
/// Used in history lists and detail views.
struct DoseBadge: View {
    let status: DoseStatus
    var size: BadgeSize = .medium

    var body: some View {
        Image(systemName: status.iconName)
            .font(iconFont)
            .foregroundStyle(.white)
            .frame(width: badgeDimension, height: badgeDimension)
            .background(Color.forDoseStatus(status))
            .clipShape(Circle())
    }

    // MARK: - Size Variants

    private var iconFont: Font {
        switch size {
        case .small:  return .caption2
        case .medium: return .caption
        case .large:  return .body
        }
    }

    private var badgeDimension: CGFloat {
        switch size {
        case .small:  return 20
        case .medium: return 28
        case .large:  return 36
        }
    }
}

// MARK: - Badge Size

enum BadgeSize {
    case small, medium, large
}

// MARK: - Dose Status Label

/// A combined badge + text label for dose status.
struct DoseStatusLabel: View {
    let status: DoseStatus
    var showText: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            DoseBadge(status: status, size: .small)

            if showText {
                Text(status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.forDoseStatus(status))
            }
        }
    }
}

// MARK: - Adherence Percentage Badge

/// Displays an adherence percentage with color coding.
struct AdherenceBadge: View {
    let percentage: Double

    var body: some View {
        Text(String(format: "%.0f%%", percentage))
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(adherenceColor.opacity(0.15))
            .foregroundStyle(adherenceColor)
            .clipShape(Capsule())
    }

    private var adherenceColor: Color {
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .orange }
        return .red
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Dose Badges
        HStack(spacing: 16) {
            ForEach(DoseStatus.allCases) { status in
                VStack {
                    DoseBadge(status: status, size: .large)
                    DoseBadge(status: status, size: .medium)
                    DoseBadge(status: status, size: .small)
                    Text(status.displayName)
                        .font(.caption)
                }
            }
        }

        Divider()

        // Status Labels
        VStack(alignment: .leading, spacing: 8) {
            ForEach(DoseStatus.allCases) { status in
                DoseStatusLabel(status: status)
            }
        }

        Divider()

        // Adherence Badges
        HStack(spacing: 12) {
            AdherenceBadge(percentage: 95)
            AdherenceBadge(percentage: 65)
            AdherenceBadge(percentage: 30)
        }
    }
    .padding()
}
