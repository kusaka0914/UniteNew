import SwiftUI
import FirebaseFirestore

struct AllFollowingView: View {
    @Binding var user: User
    @Binding var currentUser: User
    @State private var users: [User] = []
    @State private var selectedUser: User
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    @State private var showFollowButton = false
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    private var db = Firestore.firestore()

    init(user: Binding<User>, currentUser: Binding<User>, selectedUser: User) {
        self._user = user
        self._currentUser = currentUser
        self.selectedUser = selectedUser
    }

    var body: some View {
        // NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if users.isEmpty {
                            
                            Spacer()
                            HStack {
                            Spacer()
                            Text("フォロー中のユーザーがいません")
                                .foregroundColor(.gray)
                                
                            Spacer()
                            }
                            Spacer()
                        } else {
                        ForEach($users) { $user in
                            UserRow(user: $user, currentUser: $currentUser, showFollowButton: $showFollowButton, onSelect: {
                                selectedUser = $user.wrappedValue
                                    if selectedUser.id != currentUser.id {
                                        isAnotherUserProfileViewActive = true
                                    } else {
                                        isUserProfileViewActive = true
                                    }
                                })
                            
                        }
                        }
                    }
                }
            }
            }
            .onAppear {
                isLoading = true
                loadUsers()
                // loadCurrentUser(
            }
            .background(Color.black)
            .foregroundColor(.white)
            .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                
                    AnotherUserProfileView(user: $selectedUser, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                
            }
            .navigationDestination(isPresented: $isUserProfileViewActive) {
                UserProfileView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
        // }
        .navigationTitle("フォロー中のユーザー")
        .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
    }
    
    private func loadUsers() {
        db.collection("users").getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                isLoading = false
                return
            }
            let allUsers = documents.compactMap { queryDocumentSnapshot -> User? in
                let data = queryDocumentSnapshot.data()
                return FirestoreHelper.shared.decodeUser(from: data)
            }
            self.users = allUsers.filter { user.following.contains($0.id) }
            isLoading = false
        } 
    }

    private func loadCurrentUser() {
        FirestoreHelper.shared.loadCurrentUser { result in
            switch result {
            case .success(let user):
                currentUser = user
            case .failure(let error):
                print("Current user not found: \(error)")
            }
        }
    }
}