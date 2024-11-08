import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

struct EditIconView: View {
    @Binding var currentUser: User
    @Binding var iconImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isSaving = false // 保存中の状態を追加
    @State private var alertMessage = ""
    @State private var showAlert = false
    private var db = Firestore.firestore()
    private var storage = Storage.storage()

    init(currentUser: Binding<User>, iconImage: Binding<UIImage?>) {
        self._currentUser = currentUser
        self._iconImage = iconImage
    }

    var body: some View {
        Form {
            Section(header: Text("アイコンを編集")) {
                if let iconImage = iconImage {
                    Image(uiImage: iconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(Circle())
                } else {
                    Image("Sphere")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200) 
                        .clipShape(Circle())
                }
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("写真フォルダーから選択")
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            iconImage = uiImage
                        } else {
                            print("Failed to load image data")
                        }
                    }
                }
            }
            Section {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button(action: {
                        saveIcon()
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationTitle("アイコン")
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

    private func saveIcon() {
        isSaving = true
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId") else {
            print("No logged in user ID found")
            isSaving = false
            alertMessage = "エラーが発生しました。再ログインしてください。"
            showAlert = true
            return
        }

        guard let iconImage = iconImage, let imageData = iconImage.pngData() else {
            print("Failed to convert UIImage to Data")
            isSaving = false
            alertMessage = "写真を選択してください。"
            showAlert = true
            return
        }

        let storageRef = storage.reference().child("userIcons/\(userId).png")
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"

        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Failed to upload image: \(error)")
                isSaving = false
                alertMessage = "エラーが発生しました。再ログインしてください。"
                showAlert = true
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error)")
                    isSaving = false
                    alertMessage = "エラーが発生しました。再ログインしてください。"
                    showAlert = true
                    return
                }

                guard let downloadURL = url else {
                    print("Download URL is nil")
                    isSaving = false
                    alertMessage = "エラーが発生しました。再ログインしてください。"
                    showAlert = true
                    return
                }

                FirestoreHelper.shared.loadUser(userId: userId) { result in
                    switch result {
                    case .success(var user):
                        user.iconImageURL = downloadURL.absoluteString
                        FirestoreHelper.shared.saveUser(user) { saveResult in
                            isSaving = false
                            switch saveResult {
                            case .success:
                                print("Icon successfully updated")
                                DispatchQueue.main.async {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            case .failure(let error):
                                print("Failed to save icon: \(error)")
                                alertMessage = "エラーが発生しました。再ログインしてください。"
                                showAlert = true
                            }
                        }
                    case .failure(let error):
                        print("User not found: \(error)")
                        alertMessage = "エラーが発生しました。再ログインしてください。"
                        showAlert = true
                    }
                }
            }
        }
    }
}