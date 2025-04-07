import SwiftUI
import PhotosUI
import CoreData
import Charts // Add Charts framework for visualizations

enum PhotoType {
    case front, back, side
    
    var title: String {
        switch self {
            case .front: return "Front View"
            case .back: return "Back View"
            case .side: return "Side View"
        }
    }
}

enum TimeRange: Int, CaseIterable, Identifiable {
    case week, month, threeMonths
    
    var id: Int { rawValue }
    
    var days: Int {
        switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
        }
    }
    
    var title: String {
        switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .threeMonths: return "3 Months"
        }
    }
}

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var weight: String = ""
    @State private var runTime: String = ""
    @State private var completionRate: String = ""
    @State private var notes: String = ""
    @State private var selectedDate = Date()
    @State private var showingImagePicker = false
    @State private var currentPhotoType: PhotoType = .front
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var sideImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedTimeRange: TimeRange = .month
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProgressEntry.entryDate, ascending: false)]
    ) private var progressEntries: FetchedResults<ProgressEntry>
    
    var latestEntry: ProgressEntry? {
        return progressEntries.first
    }
    
    // MARK: - Analytics Properties
    
    var weightTrend: Double {
        guard progressEntries.count >= 2 else { return 0 }
        let latest = progressEntries[0].weight
        let previous = progressEntries[1].weight
        guard previous > 0 else { return 0 }
        let change = latest - previous
        return (change / previous) * 100
    }
    
    var averageRunTime: Double {
        let validEntries = progressEntries.prefix(selectedTimeRange.days).filter { $0.runTimeSeconds > 0 }
        guard !validEntries.isEmpty else { return 0 }
        let total = validEntries.reduce(0.0) { $0 + Double($1.runTimeSeconds) }
        return total / Double(validEntries.count)
    }
    
    var bestRunTime: Int32 {
        progressEntries.prefix(selectedTimeRange.days).min(by: { $0.runTimeSeconds < $1.runTimeSeconds })?.runTimeSeconds ?? 0
    }
    
    var averageCompletionRate: Double {
        let validEntries = progressEntries.prefix(selectedTimeRange.days).filter { $0.completionRate > 0 }
        guard !validEntries.isEmpty else { return 0 }
        return validEntries.reduce(0.0) { $0 + $1.completionRate } / Double(validEntries.count)
    }
    
    var consistencyStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for entry in progressEntries {
            guard let entryDate = entry.entryDate else { break }
            let daysApart = calendar.dateComponents([.day], from: entryDate, to: currentDate).day ?? 0
            
            if daysApart <= 1 {
                streak += 1
                currentDate = entryDate
            } else {
                break
            }
        }
        return streak
    }
    
    // Check if selected date is a Sunday
    var isSunday: Bool {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: selectedDate) == 1
    }
    
    // Get next Sunday if current date isn't Sunday
    var nextSunday: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        components.weekday = 1 // 1 represents Sunday
        components.hour = 12 // Set to noon to avoid any timezone issues
        return calendar.nextDate(after: selectedDate, matching: components, matchingPolicy: .nextTime) ?? selectedDate
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Check-in Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weekly Check-in")
                            .font(.title2)
                            .bold()
                        
                        if !isSunday {
                            Text("Next check-in: \(nextSunday.formatted(.dateTime.weekday().day().month()))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Current Stats Card
                    CurrentStatsCard(latestEntry: latestEntry)
                    
                    // Progress Insights
                    ProgressInsightsCard(
                        weightTrend: weightTrend,
                        averageRunTime: averageRunTime,
                        bestRunTime: bestRunTime,
                        averageCompletion: averageCompletionRate,
                        consistencyStreak: consistencyStreak
                    )
                    
                    // Weight Trend Chart
                    WeightTrendChart(entries: Array(progressEntries.prefix(selectedTimeRange.days)))
                        .frame(height: 200)
                        .padding()
                    
                    // New Entry Form
                    VStack(spacing: 16) {
                        Text("New Check-in Entry")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        DatePicker("Check-in Date", selection: $selectedDate, displayedComponents: .date)
                        
                        TextField("Weight (lbs)", text: $weight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        TextField("Best 5K Time (minutes)", text: $runTime)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        TextField("Week Completion Rate (%)", text: $completionRate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                        
                        // Progress Photos
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress Photos")
                                .font(.headline)
                            
                            PhotoSelectionRow(
                                title: "Front View",
                                image: $frontImage,
                                onTap: { currentPhotoType = .front; showingImagePicker = true }
                            )
                            
                            PhotoSelectionRow(
                                title: "Back View",
                                image: $backImage,
                                onTap: { currentPhotoType = .back; showingImagePicker = true }
                            )
                            
                            PhotoSelectionRow(
                                title: "Side View",
                                image: $sideImage,
                                onTap: { currentPhotoType = .side; showingImagePicker = true }
                            )
                        }
                        
                        Button(action: saveEntry) {
                            Text("Save Check-in")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(!isSunday)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // History Section
                    if !progressEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Check-in History")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(progressEntries.prefix(10)), id: \.self) { entry in
                                EnhancedHistoryCard(entry: entry)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteEntry(entry)
                                        } label: {
                                            Label("Delete Entry", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Progress Tracker")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: binding(for: currentPhotoType))
            }
            .alert("Progress Entry", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func binding(for photoType: PhotoType) -> Binding<UIImage?> {
        switch photoType {
            case .front: return $frontImage
            case .back: return $backImage
            case .side: return $sideImage
        }
    }
    
    private func saveEntry() {
        guard isSunday else {
            alertMessage = "Check-ins can only be saved on Sundays"
            showingAlert = true
            return
        }
        
        let weightValue = Double(weight) ?? 0.0  // Store as is, already in lbs
        let runTimeMinutes = Double(runTime) ?? 0.0
        let runTimeSeconds = Int32(runTimeMinutes * 60)
        let completionValue = Double(completionRate) ?? 0.0
        
        // Process photos
        let frontPhotoData = frontImage?.jpegData(compressionQuality: 0.8)
        let backPhotoData = backImage?.jpegData(compressionQuality: 0.8)
        let sidePhotoData = sideImage?.jpegData(compressionQuality: 0.8)
        
        let entry = CoreDataManager.shared.createProgressEntry(
            date: selectedDate,
            weight: weightValue,  // Pass weight as is
            runTime: runTimeSeconds,
            completion: completionValue,
            notes: notes,
            frontPhoto: frontPhotoData,
            backPhoto: backPhotoData,
            sidePhoto: sidePhotoData
        )
        
        // Reset form
        weight = ""
        runTime = ""
        completionRate = ""
        notes = ""
        frontImage = nil
        backImage = nil
        sideImage = nil
        selectedDate = nextSunday
        
        alertMessage = "Weekly check-in saved successfully!"
        showingAlert = true
    }
    
    private func deleteEntry(_ entry: ProgressEntry) {
        withAnimation {
            viewContext.delete(entry)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting entry: \(error)")
            }
        }
    }
}

struct PhotoSelectionRow: View {
    let title: String
    @Binding var image: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(title)
                    Spacer()
                    Image(systemName: image == nil ? "camera" : "photo.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
            }
        }
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
        guard let weight = latestEntry?.weight, weight > 0 else { return "N/A" }
        return String(format: "%.1f lbs", weight)
    }
    
    var formattedRunTime: String {
        guard let seconds = latestEntry?.runTimeSeconds, seconds > 0 else { return "N/A" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var formattedCompletion: String {
        guard let completion = latestEntry?.completionRate, completion > 0 else { return "N/A" }
        return String(format: "%.0f%%", completion)
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
                    value: formattedCompletion,
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

struct ProgressInsightsCard: View {
    let weightTrend: Double
    let averageRunTime: Double
    let bestRunTime: Int32
    let averageCompletion: Double
    let consistencyStreak: Int
    
    var formattedWeightTrend: String {
        if abs(weightTrend) < 0.01 {
            return "0.0%"
        }
        return String(format: "%.1f%%", weightTrend)
    }
    
    var weightTrendColor: Color {
        if weightTrend > 0 {
            return .green
        } else if weightTrend < 0 {
            return .red
        }
        return .gray
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Insights")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    title: "Weight Trend",
                    value: formattedWeightTrend,
                    icon: weightTrend > 0 ? "arrow.up.right" : "arrow.down.right",
                    color: weightTrendColor
                )
                
                InsightRow(
                    title: "Avg Run Time",
                    value: String(format: "%d:%02d", Int(averageRunTime) / 60, Int(averageRunTime) % 60),
                    icon: "stopwatch",
                    color: .blue
                )
                
                InsightRow(
                    title: "Best Run",
                    value: String(format: "%d:%02d", bestRunTime / 60, bestRunTime % 60),
                    icon: "trophy",
                    color: .yellow
                )
                
                InsightRow(
                    title: "Avg Completion",
                    value: String(format: "%.0f%%", averageCompletion),
                    icon: "checkmark.circle",
                    color: .green
                )
                
                InsightRow(
                    title: "Streak",
                    value: "\(consistencyStreak) days",
                    icon: "flame",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .bold()
        }
    }
}

struct WeightTrendChart: View {
    let entries: [ProgressEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight Trend")
                .font(.headline)
                .padding(.horizontal)
            
            if entries.isEmpty {
                Text("No data available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Chart {
                    ForEach(entries.reversed(), id: \.self) { entry in
                        LineMark(
                            x: .value("Date", entry.entryDate ?? Date()),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("Date", entry.entryDate ?? Date()),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct EnhancedHistoryCard: View {
    let entry: ProgressEntry
    @State private var showingDetail = false
    @State private var selectedPhotoType: PhotoType = .front
    
    var formattedDate: String {
        entry.entryDate?.formatted(date: .long, time: .omitted) ?? "Unknown Date"
    }
    
    var formattedWeight: String {
        String(format: "%.1f lbs", entry.weight)
    }
    
    var formattedRunTime: String {
        let minutes = Int(entry.runTimeSeconds / 60)
        let seconds = Int(entry.runTimeSeconds % 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedCompletionRate: String {
        String(format: "%.0f%% Complete", entry.completionRate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(formattedDate)
                        .font(.headline)
                    
                    HStack {
                        Label(formattedWeight, systemImage: "scalemass")
                        Spacer()
                        Label(formattedRunTime, systemImage: "stopwatch")
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { withAnimation { showingDetail.toggle() } }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(showingDetail ? 90 : 0))
                }
            }
            
            if showingDetail {
                VStack(alignment: .leading, spacing: 8) {
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.vertical, 4)
                    }
                    
                    // Photo Selection Picker
                    Picker("Photo View", selection: $selectedPhotoType) {
                        Text("Front").tag(PhotoType.front)
                        Text("Back").tag(PhotoType.back)
                        Text("Side").tag(PhotoType.side)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 4)
                    
                    // Display selected photo
                    Group {
                        switch selectedPhotoType {
                            case .front:
                                if let photoData = entry.frontPhoto,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                }
                            case .back:
                                if let photoData = entry.backPhoto,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                }
                            case .side:
                                if let photoData = entry.sidePhoto,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                }
                        }
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                    
                    HStack {
                        Label(formattedCompletionRate, systemImage: "chart.bar.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ProgressView()
        .environment(\.managedObjectContext, CoreDataManager.shared.container.viewContext)
} 