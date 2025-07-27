import SwiftUI
import CoreBluetooth

struct PeripheralView: View {
    @State private var peripheralManager = PeripheralManager()
    @State private var isAdvertising: Bool = false
    @State private var selectedItem: String? = nil
    @State private var showConfirmation = false
    @State private var customInput: String = ""
    @FocusState private var isTextFieldFocused: Bool

    let items = ["Pads", "Tampons", "Tissue", "Morning After Pill", "Contraception"]

    var body: some View {
        ZStack {
            Color("BGColor").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)
                // 🔹 Themed Toggle
                Toggle(isOn: $isAdvertising) {
                    Text("Requesting for help nearby...")
                        .font(.headline)
                        .foregroundColor(Color("FontColor"))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color("FontColor")))
                .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 16) {
                        // 🔹 Predefined items
                        ForEach(items, id: \.self) { item in
                            Button(action: {
                                selectedItem = item
                                showConfirmation = true
                            }) {
                                Text(item)
                                    .foregroundColor(Color("FontColor"))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("FontColor"), lineWidth: 1)
                                    )
                            }
                        }

                        // 🔹 Others section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Others")
                                .font(.headline)
                                .foregroundColor(Color("FontColor"))

                            TextField("What is the emergency?", text: $customInput)
                                .padding()
                                .foregroundColor(Color("FontColor"))
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color("FontColor").opacity(0.5), lineWidth: 1)
                                )
                                .focused($isTextFieldFocused)

                            if !customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button("Request") {
                                    selectedItem = customInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                    showConfirmation = true
                                    isTextFieldFocused = false
                                }
                                .foregroundColor(Color("FontColor"))
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Request Help")
                    .font(.headline)
                    .foregroundColor(Color("FontColor"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("BGColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)

        .alert("Would you like to request for \(selectedItem ?? "")?", isPresented: $showConfirmation) {
            Button("Yes") {
                if let item = selectedItem {
                    let service = peripheralManager.createSingleWritableService(withDescription: item)
                    peripheralManager.addService(service)
                    isAdvertising = true
                }
            }
            Button("No", role: .cancel) { }
        }

        .onChange(of: isAdvertising) { _, newValue in
            if newValue {
                peripheralManager.startAdvertising()
            } else {
                peripheralManager.stopAdvertising()
            }
        }

        .onDisappear {
            isAdvertising = false
        }
    }
}
