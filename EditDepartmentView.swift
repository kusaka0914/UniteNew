import SwiftUI
import FirebaseFirestore

struct EditDepartmentView: View {
    @Binding var department: String
    @Binding var faculty: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isSaving = false // 保存中の状態を追加
    @State private var alertMessage = ""
    @State private var showAlert = false
    private var db = Firestore.firestore()

    init(department: Binding<String>, faculty: Binding<String>) {
        self._department = department
        self._faculty = faculty
    }

    let scienceDepartments = ["電子情報工学科", "機械化学科", "数物科学科", "物質創生科学科", "地球環境防災学科", "自然エネルギー学科"]
    let agricultureDepartments = ["生物学科", "分子生命科学科", "農業化学科", "食料資源学科", "国際園芸農学科", "地球環境工学科"]
    let educationDepartments = ["小学校コース", "中学校コース", "特別支援教育専攻"]
    let humanitiesDepartments = ["文化資源学コース", "多文化共生コース", "経済法律コース", "企業戦略コース", "地域行動コース"]
    let medicalDepartments = ["医学科", "保健学科", "心理支援科学科"]

    var body: some View {
        Form {
            Section(header: Text("所属学科を編集").foregroundColor(.white)) {
                Picker("所属学科", selection: $department) {
                    if faculty == "理工学部" {
                        ForEach(scienceDepartments, id: \.self) { department in
                            Text(department)
                                .foregroundColor(.white) // 文字色を白に設定
                                .tag(department)
                        }
                    }
                    if faculty == "農学生命科学部" {
                        ForEach(agricultureDepartments, id: \.self) { department in
                            Text(department)
                                .foregroundColor(.white) // 文字色を白に設定
                                .tag(department)
                        }
                    }
                    if faculty == "教育学部" {
                        ForEach(educationDepartments, id: \.self) { department in
                            Text(department)
                                .foregroundColor(.white) // 文字色を白に設定
                                .tag(department)
                        }
                    }
                    if faculty == "人文社会科学部" {
                        ForEach(humanitiesDepartments, id: \.self) { department in
                            Text(department)
                                .foregroundColor(.white) // 文字色を白に設定
                                .tag(department)
                        }
                    }
                    if faculty == "医学部" {
                        ForEach(medicalDepartments, id: \.self) { department in
                            Text(department)
                                .foregroundColor(.white) // 文字色を白に設定
                                .tag(department)
                        }
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
                        saveDepartment()
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("所属学科")
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

    private func saveDepartment() {
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
                user.department = department
                FirestoreHelper.shared.saveUser(user) { saveResult in
                    isSaving = false
                    switch saveResult {
                    case .success:
                        print("Department successfully updated to: \(user.department)")
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    case .failure(let error):
                        print("Failed to save department: \(error)")
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