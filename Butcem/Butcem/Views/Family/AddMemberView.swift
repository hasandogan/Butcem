import SwiftUI

struct AddMemberView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var email: String
    @ObservedObject var viewModel: FamilyBudgetViewModel
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Üye Ekleme Formu
                VStack(alignment: .leading, spacing: 16) {
                    Text("Yeni Üye Ekle")
                        .font(.headline)
                    
                    HStack {
                        TextField("E-posta", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        Button {
                            onAdd(email)
                            email = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(email.isEmpty)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Mevcut Üyeler Listesi
                if let budget = viewModel.currentBudget {
                    List {
                        Section(header: Text("Mevcut Üyeler")) {
                            ForEach(budget.members) { member in
                                MemberRow(member: member)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Task {
                                                do {
                                                    try await viewModel.removeMember(member.email)
                                                } catch {
                                                    print("Failed to remove member: \(error.localizedDescription)")
                                                }
                                            }
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .padding(.top)
            .navigationTitle("Üyeler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}
