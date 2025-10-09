import SwiftUI

struct ContentView: View {
    @State private var droppedPath: String? = nil
    @State private var normalize: Bool = true
    @State private var trimSilence: Bool = false
    @State private var layout: Layout = .flat
    @State private var outputLog: String = ""
    @State private var isRunning: Bool = false

    enum Layout: String, CaseIterable, Identifiable {
        case keep, flatPrefix = "flat-prefix", flat
        var id: String { rawValue }
        var label: String {
            switch self {
            case .keep: return "Keep subfolders"
            case .flatPrefix: return "Flat with prefix"
            case .flat: return "Flat"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Samplem Repacker").font(.title2).bold()
            Text("Drag a sample folder below, choose options, then Run.")
                .foregroundColor(.secondary)

            DropZone(droppedPath: $droppedPath)
                .frame(height: 140)

            HStack {
                Toggle("Normalize", isOn: $normalize)
                Toggle("Trim silence", isOn: $trimSilence)
                Picker("Layout", selection: $layout) {
                    ForEach(Layout.allCases) { l in
                        Text(l.label).tag(l)
                    }
                }.pickerStyle(.segmented)
            }

            HStack {
                Button(isRunning ? "Running..." : "Run") {
                    runSamplem()
                }
                .disabled(droppedPath == nil || isRunning)

                if let path = droppedPath {
                    Text(path).lineLimit(1).truncationMode(.middle)
                } else {
                    Text("No folder selected").foregroundColor(.secondary)
                }
                Spacer()
            }

            ScrollView {
                Text(outputLog).font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.border(Color.gray.opacity(0.2))
        }
        .padding(16)
        .frame(minWidth: 720, minHeight: 520)
    }

    func runSamplem() {
        guard let path = droppedPath else { return }
        outputLog = ""
        isRunning = true
        let args = [
            "-lc",
            "PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; samplem repack --path \(path.shellEscaped()) \(normalize ? "--normalize" : "--no-normalize") \(trimSilence ? "--trim" : "--no-trim") --layout \(layout.rawValue)"
        ]

        let proc = Process()
        proc.launchPath = "/bin/zsh"
        proc.arguments = args

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { h in
            if let s = String(data: h.availableData, encoding: .utf8), !s.isEmpty {
                DispatchQueue.main.async { outputLog += s }
            }
        }

        proc.terminationHandler = { _ in
            DispatchQueue.main.async { isRunning = false }
        }

        do { try proc.run() } catch {
            outputLog += "\nFailed to start: \(error.localizedDescription)\n"
            isRunning = false
        }
    }
}

private struct DropZone: View {
    @Binding var droppedPath: String?
    @State private var isTargeted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            Text("Drop folder here")
                .foregroundColor(.secondary)
        }
        .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async { droppedPath = url.path }
            }
            return true
        }
    }
}

private extension String {
    func shellEscaped() -> String {
        self.replacingOccurrences(of: "'", with: "'\\''")
    }
}


