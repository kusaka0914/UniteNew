import SwiftUI
import FirebaseFirestore

struct BulltinBoardDetailView: View {
    @State var post: BulltinBoard
    @State private var isCreateAnswerViewActive = false
    @State private var postUser: User? = nil
    @Binding var currentUser: User
    @State private var answers: [Answer] = []
    @State private var isBulltinBoardViewActive = false
    private var db = Firestore.firestore()
    @Environment(\.dismiss) private var dismiss
    @State private var ismakeResponder = false
    @State private var showAlert = false

    init(post: BulltinBoard, currentUser: Binding<User>) {
        self._post = State(initialValue: post)
        self._currentUser = currentUser
        self._ismakeResponder = State(initialValue: UserDefaults.standard.bool(forKey: "isMakeResponder_\(post.id)"))
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    BulltinBoardPostDetailView(post: post, user: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0), currentUser: $currentUser)
                    AnswerListView(answers: $answers, post: post, currentUser: $currentUser, ismakeResponder: $ismakeResponder, showAlert: $showAlert, db: db)
                }
            }
            .navigationTitle("投稿詳細")
            .navigationBarItems(leading: Button(action: {
                isBulltinBoardViewActive = true
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
            .navigationDestination(isPresented: $isBulltinBoardViewActive) {
                BulltinBoardView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCurrentUser()
                loadAnswers()
            }

            Spacer()

            if post.userId != currentUser.id && ismakeResponder == false {
                Button(action: {
                    isCreateAnswerViewActive = true
                }) {
                    HStack {
                        Spacer()
                        Text("回答する")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .navigationDestination(isPresented: $isCreateAnswerViewActive) {
                    CreateAnswerView(currentUser: $currentUser, post: post, receiverId: post.userId)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }.background(Color.black)
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

    private func loadAnswers() {
        db.collection("answers").whereField("postId", isEqualTo: post.id).getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.answers = documents.compactMap { queryDocumentSnapshot -> Answer? in
                let data = queryDocumentSnapshot.data()
                do {
                    return try JSONDecoder().decode(Answer.self, from: JSONSerialization.data(withJSONObject: data))
                } catch {
                    print("Failed to decode Answer: \(error)")
                    return nil
                }
            }
        }
    }
}

struct BulltinBoardPostDetailView: View {
    var post: BulltinBoard
    @State private var user: User
    @Binding var currentUser: User
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    init(post: BulltinBoard, user: User, currentUser: Binding<User>) {
        self.post = post
        self.user = user
        self._currentUser = currentUser
    }

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                HStack {
                    if let iconUrl = user.iconImageURL, let url = URL(string: iconUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            
                            .onTapGesture {
                                if user.id != currentUser.id {
                                    isAnotherUserProfileViewActive = true
                                }else{
                                    isUserProfileViewActive = true
                                }
                            }
                    } placeholder: {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    }
                } else {
                    Image("Sphere")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                }
                    Text(user.username)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
                .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                    AnotherUserProfileView(user: $user, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                .navigationDestination(isPresented: $isUserProfileViewActive) {
                    UserProfileView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                HStack {
                    Text(post.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    Spacer()
                }
                HStack {
                    Text(post.text)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    Spacer()
                }

                if let imageUrls = post.images {
                    TabView {
                        ForEach(imageUrls, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: UIScreen.main.bounds.width - 40)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 16)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                        }
                    }
                    .frame(height: 300) // 画像の高さを設定
                    .tabViewStyle(PageTabViewStyle())
                }
            }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 0.5)
            )
            .background(Color(red: 33/255, green: 33/255, blue: 33/255))
        }
        .padding(.horizontal, 24)
        .onAppear {
            loadUser()
        }
    }

    private func loadUser() {
        FirestoreHelper.shared.loadUser(userId: post.userId) { result in
            switch result {
            case .success(let user):
                self.user = user
            case .failure(let error):
                print("Current user not found: \(error)")
            }
        }
    }
}

struct AnswerListView: View {
    @Binding var answers: [Answer]
    var post: BulltinBoard
    @Binding var currentUser: User
    @Binding var ismakeResponder: Bool
    @Binding var showAlert: Bool
    var db: Firestore

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("回答一覧")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                Spacer()
            }

            if answers.isEmpty {
                HStack {
                    Text("まだ回答がありません")
                        .foregroundColor(.gray)
                        .padding(.leading, 32)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    Spacer()
                }
            } else {
                ForEach(answers) { answer in
                    AnswerView(answer: answer, post: post, currentUser: $currentUser, ismakeResponder: $ismakeResponder, showAlert: $showAlert, db: db, senderUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0))
                }.padding(.horizontal, 24)
            }
        }
    }
}

