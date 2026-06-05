import Foundation
import SwiftData
import UIKit

struct SavedCreationMetadata {
    var prompt: String?
    var themeName: String?
    var monthLabel: String?
    var projectID: String?
}

enum SavedCreationsError: Error {
    case downloadFailed
    case writeFailed
    case notFound
}

protocol SavedCreationsService {
    func save(imageURL: URL, metadata: SavedCreationMetadata) async throws -> SavedCreationModel
    func save(imageData: Data, metadata: SavedCreationMetadata) async throws -> SavedCreationModel
    func loadAll() async -> [SavedCreationModel]
    func loadImage(for creation: SavedCreationModel) -> UIImage?
    func delete(_ creation: SavedCreationModel) async throws
}

@MainActor
final class SavedCreationsServiceImpl: SavedCreationsService {
    private let context: ModelContext
    private let urlSession: URLSession
    private let directoryName = "SavedCreations"

    init(context: ModelContext, urlSession: URLSession = .shared) {
        self.context = context
        self.urlSession = urlSession
    }

    func save(imageURL: URL, metadata: SavedCreationMetadata) async throws -> SavedCreationModel {
        let (data, response) = try await urlSession.data(from: imageURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw SavedCreationsError.downloadFailed
        }
        return try writeAndInsert(data: data, sourceURL: imageURL.absoluteString, metadata: metadata)
    }

    func save(imageData: Data, metadata: SavedCreationMetadata) async throws -> SavedCreationModel {
        try writeAndInsert(data: imageData, sourceURL: "local://\(UUID().uuidString)", metadata: metadata)
    }

    private func writeAndInsert(data: Data, sourceURL: String, metadata: SavedCreationMetadata) throws -> SavedCreationModel {
        let fileName = "\(UUID().uuidString).jpg"
        let directory = try savedCreationsDirectory()
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw SavedCreationsError.writeFailed
        }

        let model = SavedCreationModel(
            sourceImageURL: sourceURL,
            localFileName: fileName,
            prompt: metadata.prompt,
            themeName: metadata.themeName,
            monthLabel: metadata.monthLabel,
            projectID: metadata.projectID
        )
        context.insert(model)
        try context.save()
        return model
    }

    func loadAll() async -> [SavedCreationModel] {
        let descriptor = FetchDescriptor<SavedCreationModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func loadImage(for creation: SavedCreationModel) -> UIImage? {
        guard let directory = try? savedCreationsDirectory() else { return nil }
        let fileURL = directory.appendingPathComponent(creation.localFileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func delete(_ creation: SavedCreationModel) async throws {
        if let directory = try? savedCreationsDirectory() {
            let fileURL = directory.appendingPathComponent(creation.localFileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        context.delete(creation)
        try context.save()
    }

    private func savedCreationsDirectory() throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = docs.appendingPathComponent(directoryName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}
