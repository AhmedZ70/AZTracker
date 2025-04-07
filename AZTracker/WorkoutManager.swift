import Foundation

class WorkoutManager {
    static let shared = WorkoutManager()
    
    // MARK: - Workout Schedule
    struct Exercise {
        let name: String
        let sets: Int
        let repRange: String
        var isAMRAP: Bool = false
        var isPyramid: Bool = false
    }
    
    struct WorkoutDay {
        let name: String
        let exercises: [Exercise]
    }
    
    // MARK: - Meal Planning
    struct MealOption {
        let description: String
        let calories: Int
    }
    
    struct MealPlan {
        let time: String
        let title: String
        let options: [MealOption]
    }
    
    // Low Carb Day Meals
    let lowCarbMeals: [MealPlan] = [
        MealPlan(
            time: "7:30 AM",
            title: "Breakfast",
            options: [
                MealOption(
                    description: "2 whole eggs + 6 egg whites + 2 slices gluten-free toast + apple + multivitamin + 2 omega-3 capsules",
                    calories: 515
                ),
                MealOption(
                    description: "1.5 scoops whey isolate + 50g oats + 150g strawberries + multivitamin + 2 omega-3",
                    calories: 540
                )
            ]
        ),
        MealPlan(
            time: "10:00 AM",
            title: "Mid-Morning Snack",
            options: [
                MealOption(
                    description: "1 scoop whey isolate + 250ml almond milk + orange",
                    calories: 212
                ),
                MealOption(
                    description: "1 scoop MRE Lite + 200ml almond milk + orange",
                    calories: 210
                )
            ]
        ),
        MealPlan(
            time: "1:00 PM",
            title: "Lunch",
            options: [
                MealOption(
                    description: "150g chicken breast + 100g white rice + 2 cucumbers",
                    calories: 430
                ),
                MealOption(
                    description: "150g chicken + 120g baked potato + 2 cucumbers",
                    calories: 440
                )
            ]
        ),
        MealPlan(
            time: "4:00 PM",
            title: "Pre-Workout",
            options: [
                MealOption(
                    description: "1 can tuna (in water) + salad (lettuce, parsley, green onion, cucumber, green peppers, vinegar)",
                    calories: 150
                ),
                MealOption(
                    description: "150g chicken breast + same salad",
                    calories: 280
                )
            ]
        ),
        MealPlan(
            time: "7:00 PM",
            title: "Dinner",
            options: [
                MealOption(
                    description: "150g chicken with mustard + 120g basmati rice + cucumber",
                    calories: 430
                ),
                MealOption(
                    description: "200g shrimp + 140g baked potato + cooked vegetables",
                    calories: 410
                )
            ]
        )
    ]
    
    // High Carb Day Meals
    let highCarbMeals: [MealPlan] = [
        MealPlan(
            time: "7:30 AM",
            title: "Breakfast",
            options: [
                MealOption(
                    description: "2 whole eggs + 4 egg whites + 2 slices whole wheat gluten-free toast + apple + multivitamin + 2 omega-3",
                    calories: 463
                ),
                MealOption(
                    description: "1.5 scoops whey isolate + 60g oatmeal + 1 cup strawberries + multivitamin + 2 omega-3",
                    calories: 555
                )
            ]
        ),
        MealPlan(
            time: "10:00 AM",
            title: "Mid-Morning Snack",
            options: [
                MealOption(
                    description: "1 scoop whey isolate + 250ml almond milk",
                    calories: 150
                ),
                MealOption(
                    description: "1 scoop MRE Lite + 200ml almond milk",
                    calories: 150
                )
            ]
        ),
        MealPlan(
            time: "1:00 PM",
            title: "Lunch",
            options: [
                MealOption(
                    description: "150g chicken + 150g white rice + 2 cucumbers",
                    calories: 480
                ),
                MealOption(
                    description: "150g chicken + 170g baked potato + 2 cucumbers",
                    calories: 440
                )
            ]
        ),
        MealPlan(
            time: "4:00 PM",
            title: "Pre-Workout",
            options: [
                MealOption(
                    description: "250g shrimp + 150g white rice + mushrooms + vegetables",
                    calories: 450
                ),
                MealOption(
                    description: "200g chicken + 200g baked potato + green veggies",
                    calories: 430
                )
            ]
        ),
        MealPlan(
            time: "7:00 PM",
            title: "Dinner (Cheat Meal)",
            options: [
                MealOption(
                    description: "Hamburger or cheeseburger + fries/sweet potato fries/onion rings",
                    calories: 850
                ),
                MealOption(
                    description: "Steak + baked or mashed potato",
                    calories: 700
                )
            ]
        )
    ]
    
