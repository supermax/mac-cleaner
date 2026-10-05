import Foundation

enum DiskScanner {
    static func size(of url: URL) -> Int64 {
        let manager = FileManager.default
        guard manager.fileExists(atPath: url.path) else { return 0 }
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .totalFileAllocatedSizeKey]
        guard let recursive = manager.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles], errorHandler: { _, _ in true }) else { return 0 }
        var total: Int64 = 0
        while let entry = recursive.nextObject() as? URL {
            let values = try? entry.resourceValues(forKeys: keys)
            if values?.isRegularFile == true { total += Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0) }
        }
        return total
    }
}
