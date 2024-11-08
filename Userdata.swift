import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct Answer: Identifiable, Codable {
    var id: String
    var postId: String // BulltinBoardのID
    var senderId: String
    var receiverId: String
    var text: String
    var images: [String]?
    var senderName: String // 回答者のユーザーネーム
    var senderIconUrl: String? // 回答者のアイコンURL
}

struct Memo: Identifiable, Codable{
    var id: String
    var name: String
    var senderId: String
    var receiverId: String
    var text: String
    var date: Timestamp = Timestamp(date: Date())
}

struct TextPost: Identifiable, Codable{
    var id: String
    var text: String
    var userId: String
    var goodCount: Int = 0
    var likedBy: [String] = []
    var date: Timestamp = Timestamp(date: Date())
}

struct Post: Identifiable, Codable {
    var id: String
    var text: String
    var userId: String
    var imageUrls: [String]
    var goodCount: Int = 0
    var likedBy: [String] = []
    var date: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id, text, userId, imageUrls, goodCount, likedBy, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        userId = try container.decode(String.self, forKey: .userId)
        imageUrls = try container.decode([String].self, forKey: .imageUrls)
        goodCount = try container.decode(Int.self, forKey: .goodCount)
        likedBy = try container.decode([String].self, forKey: .likedBy)
        if let timestamp = try? container.decode(Timestamp.self, forKey: .date) {
            date = timestamp.dateValue()
        } else {
            date = try container.decode(Date.self, forKey: .date)
        }
    }

    init(id: String, text: String, userId: String, imageUrls: [String], goodCount: Int = 0, likedBy: [String] = [], date: Date = Date()) {
        self.id = id
        self.text = text
        self.userId = userId
        self.imageUrls = imageUrls
        self.goodCount = goodCount
        self.likedBy = likedBy
        self.date = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(userId, forKey: .userId)
        try container.encode(imageUrls, forKey: .imageUrls)
        try container.encode(goodCount, forKey: .goodCount)
        try container.encode(likedBy, forKey: .likedBy)
        try container.encode(Timestamp(date: date), forKey: .date)
    }
}

