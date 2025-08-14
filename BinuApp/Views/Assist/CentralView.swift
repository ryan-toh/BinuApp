//
//  CentralView.swift
//  BinuApp
//
//  Created by Ryan on 24/7/25.
//

import SwiftUI
import CoreBluetooth

/**
 Development Receiver View
 */
struct CentralView: View {
    @State private var centralManager: CentralManager
    @State private var scanning: Bool = false
    @State private var scanningUUIDs: [CBUUID]? = [CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")]
    @State private var allowDuplicateKey: Bool = false
    @State private var solicitedServiceUUIDs: [CBUUID] = []
    
    @State private var scanningUUIDsString: String = ""
    @State private var allowDuplicateKeyEdit: Bool = false
    @State private var solicitedServiceUUIDsString: String = ""
    
    @State private var showEdit: Bool = false

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                HStack(spacing: 32)  {
                    Text("**Scan**")
                    Spacer()
                        .frame(maxWidth: .infinity)
                    Toggle("", isOn: $scanning)
                }
                
//                VStack {
//                    Text("Scan options")
//                        .fontWeight(.bold)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    Text("Service UUIDs: \(scanningUUIDs?.map{$0.uuidString}.joined(separator: ", ") ?? "Any")")
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    Text("Allow duplicate key: \(allowDuplicateKey)")
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    Text("Solicited Service UUIDs: \((solicitedServiceUUIDs).isEmpty ? "Not Specified" :solicitedServiceUUIDs.map{$0.uuidString}.joined(separator: ", "))")
//                        .frame(maxWidth: .infinity, alignment: .leading)
//
//                }
                .font(.subheadline)
                .foregroundStyle(.gray)

                
                if let error = centralManager.error {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)

                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 32)
            
            
            List {
                Section {
                    if centralManager.discoveredPeripherals.isEmpty {
                        Text("No peripherals found")
                    }
                    
                    ForEach(centralManager.discoveredPeripherals, id: \.identifier) { peripheral in
                        NavigationLink(destination: {
                            PeripheralDetailView(peripheralId: peripheral.identifier)
                                .environment(centralManager)

                        }, label: {
                            VStack(spacing: 8) {
                                
//                                if peripheral.state == .connected {
//                                    Text("ID: \(peripheral.identifier)  \(Image(systemName: "personalhotspot"))")
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                } else {
//                                    Text("ID: \(peripheral.identifier)")
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                }
                                
                                Text("Name: \(peripheral.name ?? "(not specified)")")
                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                    .font(.subheadline)
//                                    .foregroundStyle(.gray)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Text("Services: \(peripheral.services == nil ? "(not discovered yet)" : "\(peripheral.services!.count)")")
//                                    .font(.subheadline)
//                                    .foregroundStyle(.gray)
//                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                        })

                    }
                } header: {
//                    Text("Discovered peripherals")
                    Text("Help Requests")
                }
            }

        }
        .multilineTextAlignment(.leading)
        .navigationTitle("Provide Help")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            scanning = false
        }
        .onChange(of: scanning, initial: true, {
            if scanning {
                centralManager.startScanning(serviceUUIDs: scanningUUIDs, allowDuplicateKey: allowDuplicateKey, solicitedServiceUUIDs: solicitedServiceUUIDs)
            } else {
                centralManager.stopScanning()
            }
        })
        .onChange(of: centralManager.restoredScanningOption, initial: true, {
            if let option = centralManager.restoredScanningOption {
                self.scanningUUIDs = option.serviceUUID
                self.allowDuplicateKey = option.allowDuplicates
                self.solicitedServiceUUIDs = option.solicitedServiceUUIDs
            }
        })
        .toolbar(content: {
            Button(action: {
                scanning = false
                showEdit = true
            }, label: {
                Text("Edit")
            })
        })
        .sheet(isPresented: $showEdit, content: {
            VStack(spacing: 24) {
                
                HStack {
                    Text("Scan options")
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 16) {
                                                
                        Button(action: {
                            showEdit = false
                        }, label: {
                            Text("Cancel")
                                .foregroundStyle(.red)
                        })
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            scanningUUIDs = scanningUUIDsString.cbUUIDs
                            solicitedServiceUUIDs = solicitedServiceUUIDsString.cbUUIDs ?? []
                            allowDuplicateKey = allowDuplicateKeyEdit
                            showEdit = false
                        }, label: {
                            Text("Save")
                        })
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                }
                    
        
                VStack {
                    Text("Service CBUUIDs to scan for")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\",\" separated. 128-bit UUID only. \nLeave it empty to scan for all services.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    
                    TextField("", text: $scanningUUIDsString, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
                Button(action: {
                    allowDuplicateKeyEdit.toggle()
                }, label: {
                    HStack {
                        Text("Allow Duplicate Keys")
                        Image(systemName: allowDuplicateKeyEdit ? "checkmark.square" : "square")
                            .resizable()
                            .fontWeight(.bold)
                            .frame(width: 12, height: 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                })
                
                VStack {
                    Text("Solicited CBUUIDs")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\",\" separated. 128-bit UUID only.")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.gray)
                    
                    TextField("", text: $solicitedServiceUUIDsString, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
            }
            .textFieldStyle(.roundedBorder)
            .padding(.all, 32)
            .frame(maxHeight: .infinity, alignment: .top)
            .presentationDetents(.init([.fraction(0.7)]))
            .background(.gray.opacity(0.2))
            .onAppear {
                solicitedServiceUUIDsString = solicitedServiceUUIDs.map{$0.uuidString}.joined(separator: ", ")
                scanningUUIDsString = scanningUUIDs?.map{$0.uuidString}.joined(separator: ", ") ?? ""
                allowDuplicateKeyEdit = allowDuplicateKey
            }
        })
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

//private struct PeripheralDetailView: View {
//    @Environment(CentralManager.self) private var centralManager
//    var peripheralId: UUID
//
//    @State private var connected: Bool = false
//    
//    var body: some View {
//        if let peripheral = centralManager.discoveredPeripherals.first(where: { $0.identifier == peripheralId }) {
//            let services = peripheral.services
//            
//            VStack {
//                VStack(spacing: 16) {
//                    HStack(spacing: 32)  {
//                        Text("**Connect**")
//                        Spacer()
//                            .frame(maxWidth: .infinity)
//                        Toggle("", isOn: $connected)
//                    }
//
//                    
//                    if let error = centralManager.error {
//                        Text("Error: \(error)")
//                            .foregroundStyle(.red)
//                            .frame(maxWidth: .infinity, alignment: .center)
//
//                    }
//                }
//                .padding(.top, 16)
//                .padding(.horizontal, 32)
//                
//                List {
//                    Section {
//
//                        if services == nil {
//                            Text(peripheral.state == .connected ? "Discovering..." : "Connect to discover")
//                        } else if services!.isEmpty {
//                            Text("No services discovered.")
//                        }
//                        
//                        if let services {
//                            ForEach(services, id: \.uuid) { service in
//                                
//                                NavigationLink(destination: {
//                                    ServiceDetailView(peripheralId: peripheralId, serviceId: service.uuid)
//                                        .environment(centralManager)
//
//                                }, label: {
//                                    VStack(spacing: 8) {
//                                        Text("ID: \(service.uuid)")
//                                            .frame(maxWidth: .infinity, alignment: .leading)
//                                        Text("Primary: \(service.isPrimary)")
//                                            .font(.subheadline)
//                                            .foregroundStyle(.gray)
//                                            .frame(maxWidth: .infinity, alignment: .leading)
//                                        
//                                        Text("Characteristics: \(service.characteristics == nil ? "(not discovered yet)" : "\(service.characteristics!.count)")")
//                                            .font(.subheadline)
//                                            .foregroundStyle(.gray)
//                                            .frame(maxWidth: .infinity, alignment: .leading)
//                                        
//                                        Text("Included Services: \(service.includedServices == nil ? "(not discovered yet)" : "\(service.includedServices!.count)")")
//                                            .font(.subheadline)
//                                            .foregroundStyle(.gray)
//                                            .frame(maxWidth: .infinity, alignment: .leading)
//
//                                    }
//                                })
//
//                            }
//
//                        }
//                    } header: {
//                        Text("Services")
//                    }
//                }
//            }
//            .navigationTitle("Peripheral: \(peripheral.name ?? peripheral.identifier.uuidString)")
//            .navigationBarTitleDisplayMode(.inline)
//            .multilineTextAlignment(.leading)
//            .onAppear {
//                connected = peripheral.state == .connected
//                if peripheral.services == nil && connected {
//                    centralManager.discoverServices(peripheral, serviceUUIDs: centralManager.scanningOption.serviceUUID)
//                }
//            }
//            .onChange(of: connected, initial: true, {
//                if connected {
//                    centralManager.makeConnection(peripheral)
//                } else {
//                    centralManager.cancelConnection(peripheral)
//                }
//            })
//            .onChange(of: peripheral.state, {
//                print("peripheral State changed: \(peripheral.state)")
//
//                switch peripheral.state {
//                case .connected:
//                    self.connected = true
//                    print("connected")
//                case .disconnected:
//                    self.connected = false
//                    print( "disconnected")
//                case .connecting:
//                    print("connecting")
//                case .disconnecting:
//                    print("disconnecting")
//                @unknown default:
//                    break
//                }
//            })
//  
//        } else {
//            VStack {
//                Text("Cannot find peripheral with the given ID")
//                    .foregroundStyle(.red)
//            }
//            .padding(.all, 32)
//
//            .navigationTitle("Peripheral")
//            .navigationBarTitleDisplayMode(.inline)
//            .multilineTextAlignment(.leading)
//        }
//        
//    }
//
//}


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




