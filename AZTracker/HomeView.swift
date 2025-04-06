import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var dayRecord: DayRecord?
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }
    
    var workoutFocus: String {
        switch dayOfWeek {
        case "Monday": return "Leg Day"
        case "Tuesday": return "Arm Day"
        case "Wednesday": return "Rest Day"
        case "Thursday": return "Chest Day"
        case "Friday": return "Back Day"
        case "Saturday": return "Shoulder Day"
        default: return "Rest Day"
        }
    }
    
    var carbType: String {
        return dayOfWeek == "Monday" ? "High Carb" : "Low Carb"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date Picker
                    DatePicker("Select Date",
                             selection: $selectedDate,
                             displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .padding()
                        .onChange(of: selectedDate) { _ in
                            loadDayRecord()
                        }
                    
                    // Day Header
                    VStack(alignment: .leading) {
                        Text("\(dayOfWeek) – \(workoutFocus)")
                            .font(.title)
                            .bold()
                        Text(carbType)
                            .font(.headline)
                            .foregroundColor(carbType == "High Carb" ? .red : .gray)
                    }
                    .padding(.horizontal)
                    
                    // Morning Cardio Section
                    DailyTaskCard(
                        title: "Morning Cardio",
                        description: getMorningCardioDescription(),
                        isCompleted: Binding(
                            get: { dayRecord?.didRun ?? false },
                            set: { newValue in
                                dayRecord?.didRun = newValue
                                saveContext()
                            }
                        ),
                        iconName: "figure.run"
                    )
                    
                    // Evening Workout Section
                    DailyTaskCard(
                        title: "Evening Workout",
                        description: getEveningWorkoutDescription(),
                        isCompleted: Binding(
                            get: { dayRecord?.didLift ?? false },
                            set: { newValue in
                                dayRecord?.didLift = newValue
                                saveContext()
                            }
                        ),
                        iconName: "dumbbell.fill"
                    )
                    
                    // Meals Section
                    DailyTaskCard(
                        title: "Meals",
                        description: "Complete all 5 meals for today",
                        isCompleted: Binding(
                            get: { dayRecord?.mealsCompleted ?? false },
                            set: { newValue in
                                dayRecord?.mealsCompleted = newValue
                                saveContext()
                            }
                        ),
                        iconName: "fork.knife"
                    )
                    
                    // Supplements Section
                    DailyTaskCard(
                        title: "Supplements",
                        description: "Take all scheduled supplements",
                        isCompleted: Binding(
                            get: { dayRecord?.supplementsTaken ?? false },
                            set: { newValue in
                                dayRecord?.supplementsTaken = newValue
                                saveContext()
                            }
                        ),
                        iconName: "pills.fill"
                    )
                    
                    // Post-Workout Shake Section
                    if !isRestDay() {
                        DailyTaskCard(
                            title: "Post-Workout Shake",
                            description: getShakeDescription(),
                            isCompleted: Binding(
                                get: { dayRecord?.didShake ?? false },
                                set: { newValue in
                                    dayRecord?.didShake = newValue
                                    saveContext()
                                }
                            ),
                            iconName: "cup.and.saucer.fill"
                        )
                    }
                }
            }
            .navigationTitle("Daily Dashboard")
            .onAppear {
                loadDayRecord()
            }
        }
    }
    
    private func loadDayRecord() {
        dayRecord = CoreDataManager.shared.getOrCreateDayRecord(for: selectedDate)
    }
    
    private func saveContext() {
        CoreDataManager.shared.saveContext()
    }
    
    private func isRestDay() -> Bool {
        return dayOfWeek == "Wednesday" || dayOfWeek == "Sunday"
    }
    
    private func getMorningCardioDescription() -> String {
        switch dayOfWeek {
        case "Monday": return "Moderate 5K run (or Tempo run)"
        case "Tuesday": return "Easy jog 3-4K (Recovery run)"
        case "Wednesday": return "Recovery 5K or incline walk"
        case "Thursday": return "Intervals – 4×800m fast repeats"
        case "Friday": return "Rest or optional 25-min walk"
        case "Saturday": return "5K run (best effort for time)"
        default: return "Full Rest (no cardio)"
        }
    }
    
    private func getEveningWorkoutDescription() -> String {
        switch dayOfWeek {
        case "Monday": return "Legs workout"
        case "Tuesday": return "Arms workout"
        case "Wednesday": return "Rest day"
        case "Thursday": return "Chest workout"
        case "Friday": return "Back workout"
        case "Saturday": return "Shoulders workout"
        default: return "Rest day"
        }
    }
    
    private func getShakeDescription() -> String {
        if dayOfWeek == "Monday" {
            return "Post-workout shake with carb powder"
        } else {
            return "Post-workout shake with banana"
        }
    }
}

struct DailyTaskCard: View {
    let title: String
    let description: String
    @Binding var isCompleted: Bool
    let iconName: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $isCompleted)
                    .labelsHidden()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 