import Foundation
import FirebaseFirestore
struct Notification: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var type: NotificationType
    var message: String = ""
    var senderId: String = ""
    var senderUsername: String = ""
    var senderIconURL: String = ""
    var isRead: Bool = false
    
    enum NotificationType: String, Codable {
        case follow
        case good
        // 他の通知タイプを追加する場合はここに追加
    }

    static func == (lhs: Notification, rhs: Notification) -> Bool {
        return lhs.id == rhs.id
    }
}