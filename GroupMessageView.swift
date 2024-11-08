import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import SDWebImageSwiftUI

struct GroupMessageView: View {
    @Binding var groupMessage: GroupMessage
    @Binding var currentUser: User
    @Binding var selectedUsersId: [String]
    @State var users: [User] = []
    @Binding var iconImageURL: String?
    @State var selectedUser: User
    @Binding var groupName: String
    @Binding var groupId: String
    @State private var messageText: String = ""
    @State private var messages: [MessageGroup] = []
    @State private var selectedImages: [String] = []
    @State private var showImagePicker = false
    @FocusState private var isMessageFieldFocused: Bool
    @State private var isAllMessageViewActive = false
    @State private var isAllMemberViewActive = false
    @State private var isMessageMeMoViewActive = false
    @State private var dragOffset: CGFloat = 0.0
    @Environment(\.presentationMode) var presentationMode

    private var db = Firestore.firestore()

    init(groupMessage: Binding<GroupMessage>, currentUser: Binding<User>, selectedUsersId: Binding<[String]>, iconImageURL: Binding<String?>, groupName: Binding<String>, selectedUser: User, groupId: Binding<String>) {
        self._groupMessage = groupMessage
        self._currentUser = currentUser
        self._selectedUsersId = selectedUsersId
        self._iconImageURL = iconImageURL
        self._groupName = groupName
        self.selectedUser = selectedUser
        self._groupId = groupId
    }

    var body: some View {
        ZStack {
            if isMessageMeMoViewActive {
                // MessageMemoView(currentUser: $currentUser, selectedUsers: $selectedUsers)
                //     .transition(.move(edge: .trailing))
            } else {
                VStack {
                            HStack {
                                Button(action: {
                                    isAllMessageViewActive = true
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .imageScale(.large)
                                        .padding(.leading, 16)
                                    
                                }
                                Spacer()
                                Text(groupName )
                                    .font(.headline)
                                    .onTapGesture {
                                        isAllMemberViewActive = true
                                    }
                                Text(">")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .onTapGesture {
                                        isAllMemberViewActive = true
                                    }
                                Spacer()
                            }.padding(.top, 16)
                            .navigationDestination(isPresented: $isAllMemberViewActive) {
                                        AllMemberView(groupMessage: $groupMessage, groupName: $groupName, allUsersId: selectedUsersId, currentUser: $currentUser, selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: iconImageURL, notifications: [], messages: [], courses: [], groupMessages: [], points: 0), iconImageURL: $iconImageURL)
                                        .navigationBarBackButtonHidden(true)
                            }
                            ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            GroupMessageListView(messages: $messages, currentUser: $currentUser, users: $users, deleteMessage: deleteMessage)
                                .onChange(of: messages) { _ in
                                    scrollToBottom(scrollViewProxy: scrollViewProxy)
                                }
                                .onTapGesture {
                                    isMessageFieldFocused = false
                                }
                        }
                        GroupMessageInputView(messageText: $messageText, showImagePicker: $showImagePicker, selectedImages: $selectedImages, isMessageFieldFocused: $isMessageFieldFocused, messages: $messages, sendMessage: sendMessage, sendImages: sendImages, scrollViewProxy: scrollViewProxy)
                    }
                }
                .background(Color.black)
                .onAppear {
                    loadMessages()
                    markMessagesAsRead()
                    loadUsers()
                }
                .navigationDestination(isPresented: $isAllMessageViewActive) {
                    AllMessageView(currentUserId: $currentUser.id)
                    .navigationBarBackButtonHidden(true)
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImages: $selectedImages)
                }
                .onChange(of: selectedImages) { _ in
                    if !selectedImages.isEmpty {
                        sendImages(selectedImages)
                        showImagePicker = false
                    }
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -100 {
                                withAnimation {
                                    isMessageMeMoViewActive = true
                                }
                            }
                            dragOffset = 0
                            if value.translation.width > 100 {
                                withAnimation {
                                    isAllMessageViewActive = true
                                }
                            }
                        }
                )
            }
        }
    }
    private func loadUsers() {
        let userIds = selectedUsersId
        for userId in userIds {
            FirestoreHelper.shared.loadUser(userId: userId) { result in
                switch result {
                case .success(let user):
                    self.users.append(user)
                case .failure(let error):
                    print("Failed to load user: \(error)")
                }
            }
        }
    }

    private func markMessagesAsRead() {
        let userRef = db.collection("users").document(currentUser.id)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error getting document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, var userData = document.data() else {
                print("No user data found")
                return
            }
            
            if var messages = userData["messages"] as? [[String: Any]] {
                for i in 0..<messages.count {
                    messages[i]["isRead"] = true
                }
                userData["messages"] = messages
                
                userRef.setData(userData, merge: true) { error in
                    if let error = error {
                        print("Error updating messages: \(error.localizedDescription)")
                    } else {
                        print("All messages marked as read")
                    }
                }
            }
        }
    }

    private func loadMessages() {
        let currentUserId = currentUser.id

        db.collection("messages")
            .whereField("groupId", isEqualTo: groupId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                self.messages = documents.compactMap { queryDocumentSnapshot -> MessageGroup? in
                    try? queryDocumentSnapshot.data(as: MessageGroup.self)
                }.sorted(by: { $0.date.dateValue() < $1.date.dateValue() })
            }
    }

    private func sendMessage() {
    let currentUserId = currentUser.id
    let allIds = currentUser.groupMessages.first(where: { $0.id == groupId })?.userIds ?? []

    let message = MessageGroup(
        id: UUID().uuidString,
        senderId: currentUserId,
        receiverId: selectedUsersId.filter { $0 != currentUserId },
        allIds: allIds,
        text: messageText,
        images: [],
        date: Timestamp(date: Date()),
        isRead: false,
        groupId: groupId
    )
    
    do {
        let documentRef = db.collection("messages").document()
        var messageWithId = message
        messageWithId.id = documentRef.documentID
        try documentRef.setData(from: messageWithId) { error in
            if let error = error {
                print("Error writing message to Firestore: \(error)")
            } else {
                print("Message successfully written!")
                self.messageText = ""
                self.updateMessagesGroup(for: allIds, with: messageWithId)
            }
        }
    } catch {
        print("Error writing message to Firestore: \(error)")
    }
}

