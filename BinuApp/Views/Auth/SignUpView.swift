//
//  LoginView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss  // for BACK button

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""

    @State private var selectedGender: String? = nil
    @State private var selectedAge: Int? = nil

    @State private var isGenderPickerVisible = false
    @State private var isAgePickerVisible = false

    @State private var isLoading = false
    @State private var showAlert = false
    @State private var errorMessage = ""

    let genderOptions = ["Female", "Male"]
    let ageRange = Array(18...100)

    var body: some View {
        ZStack {
            Color("BGColor")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // Back Button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(Color("FontColor"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                    Text("Create Your Account")
                        .font(.largeTitle.bold())
                        .foregroundColor(Color("FontColor"))

                    // Email, Password, Username
                    VStack(spacing: 0) {
                        customField("Email", text: $email, keyboard: .emailAddress)
                        Divider().background(Color.white.opacity(0.3))
                        customSecureField("Password", text: $password)
                        Divider().background(Color.white.opacity(0.3))
                        customField("Username", text: $username)
                    }
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal, 30)

                    // Gender, Age
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation {
                                isGenderPickerVisible.toggle()
                                isAgePickerVisible = false
                            }
                        }) {
                            HStack {
                                Text(selectedGender ?? "Gender")
                                    .foregroundColor(selectedGender == nil ? .gray : Color("FontColor"))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }

                        if isGenderPickerVisible {
                            Picker("Gender", selection: Binding(
                                get: { selectedGender ?? "" },
                                set: {
                                    selectedGender = $0
                                    withAnimation {
                                        isGenderPickerVisible = false
                                    }
                                }
                            )) {
                                ForEach(genderOptions, id: \.self) { gender in
                                    Text(gender).tag(gender)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                            .transition(.opacity)
                        }

                        Divider().background(Color.white.opacity(0.3))

                        Button(action: {
                            withAnimation {
                                isAgePickerVisible.toggle()
                                isGenderPickerVisible = false
                            }
                        }) {
                            HStack {
                                Text(selectedAge == nil ? "Age" : "Age: \(selectedAge!)")
                                    .foregroundColor(selectedAge == nil ? .gray : Color("FontColor"))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }

                        if isAgePickerVisible {
                            Picker("Age", selection: Binding(
                                get: { selectedAge ?? ageRange.first! },
                                set: {
                                    selectedAge = $0
                                    withAnimation {
                                        isAgePickerVisible = false
                                    }
                                }
                            )) {
                                ForEach(ageRange, id: \.self) { age in
                                    Text("\(age)").tag(age)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                            .transition(.opacity)
                        }
                    }
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal, 30)

                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(Color("FontColor"))
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("FontColor").opacity(0.1))
                            )
                            .padding(.horizontal, 30)
                    }

                    // Create Account Button
                    Button(action: {
                        guard let gender = selectedGender else {
                            errorMessage = "Please select a gender."
                            return
                        }

                        guard let age = selectedAge else {
                            errorMessage = "Please select your age."
                            return
                        }

                        isLoading = true
                        errorMessage = ""
                        authVM.signUp(
                            email: email,
                            password: password,
                            username: username,
                            gender: gender,
                            age: age
                        ) { success in
                            isLoading = false
                            if !success {
                                errorMessage = "Oops! We couldn’t sign you up. Please check your details and try again."
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("FontColor"))
                                .cornerRadius(25)
                        } else {
                            Text("Create Account")
                                .fontWeight(.bold)
                                .foregroundColor(Color("BGColor"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("FontColor"))
                                .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 30)
                    .disabled(isLoading)

                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
    }

    // Reusable Input Fields
    func customField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .autocapitalization(.none)
            .padding()
            .foregroundColor(Color("FontColor"))
    }

    func customSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding()
            .foregroundColor(Color("FontColor"))
    }
}

#Preview {
    SignUpView().environmentObject(AuthViewModel())
}