struct AnswerView: View {
    var answer: Answer
    var post: BulltinBoard
    @Binding var currentUser: User
    @Binding var ismakeResponder: Bool
    @Binding var showAlert: Bool
    var db: Firestore
    @State private var senderUser: User
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    init(answer: Answer, post: BulltinBoard, currentUser: Binding<User>, ismakeResponder: Binding<Bool>, showAlert: Binding<Bool>, db: Firestore, senderUser: User) {
        self.answer = answer
        self.post = post
        self._currentUser = currentUser
        self._ismakeResponder = ismakeResponder
        self._showAlert = showAlert
        self.db = db
        self.senderUser = senderUser
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let iconUrl = senderUser.iconImageURL, let url = URL(string: iconUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .onTapGesture {
                                if senderUser.id != currentUser.id {
                                    isAnotherUserProfileViewActive = true
                                }
                            }
                    } placeholder: {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    }
                } else {
                    Image("Sphere")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .onTapGesture {
                            isAnotherUserProfileViewActive = true
                        }
                }
                Button(action: {
                    if senderUser.id != currentUser.id {
                        isAnotherUserProfileViewActive = true
                    }else{
                        isUserProfileViewActive = true
                    }
                }) {
                    Text(senderUser.username)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                }
                .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                    AnotherUserProfileView(user: $senderUser, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                .navigationDestination(isPresented: $isUserProfileViewActive) {
                    UserProfileView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                    .fontWeight(.bold)
                    .padding(.trailing, 16)
                    .navigationDestination(isPresented: $ismakeResponder) {
                        BulltinBoardView(currentUser: $currentUser)
                    }
                if post.userId == currentUser.id && post.responderId == nil && ismakeResponder == false {
                    Button(action: {
                        showAlert = true
                    }) {
                        Text("回答者にする")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            Text(answer.text)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            if let imageUrls = answer.images {
                TabView {
                    ForEach(imageUrls, id: \.self) { imageUrl in
                        if let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: UIScreen.main.bounds.width - 40)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
                .frame(height: 300) // 画像の高さを設定
                .tabViewStyle(PageTabViewStyle())
            }
            Divider()
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 0.5)
        )
        .background(Color(red: 33/255, green: 33/255, blue: 33/255))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("本当に回答者にしますか？"), message: Text("回答者は1度しか選べません"), primaryButton: .default(Text("決定")) {
                makeResponder(post: post, answer: answer)
                ismakeResponder = true
                UserDefaults.standard.set(true, forKey: "isMakeResponder_\(post.id)")
            }, secondaryButton: .cancel(Text("キャンセル")))
        }
        .onAppear {
            loadSenderUser()
        }
    }

    private func loadSenderUser() {
        db.collection("users").document(answer.senderId).getDocument { document, error in
            if let error = error {
                print("Error getting user document: \(error)")
                return
            }

            guard let document = document, document.exists else {
                print("User does not exist")
                return
            }

            do {
                senderUser = try document.data(as: User.self)
                self.senderUser = senderUser
            } catch {
                print("Error decoding user data: \(error)")
            }
        }
    }

    private func makeResponder(post: BulltinBoard, answer: Answer) {
        let userId = answer.senderId
        let userRef = db.collection("users").document(userId)
        let postRef = db.collection("bulletinBoardPosts").document(post.id)

        userRef.getDocument { document, error in
            if let error = error {
                print("Error getting user document: \(error)")
                return
            }

            guard let document = document, document.exists else {
                print("User does not exist")
                return
            }

            do {
                var user = try document.data(as: User.self)
                user.points += 10
                user.solution += 1

                FirestoreHelper.shared.saveUser(user) { result in
                    switch result {
                    case .success:
                        print("ユーザーのポイントが加算されました", user.points)
                    case .failure(let error):
                        print("Failed to update user: \(error)")
                    }
                }

                try userRef.setData(from: user) { error in
                    if let error = error {
                        print("Error setting user data: \(error)")
                        return
                    }

                    postRef.updateData(["isResolved": true]) { error in
                        if let error = error {
                            print("Error updating isResolved: \(error)")
                        } else {
                            print("isResolved: \(post.isResolved)")
                        }
                    }
                }
            } catch {
                print("Error decoding user data: \(error)")
            }
        }
    }
}
