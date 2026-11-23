//
//  RecentsView.swift
//  The five most recent files/folders, draggable straight out of the notch.
//

import AppKit
import SwiftUI

struct RecentsView: View {
    @StateObject private var store = RecentItemsStore.shared

    var body: some View {
        Group {
            if store.items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock")
                        .symbolVariant(.fill)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white, .gray)
                        .imageScale(.large)
                    Text("No recent files")
                        .foregroundStyle(.gray)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(store.items) { item in
                        RecentItemCell(item: item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 4)
        .onAppear { store.refresh() }
    }
}

private struct RecentItemCell: View {
    let item: RecentItem
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
            Text(item.url.lastPathComponent)
                .font(.caption)
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text(item.date, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(hovering ? 0.12 : 0.05)))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onHover { hovering = $0 }
        .onDrag { NSItemProvider(object: item.url as NSURL) }
        .onTapGesture { NSWorkspace.shared.open(item.url) }
        .contextMenu {
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url.path, forType: .string)
            }
        }
    }
}
