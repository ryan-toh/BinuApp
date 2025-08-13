import SwiftUI
import CoreBluetooth

struct PeripheralView: View {
    @State private var peripheralManager = PeripheralManager()
    @State private var isAdvertising: Bool = false
    @State private var selectedItem: String? = nil
    @State private var showConfirmation = false
    @State private var customInput: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private let items = ["Pads", "Tampons", "Tissue", "Morning After Pill", "Contraception"]

    var body: some View {
        ZStack {
            Color("BGColor").ignoresSafeArea()

            VStack(spacing: 0) {
                Header()

                ToggleRow(isOn: $isAdvertising)

                ResponseCard(text: peripheralManager.lastWrittenValue)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SectHeader(title: "What do you need?")

                        // Preset request buttons
                        VStack(spacing: 12) {
                            ForEach(items, id: \.self) { item in
                                PresetItemButton(title: item) {
                                    selectedItem = item
                                    showConfirmation = true
                                }
                            }
                        }

                        // Custom request
                        SectHeader(title: "Others")
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 10) {
                            TextField("What is the emergency?", text: $customInput)
                                .textInputAutocapitalization(.sentences)
                                .disableAutocorrection(false)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                                )
                                .focused($isTextFieldFocused)

                            Button {
                                let trimmed = customInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                selectedItem = trimmed
                                showConfirmation = true
                                isTextFieldFocused = false
                            } label: {
                                Label("Send Request", systemImage: "paperplane.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.7 : 1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarHidden(true)

        // Confirm + start advertising
        .alert("Request “\(selectedItem ?? "")”?", isPresented: $showConfirmation) {
            Button("Yes") {
                if let item = selectedItem {
                    let service = peripheralManager.createSingleWritableService(withDescription: item)
                    peripheralManager.addService(service)
                    isAdvertising = true
                }
            }
            Button("No", role: .cancel) { }
        }

        // Start/stop advertising like before
        .onChange(of: isAdvertising) { _, newValue in
            if newValue {
                peripheralManager.startAdvertising()
            } else {
                peripheralManager.stopAdvertising()
            }
        }
        .onDisappear { isAdvertising = false }
        .transaction { $0.disablesAnimations = true } // avoids mid‑tap churn
    }
}

// MARK: - Subviews (keeps the main body simple, faster to type‑check)

private struct Header: View {
    var body: some View {
        HStack {
            Image(systemName: "person.2.wave.2.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 30, weight: .medium))
                .padding(.trailing, 5)
            Text("Request Help Nearby")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .shadow(radius: 1)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

private struct ToggleRow: View {
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Label(
                isOn ? "Broadcasting Request" : "Enable Broadcast",
                systemImage: isOn ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
            )
            .fontWeight(.medium)
            .foregroundColor(isOn ? .accentColor : .gray)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(.accentColor)
        }
        .padding([.horizontal, .top], 20)
    }
}

private struct ResponseCard: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Latest Response", systemImage: "message.fill")
                .font(.headline)
                .foregroundColor(.accentColor)

            if !text.isEmpty {
                Text("“\(text)”")
                    .font(.title3.bold())
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(8)
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Waiting for response…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

private struct SectHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title3)
            .foregroundColor(Color("BGColor")) // matches your CentralView2 header style
            .padding(.bottom, 4)
    }
}

private struct PresetItemButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.tertiaryLabel)) // UIColor bridged; avoids type ambiguity
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}


//struct PeripheralView: View {
//    @State private var peripheralManager = PeripheralManager()
//    @State private var isAdvertising: Bool = false
//    @State private var selectedItem: String? = nil
//    @State private var showConfirmation = false
//    @State private var customInput: String = ""
//    @FocusState private var isTextFieldFocused: Bool
//
//    let items = ["Pads", "Tampons", "Tissue", "Morning After Pill", "Contraception"]
//
//    var body: some View {
//        ZStack {
//            Color("BGColor").ignoresSafeArea()
//
//            VStack(alignment: .leading, spacing: 16) {
//                Spacer().frame(height: 12)
//                // 🔹 Themed Toggle
//                Toggle(isOn: $isAdvertising) {
//                    Text("Requesting for help nearby...")
//                        .font(.headline)
//                        .foregroundColor(Color("FontColor"))
//                }
//                .toggleStyle(SwitchToggleStyle(tint: Color("FontColor")))
//                .padding(.horizontal)
//                
//                if !peripheralManager.lastWrittenValue.isEmpty {
//                    Group {
//                        Text("Received value:")
//                            .font(.subheadline)
//                            .foregroundColor(Color("FontColor"))
//                        Text("“\(peripheralManager.lastWrittenValue)”")
//                            .font(.title2)
//                            .bold()
//                            .foregroundStyle(.green)
//                            .padding(.bottom, 8)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                } else {
//                    Text("Waiting for response..")
//                        .font(.title2)
//                        .bold()
//                        .padding(.bottom, 8)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                }
//
//
//                ScrollView {
//                    VStack(spacing: 16) {
//                        // 🔹 Predefined items
//                        ForEach(items, id: \.self) { item in
//                            Button(action: {
//                                selectedItem = item
//                                showConfirmation = true
//                            }) {
//                                Text(item)
//                                    .foregroundColor(Color("FontColor"))
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                                    .background(
//                                        RoundedRectangle(cornerRadius: 10)
//                                            .stroke(Color("FontColor"), lineWidth: 1)
//                                    )
//                            }
//                        }
//
//                        // 🔹 Others section
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Others")
//                                .font(.headline)
//                                .foregroundColor(Color("FontColor"))
//
//                            TextField("What is the emergency?", text: $customInput)
//                                .padding()
//                                .foregroundColor(Color("FontColor"))
//                                .background(
//                                    RoundedRectangle(cornerRadius: 10)
//                                        .stroke(Color("FontColor").opacity(0.5), lineWidth: 1)
//                                )
//                                .focused($isTextFieldFocused)
//
//                            if !customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                                Button("Request") {
//                                    selectedItem = customInput.trimmingCharacters(in: .whitespacesAndNewlines)
//                                    showConfirmation = true
//                                    isTextFieldFocused = false
//                                }
//                                .foregroundColor(Color("FontColor"))
//                                .padding(.top, 4)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//        .toolbar {
//            ToolbarItem(placement: .principal) {
//                Text("Request Help")
//                    .font(.headline)
//                    .foregroundColor(Color("FontColor"))
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbarBackground(Color("BGColor"), for: .navigationBar)
//        .toolbarBackground(.visible, for: .navigationBar)
//
//        .alert("Would you like to request for \(selectedItem ?? "")?", isPresented: $showConfirmation) {
//            Button("Yes") {
//                if let item = selectedItem {
//                    let service = peripheralManager.createSingleWritableService(withDescription: item)
//                    peripheralManager.addService(service)
//                    isAdvertising = true
//                }
//            }
//            Button("No", role: .cancel) { }
//        }
//
//        .onChange(of: isAdvertising) { _, newValue in
//            if newValue {
//                peripheralManager.startAdvertising()
//            } else {
//                peripheralManager.stopAdvertising()
//            }
//        }
//
//        .onDisappear {
//            isAdvertising = false
//        }
//    }
//}
