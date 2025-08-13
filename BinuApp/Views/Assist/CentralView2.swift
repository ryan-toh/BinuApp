import SwiftUI
import CoreBluetooth

// New Receiver
struct CentralView2: View {
    @State var centralManager: CentralManager
    @State private var scanning: Bool = true
    @State private var scanningUUIDs: [CBUUID]? = [CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")]
    @State private var allowDuplicateKey: Bool = false
    @State private var solicitedServiceUUIDs: [CBUUID] = [CBUUID(string: "E100")]
    
    @State private var scanningUUIDsString: String = ""
    @State private var allowDuplicateKeyEdit: Bool = false
    @State private var solicitedServiceUUIDsString: String = ""
    
    @State private var stablePeripherals: [CBPeripheral] = []
    @State private var debounceWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            Color("BGColor").ignoresSafeArea()
            VStack {
                // Title bar
                HStack {
                    Image(systemName: "person.2.wave.2.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 30, weight: .medium))
                        .padding(.trailing, 5)
                    Text("Provide Help Nearby")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                        .shadow(radius: 1)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Toggle, with glowing accent
                HStack {
                    Label("Enable Scanning", systemImage: scanning ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .fontWeight(.medium)
                        .foregroundColor(scanning ? .accentColor : .gray)
                    Spacer()
                    Toggle("", isOn: $scanning)
                        .toggleStyle(.switch)
                        .tint(.accentColor)
                }
                .padding([.horizontal, .top], 20)

                // Error status
                if let error = centralManager.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("\(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                    .padding([.horizontal, .bottom], 12)
                }

                // Help request list
                List {
                    Section {
//                        if centralManager.discoveredPeripherals.isEmpty
                        if stablePeripherals.isEmpty {
                            VStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36))
                                    .padding(.bottom, 8)
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No help requests nearby.\nLeave scanning on.")
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(.clear)
                        } else {
//                            ForEach(centralManager.discoveredPeripherals, id: \.identifier)
                            ForEach(stablePeripherals, id: \.identifier) { peripheral in
                                NavigationLink(destination: PeripheralDetailView(peripheralId: peripheral.identifier)
                                                .environment(centralManager)) {
                                    HStack(spacing: 18) {
                                        // Simple avatar based on hash
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(gradient: Gradient(colors: [
                                                    Color.accentColor.opacity(0.19), Color.accentColor.opacity(0.47)
                                                ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing))
                                                .frame(width: 46, height: 46)
                                            Image(systemName: "person.fill")
                                                .font(.title2)
                                                .foregroundColor(.accentColor)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(centralManager.characteristicDescriptions[peripheral.identifier] ?? "Request Withdrawn")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text("Tap to view & assist")
                                                .foregroundColor(.blue)
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        // Connection status indicator
                                        if peripheral.state == .connected {
                                            Image(systemName: "link.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding([.vertical], 8)
                                }
                                .listRowBackground(Color(.secondarySystemGroupedBackground))
                            }
                        }
                    } header: {
                        Text("Nearby Help Requests")
                            .font(.title3)
                            .foregroundColor(Color("BGColor"))
                            .padding(.bottom, 4)
                    }
                }
                .listStyle(.insetGrouped)
                .background(.clear)
                .onChange(of: centralManager.connectedTargetPeripherals) { newValue in
                    debounceWorkItem?.cancel()
                    let workItem = DispatchWorkItem {
                        stablePeripherals = newValue
                    }
                    debounceWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
                }
            }
        }
        .navigationBarHidden(true)
//        .onDisappear { scanning = false }
        .onChange(of: scanning, initial: true) { _, isNowScanning in
            if isNowScanning {
                centralManager.startScanning(
                    serviceUUIDs: scanningUUIDs,
                    allowDuplicateKey: allowDuplicateKey,
                    solicitedServiceUUIDs: solicitedServiceUUIDs
                )
            } else { centralManager.stopScanning() }
        }
        .onChange(of: centralManager.restoredScanningOption, initial: true) { _, opt in
            if let option = opt {
                self.scanningUUIDs = option.serviceUUID
                self.allowDuplicateKey = option.allowDuplicates
                self.solicitedServiceUUIDs = option.solicitedServiceUUIDs
            }
        }
    }
}


private struct PeripheralDetailView: View {
    @Environment(CentralManager.self) private var centralManager
    var peripheralId: UUID

    @State private var inputValue: String = ""
    @State private var writeError: String?
    @State private var isWriting: Bool = false

    var body: some View {
        if let peripheral = centralManager.discoveredPeripherals.first(where: { $0.identifier == peripheralId }),
           let service = peripheral.services?.first(where: { $0.uuid == CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961") }),
           let characteristic = service.characteristics?.first(where: { $0.uuid == CBUUID(string: "E100") }) {

            let description = centralManager.characteristicDescriptions[peripheral.identifier] ?? "(No description discovered yet)"
            let value = characteristic.value?.string ?? ""

            VStack(alignment: .leading, spacing: 20) {
                // User section with icon and gradient background card
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(peripheral.name ?? peripheral.identifier.uuidString)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Text("User found nearby")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.15), Color("BGColor").opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )

                // Requested item card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Requested Item", systemImage: "lightbulb.min.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    Text(description)
                        .font(.title3.bold())
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1.5)
                )

                Divider().padding(.vertical, 2)

                // Instruction input card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Send Instructions", systemImage: "mappin.and.ellipse")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    Text("Provide your location or any useful info for the user seeking help.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray.opacity(0.8))
                        TextField("E.g. 'Near the red bench by the gate'", text: $inputValue)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isWriting)
                    }
                    Button {
                        guard let data = inputValue.data(using: .utf8) else {
                            self.writeError = "Failed to encode input."
                            return
                        }
                        isWriting = true
                        writeError = nil
                        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                        centralManager.writeValue(peripheral, data: data, for: characteristic, type: writeType)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isWriting = false
                        }
                    } label: {
                        Label("Send", systemImage: "paperplane.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isWriting || inputValue.isEmpty)
                    .opacity(isWriting ? 0.7 : 1)
                    .padding(.top, 4)

                    if let writeError {
                        Text(writeError)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.10), radius: 4, x: 0, y: 2)
                )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color("BGColor").ignoresSafeArea())

//            VStack(alignment: .leading, spacing: 18) {
//                Text("User: \(peripheral.name ?? peripheral.identifier.uuidString)")
//                    .font(.headline)
//                    .padding(.top)
//
//                Text("Requested Item:")
//                Text(description)
//                    .font(.body)
//                    .foregroundStyle(.blue)
//
//                Divider()
//
//                Text("Send Instructions")
//                TextField("Provide location info here...", text: $inputValue)
//                    .textFieldStyle(.roundedBorder)
//                    .disabled(isWriting)
//
//                Button("Send", action: {
//                    guard let data = inputValue.data(using: .utf8) else {
//                        self.writeError = "Failed to encode input."
//                        return
//                    }
//                    isWriting = true
//                    writeError = nil
//                    // Try writeWithResponse first, fallback to withoutResponse
//                    let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
//                    centralManager.writeValue(peripheral, data: data, for: characteristic, type: writeType)
//                    // Optionally, clear or reset after write
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                        isWriting = false
//                    }
//                })
//                .buttonStyle(.borderedProminent)
//                .disabled(isWriting || inputValue.isEmpty)
//
//                if let writeError {
//                    Text(writeError)
//                        .foregroundStyle(.red)
//                        .font(.footnote)
//                }
//
//                Text("Peripheral State: \(String(describing: peripheral.state))")
//                    .font(.footnote)
//                    .foregroundStyle(.gray)
//            }
            .onAppear {
                if peripheral.state != .connected {
                    centralManager.makeConnection(peripheral)
                }
            }
        } else {
            Text("Cannot find peripheral with the given ID")
                .foregroundStyle(.red)
                .padding()
        }
    }
}




