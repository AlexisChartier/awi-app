import SwiftUI

struct VendorsView: View {
    @StateObject var vm = VendorsViewModel()

    var body: some View {
        List(vm.vendors, id: \.id) { v in
            VStack(alignment: .leading) {
                Text(v.nom).bold()
                Text("Email: \(v.email)")
            }
        }
        .navigationTitle("Vendeurs")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Ajouter") {
                    // logiques d’ouverture de formulaire
                }
            }
        }
        .onAppear {
            vm.loadVendors()
        }
    }
}
