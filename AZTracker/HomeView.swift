import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    
    // Use @FetchRequest instead of @State for DayRecord
    @FetchRequest private var dayRecords: FetchedResults<DayRecord>
    
    private var dayRecord: DayRecord? {
        dayRecords.first
    }
    
    init() {
        // Initialize the fetch request with a predicate for the selected date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        
        _dayRecords = FetchRequest(
            entity: DayRecord.entity(),
            sortDescriptors: [],
            predicate: predicate
        )
    }
    
    var isHighCarb: Bool {
        WorkoutManager.shared.isHighCarbDay(selectedDate)
    }
    
    var workout: WorkoutManager.WorkoutDay {
        WorkoutManager.shared.getWorkoutForDate(selectedDate)
    }
    
    var cardioDescription: String {
        selectedDate.isWeekend ? "Rest Day" : "30 min fasted cardio"
    }
    
    var totalCalories: Int {
        // Calculate total calories based on meal plan
        var total = 0
        for mealNumber in 1...5 {
            let mealPlan = WorkoutManager.shared.getMealPlan(for: selectedDate, mealNumber: mealNumber)
            total += mealPlan.options.first?.calories ?? 0
        }
        
        if !isRestDay() {
            let shake = WorkoutManager.shared.getPostWorkoutShake(isHighCarb: isHighCarb)
            total += shake.calories
        }
        
        let comfortFood = WorkoutManager.shared.getComfortFood()
        total += comfortFood.calories
        
        return total
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Picker
                    DatePicker("Select Date",
                             selection: $selectedDate,
                             displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .padding()
                        .onChange(of: selectedDate) { _ in
                            updateFetchRequest()
                        }
                    
                    // Day Overview
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                            .font(.title)
                            .bold()
                        
                        HStack {
                            Image(systemName: isHighCarb ? "flame.fill" : "leaf.fill")
                                .foregroundColor(isHighCarb ? .red : .green)
                            Text(isHighCarb ? "High Carb Day" : "Low Carb Day")
                                .foregroundColor(isHighCarb ? .red : .green)
                        }
                        
                        Text("Target Calories: \(totalCalories) kcal")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Morning Cardio
                    DailyTaskCard(
                        title: "Morning Cardio",
                        subtitle: cardioDescription,
                        systemImage: "figure.run",
                        isCompleted: dayRecord?.didRun ?? false,
                        isEnabled: true,
                        onToggle: { toggleTask(\.didRun) }
                    )
                    
                    // Workout
                    DailyTaskCard(
                        title: "Evening Workout",
                        subtitle: workout.exercises.isEmpty ? "Rest Day" : "\(workout.name) Day",
                        systemImage: "dumbbell.fill",
                        isCompleted: dayRecord?.didLift ?? false,
                        isEnabled: true,
                        onToggle: { toggleTask(\.didLift) }
                    )
                    
                    // Meals
                    DailyTaskCard(
                        title: "Meals",
                        subtitle: "5 meals + post-workout shake",
                        systemImage: "fork.knife",
                        isCompleted: dayRecord?.mealsCompleted ?? false,
                        isEnabled: false,
                        onToggle: {}
                    )
                    
                    // Supplements
                    DailyTaskCard(
                        title: "Supplements",
                        subtitle: "Daily supplements taken",
                        systemImage: "pills.fill",
                        isCompleted: dayRecord?.supplementsCompleted ?? false,
                        isEnabled: true,
                        onToggle: { toggleTask(\.supplementsCompleted) }
                    )
                    
                    // Notes Section
                    if let note = dayRecord?.note, !note.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Notes")
                                .font(.headline)
                            Text(note)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                updateFetchRequest()
            }
        }
    }
    
    private func updateFetchRequest() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        
        // Get or create the day record
        let record = CoreDataManager.shared.getOrCreateDayRecord(for: selectedDate)
        
        // Update the fetch request's predicate
        dayRecords.nsPredicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
    }
    
    private func toggleTask<Value>(_ keyPath: ReferenceWritableKeyPath<DayRecord, Value>) where Value == Bool {
        guard let record = dayRecord else { return }
        
        viewContext.perform {
            record[keyPath: keyPath].toggle()
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    private func isRestDay() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: selectedDate)
        return dayOfWeek == "Wednesday" || dayOfWeek == "Sunday"
    }
}

struct DailyTaskCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isCompleted: Bool
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(isCompleted ? .green : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isEnabled {
                Toggle("", isOn: .init(
                    get: { isCompleted },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            } else {
                // Show a non-interactive indicator for disabled toggles
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 22, height: 22)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

extension Date {
    var isWeekend: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return weekday == 1 || weekday == 7 // 1 is Sunday, 7 is Saturday
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 