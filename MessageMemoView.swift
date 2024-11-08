import SwiftUI
import FirebaseFirestore

struct MessageMemoView: View {
    @Binding var currentUser: User
    @Binding var otherUser: User
    @State private var dragOffset: CGFloat = 0.0
    @State private var memos: [Memo] = []
    @State private var isMessageViewActive = false
    @State private var showCreateMemoView = false
    @State private var showAlert = false
    @State private var memoToDelete: Memo?
    @State private var prevView: String = "MessageMemoView"
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, otherUser: Binding<User>) {
        self._currentUser = currentUser
        self._otherUser = otherUser
    }

    var body: some View {
        ZStack {
            if isMessageViewActive {
                MessageView(currentUser: $currentUser, otherUser: $otherUser, prevView: $prevView)
                    .transition(.move(edge: .leading))
            } else {
                VStack {
                    // ヘッダ部分
                    HStack {
                        Button(action: {
                            isMessageViewActive = true
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding(.leading, 16)
                        }
                        Spacer()
                        Text("メモ一覧")
                            .font(.headline)
                            .padding()
                        Spacer()
                        Button(action: {
                        showCreateMemoView = true
                    }) {
                        Text("+ 新規作成")
                            .fontWeight(.bold)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1.5)
                            )

                    }
                    .padding(.trailing, 16)
                    .navigationDestination(isPresented: $showCreateMemoView) {
                        CreateMemoView(currentUser: $currentUser, otherUser: $otherUser)
                            .navigationBarBackButtonHidden(true)
                    }
                    }

                    // メモがない場合の表示
                    if memos.isEmpty {
                        HStack {
                            Spacer()
                            Text("メモがありません")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        List {
                            // メモのリスト表示と削除機能
                            ForEach($memos.sorted(by: { $0.wrappedValue.date.dateValue() > $1.wrappedValue.date.dateValue() })) { $memo in
                                ZStack(alignment: .trailing) {
                                    NavigationLink(destination: MemoDetailView(currentUser: $currentUser, otherUser: $otherUser, memo: $memo, isMessageMemoViewActive: $isMessageViewActive)
                                    .navigationBarBackButtonHidden(true)) {
                                        VStack(alignment: .leading) {
                                            Text(memo.name)
                                                .font(.headline)
                                            Text(memo.text)
                                                .font(.subheadline)
                                                .lineLimit(2) // 2行に制限
                                                .truncationMode(.tail) // 省略記号を末尾に表示
                                        }
                                        .frame(height: 50)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // ボタンスタイルをプレーンに設定
                                    Button(action: {
                                        memoToDelete = memo
                                        showAlert = true
                                    }) {
                                        Image("trash")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .padding(.trailing, 16)
                                            
                                    }
                                    .buttonStyle(BorderlessButtonStyle()) // ボタンスタイルをボーダーレスに設定
                                }
                            }
                        }
                    }

                    Spacer()
                    
                    
                    
                }
                .onAppear {
                    loadMemos()
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 100 {
                                withAnimation {
                                    isMessageViewActive = true
                                }
                            }
                            dragOffset = 0
                        }
                )
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("メモを削除"),
                        message: Text("本当に削除しますか？"),
                        primaryButton: .destructive(Text("削除")) {
                            if let memo = memoToDelete {
                                deleteMemo(memo)
                            }
                        },
                        secondaryButton: .cancel(Text("キャンセル"))
                    )
                }
            }
        }
    }

    // メモの読み込み
    private func loadMemos() {
    let currentUserId = currentUser.id
    let otherUserId = otherUser.id

    db.collection("memos")
        .whereField("senderId", isEqualTo: currentUserId)
        .whereField("receiverId", isEqualTo: otherUserId)
        .order(by: "date", descending: true)
        .addSnapshotListener { querySnapshot, error in
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                self.memos = documents.compactMap { queryDocumentSnapshot -> Memo? in
                    try? queryDocumentSnapshot.data(as: Memo.self)
                }
            } else {
                // センダーとレシーバーを逆にして再検索
                db.collection("memos")
                    .whereField("senderId", isEqualTo: otherUserId)
                    .whereField("receiverId", isEqualTo: currentUserId)
                    .order(by: "date", descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("No documents")
                            return
                        }
                        self.memos = documents.compactMap { queryDocumentSnapshot -> Memo? in
                            try? queryDocumentSnapshot.data(as: Memo.self)
                        }
                    }
            }
        }
}

    // メモ削除処理
    private func deleteMemo(_ memo: Memo) {
        db.collection("memos").document(memo.id).delete { error in
            if let error = error {
                print("Error deleting memo: \(error)")
            } else {
                if let index = memos.firstIndex(where: { $0.id == memo.id }) {
                    memos.remove(at: index)
                }
            }
        }
    }
}