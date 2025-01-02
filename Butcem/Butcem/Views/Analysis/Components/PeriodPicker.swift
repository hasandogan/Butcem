import SwiftUI

struct PeriodPicker: View {
    @Binding var selectedPeriod: AnalysisPeriod
    
    var body: some View {
        Picker("Dönem", selection: $selectedPeriod) {
            ForEach(AnalysisPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
} 
