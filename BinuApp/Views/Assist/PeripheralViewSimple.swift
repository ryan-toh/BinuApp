
//import SwiftUI
//import CoreBluetooth
//
//struct PeripheralViewSimple: View {
//    @State private var peripheralManager = PeripheralManager()
//    @State private var descriptionText = ""
//    @State private var service: CBMutableService
//
//    var body: some View {
//        VStack(spacing: 24) {
//            TextField("Characteristic Description", text: $descriptionText)
//                .textFieldStyle(.roundedBorder)
//                .padding(.top, 32)
//
//            Button("Create Service") {
//                service = peripheralManager.createSingleWritableService(withDescription: descriptionText)
//                peripheralManager.addService(service)
//                peripheralManager.startAdvertising()
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//            Spacer()
//        }
//        .padding()
//    }
//}

import SwiftUI
import CoreBluetooth

struct PeripheralViewSimple: View {
    @State private var peripheralManager = PeripheralManager()
    @State private var descriptionText = ""
    @State private var service: CBMutableService? = nil  // <- Now optional

    var cachedValueString: String {
        if let char = service?.characteristics?.first as? CBMutableCharacteristic,
           let data = char.value, !data.isEmpty {
            return String(data: data, encoding: .utf8) ?? "(binary data)"
        }
        return "(none)"
    }

    var body: some View {
        VStack(spacing: 24) {
            TextField("Characteristic Description", text: $descriptionText)
                .textFieldStyle(.roundedBorder)
                .padding(.top, 32)

            Button("Create Service") {
                // Don't shadow the state variable!
                let newService = peripheralManager.createSingleWritableService(withDescription: descriptionText)
                peripheralManager.addService(newService)
                peripheralManager.startAdvertising()
                // For demo: set the characteristic .value (though CB rules only allow .value for read-only chars)
                if let char = newService.characteristics?.first as? CBMutableCharacteristic {
                    char.value = descriptionText.data(using: .utf8)
                }
                service = newService
            }
            .buttonStyle(.borderedProminent)
            .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let _ = service {
                Text("Cached value: \(cachedValueString)")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

