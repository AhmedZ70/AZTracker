import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "AZTracker")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Day Record Operations
    
    func getDayRecord(for date: Date) -> DayRecord? {
        let request = DayRecord.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      date.startOfDay as NSDate,
                                      date.endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            let records = try container.viewContext.fetch(request)
            return records.first
        } catch {
            print("Failed to fetch day record: \(error)")
            return nil
        }
    }
    
    func createDayRecord(for date: Date) -> DayRecord {
        let record = DayRecord(context: container.viewContext)
        record.date = date
        record.didRun = false
        record.didLift = false
        record.mealsCompleted = false
        record.supplementsTaken = false
        record.didShake = false
        saveContext()
        return record
    }
    
    func getOrCreateDayRecord(for date: Date) -> DayRecord {
        if let existingRecord = getDayRecord(for: date) {
            return existingRecord
        }
        return createDayRecord(for: date)
    }
    
    // MARK: - Progress Entry Operations
    
    func saveProgressEntry(weight: Double?, runTimeSeconds: Int32?, notes: String?, photo: Data?, completionRate: Double?) {
        let entry = ProgressEntry(context: container.viewContext)
        entry.entryDate = Date()
        entry.weight = weight ?? 0
        entry.runTimeSeconds = runTimeSeconds ?? 0
        entry.notes = notes
        entry.photo = photo
        entry.completionRate = completionRate ?? 0
        saveContext()
    }
    
    func getLatestProgressEntry() -> ProgressEntry? {
        let request = ProgressEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressEntry.entryDate, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let entries = try container.viewContext.fetch(request)
            return entries.first
        } catch {
            print("Failed to fetch latest progress entry: \(error)")
            return nil
        }
    }
    
    func getAllProgressEntries() -> [ProgressEntry] {
        let request = ProgressEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProgressEntry.entryDate, ascending: false)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch progress entries: \(error)")
            return []
        }
    }
    
    // MARK: - Utility Functions
    
    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
} 