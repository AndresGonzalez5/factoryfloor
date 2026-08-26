// ABOUTME: Card-style picker for CodingHarness — pixel avatar on top, name below.
// ABOUTME: Reused in the new-workstream sheet and Settings.

import SwiftUI

/// Horizontal card picker for `CodingHarness`. Each card shows the harness's
/// pixel avatar (if available) above its display name. Selection is indicated
/// with a brand-colored border and a faint tinted fill.
struct HarnessPicker: View {
    @Binding var selection: CodingHarness

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CodingHarness.allCases, id: \.self) { candidate in
                HarnessCard(
                    harness: candidate,
                    isSelected: candidate == selection
                ) {
                    selection = candidate
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct HarnessCard: View {
    let harness: CodingHarness
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                avatar
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(
                                isSelected ? harness.brandColor : Color.primary.opacity(0.1),
                                lineWidth: isSelected ? 1.8 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? harness.brandColor.opacity(0.22) : .clear,
                        radius: isSelected ? 5 : 0,
                        y: isSelected ? 1 : 0
                    )
                    // Unselected avatars are slightly muted so the selected one pops.
                    .saturation(isSelected ? 1 : 0.9)
                    .opacity(isSelected ? 1 : 0.88)
                    .scaleEffect(isSelected ? 1 : 0.98)
                    .animation(.easeInOut(duration: 0.16), value: isSelected)

                Text(harness.displayName)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.14), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? harness.brandColor.opacity(0.10)
                            : (isHovering ? Color.primary.opacity(0.05) : Color.primary.opacity(0.03))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? harness.brandColor.opacity(0.9) : Color.primary.opacity(isHovering ? 0.12 : 0.08),
                        lineWidth: isSelected ? 1.4 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        // Cards are not focusable — Tab is handled at the sheet level to cycle
        // selection directly (spec: Tab cycles harness, Enter always creates).
        // Keeping them non-focusable prevents Enter from activating a card instead
        // of the default Create button, and keeps focus in the name field.
        .focusable(false)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(Text(harness.displayName))
        .accessibilityValue(isSelected ? Text("Selected") : Text(""))
        .animation(.easeInOut(duration: 0.16), value: isHovering)
        .animation(.easeInOut(duration: 0.16), value: isSelected)
    }

    @ViewBuilder
    private var avatar: some View {
        if let nsImage = AgentSpriteStore.shared.avatar(name: harness.portraitName, palette: 0, variant: 0) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                Image(systemName: harness.systemImageName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var sel: CodingHarness = .claudeCode
    VStack {
        HarnessPicker(selection: $sel)
            .padding()
        Text("Selected: \(sel.displayName)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .frame(width: 380)
    .padding()
}