struct EverythingBoard: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var category: String
    var goodCount: Int = 0
    var likedBy: [String] = []
    var text: String
    var images: [String]? // DataからStringに変更
    var date: Date = Date()
    var userId: String
    var senderUniversity: String
    var link: String?

    enum CodingKeys: String, CodingKey {
        case id, title, category, goodCount, likedBy, text, images, date, userId, senderUniversity, link
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        goodCount = try container.decode(Int.self, forKey: .goodCount)
        likedBy = try container.decode([String].self, forKey: .likedBy)
        text = try container.decode(String.self, forKey: .text)
        images = try container.decodeIfPresent([String].self, forKey: .images) // DataからStringに変更
        if let timestamp = try? container.decode(Timestamp.self, forKey: .date) {
            date = timestamp.dateValue()
        } else {
            date = try container.decode(Date.self, forKey: .date)
        }
        userId = try container.decode(String.self, forKey: .userId)
        senderUniversity = try container.decode(String.self, forKey: .senderUniversity)
        link = try container.decode(String.self, forKey: .link)
    }

    init(id: String, title: String, category: String, goodCount: Int = 0, likedBy: [String] = [], text: String, images: [String]? = nil, date: Date = Date(), userId: String, senderUniversity: String, link: String = "") {
        self.id = id
        self.title = title
        self.category = category
        self.goodCount = goodCount
        self.likedBy = likedBy
        self.text = text
        self.images = images
        self.date = date
        self.userId = userId
        self.senderUniversity = senderUniversity
        self.link = link
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encode(goodCount, forKey: .goodCount)
        try container.encode(likedBy, forKey: .likedBy)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(images, forKey: .images) // DataからStringに変更
        try container.encode(Timestamp(date: date), forKey: .date)
        try container.encode(userId, forKey: .userId)
        try container.encode(senderUniversity, forKey: .senderUniversity)
        try container.encode(link, forKey: .link)
    }

    static func == (lhs: EverythingBoard, rhs: EverythingBoard) -> Bool {
        return lhs.id == rhs.id
    }
}
struct BulltinBoard: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var text: String
    var images: [String]? // DataからStringに変更
    var date: Date = Date()
    var userId: String
    var senderUniversity: String
    var isResolved: Bool = false
    var responderId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, text, images, date, userId, senderUniversity, isResolved, responderId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        images = try container.decodeIfPresent([String].self, forKey: .images) // DataからStringに変更
        if let timestamp = try? container.decode(Timestamp.self, forKey: .date) {
            date = timestamp.dateValue()
        } else {
            date = try container.decode(Date.self, forKey: .date)
        }
        userId = try container.decode(String.self, forKey: .userId)
        senderUniversity = try container.decode(String.self, forKey: .senderUniversity)
        isResolved = try container.decode(Bool.self, forKey: .isResolved)
        responderId = try container.decodeIfPresent(String.self, forKey: .responderId)
    }

    init(id: String, title: String, text: String, images: [String]? = nil, date: Date = Date(), userId: String, senderUniversity: String, isResolved: Bool = false, responderId: String? = nil) {
        self.id = id
        self.title = title
        self.text = text
        self.images = images
        self.date = date
        self.userId = userId
        self.senderUniversity = senderUniversity
        self.isResolved = isResolved
        self.responderId = responderId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(images, forKey: .images) // DataからStringに変更
        try container.encode(Timestamp(date: date), forKey: .date)
        try container.encode(userId, forKey: .userId)
        try container.encode(senderUniversity, forKey: .senderUniversity)
        try container.encode(isResolved, forKey: .isResolved)
        try container.encodeIfPresent(responderId, forKey: .responderId)
    }

    static func == (lhs: BulltinBoard, rhs: BulltinBoard) -> Bool {
        return lhs.id == rhs.id
    }
}
struct MessageGroup: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var senderId: String
    var receiverId: [String]
    var allIds: [String]
    var text: String
    var images: [String]?
    var date: Timestamp
    var isRead: Bool
    var groupId: String
}
struct Message: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var senderId: String
    var receiverId: String
    var text: String
    var images: [String]?
    var date: Timestamp
    var isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, senderId, receiverId, text, images, date, isRead
    }

    

    init(id: String, senderId: String, receiverId: String, text: String, images: [String]? = nil, date: Date, isRead: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.images = images
        self.date = Timestamp(date: date)
        self.isRead = isRead
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encode(date, forKey: .date)
        try container.encode(isRead, forKey: .isRead)
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

struct GroupMessage: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var userIds: [String]
    var messages: [Message]
    var iconImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, userIds, messages, iconImageURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        userIds = try container.decode([String].self, forKey: .userIds)
        messages = try container.decode([Message].self, forKey: .messages)
        iconImageURL = try container.decodeIfPresent(String.self, forKey: .iconImageURL)
    }

    init(id: String, name: String, userIds: [String], messages: [Message], iconImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.userIds = userIds
        self.messages = messages
        self.iconImageURL = iconImageURL
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(userIds, forKey: .userIds)
        try container.encode(messages, forKey: .messages)
        try container.encodeIfPresent(iconImageURL, forKey: .iconImageURL)
    }

    static func == (lhs: GroupMessage, rhs: GroupMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct User: Identifiable, Codable {
    var id: String
    var password: String?
    var username: String
    var university: String
    var posts: [Post] = []
    var texts: [TextPost] = []
    var followers: [String] = []
    var following: [String] = []
    var accountname: String
    var faculty: String
    var department: String
    var club: String
    var bio: String
    var twitterHandle: String
    var email: String
    var stories: [Story] = []
    var iconImageURL: String?
    var notifications: [Notification] = []
    var messages: [Message] = []
    var messagesGroup: [MessageGroup] = []
    var courses: [Course] = []
    var groupMessages: [GroupMessage] = []
    var everythingBoards: [EverythingBoard] = []
    var points: Int = 0
    var solution:Int = 0
    var isSubscribed: Bool = false
    var blockedUsers: [String] = []
    var website: String = ""
    

    func isFollowing(user: User) -> Bool {
        return following.contains(user.id)
    }

    func unreadMessagesCount() -> Int {
        return messages.filter { !$0.isRead && $0.receiverId == id }.count
    }
}

class AuthHelper {
    static let shared = AuthHelper()
    
    private init() {}
    
    func signUp(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    func logIn(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    func logOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch let signOutError as NSError {
            completion(.failure(signOutError))
        }
    }
}

class FirestoreHelper {
    static let shared = FirestoreHelper()
    private let db = Firestore.firestore()
    private let storage = Storage.storage() // ここでstorageインスタンスを定義
    
    private init() {}
    
    func saveUser(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
    do {
        // Userをエンコードして辞書形式に変換
        let data = try JSONEncoder().encode(user)
        var dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        
        // courses から courseNames を生成
        let courseNames = user.courses.map { $0.name }
        
        // courseNames を dictionary に追加
        dictionary["courseNames"] = courseNames
        
        // Firestoreに保存する際、Date型をそのまま保存できるように修正
        let firestoreData = dictionary.mapValues { value -> Any in
            if let date = value as? Date {
                return Timestamp(date: date) // FirestoreのTimestamp型に変換
            }
            return value
        }

        // Firestoreに保存
        db.collection("users").document(user.id).setData(firestoreData, merge: true) { error in
            if let error = error {
                print("Failed to save user: \(error)")
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    } catch {
        print("Failed to encode user: \(error)")
        completion(.failure(error))
    }
}


    func loadUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let data = try JSONSerialization.data(withJSONObject: document.data()!, options: .fragmentsAllowed)
                    let user = try JSONDecoder().decode(User.self, from: data)
                    completion(.success(user))
                } catch {
                    print("Failed to decode user: \(error)")
                    completion(.failure(error))
                }
            } else {
                print("User does not exist")
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User does not exist"])))
            }
        }
    }

    func loadGroupMessages(for userId: String, completion: @escaping ([GroupMessage]) -> Void) {
        db.collection("groupMessages").whereField("userIds", arrayContains: userId).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting group messages: \(error)")
                completion([])
            } else {
                let groupMessages = querySnapshot?.documents.compactMap { document -> GroupMessage? in
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data(), options: .fragmentsAllowed)
                        return try JSONDecoder().decode(GroupMessage.self, from: data)
                    } catch {
                        print("Failed to decode group message: \(error)")
                        return nil
                    }
                } ?? []
                completion(groupMessages)
            }
        }
    }
    
    func loadCurrentUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])))
            return
        }
        loadUser(userId: currentUserId, completion: completion)
    }

    func decodeUser(from data: [String: Any]) -> User? {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .fragmentsAllowed)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(Timestamp.self)
            return timestamp.dateValue()
        }
        return try decoder.decode(User.self, from: jsonData)
    } catch {
        print("Failed to decode user: \(error)")
        return nil
    }
}

    func uploadIconImage(_ image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = storage.reference().child("userIcons/\(userId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let downloadURL = url?.absoluteString {
                    completion(.success(downloadURL))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                }
            }
        }
    }

    func sendMessage(sender: User, receiver: User, text: String, images: [String]? = nil) {
        let message = Message(id: UUID().uuidString, senderId: sender.id, receiverId: receiver.id, text: text, images: images, date: Date())
        do {
            let data = try JSONEncoder().encode(message)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
            db.collection("messages").addDocument(data: dictionary) { error in
                if let error = error {
                    print("Failed to send message: \(error)")
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }

    func loadMessages(for userId: String, completion: @escaping ([Message]) -> Void) {
        let receiverQuery = db.collection("messages").whereField("receiverId", isEqualTo: userId)
        let senderQuery = db.collection("messages").whereField("senderId", isEqualTo: userId)
        
        let dispatchGroup = DispatchGroup()
        var allMessages: [Message] = []
        
        dispatchGroup.enter()
        receiverQuery.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting messages: \(error)")
            } else {
                let messages = querySnapshot?.documents.compactMap { document -> Message? in
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data(), options: .fragmentsAllowed)
                        return try JSONDecoder().decode(Message.self, from: data)
                    } catch {
                        print("Failed to decode message: \(error)")
                        return nil
                    }
                } ?? []
                allMessages.append(contentsOf: messages)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        senderQuery.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting messages: \(error)")
            } else {
                let messages = querySnapshot?.documents.compactMap { document -> Message? in
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data(), options: .fragmentsAllowed)
                        return try JSONDecoder().decode(Message.self, from: data)
                    } catch {
                        print("Failed to decode message: \(error)")
                        return nil
                    }
                } ?? []
                allMessages.append(contentsOf: messages)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            let uniqueMessages = Array(Set(allMessages))
            completion(uniqueMessages)
        }
    }

    func loadUsers(userIds: [String], completion: @escaping (Result<[User], Error>) -> Void) {
        let usersRef = db.collection("users")
        let query: Query

        if userIds.isEmpty {
            query = usersRef // 全ユーザーを取得
        } else {
            query = usersRef.whereField("id", in: userIds) // 特定のユーザーIDを持つユーザーを取得
        }

        query.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(.failure(error))
            } else {
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    completion(.success([]))
                    return
                }

                var users: [User] = []
                for document in documents {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data(), options: .fragmentsAllowed)
                        let user = try JSONDecoder().decode(User.self, from: data)
                        users.append(user)
                    } catch {
                        print("Error decoding user: \(error)")
                    }
                }
                
                completion(.success(users))
            }
        }
    }
    
