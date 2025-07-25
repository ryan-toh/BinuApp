//
//  PeripheralView.swift
//  BinuApp
//
//  Created by Ryan on 24/7/25.
//


import SwiftUI
import CoreBluetooth

// Sender
struct PeripheralView: View {
    @State private var peripheralManager = PeripheralManager()
    @State private var isAdvertising: Bool = false
    @State private var isEditing = false
   
    @State private var showAddServiceSheet: Bool = false
    @State private var showAddCharacteristicSheet: Bool = false

    @State private var addedCharacteristics: [CBMutableCharacteristic] = []
    @State private var isPrimary: Bool = false

    @State private var cachedValueString: String = ""
    @State private var characteristicDescription: String = ""
    @State private var allowedProperties: CBCharacteristicProperties = []
    
    @State private var includedServices: [CBMutableService] = []
    @State private var showPicker: Bool = false
    private static let allServices = "(all)"

    var body: some View {
        
        VStack {
            VStack(spacing: 16) {
                
                HStack(spacing: 32)  {
                    Text("**Advertise**")
                    Spacer()
                        .frame(maxWidth: .infinity)
                    Toggle("", isOn: $isAdvertising)
                }
                if let error = peripheralManager.error {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Button("Add Sample Service") {
                    addSampleService()
                }

            }
            .padding(.top, 16)
            .padding(.horizontal, 32)

            
            List {
                Section {
                    if peripheralManager.addedServices.isEmpty {
                        Text("Add a service to start advertising")
                    }
                    ForEach(peripheralManager.addedServices, id: \.uuid) { service in
                        HStack(spacing: 16) {
                            if isEditing {
                                Button(action: {
                                    isAdvertising = false
                                    peripheralManager.removeService(service)
                                    
                                }, label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                })
                                
                            }
                        
                            NavigationLink(destination: {
                                ServiceDetailView(service: service)
                                    .environment(peripheralManager)

                            }, label: {
      
                                    VStack(spacing: 8) {
                                        Text("ID: \(service.uuid)")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("Primary: \(service.isPrimary)")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("Characteristics: \(service.characteristics?.count ?? 0)")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("Included services: \(service.includedServices?.count ?? 0)")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                    }

                            })
                            .disabled(isEditing)
                            
                        }
                    
                        
                    }
                
                } header: {
                    Text("Added services")
                }
            }

        }
        .multilineTextAlignment(.leading)
        .navigationTitle("My Services")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            isAdvertising = false
        }
        .toolbar(content: {
            Button(action: {
                showAddServiceSheet = true
            }, label: {
                Text("Add")
            })
            
            Button(action: {
                isEditing.toggle()
            }, label: {
                Text(isEditing ? "Done" : "Edit")
            })
            
        })
        .onChange(of: isAdvertising, initial: true, {
            if isAdvertising {
                peripheralManager.startAdvertising()
            } else {
                peripheralManager.stopAdvertising()
            }
        })
        .sheet(isPresented: $showAddServiceSheet, content: {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("New Service")
                            .font(.headline)
                            .lineLimit(1)
                        
                        HStack(spacing: 16) {
                                                    
                            Button(action: {
                                showAddServiceSheet = false
                            }, label: {
                                Text("Cancel")
                                    .foregroundStyle(.red)
                            })
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                let service = CBMutableService(type: CBUUID(nsuuid: UUID()) , primary: isPrimary)
                                service.characteristics = addedCharacteristics
                                let includedServices: [CBService] = self.includedServices.map({$0 as CBService})

                                service.includedServices = includedServices
                                
                                peripheralManager.addService(service)
                                showAddServiceSheet = false
                            }, label: {
                                Text("Add")
                            })
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    }
                    
