//
//  DiskDetailView.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/29/25.
//
import SwiftUI
import Charts

// MARK: – Models & Utility
struct DiskInfo {
    let total: Int64
    let free: Int64
    var used: Int64 { total - free }
}

struct CategoryUsage: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
}

class DiskUtility {
    /// Returns total & free bytes on "/"
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

    /// Measures directory sizes at depth = 1, returns top `limit` entries
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

    /// Recursively walk and sum file sizes (blocking—run off the main thread)
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
                } catch { /* ignore permission errors */ }
            }
        }
        return total
    }

    /// Human-readable bytes
    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: – The Disk Detailed View
struct DiskDetailedView: View {
    @State private var diskInfo: DiskInfo?
    @State private var categories: [CategoryUsage] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Storage Detailed View")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            // ——— Usage Bar ———
            if let info = diskInfo {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // full bar
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.2))
                            // used portion
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

            // ——— Top Categories ———
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

    private func usageFraction(info: DiskInfo) -> CGFloat {
        guard info.total > 0 else { return 0 }
        return CGFloat(info.used) / CGFloat(info.total)
    }

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


// MARK: – DiskUtility extension for file-type breakdown
extension DiskUtility {
  /// Enumerates the entire filesystem under `path`, groups by file extension,
  /// and returns the top `limit` categories by total size.
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

// MARK: – File-Type Breakdown View
struct FileTypeBreakdownView: View {
    @State private var diskInfo: DiskInfo?
    @State private var breakdown: [CategoryUsage] = []

    var body: some View {
        VStack(spacing: 20) {
            // ——— Title & Usage Bar ———
            Text("Storage Detailed View")
                .font(.largeTitle)
                .bold()
                .padding(.top)

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

            // ——— File-Type Breakdown ———
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
            Task {  // async/await for file-type walk
                // 1) Disk info is sync
                diskInfo = DiskUtility.getDiskInfo()
                // 2) File-type breakdown is async
                breakdown = await DiskUtility.getFileTypeBreakdown(limit: 5)
            }
        }
    }

    private func usageFraction(info: DiskInfo) -> CGFloat {
        guard info.total > 0 else { return 0 }
        return CGFloat(info.used) / CGFloat(info.total)
    }
}


// MARK: – Pie-Chart View of Disk Usage
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
          // you can also annotate with percentages here if you like:
          Text(slice.name)
            .font(.caption2)
        }
      }
      .chartLegend(.visible)
      .frame(height: 280)
      .padding(.horizontal)

      // ——— Value Strip ———
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
        // 1. Get raw numbers
        let info = DiskUtility.getDiskInfo()
        // 2. Build the two‐slice model
        let built: [CategoryUsage] = {
          guard let i = info else { return [] }
          return [
            CategoryUsage(name: "Used", size: i.used),
            CategoryUsage(name: "Free", size: i.free)
          ]
        }()
        // 3. Update state on the main actor
        await MainActor.run {
          diskInfo = info
          slices = built
        }
      }
    }
  }
}