    let workoutSchedule: [WorkoutDay] = [
        // Monday - Legs
        WorkoutDay(name: "Legs", exercises: [
            Exercise(name: "Hack Squats", sets: 4, repRange: "10-12"),
            Exercise(name: "Leg Press", sets: 4, repRange: "10-12"),
            Exercise(name: "Lunges", sets: 4, repRange: "12-15"),
            Exercise(name: "Leg Curls", sets: 4, repRange: "10-12"),
            Exercise(name: "Leg Extensions", sets: 4, repRange: "12-15"),
            Exercise(name: "Calf Raises", sets: 6, repRange: "15-20")
        ]),
        
        // Tuesday - Arms & Shoulders
        WorkoutDay(name: "Arms & Shoulders", exercises: [
            Exercise(name: "Seated Dumbbell Shoulder Press", sets: 3, repRange: "8-10"),
            Exercise(name: "Dumbbell Lateral Raises", sets: 3, repRange: "12-15"),
            Exercise(name: "Barbell Bicep Curls", sets: 3, repRange: "8-10"),
            Exercise(name: "Alternating Dumbbell Curls", sets: 2, repRange: "10-12"),
            Exercise(name: "Hammer Curls", sets: 2, repRange: "12-15"),
            Exercise(name: "Close-Grip Bench Press", sets: 3, repRange: "8-10"),
            Exercise(name: "Overhead Triceps Extension", sets: 2, repRange: "10-12"),
            Exercise(name: "Triceps Rope Pushdowns", sets: 3, repRange: "12-15")
        ]),
        
        // Wednesday - Rest
        WorkoutDay(name: "Rest", exercises: []),
        
        // Thursday - Chest & Triceps
        WorkoutDay(name: "Chest & Triceps", exercises: [
            Exercise(name: "Bench Press", sets: 4, repRange: "8-10"),
            Exercise(name: "Incline Dumbbell Press", sets: 3, repRange: "10-12"),
            Exercise(name: "Chest Flies", sets: 3, repRange: "12-15"),
            Exercise(name: "Incline Bench Press", sets: 7, repRange: "Pyramid 15→6", isPyramid: true),
            Exercise(name: "Tricep Dips", sets: 4, repRange: "10-12"),
            Exercise(name: "Tricep Pushdowns", sets: 6, repRange: "12-15"),
            Exercise(name: "Overhead Tricep Extension", sets: 6, repRange: "12-15")
        ]),
        
        // Friday - Back & Biceps
        WorkoutDay(name: "Back & Biceps", exercises: [
            Exercise(name: "Pull-Ups", sets: 4, repRange: "8-10"),
            Exercise(name: "Bent Over Rows", sets: 4, repRange: "10-12"),
            Exercise(name: "Lat Pulldowns", sets: 4, repRange: "12-15"),
            Exercise(name: "Single-Arm Dumbbell Rows", sets: 4, repRange: "6-10"),
            Exercise(name: "Hyper Extensions", sets: 4, repRange: "15"),
            Exercise(name: "Barbell Curls", sets: 4, repRange: "10-12"),
            Exercise(name: "Hammer Curls", sets: 4, repRange: "12-15"),
            Exercise(name: "Seated Rows", sets: 4, repRange: "12-15")
        ]),
        
        // Saturday - Shoulders & Triceps
        WorkoutDay(name: "Shoulders & Triceps", exercises: [
            Exercise(name: "Shoulder Press", sets: 4, repRange: "8-10"),
            Exercise(name: "Lateral Raises", sets: 4, repRange: "12-15"),
            Exercise(name: "Front Raises", sets: 4, repRange: "12-15"),
            Exercise(name: "Reverse Machine Flies", sets: 4, repRange: "8-10"),
            Exercise(name: "Reverse EZ Bar Pushdowns", sets: 4, repRange: "10-12"),
            Exercise(name: "Skull Crushers", sets: 4, repRange: "12-15"),
            Exercise(name: "Rope Tricep Pushdowns", sets: 4, repRange: "12-15")
        ]),
        
        // Sunday - Rest
        WorkoutDay(name: "Rest", exercises: [])
    ]
    
    // MARK: - Utility Functions
    func getWorkoutForDate(_ date: Date) -> WorkoutDay {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Convert to 0-based index (Sunday = 0)
        let index = (weekday + 5) % 7
        return workoutSchedule[index]
    }
    
    func getLastWeekWeight(for exercise: String, on date: Date) -> [Double] {
        let calendar = Calendar.current
        guard let lastWeek = calendar.date(byAdding: .day, value: -7, to: date) else {
            return []
        }
        
        let log = CoreDataManager.shared.getOrCreateWorkoutLog(for: lastWeek, exercise: exercise)
        return log.setWeights as? [Double] ?? []
    }
    
    func getMealPlan(for date: Date, mealNumber: Int) -> MealPlan {
        let isHighCarb = isHighCarbDay(date)
        let meals = isHighCarb ? highCarbMeals : lowCarbMeals
        return meals[mealNumber - 1]
    }
    
    func isHighCarbDay(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: date)
        return dayOfWeek == "Monday"
    }
    
    func getPostWorkoutShake(isHighCarb: Bool) -> MealOption {
        if isHighCarb {
            return MealOption(
                description: "2 scoops whey isolate + EAA + 5g glutamine + 5g creatine + 2g L-carnitine + 1 scoop carb powder",
                calories: 390
            )
        } else {
            return MealOption(
                description: "1 scoop whey isolate + EAA + 5g glutamine + 5g creatine + 2g L-carnitine + 1 banana",
                calories: 300
            )
        }
    }
    
    func getComfortFood() -> MealOption {
        return MealOption(
            description: "Rice Cake + 1 tbsp Peanut Butter (sugar-free PB recommended)",
            calories: 130
        )
    }
} 