                    Button(action: {
                        isPrimary.toggle()
                    }, label: {
                        HStack {
                            Text("Primary")
                            Image(systemName: isPrimary ? "checkmark.square" : "square")
                                .resizable()
                                .fontWeight(.bold)
                                .frame(width: 12, height: 12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    })
                    
                    if !peripheralManager.addedServices.isEmpty {
                        VStack(spacing:12) {
                            Button(action: {
                                showPicker.toggle()
                            }, label: {
                                
                                HStack {
                                    Text("Include: \(includedServices.count == peripheralManager.addedServices.count ? Self.allServices : "\(includedServices.count) services")")
                                        .lineLimit(1)
                                    Spacer()
                                    
                                    Image(systemName: showPicker ? "chevron.up" : "chevron.down")
                                }
                                
                            })
                            .buttonStyle(.plain)
                            
                            if showPicker {
                                
                                Button(action: {
                                    if includedServices.count < peripheralManager.addedServices.count {
                                        includedServices = peripheralManager.addedServices
                                    } else {
                                        includedServices = []
                                    }
                                }, label: {
                                    HStack {
                                        Image(systemName: includedServices.count == peripheralManager.addedServices.count ? "checkmark.square" : "square")
                                            .resizable()
                                            .fontWeight(.bold)
                                            .frame(width: 12, height: 12)
                                        Text(Self.allServices)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                })
                                
                                Divider()
                                
                                ForEach(0..<peripheralManager.addedServices.count, id: \.self) { index in
                                    let central: CBMutableService = peripheralManager.addedServices[index]
                                    let id = central.uuid.uuidString
                                    Button(action: {
                                        if includedServices.contains(central) {
                                            includedServices.removeAll(where: {$0 == central})
                                        } else {
                                            includedServices.append(central)
                                        }
                                    }, label: {
                                        HStack {
                                            Image(systemName: includedServices.contains(where: {$0.uuid.uuidString == id}) ? "checkmark.square" : "square")
                                                .resizable()
                                                .fontWeight(.bold)
                                                .frame(width: 12, height: 12)
                                            Text(id)
                                                .multilineTextAlignment(.leading)

                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                    })
                                    
                                }
                            }
                        }
                    }
                    
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Characteristics")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: {
                                showAddCharacteristicSheet = true
                            }, label: {
                                Text("Add")
                            })
                        }
                        
                        if addedCharacteristics.isEmpty {
                            Text("No Characteristics added yet.")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.gray)

                        }
                        
