import SwiftUI
import FirebaseFirestore

struct MemoDetailView: View {
    @Binding var currentUser: User
    @Binding var otherUser: User
    @Binding var memo: Memo
    @Binding var isMessageMemoViewActive: Bool
    @State private var isEditing: Bool = false
    let db = Firestore.firestore()
    init(currentUser: Binding<User>, otherUser: Binding<User>, memo: Binding<Memo>, isMessageMemoViewActive: Binding<Bool>) {
        self._currentUser = currentUser
        self._otherUser = otherUser
        self._memo = memo
        self._isMessageMemoViewActive = isMessageMemoViewActive
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    isMessageMemoViewActive = true
                }) {
                    if !isEditing {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding(.leading, 16)
                    }
                }
                Spacer()
                if isEditing {
                    TextField("Title", text: $memo.name)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.gray),
                            alignment: .bottom
                        )
                } else {
                    Text(memo.name)
                        .font(.headline)
                        .padding()
                }
                Spacer()
                Button(action: {
                    if isEditing {
                        saveMemo()
                    }
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "保存" : "編集")
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }.padding(.trailing, 16)
                .padding(.leading, 8)
            }
            HStack {
                if isEditing {
                TextEditor(text: $memo.text)
                    .font(.body)
                    .padding(.leading, 16)
                    .padding(.vertical, 8)
                    // .overlay(
                    //     Rectangle()
                    //         .frame(height: 1)
                    //         .foregroundColor(Color.gray),
                    //     alignment: .bottom
                    // )
            } else {
                ScrollView {
                Text(memo.text)
                    .font(.body)
                    .padding(.leading, 16)
                }
            }
            Spacer()
            }
            Spacer()
            if isEditing {
                Text("タップしてメモを編集")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.leading, 16)
                    .padding(.bottom, 20)
            }
        }.navigationDestination(isPresented: $isMessageMemoViewActive) {
            MessageMemoView(currentUser: $currentUser, otherUser: $otherUser)
                .navigationBarBackButtonHidden(true)
        }
    }

    private func saveMemo() {
        db.collection("memos").document(memo.id).updateData([
            "name": memo.name,
            "text": memo.text
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
    }
}
