import SwiftUI
import PhotosUI

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var weight: String = ""
    @State private var runTime: String = ""
    @State private var notes: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProgressEntry.entryDate, ascending: false)],
        animation: .default)
    private var progressEntries: FetchedResults<ProgressEntry>
    
    var latestEntry: ProgressEntry? {
        return progressEntries.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Stats Section
                    CurrentStatsCard(latestEntry: latestEntry)
                    
                    // New Entry Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add New Entry")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Weight Input
                        VStack(alignment: .leading) {
                            Text("Weight (kg)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("Enter weight", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // Run Time Input
                        VStack(alignment: .leading) {
                            Text("5K Time (mm:ss)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("Enter run time", text: $runTime)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // Notes Input
                        VStack(alignment: .leading) {
                            Text("Notes")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Photo Picker
                        VStack(alignment: .leading) {
                            Text("Progress Photo")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images
                            ) {
                                if let selectedImageData,
                                   let uiImage = UIImage(data: selectedImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                } else {
                                    Label("Select a photo", systemImage: "photo")
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Save Button
                        Button(action: saveEntry) {
                            Text("Save Entry")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // History Section
                    HistorySection(entries: progressEntries)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        let weightValue = Double(weight) ?? 0
        let runTimeComponents = runTime.split(separator: ":")
        var runTimeInSeconds: Int32 = 0
        
        if runTimeComponents.count == 2,
           let minutes = Int32(runTimeComponents[0]),
           let seconds = Int32(runTimeComponents[1]) {
            runTimeInSeconds = minutes * 60 + seconds
        }
        
        CoreDataManager.shared.saveProgressEntry(
            weight: weightValue,
            runTimeSeconds: runTimeInSeconds,
            notes: notes.isEmpty ? nil : notes,
            photo: selectedImageData,
            completionRate: calculateCompletionRate()
        )
        
        // Clear form
        weight = ""
        runTime = ""
        notes = ""
        selectedImageData = nil
        selectedItem = nil
    }
    
    private func calculateCompletionRate() -> Double {
        // TODO: Implement weekly completion rate calculation
        return 0.0
    }
}

struct CurrentStatsCard: View {
    let latestEntry: ProgressEntry?
    
    var formattedRunTime: String {
        guard let seconds = latestEntry?.runTimeSeconds, seconds > 0 else { return "N/A" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Stats")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Weight",
                    value: latestEntry?.weight != 0 ? String(format: "%.1f kg", latestEntry?.weight ?? 0) : "N/A",
                    icon: "scalemass.fill"
                )
                StatItem(
                    title: "Best 5K",
                    value: formattedRunTime,
                    icon: "stopwatch.fill"
                )
                StatItem(
                    title: "Week Progress",
                    value: latestEntry?.completionRate != 0 ? String(format: "%.0f%%", latestEntry?.completionRate ?? 0) : "N/A",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistorySection: View {
    let entries: FetchedResults<ProgressEntry>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("History")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(entries) { entry in
                HistoryEntryCard(entry: entry)
            }
        }
    }
}

struct HistoryEntryCard: View {
    let entry: ProgressEntry
    
    var formattedRunTime: String {
        guard entry.runTimeSeconds > 0 else { return "N/A" }
        let minutes = entry.runTimeSeconds / 60
        let seconds = entry.runTimeSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.entryDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date")
                .font(.headline)
            
            HStack {
                Text("Weight: \(String(format: "%.1f kg", entry.weight))")
                Spacer()
                Text("5K: \(formattedRunTime)")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            if let notes = entry.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let photoData = entry.photo,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    ProgressView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 