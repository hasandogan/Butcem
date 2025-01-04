import SwiftUI

struct RemindersView: View {
    @StateObject private var viewModel = ReminderViewModel()
    @State private var showingAddReminder = false
    @State private var selectedFilter: ReminderFilter = .all
    
    enum ReminderFilter {
        case all, upcoming, overdue
        
        var title: String {
            switch self {
            case .all: return "Tümü"
            case .upcoming: return "Yaklaşan"
            case .overdue: return "Geciken"
            }
        }
    }
    
    var filteredReminders: [Reminder] {
        switch selectedFilter {
        case .all:
            return viewModel.reminders
        case .upcoming:
            return viewModel.reminders.filter { $0.dueDate > Date() }
        case .overdue:
            return viewModel.reminders.filter { $0.dueDate < Date() }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filtre segmenti
                Picker("Filtre", selection: $selectedFilter) {
                    ForEach([ReminderFilter.all, .upcoming, .overdue], id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if filteredReminders.isEmpty {
                    EmptyReminderView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredReminders) { reminder in
                                ReminderCard(reminder: reminder) {
                                    Task {
                                        await viewModel.deleteReminder(reminder)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Hatırlatıcılar")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddReminder = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadReminders()
            viewModel.scheduleNotifications()
        }
        .onChange(of: viewModel.reminders) { _ in
            viewModel.scheduleNotifications()
        }
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                // Sol taraf - İkon ve kategori
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: reminder.category.icon)
                        .font(.title2)
                        .foregroundColor(reminder.category.color)
                        .frame(width: 32, height: 32)
                    
                    Text(reminder.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 60)
                
                // Orta kısım - Başlık ve detaylar
                VStack(alignment: .leading, spacing: 8) {
                    Text(reminder.title)
                        .font(.headline)
                    
                    if let note = reminder.note {
                        Text(note)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(reminder.frequency.rawValue, systemImage: "clock")
                        Spacer()
                        Text(reminder.dueDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sağ taraf - Tutar
                Text(reminder.amount.currencyFormat())
                    .font(.headline)
                    .foregroundColor(reminder.type == .income ? .green : .red)
            }
            .padding()
            
            // Alt kısım - İşlem butonları
            HStack {
                Button {
                    // Tamamlandı işlemi
                } label: {
                    Label("Tamamlandı", systemImage: "checkmark.circle")
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Sil", systemImage: "trash")
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct EmptyReminderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Henüz hatırlatıcı eklenmemiş")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Yeni bir hatırlatıcı eklemek için + butonuna tıklayın")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
} 