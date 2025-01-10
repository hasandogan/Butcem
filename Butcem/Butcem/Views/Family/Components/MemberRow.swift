import SwiftUI

struct MemberRow: View {
    let member: FamilyBudget.FamilyMember
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(member.name)
                    .font(.subheadline)
                Text(member.role.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
} 
