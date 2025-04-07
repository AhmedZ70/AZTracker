import SwiftUI

struct MealPlanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var selectedMealOptions: [Int: Int] = [:] // [mealNumber: optionIndex]
    
    // Use @FetchRequest for DayRecord
    @FetchRequest private var dayRecords: FetchedResults<DayRecord>
    
    // Use @FetchRequest for MealLogs
    @FetchRequest private var mealLogs: FetchedResults<MealLog>
    
    private var dayRecord: DayRecord? {
        dayRecords.first
    }
    
    init() {
        // Initialize the fetch requests with predicates for the selected date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        // DayRecord fetch request
        let dayPredicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        _dayRecords = FetchRequest(
            entity: DayRecord.entity(),
            sortDescriptors: [],
            predicate: dayPredicate
        )
        
        // MealLog fetch request
        let mealPredicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        _mealLogs = FetchRequest(
            entity: MealLog.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \MealLog.mealNumber, ascending: true)],
            predicate: mealPredicate
        )
    }
    
    var isHighCarb: Bool {
        WorkoutManager.shared.isHighCarbDay(selectedDate)
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
                        updateFetchRequests()
                    }
                    
                    // Carb Type Indicator
                    HStack {
                        Image(systemName: isHighCarb ? "flame.fill" : "leaf.fill")
                            .foregroundColor(isHighCarb ? .red : .green)
                        Text(isHighCarb ? "High Carb Day" : "Low Carb Day")
                            .font(.headline)
                            .foregroundColor(isHighCarb ? .red : .green)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    
                    // Meals List
                    ForEach(1...5, id: \.self) { mealNumber in
                        let mealPlan = WorkoutManager.shared.getMealPlan(for: selectedDate, mealNumber: mealNumber)
                        DetailedMealCard(
                            mealNumber: mealNumber,
                            mealPlan: mealPlan,
                            selectedOption: selectedMealOptions[mealNumber] ?? 0,
                            isCompleted: getMealLog(for: mealNumber)?.completed ?? false,
                            onOptionSelect: { option in
                                selectedMealOptions[mealNumber] = option
                            },
                            onToggle: { completed in
                                toggleMeal(number: mealNumber, completed: completed)
                            }
                        )
                    }
                    
                    // Post-Workout Shake
                    if !isRestDay() {
                        let shake = WorkoutManager.shared.getPostWorkoutShake(isHighCarb: isHighCarb)
                        PostWorkoutShakeCard(
                            shake: shake,
                            isCompleted: dayRecord?.shakeCompleted ?? false,
                            onToggle: toggleShake
                        )
                        .padding(.horizontal)
                    }
                    
                    // Comfort Food
                    let comfortFood = WorkoutManager.shared.getComfortFood()
                    ComfortFoodCard(comfortFood: comfortFood)
                        .padding(.horizontal)
                    
                    // Daily Dark Chocolate Note
                    VStack(alignment: .leading) {
                        Text("Daily Treat")
                            .font(.headline)
                        Text("You may have 2 squares of 75% dark chocolate daily to curb appetite")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Meal Plan")
            .onAppear {
                updateFetchRequests()
            }
        }
    }
    
    private func updateFetchRequests() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        
        // Get or create the day record
        let record = CoreDataManager.shared.getOrCreateDayRecord(for: selectedDate)
        
        // Update fetch request predicates
        dayRecords.nsPredicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        mealLogs.nsPredicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        
        // Ensure meal logs exist
        for mealNumber in 1...5 {
            _ = CoreDataManager.shared.getOrCreateMealLog(for: selectedDate, mealNumber: Int16(mealNumber))
        }
    }
    
    private func getMealLog(for mealNumber: Int) -> MealLog? {
        mealLogs.first { $0.mealNumber == mealNumber }
    }
    
    private func toggleMeal(number: Int, completed: Bool) {
        viewContext.perform {
            if let mealLog = getMealLog(for: number) {
                mealLog.completed = completed
                
                // Update overall meals completion status
                let allMealsCompleted = mealLogs.allSatisfy { $0.completed }
                let shakeCompleted = isRestDay() ? true : (dayRecord?.shakeCompleted ?? false)
                
                // Only set mealsCompleted to true if all meals AND shake (if required) are completed
                dayRecord?.mealsCompleted = allMealsCompleted && shakeCompleted
                
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving meal completion: \(error)")
                }
            }
        }
    }
    
    private func toggleShake(_ completed: Bool) {
        viewContext.perform {
            dayRecord?.shakeCompleted = completed
            
            // Update overall meals completion status
            let allMealsCompleted = mealLogs.allSatisfy { $0.completed }
            
            // Only set mealsCompleted to true if all meals AND shake are completed
            dayRecord?.mealsCompleted = allMealsCompleted && completed
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving shake completion: \(error)")
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

struct DetailedMealCard: View {
    let mealNumber: Int
    let mealPlan: WorkoutManager.MealPlan
    let selectedOption: Int
    let isCompleted: Bool
    let onOptionSelect: (Int) -> Void
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Meal \(mealNumber)")
                        .font(.headline)
                    Text(mealPlan.time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(mealPlan.title)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: .init(
                    get: { isCompleted },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
            
            Divider()
            
            ForEach(0..<mealPlan.options.count, id: \.self) { index in
                let option = mealPlan.options[index]
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Option \(index + 1)")
                            .font(.subheadline)
                            .bold()
                        Spacer()
                        Text("\(option.calories) kcal")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(selectedOption == index ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
                .onTapGesture {
                    onOptionSelect(index)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct PostWorkoutShakeCard: View {
    let shake: WorkoutManager.MealOption
    let isCompleted: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Post-Workout Shake")
                        .font(.headline)
                    Text("Immediately after workout")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: .init(
                    get: { isCompleted },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
            
            Divider()
            
            Text(shake.description)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(shake.calories) kcal")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct ComfortFoodCard: View {
    let comfortFood: WorkoutManager.MealOption
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Comfort Food (Allowed Daily)")
                .font(.headline)
            
            Divider()
            
            Text(comfortFood.description)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(comfortFood.calories) kcal")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    MealPlanView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 