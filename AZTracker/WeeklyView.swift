import SwiftUI

struct WeeklyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let weekDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    @State private var selectedWeekStart = Date().startOfWeek
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Week Selector
                    HStack {
                        Button(action: { selectedWeekStart = selectedWeekStart.addingTimeInterval(-7*24*60*60) }) {
                            Image(systemName: "chevron.left")
                        }
                        
                        Text(weekRangeText)
                            .font(.headline)
                        
                        Button(action: { selectedWeekStart = selectedWeekStart.addingTimeInterval(7*24*60*60) }) {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding()
                    
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(weekDays, id: \.self) { day in
                            WeekDayCard(
                                day: day,
                                date: dateFor(weekday: day),
                                dayRecord: CoreDataManager.shared.getDayRecord(for: dateFor(weekday: day))
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Weekly Split")
        }
    }
    
    var weekRangeText: String {
        let endOfWeek = selectedWeekStart.addingTimeInterval(6*24*60*60)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: selectedWeekStart)) - \(formatter.string(from: endOfWeek))"
    }
    
    func dateFor(weekday: String) -> Date {
        let weekdayIndex = weekDays.firstIndex(of: weekday) ?? 0
        return selectedWeekStart.addingTimeInterval(Double(weekdayIndex) * 24*60*60)
    }
}

struct WeekDayCard: View {
    let day: String
    let date: Date
    let dayRecord: DayRecord?
    
    var workoutFocus: String {
        switch day {
        case "Monday": return "Legs"
        case "Tuesday": return "Arms"
        case "Wednesday": return "Rest"
        case "Thursday": return "Chest"
        case "Friday": return "Back"
        case "Saturday": return "Shoulders"
        default: return "Rest"
        }
    }
    
    var cardioDescription: String {
        switch day {
        case "Monday": return "Moderate 5K"
        case "Tuesday": return "Easy 3-4K"
        case "Wednesday": return "Recovery Walk/5K"
        case "Thursday": return "Intervals 4×800m"
        case "Friday": return "Optional Walk"
        case "Saturday": return "5K Best Effort"
        default: return "Full Rest"
        }
    }
    
    var carbType: String {
        return day == "Monday" ? "High Carb" : "Low Carb"
    }
    
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day Header
            HStack {
                Text(day)
                    .font(.title2)
                    .bold()
                Spacer()
                Text(carbType)
                    .font(.subheadline)
                    .foregroundColor(carbType == "High Carb" ? .red : .gray)
            }
            
            // Workout Details
            HStack(spacing: 20) {
                // Cardio
                VStack(alignment: .leading) {
                    Label {
                        Text("Cardio")
                            .font(.subheadline)
                            .bold()
                    } icon: {
                        Image(systemName: "figure.run")
                    }
                    Text(cardioDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Workout
                VStack(alignment: .leading) {
                    Label {
                        Text("Workout")
                            .font(.subheadline)
                            .bold()
                    } icon: {
                        Image(systemName: "dumbbell.fill")
                    }
                    Text(workoutFocus)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Progress Indicators
            HStack(spacing: 8) {
                ProgressDot(
                    color: .blue,
                    label: "Cardio",
                    isCompleted: dayRecord?.didRun ?? false
                )
                ProgressDot(
                    color: .green,
                    label: "Workout",
                    isCompleted: dayRecord?.didLift ?? false
                )
                ProgressDot(
                    color: .orange,
                    label: "Meals",
                    isCompleted: dayRecord?.mealsCompleted ?? false
                )
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.red : Color.clear, lineWidth: 2)
        )
    }
}

struct ProgressDot: View {
    let color: Color
    let label: String
    let isCompleted: Bool
    
    var body: some View {
        VStack {
            Circle()
                .fill(isCompleted ? color : color.opacity(0.3))
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}

#Preview {
    WeeklyView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 