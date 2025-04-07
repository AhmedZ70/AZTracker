import SwiftUI
import PhotosUI
import CoreData

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var weight: String = ""
    @State private var runTime: String = ""
    @State private var completionRate: String = ""
    @State private var notes: String = ""
    @State private var selectedDate = Date()
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    @FetchRequest(
        entity: ProgressEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ProgressEntry.entryDate, ascending: false)]
    ) private var progressEntries: FetchedResults<ProgressEntry>
    
    var latestEntry: ProgressEntry? {
        return progressEntries.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Progress Entry")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Run Time (minutes)", text: $runTime)
                        .keyboardType(.numberPad)
                    
                    TextField("Completion Rate (%)", text: $completionRate)
                        .keyboardType(.decimalPad)
                    
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text(inputImage == nil ? "Add Photo" : "Change Photo")
                    }
                    
                    if let image = inputImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                }
                
                if !progressEntries.isEmpty {
                    Section(header: Text("History")) {
                        ForEach(progressEntries) { entry in
                            VStack(alignment: .leading) {
                                Text(entry.formattedDate)
                                    .font(.headline)
                                Text("Weight: \(entry.formattedWeight)")
                                Text("Run Time: \(entry.formattedRunTime)")
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: saveEntry) {
                        Text("Save Entry")
                    }
                }
            }
            .navigationTitle("Track Progress")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .alert("Progress Entry", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
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
        let weightValue = Double(weight) ?? 0.0
        let runTimeMinutes = Double(runTime) ?? 0.0
        let runTimeSeconds = Int32(runTimeMinutes * 60)
        let completionValue = Double(completionRate) ?? 0.0
        
        var imageData: Data? = nil
        if let image = inputImage {
            imageData = image.jpegData(compressionQuality: 0.8)
        }
        
        let entry = CoreDataManager.shared.createProgressEntry(
            date: selectedDate,
            weight: weightValue,
            runTime: runTimeSeconds,
            completion: completionValue,
            notes: notes,
            photo: imageData
        )
        
        // Reset form
        weight = ""
        runTime = ""
        completionRate = ""
        notes = ""
        inputImage = nil
        selectedDate = Date()
        
        alertMessage = "Progress entry saved successfully!"
        showingAlert = true
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CurrentStatsCard: View {
    let latestEntry: ProgressEntry?
    
    var formattedWeight: String {
        guard let weight = latestEntry?.weight, weight != 0 else { return "N/A" }
        let weightInLbs = weight * 2.20462 // Convert kg to lbs
        return String(format: "%.1f lbs", weightInLbs)
    }
    
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
                    value: formattedWeight,
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
    
    var formattedWeight: String {
        let weightInLbs = entry.weight * 2.20462 // Convert kg to lbs
        return String(format: "%.1f lbs", weightInLbs)
    }
    
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
                Text("Weight: \(formattedWeight)")
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