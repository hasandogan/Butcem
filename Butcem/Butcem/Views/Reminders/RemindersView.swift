import SwiftUI

struct RemindersView: View {
	@StateObject private var viewModel = ReminderViewModel()
	@State private var showingAddReminder = false
	@State private var selectedFilter = "Tümü".localized
	@State private var selectedReminder: Reminder?
	@State private var showingDeleteAlert = false
	@State private var reminderToDelete: Reminder?
	
	private let filterOptions = ["Tümü".localized, "Aktif".localized, "Tamamlanan".localized]
	
	var filteredReminders: [Reminder] {
		switch selectedFilter {
		case "Aktif":
			return viewModel.reminders.filter { $0.isActive }
		case "Tamamlanan":
			return viewModel.reminders.filter { !$0.isActive }
		default:
			return viewModel.reminders
		}
	}
	
	var body: some View {
		VStack(spacing: 0) {
			Picker("Filtre", selection: $selectedFilter) {
				ForEach(filterOptions, id: \.self) { option in
						Text(option).tag(option)
				}
			}
			.pickerStyle(.segmented)
			.padding()
			
			List {
				ForEach(filteredReminders) { reminder in
						ReminderRow(reminder: reminder)
							.swipeActions(edge: .trailing, allowsFullSwipe: false) {
								Button(role: .destructive) {
									reminderToDelete = reminder
									showingDeleteAlert = true
								} label: {
									Label("Sil", systemImage: "trash")
								}
								
								Button {
									selectedReminder = reminder
								} label: {
									Label("Düzenle", systemImage: "pencil")
								}
								.tint(.blue)
							}
							.swipeActions(edge: .leading, allowsFullSwipe: true) {
								Button {
									toggleReminderStatus(reminder)
								} label: {
									Label(
										reminder.isActive ? "Aktif" : "Tamamlandı",
										systemImage: reminder.isActive ? "arrow.uturn.backward" : "checkmark"
									)
								}
								.tint(reminder.isActive ? .blue : .green)
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
		.sheet(item: $selectedReminder) { reminder in
			EditReminderView(viewModel: viewModel, reminder: reminder)
		}
		.alert("Hatırlatıcıyı Sil", isPresented: $showingDeleteAlert) {
			Button("İptal", role: .cancel) {}
			Button("Sil", role: .destructive) {
				if let reminder = reminderToDelete {
					deleteReminder(reminder)
				}
			}
		} message: {
			Text("Bu hatırlatıcıyı silmek istediğinizden emin misiniz?")
		}
	}
	
	private func toggleReminderStatus(_ reminder: Reminder) {
		Task {
			var updatedReminder = reminder
			updatedReminder.isActive.toggle()
			try? await viewModel.updateReminder(updatedReminder)
		}
	}
	
	private func deleteReminder(_ reminder: Reminder) {
		Task {
			try? await viewModel.deleteReminder(reminder)
		}
	}
}

struct ReminderRow: View {
	let reminder: Reminder
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Label(reminder.title, systemImage: reminder.category.icon)
					.font(.headline)
				Spacer()
				Text(reminder.amount.currencyFormat())
					.foregroundColor(reminder.type == .expense ? .red : .green)
			}
			
			HStack {
				Text(reminder.dueDate.formattedDate())
					.font(.subheadline)
					.foregroundColor(.secondary)
				
				Spacer()
				
				ReminderStatusBadge(isActive: reminder.isActive)
			}
			
			if let note = reminder.note {
				Text(note)
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
		.padding(.vertical, 4)
	}
}

struct ReminderStatusBadge: View {
	let isActive: Bool
	
	var body: some View {
		Text(!isActive ? "Tamamlandı" : "Aktif")
			.font(.caption)
			.fontWeight(.medium)
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(isActive ? Color.gray.opacity(0.2) : Color.green.opacity(0.2))
			.foregroundColor(isActive ? .gray : .green)
			.cornerRadius(8)
	}
}
