import SwiftUI

struct MealPlanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var dayRecord: DayRecord?
    @State private var completedMeals: Set<Int> = []
    
    var isHighCarb: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: selectedDate)
        return dayOfWeek == "Monday"
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
                            loadDayRecord()
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
                        MealCard(
                            mealNumber: mealNumber,
                            isHighCarb: isHighCarb,
                            isCompleted: completedMeals.contains(mealNumber),
                            onToggle: { completed in
                                if completed {
                                    completedMeals.insert(mealNumber)
                                } else {
                                    completedMeals.remove(mealNumber)
                                }
                                updateMealsCompletion()
                            }
                        )
                    }
                    
                    // Post-Workout Shake
                    if !isRestDay() {
                        PostWorkoutShakeCard(isHighCarb: isHighCarb)
                            .padding(.horizontal)
                    }
                    
                    // Note about dark chocolate
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
                loadDayRecord()
            }
        }
    }
    
    private func loadDayRecord() {
        dayRecord = CoreDataManager.shared.getOrCreateDayRecord(for: selectedDate)
        completedMeals.removeAll()
        if dayRecord?.mealsCompleted == true {
            completedMeals = Set(1...5)
        }
    }
    
    private func updateMealsCompletion() {
        dayRecord?.mealsCompleted = completedMeals.count == 5
        CoreDataManager.shared.saveContext()
    }
    
    private func isRestDay() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: selectedDate)
        return dayOfWeek == "Wednesday" || dayOfWeek == "Sunday"
    }
}

struct MealCard: View {
    let mealNumber: Int
    let isHighCarb: Bool
    let isCompleted: Bool
    let onToggle: (Bool) -> Void
    
    var mealTime: String {
        switch mealNumber {
        case 1: return "7:30 AM"
        case 2: return "10:00 AM"
        case 3: return "1:00 PM"
        case 4: return "4:00 PM"
        case 5: return "7:00 PM"
        default: return ""
        }
    }
    
    var mealOptions: (String, String) {
        if isHighCarb {
            switch mealNumber {
            case 1:
                return ("2 whole eggs + 4 egg whites, 2 slices whole wheat gluten-free toast, + 1 apple",
                       "1.5 scoops whey isolate with 60g oatmeal (or 50g cream of rice), 1 cup strawberries")
            case 2:
                return ("1 scoop Whey Protein Isolate with 250 ml almond milk",
                       "1 scoop MRE Lite (Redcon1) with 200 ml almond milk")
            case 3:
                return ("150g chicken breast, 150g white rice, 2 peeled cucumbers (with salt and lemon)",
                       "150g chicken breast, 170g baked potato, 2 cucumbers (seasoned with salt and lemon)")
            case 4:
                return ("250g shrimp, 150g white rice, plus cooked mushrooms and mixed vegetables",
                       "200g chicken breast, 200g baked potato, with cooked greens or fresh veggies")
            case 5:
                return ("Cheat Meal: Hamburger or cheeseburger with fries, sweet potato fries, or onion rings",
                       "Cheat Meal: Steak (any cut) with baked or mashed potato")
            default:
                return ("", "")
            }
        } else {
            switch mealNumber {
            case 1:
                return ("2 whole eggs + 6 egg whites, 2 slices gluten-free toast, 1 apple",
                       "1.5 scoops whey isolate, 50g oats, 150g strawberries")
            case 2:
                return ("1 scoop Whey Protein Isolate with 250 ml almond milk + 1 orange",
                       "1 scoop MRE Lite (Redcon1) with 200 ml almond milk + 1 orange")
            case 3:
                return ("150g chicken breast, 100g white rice, 2 peeled cucumbers",
                       "150g chicken breast, 120g baked potato, 2 cucumbers")
            case 4:
                return ("1 can tuna (in water) on salad with vinegar dressing",
                       "150g chicken breast on salad with vinegar dressing")
            case 5:
                return ("150g chicken breast with cucumber and 120g basmati rice",
                       "200g shrimp with 140g baked potato and vegetables")
            default:
                return ("", "")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meal \(mealNumber) (\(mealTime))")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isCompleted },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                MealOptionView(optionNumber: 1, description: mealOptions.0)
                MealOptionView(optionNumber: 2, description: mealOptions.1)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct MealOptionView: View {
    let optionNumber: Int
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Option \(optionNumber)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(description)
                .font(.body)
        }
    }
}

struct PostWorkoutShakeCard: View {
    let isHighCarb: Bool
    
    var shakeDescription: String {
        let baseIngredients = """
        • 1-2 scoops whey isolate
        • 1 scoop EAA (5-10g)
        • 5g glutamine
        • 5g creatine monohydrate
        • 2g L-carnitine tartrate
        """
        
        let carbSource = isHighCarb ?
            "• 1 scoop cluster bomb (carb powder)" :
            "• 1 banana (for carbs and potassium)"
        
        return baseIngredients + "\n" + carbSource
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Post-Workout Shake (10:15 PM)")
                .font(.headline)
            
            Text(shakeDescription)
                .font(.body)
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