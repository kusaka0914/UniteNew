import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "エラー" // アラートのタイトルを管理する変数を追加
    @State private var alertMessage: String = ""
    @State private var showLogin: Bool = false
    @State private var showFirstSetting: Bool = false
    @State private var isLoading: Bool = false
    @FocusState private var isFocused: Bool
    @FocusState private var isFocused2: Bool
    @FocusState private var isFocused3: Bool                                
    @AppStorage("registeredEmails") private var registeredEmailsData: String = "[]"
    @AppStorage("registeredPasswords") private var registeredPasswordsData: String = "[]"
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: User
    private var db = Firestore.firestore()

    init(isLoggedIn: Binding<Bool>, currentUser: Binding<User>) {
        self._isLoggedIn = isLoggedIn
        self._currentUser = currentUser
    }

    var body: some View {
        // NavigationStack {
            VStack {
                Spacer()
                Text("アカウント作成")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                HStack {
                    Text("メールアドレス")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.leading, 40)
                TextField("メールアドレス", text: $email)
                    .padding()
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    .foregroundColor(.white) // 文字色を白に設定
                    .frame(width: 300)
                    .padding(.horizontal, 53)
                    .focused($isFocused)
                    .onTapGesture {
                        isFocused = true
                    }
                HStack {
                    Text("パスワード")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.leading, 40)
                SecureField("パスワード(6文字以上)", text: $password)
                    .padding()
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    .foregroundColor(.white) // 文字色を白に設定
                    .frame(width: 300)
                    .focused($isFocused2)
                    .onTapGesture {
                        isFocused2 = true
                    }
                HStack {
                    Text("パスワード確認")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.leading, 40)
                SecureField("パスワード確認(6文字以上)", text: $confirmPassword)
                    .padding()
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 40)
                    .foregroundColor(.white) // 文字色を白に設定
                    .frame(width: 300)
                    .focused($isFocused3)
                    .onTapGesture {
                        isFocused3 = true
                    }
                Button(action: {
                    isLoading = true
                    signUp()
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                    Text("サインアップ")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 150, height: 40)
                        .background(Color.black)
                        .border(Color.white, width: 1)
                    }
                }
                .padding(.bottom, 24)
                
                Button(action: {
                    showLogin = true
                }) {
                    VStack {
                        Text("既にアカウントをお持ちですか?")
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                        Text("ログイン")
                            .foregroundColor(.white)
                    }
                }
                .navigationDestination(isPresented: $showLogin) {
                    LoginView(
                        isLoggedIn: $isLoggedIn,
                        currentUser: $currentUser
                    )
                    .navigationBarBackButtonHidden(true)
                }
                .navigationDestination(isPresented: $showFirstSetting) {
                    FirstSettingView(
                        currentUser: $currentUser
                    )
                    .navigationBarBackButtonHidden(true) // Backボタンを非表示にする
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black) // 背景色を黒に設定
            .foregroundColor(.white) // テキスト色を白に設定
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onTapGesture {
                if isFocused {
                    isFocused = false
                }
                if isFocused2 {
                    isFocused2 = false
                }
                if isFocused3 {
                    isFocused3 = false
                }
            }
        // }
        .background(Color.black) // 余白の背景色を黒に設定
        .edgesIgnoringSafeArea(.all) // 余白を無視して全体を黒に設定
    }
    
    private func signUp() {
        // サインアップ処理をここに実装
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            alertTitle = "エラー"
            alertMessage = "全てのフィールドを入力してください。"
            showAlert = true
            isLoading = false
        } else if password != confirmPassword {
            alertTitle = "エラー"
            alertMessage = "パスワードが一致しません。"
            showAlert = true
            isLoading = false
        } else if password.count < 6 {
            alertTitle = "エラー"
            alertMessage = "パスワードは6文字以上で入力してください。"
            showAlert = true
            isLoading = false
        } else if !email.contains("@") {
            alertTitle = "エラー"
            alertMessage = "メールアドレスに@を含めてください。"
            showAlert = true
            isLoading = false
        } else {
            // FirebaseAuthを使用してユーザーを作成
            AuthHelper.shared.signUp(email: email, password: password) { result in
                switch result {
                case .success(let authResult):
                    let userId = authResult.user.uid
                    let newUser = User(
                        id: userId, // Firebase AuthenticationのユーザーIDを使用
                        password: password,
                        username: "",
                        university: "",
                        posts: [],
                        followers: [],
                        following: [],
                        accountname: email,
                        faculty: "",
                        department: "",
                        club: "",
                        bio: "",
                        twitterHandle: "",
                        email: email,
                        stories: [],
                        iconImageURL: "",
                        notifications: [],
                        messages: [],
                        courses: [],
                        groupMessages: [],
                        points: 0
                    )
                    FirestoreHelper.shared.saveUser(newUser) { result in
                        switch result {
                        case .success:
                            // alertTitle = "成功"
                            // alertMessage = "サインアップ成功！"
                            // showAlert = true
                            // isLoading = false
                            
                            // 2秒後に詳細設定画面に自動遷移
                            DispatchQueue.main.asyncAfter(deadline: .now()) {
                                currentUser = newUser
                                // isLoggedIn = true // ログイン状態に設定
                                showFirstSetting = true
                            }
                        case .failure(let error):
                            alertTitle = "エラー"
                            alertMessage = "ユーザーの保存に失敗しました: \(error.localizedDescription)"
                            showAlert = true
                            isLoading = false
                        }
                    }
                case .failure(let error):
                    alertTitle = "エラー"
                    alertMessage = "有効なメールアドレスを入力してください。"
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
}

