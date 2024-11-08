import SwiftUI
import FirebaseFirestore

struct EditAccountNameView: View {
    @Binding var accountname: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isSaving = false // 保存中の状態を追加
    @State private var alertMessage = ""
    @State private var showAlert = false
    private var db = Firestore.firestore()

    init(accountname: Binding<String>) {
        self._accountname = accountname
    }

    var body: some View {
        Form {
            Section(header: Text("アカウント名を編集")) {
                TextField("アカウント名", text: $accountname)
                    .disableAutocorrection(true) // 自動修正を無効にする
            }
            Section {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button(action: {
                        if accountname.isEmpty {
                            alertMessage = "アカウント名を入力してください。"
                            showAlert = true
                        } else {
                            saveAccountName()
                        }
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("アカウント名")
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

    private func saveAccountName() {
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
                user.accountname = accountname
                FirestoreHelper.shared.saveUser(user) { saveResult in
                    isSaving = false
                    switch saveResult {
                    case .success:
                        print("Account name successfully updated to: \(user.accountname)")
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    case .failure(let error):
                        print("Failed to save account name: \(error)")
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