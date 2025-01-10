import SwiftUI

struct PeriodPicker: View {
    @Binding var selectedPeriod: AnalysisPeriod
    
    var body: some View {
		Picker("Dönem".localized, selection: $selectedPeriod) {
            ForEach(AnalysisPeriod.allCases, id: \.self) { period in
				Text(period.description).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
} 
