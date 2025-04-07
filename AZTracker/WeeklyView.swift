import SwiftUI

struct WeeklyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedWeekStart = Date().startOfWeek
    
    // Use @FetchRequest for the week's DayRecords
    @FetchRequest private var weekRecords: FetchedResults<DayRecord>
    
    init() {
        // Initialize fetch request for the current week
        let calendar = Calendar.current
        let weekStart = Date().startOfWeek
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        let predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                  weekStart as NSDate,
                                  weekEnd as NSDate)
        
        _weekRecords = FetchRequest(
            entity: DayRecord.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \DayRecord.date, ascending: true)],
            predicate: predicate
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Week Navigation
                    HStack {
                        Button(action: { moveWeek(by: -7) }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.red)
                        }
                        
                        Text(getWeekRangeText())
                            .font(.headline)
                        
                        Button(action: { moveWeek(by: 7) }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    
                    // Week Grid
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                        ForEach(0..<7) { dayOffset in
                            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedWeekStart) {
                                WeekDayCard(date: date)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Weekly Overview")
            .onChange(of: selectedWeekStart) { _ in
                updateWeekPredicate()
            }
        }
    }
    
    private func updateWeekPredicate() {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: selectedWeekStart)!
        
        // Update fetch request predicate
        weekRecords.nsPredicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            selectedWeekStart as NSDate,
                                            weekEnd as NSDate)
        
        // Ensure records exist for the week
        var currentDate = selectedWeekStart
        while currentDate < weekEnd {
            _ = CoreDataManager.shared.getOrCreateDayRecord(for: currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
    
    private func getWeekRangeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        guard let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeekStart) else {
            return ""
        }
        
        return "\(formatter.string(from: selectedWeekStart)) - \(formatter.string(from: weekEnd))"
    }
    
    private func moveWeek(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedWeekStart) {
            selectedWeekStart = newDate
        }
    }
}

struct WeekDayCard: View {
    let date: Date
    @Environment(\.managedObjectContext) private var viewContext
    
    // Use @FetchRequest for the day's record
    @FetchRequest private var dayRecords: FetchedResults<DayRecord>
    
    private var dayRecord: DayRecord? {
        dayRecords.first
    }
    
    init(date: Date) {
        self.date = date
        
        // Initialize fetch request for this specific date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                  startOfDay as NSDate,
                                  endOfDay as NSDate)
        
        _dayRecords = FetchRequest(
            entity: DayRecord.entity(),
            sortDescriptors: [],
            predicate: predicate
        )
        
        // Ensure record exists
        _ = CoreDataManager.shared.getOrCreateDayRecord(for: date)
    }
    
    private var workout: WorkoutManager.WorkoutDay {
        WorkoutManager.shared.getWorkoutForDate(date)
    }
    
    private var isHighCarb: Bool {
        WorkoutManager.shared.isHighCarbDay(date)
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var isFullRestDay: Bool {
        dayOfWeek == "Sunday"
    }
    
    private var isPartialRestDay: Bool {
        dayOfWeek == "Wednesday"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date Header
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide)))
                    .font(.headline)
                Spacer()
                if Calendar.current.isDateInToday(date) {
                    Text("Today")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Workout Focus
            HStack {
                Image(systemName: isFullRestDay ? "moon.zzz.fill" : (workout.exercises.isEmpty ? "figure.walk" : "dumbbell.fill"))
                    .foregroundColor(isFullRestDay ? .blue : (workout.exercises.isEmpty ? .green : .red))
                Text(isFullRestDay ? "Full Rest Day" : (isPartialRestDay ? "Cardio Only" : workout.name))
                    .font(.subheadline)
            }
            
            // Carb Type
            HStack {
                Image(systemName: isHighCarb ? "flame.fill" : "leaf.fill")
                    .foregroundColor(isHighCarb ? .red : .green)
                Text(isHighCarb ? "High Carb" : "Low Carb")
                    .font(.caption)
                    .foregroundColor(isHighCarb ? .red : .green)
            }
            
            Divider()
            
            // Progress Dots
            HStack(spacing: 12) {
                if !isFullRestDay {
                    ProgressDot(title: "Run", isCompleted: dayRecord?.didRun ?? false)
                }
                if !isFullRestDay && !isPartialRestDay {
                    ProgressDot(title: "Lift", isCompleted: dayRecord?.didLift ?? false)
                }
                ProgressDot(title: "Meals", isCompleted: dayRecord?.mealsCompleted ?? false)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct ProgressDot: View {
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        VStack {
            Circle()
                .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

extension Date {
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
}

#Preview {
    WeeklyView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 