private func updateMessagesGroup(for userIds: [String], with message: MessageGroup) {
    for userId in userIds {
        FirestoreHelper.shared.loadUser(userId: userId) { result in
            switch result {
            case .success(let user):
                var updatedUser = user
                updatedUser.messagesGroup.append(message)
                FirestoreHelper.shared.saveUser(updatedUser) { result in
                    switch result {
                    case .success():
                        print("User \(userId)'s messages updated successfully")
                    case .failure(let error):
                        print("Failed to update user \(userId)'s messages: \(error)")
                    }
                }
            case .failure(let error):
                print("Failed to load user \(userId): \(error)")
            }
        }
    }
}

    private func sendImages(_ images: [String]) {
    let currentUserId = currentUser.id
    guard let group = currentUser.groupMessages.first(where: { $0.name == groupName }) else {
        print("Group not found")
        return
    }
    let groupId = group.id
    let allIds = group.userIds
    var imageUrls: [String] = []

    let dispatchGroup = DispatchGroup()

    for image in images {
        imageUrls.append(image)
    }

    dispatchGroup.notify(queue: .main) {
        let message = MessageGroup(
            id: UUID().uuidString,
            senderId: currentUserId,
            receiverId: selectedUsersId.filter { $0 != currentUserId },
            allIds: allIds,
            text: "",
            images: imageUrls,
            date: Timestamp(date: Date()),
            isRead: false,
            groupId: groupId
        )
        do {
            let documentRef = db.collection("messages").document()
            var messageWithId = message
            messageWithId.id = documentRef.documentID
            try documentRef.setData(from: messageWithId) { error in
                if let error = error {
                    print("Error writing message to Firestore: \(error)")
                } else {
                    print("Image message successfully written!")
                    self.selectedImages.removeAll()
                    self.updateMessagesGroup(for: allIds, with: messageWithId)
                }
            }
        } catch {
            print("Error writing message to Firestore: \(error)")
        }
    }
}

    private func deleteMessage(_ message: MessageGroup) {
        let messageId = message.id
        let currentUserId = currentUser.id

        db.collection("messages").document(messageId).delete { error in
            if let error = error {
                print("Error deleting message: \(error)")
            }
        }
        currentUser.messages.removeAll { $0.id == messageId }
        FirestoreHelper.shared.saveUser(currentUser) { result in
            switch result {
            case .success():
                print("User messages updated successfully")
            case .failure(let error):
                print("Failed to update user messages: \(error)")
            }
        }
        for selectedUserId in selectedUsersId {
            FirestoreHelper.shared.loadUser(userId: selectedUserId) { result in
                switch result {
                case .success(let selectedUser):
                    var updatedSelectedUser = selectedUser
                    updatedSelectedUser.messages.removeAll { $0.id == messageId }
                    FirestoreHelper.shared.saveUser(updatedSelectedUser) { result in
                        switch result {
                        case .success():
                            print("Other user's messages updated successfully")
                        case .failure(let error):
                            print("Failed to update other user's messages: \(error)")
                        }
                    }
                case .failure(let error):
                    print("Failed to load other user: \(error)")
                }
            }
        }
    }

    private func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct GroupMessageListView: View {
    @Binding var messages: [MessageGroup]
    @Binding var currentUser: User
    @Binding var users: [User]
    var deleteMessage: (MessageGroup) -> Void
    @State private var isAnotherUserProfileViewActive = false
    @State private var selectedUser: User = User(id: "", password: "", username: "", university: "", posts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], groupMessages: [])

    var body: some View {
        VStack(alignment: .leading) {
            ForEach($messages) { $message in
                HStack {
                    if message.senderId == currentUser.id {
                        Spacer()
                        if let images = message.images, !images.isEmpty {
                            ForEach(images, id: \.self) { imageUrl in
                                WebImage(url: URL(string: imageUrl))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                                    .contextMenu {
                                        Button(action: {
                                            UIPasteboard.general.string = imageUrl
                                        }) {
                                            Text("コピー")
                                            Image(systemName: "doc.on.doc")
                                        }
                                        Button(action: {
                                            deleteMessage(message)
                                        }) {
                                            Text("削除")
                                            Image(systemName: "trash")
                                        }
                                    }
                            }
                        } else {
                            Text(message.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 121/255, green: 33/255, blue: 222/255))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = message.text
                                    }) {
                                        Text("コピー")
                                        Image(systemName: "doc.on.doc")
                                    }
                                    // 削除ボタンは自分のメッセージにのみ表示
                                    Button(action: {
                                        deleteMessage(message)
                                    }) {
                                        Text("削除")
                                        Image(systemName: "trash")
                                    }
                                }
                        }
                    } else {
                        if let images = message.images, !images.isEmpty {
                            ForEach(images, id: \.self) { imageUrl in
                                WebImage(url: URL(string: imageUrl))
                                    .resizable()
                                    .padding(.horizontal, 56)
                                    .padding(.vertical, 8)
                                    .scaledToFit()
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                                    .contextMenu {
                                        Button(action: {
                                            UIPasteboard.general.string = imageUrl
                                        }) {
                                            Text("コピー")
                                            Image(systemName: "doc.on.doc")
                                        }
                                    }
                            }
                        } else {
                            VStack {
                                HStack {
                                Text(users.first(where: { $0.id == message.senderId })?.accountname ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 65)
                                    Spacer()
                                }
                                HStack {
                                    if let iconImageURL = users.first(where: { $0.id == message.senderId })?.iconImageURL, let url = URL(string: iconImageURL) {
                                    WebImage(url: url)
                                            .resizable()
                                            .onFailure { error in
                                                ProgressView()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                                    .padding(.trailing, 10)
                                            }
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .onTapGesture {
                                                isAnotherUserProfileViewActive = true
                                                selectedUser = users.first(where: { $0.id == message.senderId }) ?? User(id: "", password: "", username: "", university: "", posts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], groupMessages: [])
                                            }
                                            

                                } else {
                                    Image("Sphere")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                        .onTapGesture { 
                                            isAnotherUserProfileViewActive = true
                                            selectedUser = users.first(where: { $0.id == message.senderId }) ?? User(id: "", password: "", username: "", university: "", posts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], groupMessages: [])
                                        }
                                }
                                Text(message.text)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 46/255, green: 44/255, blue: 44/255))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                                    .contextMenu {
                                        Button(action: {
                                            UIPasteboard.general.string = message.text
                                        }) {
                                            Text("コピー")
                                            Image(systemName: "doc.on.doc")
                                        }
                                    }
                                }
                            }
                            .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                            AnotherUserProfileView(user: $selectedUser, currentUser: $currentUser)
                                .navigationBarBackButtonHidden(true)
                                .onDisappear {
                                    isAnotherUserProfileViewActive = false
                                    }
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
}

