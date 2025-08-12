import SwiftUI
import CoreBluetooth

// New Receiver
struct CentralView2: View {
    @State var centralManager: CentralManager
    @State private var scanning: Bool = false
    @State private var scanningUUIDs: [CBUUID]? = [CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")]
    @State private var allowDuplicateKey: Bool = false
    @State private var solicitedServiceUUIDs: [CBUUID] = []
    
    @State private var scanningUUIDsString: String = ""
    @State private var allowDuplicateKeyEdit: Bool = false
    @State private var solicitedServiceUUIDsString: String = ""
    
    @State private var showEdit: Bool = false

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
                    Button {
                        scanning = false
                        showEdit = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .imageScale(.large)
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 5)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Toggle, with glowing accent
                HStack {
                    Label("Active Scan", systemImage: scanning ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
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
                        if centralManager.discoveredPeripherals.isEmpty {
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
                            ForEach(centralManager.discoveredPeripherals, id: \.identifier) { peripheral in
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
                                            Text(peripheral.name ?? "Anonymous User")
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
            }
            // MARK: - Scan Settings Sheet
            .sheet(isPresented: $showEdit) {
                VStack(spacing: 28) {
                    HStack {
                        Text("Scan Settings")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.accentColor)
                        Spacer()
                        Button("Done") { showEdit = false }
                            .padding(.horizontal, 10)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Service UUIDs")
                                .font(.headline)
                            Spacer()
                        }
                        TextField("Comma separated…", text: $scanningUUIDsString)
                            .textFieldStyle(.roundedBorder)
                            .font(.callout)
                        Text("Only 128-bit UUIDs. Leave blank to scan all.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Divider()
                        Toggle("Allow Duplicate Responses", isOn: $allowDuplicateKeyEdit)
                        Divider()
                        Text("Solicited Service UUIDs")
                            .font(.headline)
                        TextField("Comma separated…", text: $solicitedServiceUUIDsString)
                            .textFieldStyle(.roundedBorder)
                            .font(.callout)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(16)

                    Spacer()
                    Button("Save & Close") {
                        scanningUUIDs = scanningUUIDsString.cbUUIDs
                        solicitedServiceUUIDs = solicitedServiceUUIDsString.cbUUIDs ?? []
                        allowDuplicateKey = allowDuplicateKeyEdit
                        showEdit = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding(.horizontal, 30)
                .background(Color("BGColor").ignoresSafeArea())
            }
        }
        .navigationBarHidden(true)
        .onDisappear { scanning = false }
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


private struct ServiceDetailView: View {
    @Environment(CentralManager.self) private var centralManager
    
    var peripheralId: UUID
    var serviceId: CBUUID
    
    @State private var selectedCharacteristic: CBCharacteristic? = nil
    @State private var showWriteSheet: Bool = false
    @State private var text: String = ""
    @State private var entryError: String? = nil
    
    var body: some View {
        Group {
            if let peripheral = centralManager.discoveredPeripherals.first(where: { $0.identifier == peripheralId }), let service = peripheral.services?.first(where: { $0.uuid == serviceId }) {
                VStack {
                    if let error = centralManager.error {
                        Text("Error: \(error)")
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 32)

                    }

                    List {
                        Section {
                            if service.characteristics == nil || service.characteristics!.isEmpty {
                                Text("No characteristics added.")
                            }
                            ForEach(service.characteristics ?? [], id: \.uuid) { characteristic in
                                HStack {
                                    VStack(spacing: 8) {
                                        Text("ID: \(characteristic.uuid)")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if !characteristic.userDescription.isEmpty {
                                            Text("Description: \(characteristic.userDescription)")
                                                .font(.subheadline)
                                                .foregroundStyle(.gray)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }

                                        Text("Allow: \(characteristic.properties.string)")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        CharacteristicValueView(characteristic: characteristic)
                                    }
                                    .frame(maxHeight: .infinity, alignment: .topLeading)

                                    VStack(spacing: 8) {
                                        if characteristic.properties.contains(.notify) {
                                            Button(action: {
                                                centralManager.setNotifying(peripheral, for: characteristic, value: !characteristic.isNotifying)
                                            }, label: {
                                                HStack {
                                                    Text("Notify")
                                                    Image(systemName: characteristic.isNotifying ? "checkmark.square" : "square")
                                                        .resizable()
                                                        .fontWeight(.bold)
                                                        .frame(width: 12, height: 12)

                                                }
                                            })
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        }

                                        
                                        if characteristic.properties.contains(.read) {
                                            Button(action: {
                                                centralManager.readCharacteristicValue(peripheral, for: characteristic)
                                            }, label: {
                                                Text("Read")
                                            })
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                        }

                                        if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                                            Button(action: {
                                                self.selectedCharacteristic = characteristic
                                                showWriteSheet = true
                                            }, label: {
                                                Text("Write")
                                            })
                                            .frame(maxWidth: .infinity, alignment: .trailing)

                                        }

                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .foregroundStyle(.blue)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .frame(maxHeight: .infinity, alignment: .topTrailing)

                                }
                                .fixedSize(horizontal: false, vertical: true)
        
                            }
                        } header: {
                            Text("Characteristics")
                        }
                        
                    }
                    .onAppear {
                        if service.characteristics == nil {
                            centralManager.discoverServiceDetails(peripheral, for: service)
                        }
                    }
                    .sheet(isPresented: $showWriteSheet, content: {
                        VStack(spacing: 24) {
                            let type: CBCharacteristicWriteType = selectedCharacteristic?.properties.contains(.writeWithoutResponse) == true ? .withoutResponse : .withResponse
                            let mtu = peripheral.maximumWriteValueLength(for: type)

                            HStack {
                                Text("Data to send")
                                    .font(.headline)
                                    .lineLimit(1)

                                HStack(spacing: 16) {

                                    Button(action: {
                                        showWriteSheet = false
                                    }, label: {
                                        Text("Cancel")
                                            .foregroundStyle(.red)
                                    })
                                    .buttonStyle(.bordered)

                                    Button(action: {
                                        if text.isEmpty {
                                            entryError = "Please enter something."
                                            return
                                        }
                                        guard let data = text.data else {
                                            self.entryError = "Failed to convert string to data."
                                            return
                                        }
                                        
                                        guard let characteristic = selectedCharacteristic else {
                                            self.entryError = "No characteristic selected."
                                            return
                                        }
                                        
                                        centralManager.writeValue(peripheral, data: data, for: characteristic, type: type)
                                        showWriteSheet = false
                                    }, label: {
                                        Text("Send")
                                    })
                                    .buttonStyle(.bordered)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)

                            }

                            let currentBytes = text.data?.count ?? 0

                            VStack {
                                Text("Max data length: \(mtu) bytes.")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(.gray)

                                Text("Current: \(currentBytes) bytes.")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(.gray)

                                TextField("", text: $text, axis: .vertical)
                                    .lineLimit(5, reservesSpace: true)
                                
                                if let entryError {
                                    Text(entryError)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(.red)
                                }

                            }


                        }
                        .textFieldStyle(.roundedBorder)
                        .padding(.all, 32)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .presentationDetents(.init([.fraction(0.5)]))
                        .onAppear {
                            entryError = ""
                            text = ""
                        }
                        .onChange(of: showWriteSheet, initial: true, {
                            if !showWriteSheet {
                                selectedCharacteristic = nil
                            }
                        })

                    })

                }

                
            } else {
                VStack {
                    Text("Cannot find service with the given ID")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)

                }
                .padding(.all, 32)

            }

        }
        .navigationTitle("Service: \(serviceId)")
        .navigationBarTitleDisplayMode(.inline)
        .multilineTextAlignment(.leading)
    }
}



private struct CharacteristicValueView: View {
    var characteristic: CBCharacteristic

    @Environment(CentralManager.self) private var centralManager
    @State private var showDataDetail: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            
            let value = characteristic.value?.string ?? ""
            let receivedData: [Data] = centralManager.receivedData[characteristic] ?? []
            
            if receivedData.isEmpty {
                Text("Value: \(value.isEmpty ? "(none)" : value)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

            } else {
                Button(action: {
                    showDataDetail.toggle()
                }, label: {
                    HStack(spacing: 16) {
                        Text("Value: \(receivedData.first!.string.isEmpty ? "(none)" : receivedData.first!.string)")
                        if receivedData.count  > 1 {
                            Image(systemName: showDataDetail ? "chevron.up" : "chevron.down")
                        }
                    }
                })
                .font(.subheadline)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

                
                if showDataDetail && receivedData.count > 1 {
                    ForEach(1..<receivedData.count, id: \.self) { index in
                        let data = receivedData[index]
                        Text("- \(data.string.isEmpty ? "(none)" : data.string)")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                    }
                }
            }

        }
        .buttonStyle(PlainButtonStyle())
    }
}




