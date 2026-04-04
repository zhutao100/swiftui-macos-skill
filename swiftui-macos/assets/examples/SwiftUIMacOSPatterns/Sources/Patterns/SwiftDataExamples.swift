#if canImport(SwiftData)
  import Foundation
  import SwiftData

  @Model
  public final class Note {
    public var title: String = ""
    public var createdAt: Date = Date.now

    public init(title: String) {
      self.title = title
    }
  }

  @ModelActor
  public actor NoteStore {
    public func add(title: String) throws {
      modelContext.insert(Note(title: title))
      try modelContext.save()
    }
  }
#endif
