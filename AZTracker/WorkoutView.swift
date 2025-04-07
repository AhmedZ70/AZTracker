import SwiftUI

struct WorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingNotes = false
    @State private var notes = ""
    
    private var workout: WorkoutManager.WorkoutDay {
        WorkoutManager.shared.getWorkoutForDate(selectedDate)
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
                    
                    // Workout Header
                    HStack {
                        Image(systemName: workout.exercises.isEmpty ? "moon.zzz.fill" : "dumbbell.fill")
                            .foregroundColor(workout.exercises.isEmpty ? .blue : .red)
                        Text(workout.name)
                            .font(.title2)
                            .bold()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    
                    if workout.exercises.isEmpty {
                        // Rest Day View
                        VStack(spacing: 12) {
                            Text("Rest Day")
                                .font(.title3)
                            Text("Focus on recovery and mobility")
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingNotes = true
                            }) {
                                Text("Add Recovery Notes")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        // Workout Exercises
                        ForEach(workout.exercises, id: \.name) { exercise in
                            ExerciseLogCard(exercise: exercise, date: selectedDate)
                        }
                    }
                }
            }
            .navigationTitle("Workout")
            .sheet(isPresented: $showingNotes) {
                NavigationView {
                    TextEditor(text: $notes)
                        .padding()
                        .navigationTitle("Recovery Notes")
                        .navigationBarItems(
                            trailing: Button("Save") {
                                // Save notes to Core Data
                                showingNotes = false
                            }
                        )
                }
            }
        }
    }
}

struct ExerciseLogCard: View {
    let exercise: WorkoutManager.Exercise
    let date: Date
    
    @State private var setWeights: [String] = []
    @State private var showingHistory = false
    
    private var lastWeekWeights: [Double] {
        WorkoutManager.shared.getLastWeekWeight(for: exercise.name, on: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                Spacer()
                Button(action: { showingHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                }
            }
            
            // Sets and Reps
            Text("\(exercise.sets) sets × \(exercise.repRange)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Weight Input Fields
            VStack(spacing: 8) {
                ForEach(0..<exercise.sets, id: \.self) { setIndex in
                    HStack {
                        Text("Set \(setIndex + 1)")
                            .font(.subheadline)
                            .frame(width: 60, alignment: .leading)
                        
                        TextField("Weight", text: weightBinding(for: setIndex))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("lbs")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !lastWeekWeights.isEmpty && setIndex < lastWeekWeights.count {
                            Text("Last: \(Int(lastWeekWeights[setIndex]))lbs")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .onAppear {
            // Initialize weights array
            if setWeights.isEmpty {
                setWeights = Array(repeating: "", count: exercise.sets)
                
                // Load saved weights from Core Data
                let log = CoreDataManager.shared.getOrCreateWorkoutLog(for: date, exercise: exercise.name)
                if let savedWeights = log.setWeights {
                    setWeights = savedWeights.map { String(Int($0)) }
                }
            }
        }
        .onChange(of: setWeights) { _ in
            saveWeights()
        }
        .sheet(isPresented: $showingHistory) {
            WorkoutHistoryView(exercise: exercise)
        }
    }
    
    private func weightBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                if index < setWeights.count {
                    return setWeights[index]
                }
                return ""
            },
            set: { newValue in
                while setWeights.count <= index {
                    setWeights.append("")
                }
                setWeights[index] = newValue.filter { "0123456789".contains($0) }
            }
        )
    }
    
    private func saveWeights() {
        let weights = setWeights.map { Double($0) ?? 0.0 }
        let log = CoreDataManager.shared.getOrCreateWorkoutLog(for: date, exercise: exercise.name)
        log.setWeights = weights
        CoreDataManager.shared.saveContext()
    }
}

struct WorkoutHistoryView: View {
    let exercise: WorkoutManager.Exercise
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("History view coming soon...")
                .navigationTitle(exercise.name)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

#Preview {
    WorkoutView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 