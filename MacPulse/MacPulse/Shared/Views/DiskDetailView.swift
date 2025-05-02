//
//  DiskDetailView.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/29/25.
//

import SwiftUI
import Charts

// MARK: - Models & Utility

// Model representing overall disk info including used/free space
struct DiskInfo {
    let total: Int64
    let free: Int64
    var used: Int64 { total - free }
}

// Model representing usage by directory or file category
struct CategoryUsage: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
}

// Utility for querying disk metrics and performing size calculations
class DiskUtility {
    // Returns total and free disk bytes for the root volume
    static func getDiskInfo() -> DiskInfo? {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            guard
                let total = (attrs[.systemSize] as? NSNumber)?.int64Value,
                let free  = (attrs[.systemFreeSize] as? NSNumber)?.int64Value
            else { return nil }
            return DiskInfo(total: total, free: free)
        } catch {
            print("Disk info error:", error)
            return nil
        }
    }

    // Returns the top `limit` largest subdirectories in the given path
    static func getTopDirectories(path: String = "/", limit: Int = 5) -> [CategoryUsage] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return [] }

        var usages: [CategoryUsage] = []
        for name in contents {
            let url = URL(fileURLWithPath: path).appendingPathComponent(name)
            let size = directorySize(url: url)
            usages.append(.init(name: name, size: size))
        }
        return usages
            .sorted(by: { $0.size > $1.size })
            .prefix(limit)
            .map { $0 }
    }

    // Recursively sums file sizes for a directory (use off main thread)
    private static func directorySize(url: URL) -> Int64 {
        var total: Int64 = 0
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        let opts: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]

        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: opts) {
            for case let fileURL as URL in enumerator {
                do {
                    let res = try fileURL.resourceValues(forKeys: Set(keys))
                    if res.isRegularFile == true, let sz = res.fileSize {
                        total += Int64(sz)
                    }
                } catch { /* permission errors are ignored */ }
            }
        }
        return total
    }

    // Converts byte count to human-readable file size string
    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Disk Detailed View

// Displays total, used, and free disk space with top-level directory breakdown
struct DiskDetailedView: View {
    @State private var diskInfo: DiskInfo?
    @State private var categories: [CategoryUsage] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Storage Detailed View")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            // Usage bar with dynamic fill based on used percentage
            if let info = diskInfo {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.2))

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * usageFraction(info: info))
                        }
                    }
                    .frame(height: 12)
                    .padding(.horizontal)

                    Text("\(DiskUtility.formatBytes(info.used)) used • \(DiskUtility.formatBytes(info.free)) free of \(DiskUtility.formatBytes(info.total))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            // List of largest top-level directories
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(categories) { cat in
                        HStack {
                            Text(cat.name)
                            Spacer()
                            Text(DiskUtility.formatBytes(cat.size))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .onAppear(perform: loadData)
        .padding(.bottom)
    }

    // Calculates fraction of total disk that is used
    private func usageFraction(info: DiskInfo) -> CGFloat {
        guard info.total > 0 else { return 0 }
        return CGFloat(info.used) / CGFloat(info.total)
    }

    // Loads disk info and top-level directory sizes
    private func loadData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let info = DiskUtility.getDiskInfo()
            let cats = DiskUtility.getTopDirectories(path: "/", limit: 5)
            DispatchQueue.main.async {
                self.diskInfo = info
                self.categories = cats
            }
        }
    }
}

// MARK: - File Type Breakdown Extension

// Groups files by extension and calculates total size for each
extension DiskUtility {
    static func getFileTypeBreakdown(path: String = "/", limit: Int = 5) async -> [CategoryUsage] {
        let fm = FileManager.default
        let rootURL = URL(fileURLWithPath: path)
        var map: [String: Int64] = [:]
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        let opts: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]

        if let enumerator = fm.enumerator(at: rootURL, includingPropertiesForKeys: keys, options: opts) {
            for case let url as URL in enumerator {
                do {
                    let res = try url.resourceValues(forKeys: Set(keys))
                    if res.isRegularFile == true {
                        let ext = url.pathExtension.lowercased().isEmpty ? "No Ext" : url.pathExtension.lowercased()
                        map[ext, default: 0] += Int64(res.fileSize ?? 0)
                    }
                } catch { /* ignore permission errors */ }
            }
        }

        return map
            .map { CategoryUsage(name: $0.key, size: $0.value) }
            .sorted(by: { $0.size > $1.size })
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - File Type Breakdown View

// Displays disk usage grouped by file extensions
struct FileTypeBreakdownView: View {
    @State private var diskInfo: DiskInfo?
    @State private var breakdown: [CategoryUsage] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Storage Detailed View")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            // Usage bar
            if let info = diskInfo {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.2))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * usageFraction(info: info))
                        }
                    }
                    .frame(height: 12)
                    .padding(.horizontal)

                    Text("\(DiskUtility.formatBytes(info.used)) used • \(DiskUtility.formatBytes(info.free)) free of \(DiskUtility.formatBytes(info.total))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            // Breakdown list
            List(breakdown) { item in
                HStack {
                    Text(item.name.capitalized)
                    Spacer()
                    Text(DiskUtility.formatBytes(item.size))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .padding(.bottom)
        .onAppear {
            Task {
                diskInfo = DiskUtility.getDiskInfo()
                breakdown = await DiskUtility.getFileTypeBreakdown(limit: 5)
            }
        }
    }

    // Helper for bar percentage
    private func usageFraction(info: DiskInfo) -> CGFloat {
        guard info.total > 0 else { return 0 }
        return CGFloat(info.used) / CGFloat(info.total)
    }
}

// MARK: - Pie Chart View

// Displays a two-slice pie chart of used vs free disk space
struct DiskPieChartView: View {
    @State private var slices: [CategoryUsage] = []
    @State private var diskInfo: DiskInfo?

    var body: some View {
        VStack(spacing: 16) {
            Text("Disk Usage Breakdown")
                .font(.title2)
                .bold()

            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Bytes", slice.size),
                    innerRadius: .ratio(0.5),
                    outerRadius: .ratio(1.0)
                )
                .foregroundStyle(by: .value("Category", slice.name))
                .annotation(position: .overlay, alignment: .center) {
                    Text(slice.name)
                        .font(.caption2)
                }
            }
            .chartLegend(.visible)
            .frame(height: 280)
            .padding(.horizontal)

            // Strip showing used and free values
            if let info = diskInfo {
                HStack {
                    Text("Used: \(DiskUtility.formatBytes(info.used))")
                    Spacer()
                    Text("Free: \(DiskUtility.formatBytes(info.free))")
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .onAppear {
            Task {
                let info = DiskUtility.getDiskInfo()
                let built: [CategoryUsage] = {
                    guard let i = info else { return [] }
                    return [
                        CategoryUsage(name: "Used", size: i.used),
                        CategoryUsage(name: "Free", size: i.free)
                    ]
                }()
                await MainActor.run {
                    diskInfo = info
                    slices = built
                }
            }
        }
    }
}
