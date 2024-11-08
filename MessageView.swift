import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct MessageView: View {
    @Binding var currentUser: User
    @Binding var otherUser: User
    @Binding var prevView: String
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    @State private var selectedImages: [String] = []
    @State private var showImagePicker = false
    @FocusState private var isMessageFieldFocused: Bool
    @State private var isAllMessageViewActive = false
    @State private var isMessageMeMoViewActive = false
    @State private var dragOffset: CGFloat = 0.0
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, otherUser: Binding<User>, prevView: Binding<String>) {
        self._currentUser = currentUser
        self._otherUser = otherUser
        self._prevView = prevView
    }

    var body: some View {
        ZStack {
            if isMessageMeMoViewActive {
                MessageMemoView(currentUser: $currentUser, otherUser: $otherUser)
                    .transition(.move(edge: .trailing))
            } else {
                VStack {
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            MessageListView(messages: $messages, currentUser: $currentUser, otherUser: $otherUser, deleteMessage: deleteMessage)
                                .onChange(of: messages) { _ in
                                    scrollToBottom(scrollViewProxy: scrollViewProxy)
                                }
                        }
                        

                        MessageInputView(messageText: $messageText, showImagePicker: $showImagePicker, selectedImages: $selectedImages, isMessageFieldFocused: $isMessageFieldFocused, messages: $messages, sendMessage: sendMessage, sendImages: sendImages, scrollViewProxy: scrollViewProxy)
                    }
                }.background(Color.black)
                .onAppear {
                            loadMessages()
                            markMessagesAsRead()
                        }
                .navigationTitle(otherUser.username)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button(action: {
                        if prevView == "AllMessageView" {
                            isAllMessageViewActive = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                )
                .navigationDestination(isPresented: $isAllMessageViewActive) {
                    AllMessageView(currentUserId: $currentUser.id)
                    .navigationBarBackButtonHidden(true)
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImages: $selectedImages)
                }.onChange(of: selectedImages) { _ in
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




//     private func isReadTrue() {
//     db.collection("users").whereField("id", isEqualTo: currentUser.id).getDocuments { querySnapshot, error in
//         if let error = error {
//             print("Error getting documents: \(error)")
//             return
//         }
//         if let documents = querySnapshot?.documents, !documents.isEmpty {
//             for document in documents {
//                 do {
//                     var user = try document.data(as: User.self)
//                     var updatedMessages = user.messages.map { message -> Message in
//                         var mutableMessage = message
//                         if message.senderId == currentUser.id {
//                             mutableMessage.isRead = true
//                         }
//                         return mutableMessage
//                     }
//                     user.messages = updatedMessages
//                     try db.collection("users").document(user.id).setData(from: user) { error in
//                         if let error = error {
//                             print("Error updating user messages: \(error)")
//                         } else {
//                             print("User messages updated successfully")
//                         }
//                     }
//                 } catch {
//                     print("Error decoding user: \(error)")
//                 }
//             }
//         }
//     }
// }
    private func loadMessages() {
        let currentUserId = currentUser.id
        let otherUserId = otherUser.id

        db.collection("messages")
            .whereField("senderId", in: [currentUserId, otherUserId])
            .whereField("receiverId", in: [currentUserId, otherUserId])
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                self.messages = documents.compactMap { queryDocumentSnapshot -> Message? in
                    try? queryDocumentSnapshot.data(as: Message.self)
                }.sorted(by: { $0.date.dateValue() < $1.date.dateValue() }) // Sort messages by date
                
            }
    }

    private func sendMessage() {
        let currentUserId = currentUser.id
        let otherUserId = otherUser.id

        let message = Message(id: UUID().uuidString, senderId: currentUserId, receiverId: otherUserId, text: messageText, images: nil, date: Date())
        do {
            let documentRef = db.collection("messages").document()
            var messageWithId = message
            messageWithId.id = documentRef.documentID
            try documentRef.setData(from: messageWithId) { error in
                if let error = error {
                    print("Error writing message to Firestore: \(error)")
                } else {
                    print("Message successfully written!")
                    self.messageText = "" // Clear the message text after sending
                    self.currentUser.messages.append(messageWithId) // Add message to currentUser's messages
                    FirestoreHelper.shared.saveUser(self.currentUser) { result in
                        switch result {
                        case .success():
                            print("User messages updated successfully")
                        case .failure(let error):
                            print("Failed to update user messages: \(error)")
                        }
                    }
                    FirestoreHelper.shared.loadUser(userId: otherUserId) { result in
                        switch result {
                        case .success(let otherUser):
                            var updatedOtherUser = otherUser
                            updatedOtherUser.messages.append(messageWithId)
                            FirestoreHelper.shared.saveUser(updatedOtherUser) { result in
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
        } catch {
            print("Error writing message to Firestore: \(error)")
        }
    }

    private func sendImages(_ images: [String]) {
        let currentUserId = currentUser.id
        let otherUserId = otherUser.id

        for imageUrl in images {
            let message = Message(id: UUID().uuidString, senderId: currentUserId, receiverId: otherUserId, text: "", images: [imageUrl], date: Date())
            do {
                let documentRef = db.collection("messages").document()
                var messageWithId = message
                messageWithId.id = documentRef.documentID
                try documentRef.setData(from: messageWithId) { error in
                    if let error = error {
                        print("Error writing message to Firestore: \(error)")
                    } else {
                        print("Image message successfully written!")
                        self.selectedImages.removeAll() // Clear the selected images after sending
                        self.currentUser.messages.append(messageWithId) // Add message to currentUser's messages
                        FirestoreHelper.shared.saveUser(self.currentUser) { result in
                            switch result {
                            case .success():
                                print("User messages updated successfully")
                            case .failure(let error):
                                print("Failed to update user messages: \(error)")
                            }
                        }
                        FirestoreHelper.shared.loadUser(userId: otherUserId) { result in
                            switch result {
                            case .success(let otherUser):
                                var updatedOtherUser = otherUser
                                updatedOtherUser.messages.append(messageWithId)
                                FirestoreHelper.shared.saveUser(updatedOtherUser) { result in
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
            } catch {
                print("Error writing message to Firestore: \(error)")
            }
        }
    }

    private func deleteMessage(_ message: Message) {
        let messageId = message.id
        let currentUserId = currentUser.id
        let otherUserId = otherUser.id

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
        otherUser.messages.removeAll { $0.id == messageId }
        FirestoreHelper.shared.saveUser(otherUser) { result in
            switch result {
            case .success():
                print("Other user's messages updated successfully")
            case .failure(let error):
                print("Failed to update other user's messages: \(error)")
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

struct MessageListView: View {
    @Binding var messages: [Message]
    @Binding var currentUser: User
    @Binding var otherUser: User
    var deleteMessage: (Message) -> Void
    @State private var isAnotherUserProfileViewActive = false
    var body: some View {
        VStack(alignment: .leading) {
            ForEach($messages) { $message in
                HStack {
                    if message.senderId == currentUser.id {
                        Spacer()
                        if let imageUrls = message.images {
                            ForEach(imageUrls, id: \.self) { imageUrl in
                                if let url = URL(string: imageUrl), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                                        .cornerRadius(20)
                                        .contextMenu {
                                            Button(action: {
                                                UIPasteboard.general.image = uiImage
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
                        if let imageUrls = message.images {
                        ForEach(imageUrls, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                                    .cornerRadius(20)
                                    .contextMenu {
                                        // Button(action: {
                                        //     saveImageToPhotos(uiImage)
                                        // }) {
                                        //     Text("保存")
                                        //     Image(systemName: "square.and.arrow.down")
                                        // }
                                    }
                            }
                        }
                    } else {
                            HStack {
                                if let iconImageURL = otherUser.iconImageURL, let url = URL(string: iconImageURL) {
                                    if iconImageURL == "" {
                                        Image("Sphere")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .onTapGesture {
                                                isAnotherUserProfileViewActive = true
                                            }
                                            .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                                    AnotherUserProfileView(user: $otherUser, currentUser: $currentUser)
                                        .navigationBarBackButtonHidden(true)
                                }
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
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .onTapGesture {
                                                isAnotherUserProfileViewActive = true
                                            }
                                            .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                                    AnotherUserProfileView(user: $otherUser, currentUser: $currentUser)
                                        .navigationBarBackButtonHidden(true)
                                }
                                    }
                                } else {
                                    Image("Sphere")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .onTapGesture {
                                            isAnotherUserProfileViewActive = true
                                        }
                                        .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                                    AnotherUserProfileView(user: $otherUser, currentUser: $currentUser)
                                        .navigationBarBackButtonHidden(true)
                                }
                                        .contextMenu {
                                            Button(action: {
                                                UIPasteboard.general.string = message.text
                                            }) {
                                                Text("コピー")
                                                Image(systemName: "doc.on.doc")
                                            }
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
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .id(message.id)
                .padding(.bottom, 8)
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var messageText: String
    @Binding var showImagePicker: Bool
    @Binding var selectedImages: [String]
    @FocusState.Binding var isMessageFieldFocused: Bool
    @Binding var messages: [Message]
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



struct DynamicHeightTextEditor: View {
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
