import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    let db: Firestore

    private init() {
        db = Firestore.firestore()
    }
}