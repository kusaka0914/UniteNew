import SwiftUI
import FirebaseFirestore

struct EditNameView: View {
    @Binding var username: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isSaving = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertType: AlertType = .error
    private var db = Firestore.firestore()

    enum AlertType {
        case error
        case confirmation
    }

    init(username: Binding<String>) {
        self._username = username
    }

    var body: some View {
        Form {
            Section(header: Text("ユーザーネームを編集")) {
                TextField("ユーザーネーム", text: $username)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
            }
            Section {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button(action: {
                        if username.isEmpty {
                            alertTitle = "エラー"
                            alertMessage = "ユーザーネームを入力してください。"
                            alertType = .error
                            showAlert = true
                        } else if !isValidUsername(username) {
                            alertTitle = "エラー"
                            alertMessage = "ユーザーネームは半角英語、数字、アンダースコア(_)のみで構成してください。"
                            alertType = .error
                            showAlert = true
                        } else {
                            checkUsernameAvailability { isAvailable in
                                if isAvailable {
                                    saveName()
                                } else {
                                    alertTitle = "エラー"
                                    alertMessage = "このユーザーネームは既に使用されています。別のユーザーネームを選択してください。"
                                    alertType = .error
                                    showAlert = true
                                }
                            }
                        }
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("ユーザーネーム")
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
            switch alertType {
            case .error:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            case .confirmation:
                return Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    primaryButton: .default(Text("OK")) {
                        saveName()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
    }

    private func saveName() {
        isSaving = true
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId") else {
            print("No logged in user ID found")
            isSaving = false
            alertTitle = "エラー"
            alertMessage = "エラーが発生しました。再ログインしてください。"
            alertType = .error
            showAlert = true
            return
        }

        FirestoreHelper.shared.loadUser(userId: userId) { result in
            switch result {
            case .success(var user):
                user.username = username
                FirestoreHelper.shared.saveUser(user) { saveResult in
                    isSaving = false
                    switch saveResult {
                    case .success:
                        print("Username successfully updated to: \(user.username)")
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    case .failure(let error):
                        print("Failed to save username: \(error)")
                        alertTitle = "エラー"
                        alertMessage = "エラーが発生しました。再ログインしてください。"
                        alertType = .error
                        showAlert = true
                    }
                }
            case .failure(let error):
                isSaving = false
                print("User not found: \(error)")
                alertTitle = "エラー"
                alertMessage = "エラーが発生しました。再ログインしてください。"
                alertType = .error
                showAlert = true
            }
        }
    }

    private func checkUsernameAvailability(completion: @escaping (Bool) -> Void) {
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error checking username availability: \(error)")
                alertTitle = "エラー"
                alertMessage = "エラーが発生しました。再ログインしてください。"
                alertType = .error
                showAlert = true
                completion(false)
                return
            }
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                completion(false) // ユーザーネームが既に存在する
                alertTitle = "エラー"
                alertMessage = "このユーザーネームは既に使用されています。別のユーザーネームを選択してください。"
                alertType = .error
                showAlert = true
            } else {
                completion(true) // ユーザーネームが利用可能
            }
        }
    }

    private func isValidUsername(_ username: String) -> Bool {
        let regex = "^[a-zA-Z0-9_]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: username)
    }
}