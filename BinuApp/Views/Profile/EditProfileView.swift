import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var gender = ""
    @State private var ageText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                VStack {
                    Form {
                        Section(header: Text("Edit Info").foregroundColor(Color("FontColor"))) {
                            TextField("Username", text: $username)
                                .foregroundColor(Color("FontColor"))

                            TextField("Gender", text: $gender)
                                .foregroundColor(Color("FontColor"))

                            TextField("Age", text: $ageText)
                                .keyboardType(.numberPad)
                                .foregroundColor(Color("FontColor"))
                        }

                        Section {
                            Button {
                                if let age = Int(ageText) {
                                    authVM.updateProfile(username: username, gender: gender, age: age) {
                                        dismiss()
                                    }
                                }
                            } label: {
                                Text("Save")
                                    .font(.headline)
                                    .foregroundColor(Color("FontColor"))
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color("BGColor"))
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let user = authVM.user {
                username = user.username
                gender = user.gender
                ageText = "\(user.age)"
            }
        }
    }
}
