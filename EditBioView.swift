import SwiftUI
import FirebaseFirestore

struct EditBioView: View {
    @Binding var bio: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isSaving = false // 保存中の状態を追加
    @State private var alertMessage = ""
    @State private var showAlert = false
    private var db = Firestore.firestore()

    init(bio: Binding<String>) {
        self._bio = bio
    }

    var body: some View {
        Form {
            Section(header: Text("自己紹介を編集")) {   
                TextEditor(text: $bio)
                    .disableAutocorrection(true) // 自動修正を無効にする
                    .frame(minHeight: 100) // 必要に応じて高さを調整
            }
            Section {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button(action: {
                        saveBio()
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("自己紹介")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            if !isSaving {
            Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            }   
        })
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func saveBio() {
        isSaving = true
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId") else {
            print("No logged in user ID found")
            isSaving = false
            alertMessage = "エラーが発生しました。再ログインしてください。"
            showAlert = true
            return
        }

        FirestoreHelper.shared.loadUser(userId: userId) { result in
            switch result {
            case .success(var user):
                user.bio = bio
                FirestoreHelper.shared.saveUser(user) { saveResult in
                    isSaving = false
                    switch saveResult {
                    case .success:
                        print("Bio successfully updated to: \(user.bio)")
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    case .failure(let error):
                        print("Failed to save bio: \(error)")
                        alertMessage = "エラーが発生しました。再ログインしてください。"
                        showAlert = true
                    }
                }
            case .failure(let error):
                isSaving = false
                print("User not found: \(error)")
                alertMessage = "エラーが発生しました。再ログインしてください。"
                showAlert = true
            }
        }
    }
}