//     func followUser(follower: User, followee: User, completion: @escaping (Result<Void, Error>) -> Void) {
//     let followerId = follower.id
//     let followeeId = followee.id
    
//     let batch = db.batch()
    
//     let followerRef = db.collection("users").document(followerId)
//     batch.updateData(["following": FieldValue.arrayUnion([followeeId])], forDocument: followerRef)
    
//     let followeeRef = db.collection("users").document(followeeId)
//     batch.updateData(["followers": FieldValue.arrayUnion([followerId])], forDocument: followeeRef)
    
//     // 通知を作成
//     let notification = Notification(
//         id: UUID().uuidString,
//         type: .follow,
//         message: "\(follower.username)さんがフォローしました",
//         senderId: follower.id,
//         senderUsername: follower.username,
//         senderIconURL: follower.iconImageURL ?? "",
//         isRead: false
//     )
    
//     // 通知を保存
//     do {
//         let notificationData = try Firestore.Encoder().encode(notification)
//         batch.updateData(["notifications": FieldValue.arrayUnion([notificationData])], forDocument: followeeRef)
//     } catch {
//         completion(.failure(error))
//         return
//     }
    
//     batch.commit { error in
//         if let error = error {
//             completion(.failure(error))
//         } else {
//             completion(.success(()))
//         }
//     }
// }
func followUser(follower: User, followee: User, completion: @escaping (Result<Void, Error>) -> Void) {
    let followerId = follower.id
    let followeeId = followee.id
    
    let batch = db.batch()
    
    let followerRef = db.collection("users").document(followerId)
    batch.updateData(["following": FieldValue.arrayUnion([followeeId])], forDocument: followerRef)
    
    let followeeRef = db.collection("users").document(followeeId)
    batch.updateData(["followers": FieldValue.arrayUnion([followerId])], forDocument: followeeRef)

    // batch.commit { error in
    //     if let error = error {
    //         completion(.failure(error))
    //     } else {
    //         completion(.success(()))
    //     }
    // }
    
    // 通知を作成
    let notification = Notification(
        id: UUID().uuidString,
        type: .follow,
        message: "\(follower.username)さんがフォローしました",
        senderId: follower.id,
        senderUsername: follower.username,
        senderIconURL: follower.iconImageURL ?? "",
        isRead: false
    )
    
    // 既存の通知を取得して重複をチェック
    followeeRef.getDocument { (document, error) in
        if let document = document, document.exists {
            if let data = document.data(), let notifications = data["notifications"] as? [[String: Any]] {
                let existingNotification = notifications.first { notif in
                    notif["type"] as? String == "follow" && notif["senderId"] as? String == followerId
                }
                
                if existingNotification != nil {
                    // 既に同じ通知が存在する場合
                    completion(.success(()))
                    batch.commit { error in
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
    }
                    return
                }
            }
            
            // 通知を保存
            do {
                let notificationData = try Firestore.Encoder().encode(notification)
                batch.updateData(["notifications": FieldValue.arrayUnion([notificationData])], forDocument: followeeRef)
            } catch {
                completion(.failure(error))
                return
            }
            
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } else {
            completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve followee document"])))
        }
    }
}


