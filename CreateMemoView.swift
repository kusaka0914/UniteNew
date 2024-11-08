import SwiftUI
import FirebaseFirestore

struct CreateMemoView: View {
    @Binding var currentUser: User
    @Binding var otherUser: User
    @Environment(\.presentationMode) var presentationMode
    @State private var memoTitle: String = ""
    @State private var memoText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var isMessageMemoViewActive: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isPosting: Bool = false
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, otherUser: Binding<User>) {
        self._currentUser = currentUser
        self._otherUser = otherUser
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                            isMessageMemoViewActive = true
                        }) {
                            if !isPosting {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                            }
                        }.navigationDestination(isPresented: $isMessageMemoViewActive) {
                            MessageMemoView(currentUser: $currentUser, otherUser: $otherUser)
                            .navigationBarBackButtonHidden(true)
                        }
                    Spacer()
                    Text("メモ作成")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                    if !memoTitle.isEmpty && !memoText.isEmpty {
                        isPosting = true
                        saveMemo()
                    } else {
                        alertMessage = "メモタイトルとメモ内容を入力してください"
                        showAlert = true
                    }
                }) {
                    if !isPosting {
                    Text("保存")
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                }.padding(.bottom, 20)
            HStack {
            TextField("メモタイトルを入力", text: $memoTitle)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .focused($isTextFieldFocused)
            }.padding(.horizontal, 12)
            .padding(.bottom, 20)
            HStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $memoText)
                .frame(height: 150)
                .padding(.top,6)
                .padding(.horizontal, 10)
                .scrollContentBackground(.hidden)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .focused($isTextFieldFocused)
                if memoText.isEmpty {
                    Text("メモを入力")
                        .foregroundColor(Color.gray.opacity(0.5))
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .onTapGesture {
                            isTextFieldFocused = true
                        }
                }
            }
            }.padding(.horizontal, 16)
                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveMemo() {
        let newMemo = Memo(id: UUID().uuidString, name: memoTitle, senderId: currentUser.id, receiverId: otherUser.id, text: memoText, date: Timestamp(date: Date()))

        do {
            try db.collection("memos").document(newMemo.id).setData(from: newMemo) { error in
                if let error = error {
                    print("Error saving memo: \(error)")
                } else {
                    print("Memo successfully saved!")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } catch {
            print("Error saving memo: \(error)")
        }
    }
}
