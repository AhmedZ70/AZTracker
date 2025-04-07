import CoreData
import SwiftUI
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AZTracker")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - Day Records
    func getOrCreateDayRecord(for date: Date) -> DayRecord {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let fetchRequest: NSFetchRequest<DayRecord> = DayRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        
        if let existingRecord = try? viewContext.fetch(fetchRequest).first {
            return existingRecord
        }
        
        let newRecord = DayRecord(context: viewContext)
        newRecord.date = startOfDay
        newRecord.cardioCompleted = false
        newRecord.workoutCompleted = false
        newRecord.mealsCompleted = false
        newRecord.supplementsCompleted = false
        saveContext()
        
        return newRecord
    }
    
    // MARK: - Progress Entries
    func createProgressEntry(date: Date, weight: Double? = nil, runTime: Int32? = nil, completion: Double? = nil, notes: String? = nil, photo: Data? = nil) -> ProgressEntry {
        let entry = ProgressEntry(context: viewContext)
        entry.entryDate = date
        entry.weight = weight ?? 0.0
        entry.runTimeSeconds = runTime ?? 0
        entry.completionRate = completion ?? 0.0
        entry.notes = notes
        entry.photo = photo
        saveContext()
        return entry
    }
    
    func getProgressEntries(startDate: Date? = nil, endDate: Date? = nil) -> [ProgressEntry] {
        let request = ProgressEntry.fetchRequest()
        
        if let start = startDate, let end = endDate {
            request.predicate = NSPredicate(format: "entryDate >= %@ AND entryDate <= %@", start as NSDate, end as NSDate)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "entryDate", ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching progress entries: \(error)")
            return []
        }
    }
    
    func deleteProgressEntry(_ entry: ProgressEntry) {
        viewContext.delete(entry)
        saveContext()
    }
    
    // MARK: - Workout Logging
    func getOrCreateWorkoutLog(for date: Date, exercise: String) -> WorkoutLog {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let fetchRequest: NSFetchRequest<WorkoutLog> = WorkoutLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@ AND exerciseName == %@", 
                                           startOfDay as NSDate, 
                                           exercise)
        
        if let existingLog = try? viewContext.fetch(fetchRequest).first {
            return existingLog
        }
        
        let newLog = WorkoutLog(context: viewContext)
        newLog.date = startOfDay
        newLog.exerciseName = exercise
        newLog.setWeights = []
        newLog.notes = ""
        saveContext()
        
        return newLog
    }
    
    func updateWorkoutLog(_ log: WorkoutLog, weights: [Double]) {
        log.setWeights = weights
        saveContext()
    }
    
    // MARK: - Meal Tracking
    func getOrCreateMealLog(for date: Date, mealNumber: Int16) -> MealLog {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let fetchRequest: NSFetchRequest<MealLog> = MealLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@ AND mealNumber == %d", 
                                           startOfDay as NSDate, 
                                           mealNumber)
        
        if let existingLog = try? viewContext.fetch(fetchRequest).first {
            return existingLog
        }
        
        let newLog = MealLog(context: viewContext)
        newLog.date = startOfDay
        newLog.mealNumber = mealNumber
        newLog.completed = false
        newLog.optionSelected = 1
        newLog.calories = 0
        saveContext()
        
        return newLog
    }
    
    // MARK: - Utility Functions
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func deleteAllData() {
        let entities = container.managedObjectModel.entities
        entities.forEach { entity in
            guard let entityName = entity.name else { return }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? container.persistentStoreCoordinator.execute(deleteRequest, with: viewContext)
        }
        saveContext()
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