private func checkAndSaveNotification(receiver: User, sender: User, completion: @escaping (Result<Void, Error>) -> Void) {
    let notificationsRef = db.collection("users").document(receiver.id).collection("notifications")
    
    notificationsRef
        .whereField("senderId", isEqualTo: sender.id)
        .whereField("type", isEqualTo: "follow")
        .getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                // 同じ内容の通知が既に存在する場合
                completion(.success(()))
            } else {
                // 同じ内容の通知が存在しない場合、新しい通知を作成
                let notification = Notification(
                    id: UUID().uuidString,
                    type: .follow,
                    message: "\(sender.username)さんがフォローしました",
                    senderId: sender.id,
                    senderUsername: sender.username,
                    senderIconURL: sender.iconImageURL ?? "",
                    isRead: false
                )
                var mutableReceiver = receiver // コピーを作成して変更可能にする
                mutableReceiver.notifications.append(notification)
                
                // self.saveUser(mutableReceiver) { result in
                //     switch result {
                //     case .success():
                //         print("Notification saved successfully")
                //         completion(.success(()))
                //     case .failure(let error):
                //         print("Failed to save notification: \(error)")
                //         completion(.failure(error))
                //     }
                // }
            }
        }
}

     func checkAndSaveNotificationgood(receiver: User, sender: User, completion: @escaping (Result<Void, Error>) -> Void) {
    let notificationsRef = db.collection("users").document(receiver.id)
    let notification = Notification(
        id: UUID().uuidString,
        type: .good,
        message: "\(sender.username)さんがあなたの投稿に拍手を送りました",
        senderId: sender.id,
        senderUsername: sender.username,
        senderIconURL: sender.iconImageURL ?? "",
        isRead: false
    )
    
    notificationsRef.collection("notifications")
        .whereField("senderId", isEqualTo: sender.id)
        .whereField("type", isEqualTo: "good")
        .getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                // 同じ内容の通知が既に存在する場合
                completion(.success(()))
            } else {
                // 同じ内容の通知が存在しない場合、新しい通知を作成
                do {
                    let notificationData = try Firestore.Encoder().encode(notification)
                    notificationsRef.updateData(["notifications": FieldValue.arrayUnion([notificationData])]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            print("Notification saved successfully")
                            completion(.success(()))
                        }
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
}

    

    func unfollowUser(follower: User, followee: User, completion: @escaping (Result<Void, Error>) -> Void) {
        let followerId = follower.id
        let followeeId = followee.id
        
        self.db.collection("users").document(followerId).updateData([
            "following": FieldValue.arrayRemove([followeeId])
        ]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.db.collection("users").document(followeeId).updateData([
                "followers": FieldValue.arrayRemove([followerId])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func deletePost(user: User, post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
    let userId = user.id
    
    // Postオブジェクト全体を削除するために、ユーザーのposts配列を更新
    db.collection("users").document(userId).updateData([
        "posts": FieldValue.arrayRemove([post.id]) // postのIDを使用して削除
    ]) { error in
        if let error = error {
            print("Failed to delete post: \(error)")
            completion(.failure(error))
        } else {
            // Firestoreのpostsコレクションからも削除
            FirestoreHelper.shared.saveUser(user) { result in
                switch result {
                case .success:
                    print("User successfully saved!")
                case .failure(let error):
                    print("Error saving user: \(error)")
                }
            }
            self.db.collection("posts").document(post.id).delete { error in
                if let error = error {
                    print("Failed to delete post from posts collection: \(error)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
    
    func createGroupMessage(userIds: [String], text: String) {
        let groupMessage = GroupMessage(id: UUID().uuidString, name: "GroupMessage", userIds: userIds, messages: [])
        
        do {
            let data = try JSONEncoder().encode(groupMessage)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
            let groupMessageRef = db.collection("groupMessages").document(groupMessage.id)
            groupMessageRef.setData(dictionary) { error in
                if let error = error {
                    print("Failed to create group message: \(error)")
                } else {
                    for userId in userIds {
                        self.db.collection("users").document(userId).updateData([
                            "groupMessages": FieldValue.arrayUnion([groupMessageRef.documentID])
                        ])
                    }
                }
            }
        } catch {
            print("Failed to encode group message: \(error)")
        }
    }
    
    func updateGroupMessage(_ groupMessage: GroupMessage) {
        let groupId = groupMessage.id
        
        do {
            let data = try JSONEncoder().encode(groupMessage)
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
            db.collection("groupMessages").document(groupId).setData(dictionary) { error in
                if let error = error {
                    print("Failed to update group message: \(error)")
                }
            }
        } catch {
            print("Failed to encode group message: \(error)")
        }
    }
    
    func deleteMessage(_ message: Message) {
        let messageId = message.id
        
        db.collection("messages").document(messageId).delete { error in
            if let error = error {
                print("Failed to delete message: \(error)")
            }
        }
    }

    
    func saveBulletinBoardPosts(_ posts: [BulltinBoard]) {
        for post in posts {
            do {
                let data = try JSONEncoder().encode(post)
                let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                db.collection("bulletinBoard").document(post.id).setData(dictionary) { error in
                    if let error = error {
                        print("Failed to save bulletin board post: \(error)")
                    }
                }
            } catch {
                print("Failed to encode bulletin board post: \(error)")
            }
        }
    }
    
    func loadBulletinBoardPosts(completion: @escaping (Result<[BulltinBoard], Error>) -> Void) {
        db.collection("bulletinBoard").getDocuments { querySnapshot, error in
            if let querySnapshot = querySnapshot {
                let posts = querySnapshot.documents.compactMap { document -> BulltinBoard? in
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data(), options: .fragmentsAllowed)
                        return try JSONDecoder().decode(BulltinBoard.self, from: data)
                    } catch {
                        print("Failed to decode bulletin board post: \(error)")
                        return nil
                    }
                }
                completion(.success(posts))
            } else {
                print("Failed to load bulletin board posts: \(error?.localizedDescription ?? "Unknown error")")
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load bulletin board posts"])))
            }
        }
    }

    func deleteAccount(user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        // Firestoreからユーザーデータを削除
        db.collection("users").document(user.id).delete { error in
            if let error = error {
                print("Failed to delete user data from Firestore: \(error)")
                completion(.failure(error))
                return
            }

            // Firebase Authenticationからユーザーを削除
            Auth.auth().currentUser?.delete { error in
                if let error = error {
                    print("Failed to delete user from Firebase Auth: \(error)")
                    completion(.failure(error))
                } else {
                    print("User successfully deleted from Firebase Auth and Firestore")
                    completion(.success(()))
                }
            }
        }
    }
    
}