struct GroupMessageInputView: View {
    @Binding var messageText: String
    @Binding var showImagePicker: Bool
    @Binding var selectedImages: [String]
    @FocusState.Binding var isMessageFieldFocused: Bool
    @Binding var messages: [MessageGroup]
    var sendMessage: () -> Void
    var sendImages: ([String]) -> Void
    var scrollViewProxy: ScrollViewProxy

    var body: some View {
        HStack {
            DynamicHeightTextEditor(messageText: $messageText, placeholder: "メッセージを入力...", maxHeight: 100)
                .font(.system(size: 18))

            Button(action: {
                showImagePicker = true
            }) {
                Image(systemName: "photo")
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }

            Button(action: {
                if !selectedImages.isEmpty {
                    sendImages(selectedImages)
                } else if messageText.isEmpty {
                    isMessageFieldFocused = false
                } else {
                    sendMessage()
                }
                scrollToBottom(scrollViewProxy: scrollViewProxy)
            }) {
                if !messageText.isEmpty || !selectedImages.isEmpty {
                    Text("送信")
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
            }
        }
        .padding()
    }

    private func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}



struct GroupDynamicHeightTextEditor: View {
    @Binding var messageText: String
    let placeholder: String
    let maxHeight: CGFloat
    @FocusState var isMessageFieldFocused: Bool
    var body: some View {
        ZStack(alignment: .leading) {

            // テキストエディター
            HStack {
                Text(messageText.isEmpty ? " " : messageText)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
            .foregroundColor(.clear)
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
            .background(TextEditor(text: $messageText).scrollContentBackground(.hidden).background(.clear).offset(y: 1.8).focused($isMessageFieldFocused))
            if messageText.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
                    .onTapGesture {
                    isMessageFieldFocused = true
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(maxHeight: maxHeight) // テキストエディタの最大サイズを設定する
        .fixedSize(horizontal: false, vertical: true) // テキストエディタの最大サイズを設定する
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}
