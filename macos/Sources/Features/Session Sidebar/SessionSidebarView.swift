import SwiftUI

/// Collapsible list of the window's tabs. Rows stay in the order they are given.
struct SessionSidebarView: View {
    var rows: [SessionTabRow]
    @Binding var focusSearch: Bool
    @Binding var searchIsFocused: Bool
    var onSelect: (SessionTabRow) -> Void
    var onDismiss: () -> Void
    var onWidthChange: (Double) -> Void

    @State private var query = ""
    @State private var selectedID: String?
    @FocusState private var searchFieldFocused: Bool

    private var filteredRows: [SessionTabRow] {
        SessionSidebarFilter.rows(rows, matching: query)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
                .padding(8)

            Divider()

            if filteredRows.isEmpty {
                Text("No matching tabs")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(8)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(filteredRows) { row in
                                SessionSidebarRow(
                                    row: row,
                                    isKeyboardSelected: row.id == selectedID
                                ) {
                                    selectedID = row.id
                                    onSelect(row)
                                }
                                .id(row.id)
                            }
                        }
                        .padding(6)
                    }
                    .onChange(of: selectedID) { id in
                        guard let id else { return }
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(widthReader)
        .onAppear {
            if selectedID == nil {
                selectedID = filteredRows.first(where: \.isFocused)?.id ?? filteredRows.first?.id
            }
            focusSearchField()
        }
        .onChange(of: focusSearch) { newValue in
            guard newValue else { return }
            focusSearchField()
        }
        .onChange(of: searchFieldFocused) { focused in
            if searchIsFocused != focused {
                searchIsFocused = focused
            }
        }
        .onChange(of: query) { _ in
            let shown = filteredRows
            if query.isEmpty {
                selectedID = shown.first(where: \.isFocused)?.id ?? shown.first?.id
            } else {
                selectedID = shown.first?.id
            }
        }
        .onChange(of: rows) { _ in
            let shown = filteredRows
            if let selectedID, shown.contains(where: { $0.id == selectedID }) { return }
            self.selectedID = shown.first(where: \.isFocused)?.id ?? shown.first?.id
        }
    }

    private var searchField: some View {
        ZStack {
            if searchFieldFocused {
                Group {
                    Button { moveSelection(-1) } label: { Color.clear }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.upArrow, modifiers: [])
                    Button { moveSelection(1) } label: { Color.clear }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.downArrow, modifiers: [])
                }
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            }

            TextField("Search", text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($searchFieldFocused)
                .onSubmit { selectCurrent() }
                .onExitCommand { handleEscape() }
                .onMoveCommand { direction in
                    switch direction {
                    case .up: moveSelection(-1)
                    case .down: moveSelection(1)
                    default: break
                    }
                }
        }
    }

    private var widthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { onWidthChange(Double(proxy.size.width)) }
                .onChange(of: proxy.size.width) { newWidth in
                    onWidthChange(Double(newWidth))
                }
        }
    }

    private func focusSearchField() {
        // The next turn wins against the window's own focus restoration.
        DispatchQueue.main.async {
            searchFieldFocused = true
            focusSearch = false
        }
    }

    private func handleEscape() {
        if !query.isEmpty {
            query = ""
            focusSearchField()
            return
        }
        searchFieldFocused = false
        onDismiss()
    }

    private func moveSelection(_ delta: Int) {
        let shown = filteredRows
        guard !shown.isEmpty else { return }
        let next: Int
        if let current = shown.firstIndex(where: { $0.id == selectedID }) {
            next = min(max(current + delta, 0), shown.count - 1)
        } else {
            next = delta < 0 ? shown.count - 1 : 0
        }
        selectedID = shown[next].id
    }

    private func selectCurrent() {
        let shown = filteredRows
        guard let row = shown.first(where: { $0.id == selectedID }) ?? shown.first else { return }
        selectedID = row.id
        onSelect(row)
    }
}

private struct SessionSidebarRow: View {
    let row: SessionTabRow
    var isKeyboardSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(stripColor)
                    .frame(width: 3)
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.displayTitle)
                        .fontWeight(row.isFocused ? .semibold : .regular)
                        .lineLimit(1)

                    if row.showsCommand, let command = row.command {
                        Text(command)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.trailing, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(background)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(row.isFocused ? .isSelected : [])
    }

    /// The tab color, and only the tab color. Focus stays on the row background.
    private var stripColor: Color {
        guard let color = row.tabColor.displayColor else { return .clear }
        return Color(nsColor: color)
    }

    private var background: Color {
        if isKeyboardSelected {
            return Color.accentColor.opacity(0.28)
        }
        if row.isFocused {
            return Color.accentColor.opacity(0.12)
        }
        return Color.clear
    }
}
