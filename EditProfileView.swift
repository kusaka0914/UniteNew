import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import SDWebImageSwiftUI

struct EditProfileView: View {
    @Binding var currentUser: User
    @Binding var isEditProfileViewActive: Bool
    @State private var isEditNameViewActive = false
    @State private var isEditAccountNameViewActive = false
    @State private var isEditFacultyViewActive = false
    @State private var isEditDepartmentViewActive = false
    @State private var isEditClubViewActive = false
    @State private var isEditBioViewActive = false
    @State private var isEditWebsiteViewActive = false
    @State private var isEditIconViewActive = false // アイコン編集ビューの状態を追加
    @State private var isUserProfileViewActive = false
    @State private var iconImage: UIImage? = nil // アイコン画像の状態を追加
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    
    init(currentUser: Binding<User>, isEditProfileViewActive: Binding<Bool>) {
        self._currentUser = currentUser
        self._isEditProfileViewActive = isEditProfileViewActive
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: EditNameView(username: $currentUser.username)
            .navigationBarBackButtonHidden(true), isActive: $isEditNameViewActive) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                    Text("ユーザー名")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    Text(currentUser.username)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditNameViewActive = true
                }
            }
            
            NavigationLink(destination: EditAccountNameView(accountname: $currentUser.accountname)
            .navigationBarBackButtonHidden(true), isActive: $isEditAccountNameViewActive) {
                HStack {
                    Image(systemName: "at.circle.fill")
                        .foregroundColor(.white)
                    Text("アカウント名")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    Text(currentUser.accountname)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditAccountNameViewActive = true
                }
            }
            
            NavigationLink(destination: EditFacultyView(faculty: $currentUser.faculty)
            .navigationBarBackButtonHidden(true), isActive: $isEditFacultyViewActive) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.white)
                    Text("所属学部")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    Text(currentUser.faculty)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditFacultyViewActive = true
                }
            }
            
            NavigationLink(destination: EditDepartmentView(department: $currentUser.department, faculty: $currentUser.faculty)
            .navigationBarBackButtonHidden(true), isActive: $isEditDepartmentViewActive) {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                    Text("所属学科")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    Text(currentUser.department)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditDepartmentViewActive = true
                }
            }
            
            NavigationLink(destination: EditClubView(club: $currentUser.club)
            .navigationBarBackButtonHidden(true), isActive: $isEditClubViewActive) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                        
                    Text("所属サークル")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    Text(currentUser.club)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditClubViewActive = true
                }
            }
            
            NavigationLink(destination: EditBioView(bio: $currentUser.bio)
            .navigationBarBackButtonHidden(true), isActive: $isEditBioViewActive) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.white)
                    Text("プロフィール")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    Text(currentUser.bio)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditBioViewActive = true
                }
            }

            NavigationLink(destination: EditWebsiteView(website: $currentUser.website)
            .navigationBarBackButtonHidden(true), isActive: $isEditWebsiteViewActive) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.white)
                    Text("ウェブサイト")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    Text(currentUser.website)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditWebsiteViewActive = true
                }
            }
            
            NavigationLink(destination: EditIconView(currentUser: $currentUser, iconImage: $iconImage)
            .navigationBarBackButtonHidden(true), isActive: $isEditIconViewActive) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.white)
                    Text("アイコン")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Spacer()
                    if let iconImage = iconImage {
                        Image(uiImage: iconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else if let iconImageURL = currentUser.iconImageURL, let url = URL(string: iconImageURL) {
                        WebImage(url: url)
                                    .resizable()
                                    .onFailure { error in
                                        ProgressView()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                        
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    
                            } else {
                        Image("Sphere")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .contentShape(Rectangle()) // HStack全体をタップ可能にする
                .onTapGesture {
                    isEditIconViewActive = true
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .navigationTitle("プロフィール編集")
        .navigationBarItems(leading: Button(action: {
            isUserProfileViewActive = true
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .imageScale(.large)
        })
        .navigationDestination(isPresented: $isUserProfileViewActive) {
            UserProfileView(currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        if let userId = UserDefaults.standard.string(forKey: "loggedInUserId") {
            FirestoreHelper.shared.loadUser(userId: userId) { result in
                switch result {
                case .success(let loadedUser):
                    currentUser = loadedUser
                case .failure(let error):
                    print("Error loading user: \(error)")
                }
            }
        }
    }
    
    private func saveProfile() {
        FirestoreHelper.shared.saveUser(currentUser) { result in
            switch result {
            case .success:
                print("User successfully saved!")
            case .failure(let error):
                print("Error saving user: \(error)")
            }
        }
        if let iconImage = iconImage,
           let imageData = iconImage.jpegData(compressionQuality: 0.8) {
            let storageRef = storage.reference().child("userIcons/\(currentUser.id).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("Failed to upload image: \(error)")
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Failed to get download URL: \(error)")
                        return
                    }
                    
                    guard let downloadURL = url else {
                        print("Download URL is nil")
                        return
                    }
                    
                    currentUser.iconImageURL = downloadURL.absoluteString
                    FirestoreHelper.shared.saveUser(currentUser) { result in
                        switch result {
                        case .success:
                            print("User successfully saved with icon!")
                        case .failure(let error):
                            print("Error saving user with icon: \(error)")
                        }
                    }
                }
            }
        }
    }
}