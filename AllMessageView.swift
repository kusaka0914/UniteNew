import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct AllMessageView: View {
    // @Binding var user: User
    @Binding var currentUserId: String
    @State var currentUser: User = User(id: "", password: "password", username: "currentUser", university: "University", posts: [], followers: [], following: [], accountname: "accountname", faculty: "faculty", department: "department", club: "club", bio: "bio", twitterHandle: "twitterHandle", email: "email", stories: [], iconImageURL: "", notifications: [], messages: [], groupMessages: [])
    @State private var users: [User] = []
    @State private var selectedUser: User = User(id: "", password: "password", username: "currentUser", university: "University", posts: [], followers: [], following: [], accountname: "accountname", faculty: "faculty", department: "department", club: "club", bio: "bio", twitterHandle: "twitterHandle", email: "email", stories: [], iconImageURL: "https://firebasestorage.googleapis.com/v0/b/splean-app.appspot.com/o/userIcons%2F1.jpg?alt=media&token=12345678-1234-5678-1234-567812345678", notifications: [], messages: [], groupMessages: [])
    @State private var selectedGroupMessage: GroupMessage?
    @State private var isMessageViewActive = false
    @State private var isGroupMessageViewActive = false
    @State private var isHomeViewActive = false
    @State private var isCreateGroupMessageViewActive = false
    @State private var groupName: String = ""
    @State private var prevView: String = "AllMessageView"
    @State private var isLoading = true // データ読み込み中の状態を示すフラグ

    private var db = Firestore.firestore()

    init(currentUserId: Binding<String>) {
        self._currentUserId = currentUserId
        
    }
    
    var body: some View {
        if isLoading {
            ProgressView()
            .onAppear {
                loadCurrentUser() {
                    if !currentUser.messages.isEmpty {
                        loadUsers {
                        }
                    } else {
                            isLoading = false
                    }
                }
            }
        } else {
        // NavigationStack {
            VStack {
                if users.isEmpty && !currentUser.groupMessages.isEmpty {
                    ScrollView {
                    VStack {
                    ForEach(currentUser.groupMessages) { groupMessage in
                        GroupMessageRow(groupMessage: groupMessage, iconImageURL: groupMessage.iconImageURL, currentUser: $currentUser, groupName: groupMessage.name)
                        }
                        Spacer()
                    }}
                }else if users.isEmpty && currentUser.groupMessages.isEmpty {
                    Text("メッセージがありません")
                        .foregroundColor(.gray)
                        .padding()
                        Spacer()
                }else if currentUser.groupMessages.isEmpty && !users.isEmpty {
                    ScrollView {
                    VStack {
                        ForEach($users) { $user in
                            UserMessageRow(user: $user, currentUser: $currentUser, selectedUser: $selectedUser, isMessageViewActive: $isMessageViewActive,  onSelect: {
                                selectedUser = $user.wrappedValue
                                isMessageViewActive = true
                            })
                        }
                        Spacer()
                    }
                    }
                } else {
                    ScrollView {
                    VStack {
                        ForEach($users) { $user in
                            UserMessageRow(user: $user, currentUser: $currentUser, selectedUser: $selectedUser, isMessageViewActive: $isMessageViewActive,  onSelect: {
                                selectedUser = $user.wrappedValue
                                isMessageViewActive = true
                            })
                        }

                        ForEach(currentUser.groupMessages) { groupMessage in
                            GroupMessageRow(groupMessage: groupMessage, iconImageURL: groupMessage.iconImageURL, currentUser: $currentUser, groupName: groupMessage.name)
                        }
                        Spacer()
                    }
                    
                }
                }
            }.background(Color.black)
            
            .navigationDestination(isPresented: $isMessageViewActive) {
                MessageView(currentUser: $currentUser, otherUser: $selectedUser, prevView: $prevView)
                    .navigationBarBackButtonHidden(true)
            }
            .navigationTitle("メッセージ一覧")
            .navigationBarItems(leading: Button(action: {
                isHomeViewActive = true
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
            .navigationBarItems(trailing: Button(action: {
                isCreateGroupMessageViewActive = true
            }) {
                Image(systemName: "plus.message")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
            .navigationDestination(isPresented: $isHomeViewActive) {
                HomeView(currentUser: $currentUser, postUser: User(
                    id: "current_user_id",
                    password: "password",
                    username: "current_user",
                    university: "current_university",
                    posts: [],
                    followers: [],
                    following: [],
                    accountname: "current_accountname",
                    faculty: "current_faculty",
                    department: "current_department",
                    club: "current_club",
                    bio: "current_bio",
                    twitterHandle: "current_twitterHandle",
                    email: "current@example.com",
                    stories: [],
                    iconImageURL: "https://example.com/icon.jpg",
                    notifications: [],
                    messages: [],
                    courses: [],
                    groupMessages: []
                ))
                    .navigationBarBackButtonHidden(true)
            }.gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        isHomeViewActive = true
                    }
                }
            ).onAppear {
                loadCurrentUser() {
                if !currentUser.messages.isEmpty {
                loadUsers {
                    isLoading = false
                    // loadMessages {
                    //     isLoading = false // データ取得が完了したらフラグを更新
                    //     print("Data loaded successfully")
                    // }
                }
                }
            }
            }
            .navigationDestination(isPresented: $isCreateGroupMessageViewActive) {
                CreateGroupMessageView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
        // }
        }
    }

    private func loadUsers(completion: @escaping () -> Void) {
        let userIds = currentUser.messages.flatMap { [$0.senderId, $0.receiverId] }.filter { $0 != currentUser.id }
        

        FirestoreHelper.shared.loadUsers(userIds: userIds) { result in
        DispatchQueue.main.async {
            switch result {
            case .success(let users):
            print("success")
                self.users = users 
                isLoading = false
                // if let encodedData = try? JSONEncoder().encode(users) {
                //     UserDefaults.standard.set(encodedData, forKey: "users")
                // }
                print("success")
                completion()
            case .failure(let error):
                print("Failed to load users: \(error)")
                isLoading = false
            }
            
        }
    }
    }

    private func loadCurrentUser(completion: @escaping () -> Void) {
           FirestoreHelper.shared.loadUser(userId: currentUserId) { result in
       DispatchQueue.main.async {
           switch result {
           case .success(let loadedUser):
               self.currentUser = loadedUser
               completion()
           case .failure(let error):
               print("Error loading user: \(error)")
           }
       }
   }
    }

    private func loadMessages(completion: @escaping () -> Void) {
        FirestoreHelper.shared.loadMessages(for: currentUserId) { messages in
            // TimestampをDateに変換
            self.currentUser.messages = messages.map { message in
                var newMessage = message
                newMessage.date = message.date
                return newMessage
            }
            
            completion()
        }
    }


//     private func markMessagesAsRead(from user: User) {
//         var updatedMessages: [Message] = []
        
//         for i in 0..<currentUser.messages.count {
//             if currentUser.messages[i].senderId == user.id && !currentUser.messages[i].isRead {
//                 currentUser.messages[i].isRead = true
//                 updatedMessages.append(currentUser.messages[i])
//             }
//         }
        
//         // Firestoreに保存
//         let db = Firestore.firestore()
//         let batch = db.batch()
        
//         for message in updatedMessages {
//             let messageRef = db.collection("messages").document(message.id)
//             batch.updateData(["isRead": true], forDocument: messageRef)
//         }
        
//         batch.commit { error in
//             if let error = error {
//                 print("Failed to mark messages as read: \(error)")
//             } else {
//                 print("Messages marked as read")
//                 FirestoreHelper.shared.saveUser(currentUser) { result in
//                     switch result {
//                     case .success:
//                         print("User data updated")
//                     case .failure(let error):
//                         print("Failed to update user data: \(error)")
//                     }
//                 }
//             }
//         }
//     }
}

struct UserMessageRow: View {
    @Binding var user: User
    @Binding var currentUser: User
    @Binding var selectedUser: User
    @Binding var isMessageViewActive: Bool
    // var markMessagesAsRead: (User) -> Void
    var onSelect: () -> Void

    var body: some View {
        Button(action: {
            // markMessagesAsRead(user)
            onSelect()
        }) {
            HStack {
                if let iconImageURL = user.iconImageURL, let url = URL(string: iconImageURL) {
                    if iconImageURL == "" {
                        Image("Sphere")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                    WebImage(url: url)
                                    .resizable()
                                    .onFailure { error in
                                        ProgressView()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .padding(.trailing, 10)
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    
                    }
                } else {
                    Image("Sphere")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    if let lastMessage = currentUser.messages.filter({ $0.receiverId == user.id || $0.senderId == user.id }).max(by: { $0.date.dateValue() < $1.date.dateValue() }) {
                        Text(lastMessage.text)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.leading, 8)
                    }
                }
                Spacer()
                if currentUser.messages.contains(where: { $0.senderId == user.id && !$0.isRead }) {
                    Text("\(currentUser.messages.filter { $0.senderId == user.id && !$0.isRead }.count)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color(red: 75/255, green: 72/255, blue: 232/255))
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 30)
            .background(Color.black)
            .cornerRadius(10)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

struct GroupMessageRow: View {
    @State var groupMessage: GroupMessage
    @State var iconImageURL: String?
    @State var groupId: String = ""
    @State var selectedUsersId: [String] = []
    @Binding var currentUser: User
    @State var groupName: String
    @State var isGroupMessageViewActive: Bool = false

    var body: some View {
        Button(action: {
            groupId = groupMessage.id
            selectedUsersId = groupMessage.userIds
            isGroupMessageViewActive = true
        }) {
            HStack {
                if let iconImageURL = iconImageURL, let url = URL(string: iconImageURL) {
                    if iconImageURL == "" {
                        Image("Sphere")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                    WebImage(url: url)
                            .resizable()
                            .onFailure { error in
                                ProgressView()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .padding(.trailing, 10)
                            }
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                    }
                } else {
                Image("Sphere")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                }
                VStack(alignment: .leading) {
                    Text(groupName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    // if let lastMessage = currentUser.messagesGroup.max(by: { $0.date.dateValue() < $1.date.dateValue() }) {
                    //     Text(lastMessage.text)
                    //         .font(.subheadline)
                    //         .foregroundColor(.gray)
                    //         .lineLimit(1)
                    //         .truncationMode(.tail)
                    // }
                }
                Spacer()
                if groupMessage.messages.contains(where: { !$0.isRead && $0.receiverId == currentUser.id }) {
                    Text("\(groupMessage.messages.filter { !$0.isRead && $0.receiverId == currentUser.id }.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 30)
            .background(Color.black)
            .cornerRadius(10)
        }.navigationDestination(isPresented: $isGroupMessageViewActive) {
            GroupMessageView(groupMessage: $groupMessage, currentUser: $currentUser, selectedUsersId: $selectedUsersId, iconImageURL: $iconImageURL, groupName: $groupName, selectedUser: User(id: "", password: "", username: "", university: "", posts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: []), groupId: $groupId)
                        .navigationBarBackButtonHidden(true)
                
            }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}
