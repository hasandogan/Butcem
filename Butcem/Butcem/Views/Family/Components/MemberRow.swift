import SwiftUI

struct MemberRow: View {
    let member: FamilyBudget.FamilyMember
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(member.name.isEmpty ? member.email : member.name)
                    .font(.headline)
                Text(member.role.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(member.spentAmount.currencyFormat())
                .foregroundColor(member.spentAmount > 0 ? .red : .primary)
        }
    }
} 