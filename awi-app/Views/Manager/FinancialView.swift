import SwiftUI

struct FinancialView: View {
    @StateObject var vm = FinancialViewModel()
    @State var sessionId: Int = 1
    @State var pdfData: Data? = nil

    var body: some View {
        VStack {
            if vm.loading {
                ProgressView()
            } else {
                Button("Télécharger Bilan Session") {
                    Task {
                        pdfData = await vm.downloadBilanSession(sessionId: sessionId)
                    }
                }
                if let pdfData = pdfData {
                    Text("PDF Bilan téléchargé (\(pdfData.count) octets)")
                }
                if let error = vm.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Bilan Financier")
        .padding()
    }
}
