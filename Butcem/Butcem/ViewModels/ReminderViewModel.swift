import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReminderViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    private let db = Firestore.firestore()
    
	init() {
		// Call the async fetch function inside a Task
		Task {
			await fetchReminders()
		}
	}
    
    func fetchReminders() async {
         let userId = AuthManager.shared.currentUserId
        
        do {
            let snapshot = try await db.collection("reminders")
                .whereField("userId", isEqualTo: userId)
                .order(by: "dueDate", descending: false)
                .getDocuments()
            
            self.reminders = snapshot.documents.compactMap { document in
                var reminder = try? document.data(as: Reminder.self)
                reminder?.id = document.documentID
                return reminder
            }
        } catch {
            print("Hatırlatıcılar yüklenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func addReminder(_ reminder: Reminder) async {
        do {
            let _ = try await db.collection("reminders").addDocument(from: reminder)
            await fetchReminders()
        } catch {
            print("Hatırlatıcı eklenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async {
        guard let documentId = reminder.id else { return }
        
        do {
            try await db.collection("reminders").document(documentId).delete()
            await fetchReminders()
        } catch {
            print("Hatırlatıcı silinirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func updateReminder(_ reminder: Reminder) async {
        guard let documentId = reminder.id else { return }
        
        do {
            try await db.collection("reminders").document(documentId).setData(from: reminder)
            await fetchReminders()
        } catch {
            print("Hatırlatıcı güncellenirken hata oluştu: \(error.localizedDescription)")
        }
    }
} 