                        ForEach(addedCharacteristics, id: \.uuid) { characteristic in
                            HStack(spacing: 16) {
                                Button(action: {
                                    addedCharacteristics.removeAll(where: {$0.uuid == characteristic.uuid})
                                }, label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                })
                                
                                VStack(spacing: 8) {
                                    Text("ID: \(characteristic.uuid)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("Allow: \(characteristic.properties.string)")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    let value = characteristic.value?.string ?? ""
                                    Text("Value: \(value.isEmpty ? "(none)" : value)")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                    
                            }
                            
                 
                        }

                    }
                    .sheet(isPresented: $showAddCharacteristicSheet, content: {
                        VStack(spacing: 24) {
                            HStack {
                                Text("New Characteristic")
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                HStack(spacing: 16) {
                                                            
                                    Button(action: {
                                        showAddCharacteristicSheet = false
                                    }, label: {
                                        Text("Cancel")
                                            .foregroundStyle(.red)
                                    })
                                    
                                    Button(action: {
                                        var permissions: CBAttributePermissions = []
                                        if allowedProperties.contains(.read) {
                                            permissions.insert(.readable)
                                        }
                                        if allowedProperties.contains(.write) || allowedProperties.contains(.writeWithoutResponse)  {
                                            permissions.insert(.writeable)
                                        }
                                        let newCharacteristic: CBMutableCharacteristic = CBMutableCharacteristic(type:CBUUID(nsuuid: UUID()), properties: allowedProperties, value: cachedValueString.isEmpty ? nil : cachedValueString.data, permissions: permissions)
                                        
                                        if !characteristicDescription.isEmpty {
                                            let descriptor = CBMutableDescriptor(type: CBUUID(string: CBUUIDCharacteristicUserDescriptionString), value: characteristicDescription)
                                            newCharacteristic.descriptors = [descriptor]
                                        }
                                        
                                        self.addedCharacteristics.append(newCharacteristic)
                                        showAddCharacteristicSheet = false
                                    }, label: {
                                        Text("Add")
                                    })
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)

                            }
                                
                    
                            VStack {
                                Text("Allow")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 24) {
                                    Button(action: {
                                        if allowedProperties.contains(.read) {
                                            allowedProperties.remove(.read)
                                        } else {
                                            allowedProperties.insert(.read)
                                        }
                                    }, label: {
                                        HStack {
                                            Text("Read")
                                            Image(systemName: allowedProperties.contains(.read) ? "checkmark.square" : "square")
                                                .resizable()
                                                .fontWeight(.bold)
                                                .frame(width: 12, height: 12)
                                        }

                                    })
                                    
                                    Button(action: {
                                        if allowedProperties.contains(.notify) {
                                            allowedProperties.remove(.notify)
                                        } else {
                                            allowedProperties.insert(.notify)
                                        }
                                    }, label: {
                                        HStack {
                                            Text("Notify")
                                            Image(systemName: allowedProperties.contains(.notify) ? "checkmark.square" : "square")
                                                .resizable()
                                                .fontWeight(.bold)
                                                .frame(width: 12, height: 12)
                                        }

                                    })

                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                
                                HStack(spacing: 24) {
                                    Button(action: {
                                        if allowedProperties.contains(.write) {
                                            allowedProperties.remove(.write)
                                        } else {
                                            allowedProperties.insert(.write)
                                        }
                                    }, label: {
                                        HStack {
                                            Text("Write")
                                            Image(systemName: allowedProperties.contains(.write) ? "checkmark.square" : "square")
                                                .resizable()
                                                .fontWeight(.bold)
                                                .frame(width: 12, height: 12)
                                        }

                                    })
                                    
                                    Button(action: {
                                        if allowedProperties.contains(.writeWithoutResponse) {
                                            allowedProperties.remove(.writeWithoutResponse)
                                        } else {
                                            allowedProperties.insert(.writeWithoutResponse)
                                        }
                                    }, label: {
                                        HStack {
                                            Text("Write without response")
                                            Image(systemName: allowedProperties.contains(.writeWithoutResponse) ? "checkmark.square" : "square")
                                                .resizable()
                                                .fontWeight(.bold)
                                                .frame(width: 12, height: 12)
                                        }

                                    })

                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                            }
                            
                            
                            VStack {
                                Text("Cached Value")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Leave it empty to use dynamic value.")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(.gray)

                                TextField("", text: $cachedValueString, axis: .vertical)
                                    .lineLimit(2, reservesSpace: true)

                            }
                            
                            VStack {
                                Text("Description")
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("", text: $characteristicDescription, axis: .vertical)
                                    .lineLimit(2, reservesSpace: true)

                            }
      
                        }
                        .textFieldStyle(.roundedBorder)
                        .padding(.all, 32)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .presentationDetents([.fraction(0.6)])
                        .interactiveDismissDisabled()
                        .onAppear {
                            allowedProperties = []
                            cachedValueString = ""
                        }
                        
                    })

                }

            }
            .textFieldStyle(.roundedBorder)
            .padding(.all, 32)
            .frame(maxHeight: .infinity, alignment: .top)
            .presentationDetents([.large])
            .interactiveDismissDisabled()
            .onAppear {
                includedServices = []
                addedCharacteristics = []
                isPrimary = true
            }
        })

    }
    
    private func addSampleService() {
        let characteristicUUID = CBUUID(string: "FFE1")
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        
        let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        
        peripheralManager.addService(service)
    }
}


private struct ServiceDetailView: View {
    @Environment(PeripheralManager.self) private var peripheralManager
    var service: CBService

    @State private var selectedCharacteristic: CBCharacteristic? = nil
    @State private var showWriteSheet: Bool = false
    @State private var text: String = ""
    @State private var entryError: String? = nil

