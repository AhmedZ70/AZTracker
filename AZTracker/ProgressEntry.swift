import Foundation
import CoreData

@objc(ProgressEntry)
public class ProgressEntry: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProgressEntry> {
        return NSFetchRequest<ProgressEntry>(entityName: "ProgressEntry")
    }
    
    @NSManaged public var entryDate: Date?
    @NSManaged public var weight: Double
    @NSManaged public var runTimeSeconds: Int32
    @NSManaged public var completionRate: Double
    @NSManaged public var notes: String?
    @NSManaged public var frontPhoto: Data?
    @NSManaged public var backPhoto: Data?
    @NSManaged public var sidePhoto: Data?
}

extension ProgressEntry: Identifiable {
    public var id: NSManagedObjectID {
        return objectID
    }
    
    var formattedDate: String {
        entryDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date"
    }
    
    var formattedRunTime: String {
        guard runTimeSeconds > 0 else { return "N/A" }
        let minutes = runTimeSeconds / 60
        let seconds = runTimeSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedWeight: String {
        weight != 0 ? String(format: "%.1f lbs", weight) : "N/A" // Weight is already in lbs
    }
    
    var formattedCompletionRate: String {
        completionRate != 0 ? String(format: "%.0f%%", completionRate) : "N/A"
    }
} 