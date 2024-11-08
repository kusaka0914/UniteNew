import SwiftUI
import FirebaseFirestore

struct EditFacultyView: View {
    @Binding var faculty: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isSaving = false // 保存中の状態を追加
    @State private var alertMessage = ""
    @State private var showAlert = false
    private var db = Firestore.firestore()

    init(faculty: Binding<String>) {
        self._faculty = faculty
    }

    let faculties = ["理工学部", "農学生命科学部", "人文社会科学部", "教育学部", "医学部"]

    var body: some View {
        Form {
            Section(header: Text("所属学部を編集").foregroundColor(.white)) {
                Picker("所属学部", selection: $faculty) {
                    ForEach(faculties, id: \.self) { faculty in
                        Text(faculty)
                            .foregroundColor(.white) // 文字色を白に設定
                            .tag(faculty)
                    }
                }
                .pickerStyle(MenuPickerStyle()) // ピッカースタイルをメニューに設定
            }
            Section {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button(action: {
                        saveFaculty()
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("所属学部")
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

    private func saveFaculty() {
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
                user.faculty = faculty
                FirestoreHelper.shared.saveUser(user) { saveResult in
                    isSaving = false
                    switch saveResult {
                    case .success:
                        print("Faculty successfully updated to: \(user.faculty)")
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    case .failure(let error):
                        print("Failed to save faculty: \(error)")
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