    private static let allCentrals = "(all)"
    @State private var selectedCentrals: [CBCentral] = []
    @State private var showPicker: Bool = false

    
    var body: some View {
        VStack {
            if let error = peripheralManager.error {
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
                        CharacteristicCellView(updateValueAction: {
                            showWriteSheet = true
                            selectedCharacteristic = characteristic
                        }, characteristic: characteristic)
                    }
                } header: {
                    Text("Characteristics")
                }
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showWriteSheet, content: {
                let subscribedCentrals: [CBCentral] = selectedCharacteristic == nil ? [] : peripheralManager.subscribedCentrals[selectedCharacteristic!] ?? []

                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Data to update")
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
                                    
                                    peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: selectedCentrals)
                                    showWriteSheet = false
                                }, label: {
                                    Text("Send")
                                })
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            
                        }
                                                    
                        if !subscribedCentrals.isEmpty {
                            VStack(spacing:12) {
                                Button(action: {
                                    showPicker.toggle()
                                }, label: {
                                    
                                    HStack {
                                        Text("Notifying: \(selectedCentrals.count == subscribedCentrals.count ? Self.allCentrals : "\(selectedCentrals.count) centrals")")
                                            .lineLimit(1)
                                        Spacer()
                                        
                                        Image(systemName:showPicker ? "chevron.up" : "chevron.down")
                                    }
                                    
                                })
                                .buttonStyle(.plain)
                                
                                if showPicker {
                                    
                                    Button(action: {
                                        if selectedCentrals.count < subscribedCentrals.count {
                                            selectedCentrals = subscribedCentrals
                                        } else {
                                            selectedCentrals = []
                                        }
                                    }, label: {
                                        HStack {
                                            Image(systemName: selectedCentrals.count == subscribedCentrals.count ? "checkmark.square" : "square")
                                                .resizable()
                                                .fontWeight(.bold)
                                                .frame(width: 12, height: 12)
                                            Text(Self.allCentrals)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                    })
                                    
                                    Divider()
                                    
                                    ForEach(0..<subscribedCentrals.count, id: \.self) { index in
                                        let central: CBCentral = subscribedCentrals[index]
                                        let id = central.identifier.uuidString
                                        Button(action: {
                                            if selectedCentrals.contains(central) {
                                                selectedCentrals.removeAll(where: {$0 == central})
                                            } else {
                                                selectedCentrals.append(central)
                                            }
                                        }, label: {
                                            HStack {
                                                Image(systemName: selectedCentrals.contains(where: {$0.identifier.uuidString == id}) ? "checkmark.square" : "square")
                                                    .resizable()
                                                    .fontWeight(.bold)
                                                    .frame(width: 12, height: 12)
                                                Text(id)
                                                    .multilineTextAlignment(.leading)

                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                        })
                                        
                                    }
                                }
                                
                                
                            }
                        }
                        
                        
                        let mtu = subscribedCentrals.isEmpty ? 512 : subscribedCentrals.map({$0.maximumUpdateValueLength}).min() ?? 512
                        
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
                }
                .textFieldStyle(.roundedBorder)
                .padding(.all, 32)
                .frame(maxHeight: .infinity, alignment: .top)
                .presentationDetents(.init([.fraction(0.5)]))
                .onAppear {
                    entryError = ""
                    text = ""
                    selectedCentrals = subscribedCentrals
                }
                .onChange(of: showWriteSheet, initial: true, {
                    if !showWriteSheet {
                        selectedCharacteristic = nil
                    }
                })

            })

        }
        .navigationTitle("Service: \(self.service.uuid)")
        .navigationBarTitleDisplayMode(.inline)
        .multilineTextAlignment(.leading)
        
    }
}

private struct CharacteristicCellView: View {
    var updateValueAction: () -> Void
    var characteristic: CBCharacteristic

    @Environment(PeripheralManager.self) private var peripheralManager
    @State private var showAdvertisementDetail: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("ID: \(characteristic.uuid)")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    updateValueAction()
                }, label: {
                    Text("Update Value")
                })
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
            
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
            
            let value = characteristic.value?.string ?? ""
            let advertisementData: [Data] = peripheralManager.characteristicData[characteristic] ?? []
            
            if advertisementData.isEmpty {
                Text("Value: \(value.isEmpty ? "(none)" : value)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

            } else {
                Button(action: {
                    showAdvertisementDetail.toggle()
                }, label: {
                    HStack {
                        Text("Value: \(advertisementData.first!.string.isEmpty ? "(none)" : advertisementData.first!.string)")
                        if advertisementData.count  > 1 {
                            Image(systemName: showAdvertisementDetail ? "chevron.up" : "chevron.down")
                        }
                    }
                })
                .font(.subheadline)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

                
                if showAdvertisementDetail && advertisementData.count > 1 {
                    ForEach(1..<advertisementData.count, id: \.self) { index in
                        let data = advertisementData[index]
                        Text("- \(data.string.isEmpty ? "(none)" : data.string)")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                    }
                }
            }

            let centralIds = peripheralManager.subscribedCentrals[characteristic]?.map({$0.identifier.uuidString}).joined(separator: ", ") ?? ""

            Text("Subscribed channels: \(centralIds.isEmpty ? "(none)" : centralIds)")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        }
    }
}



