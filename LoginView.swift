import SwiftUI
import FirebaseFirestore
import FirebaseAuth



struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: User
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false
    @FocusState private var isFocusedEmail: Bool
    @FocusState private var isFocusedPassword: Bool
    private var db = Firestore.firestore()

    init(isLoggedIn: Binding<Bool>, currentUser: Binding<User>) {
        self._isLoggedIn = isLoggedIn
        self._currentUser = currentUser
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image("Sphere")
                        .resizable()
                        .frame(width: 35, height: 35)
                    Text("Unite")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 40)
                
                TextField("メールアドレス", text: $email)
                    .frame(width: 250)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        isFocusedEmail = true
                    }
                    .focused($isFocusedEmail)
                SecureField("パスワード", text: $password)
                    .frame(width: 250)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 40)
                    .onTapGesture {
                        isFocusedPassword = true
                    }
                    .focused($isFocusedPassword)
                Button(action: {
                    isLoading = true
                    login()
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                    Text("ログイン")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 180, height: 50)
                        .background(Color.black)
                        .border(Color.white, width: 1)
                    }
                }
                
                Button(action: {
                    showSignUp = true
                }) {
                    if !isLoading {
                    Text("アカウントを作成")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 180, height: 50)
                        .background(Color.black)
                        .padding(2)
                    }
                }
                .navigationDestination(isPresented: $showSignUp) {
                    SignUpView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width)
            .onTapGesture {
                if isFocusedEmail {
                    isFocusedEmail = false
                }
                if isFocusedPassword {
                    isFocusedPassword = false
                }
            }
            .onAppear {
                if let window = UIApplication.shared.windows.first {
                    for constraint in window.constraints {
                        if constraint.identifier == "assistantView.top" {
                            constraint.priority = .defaultLow
                        }
                    }
                }
            }
            // .padding(100)
            .background(Color.black)
            .foregroundColor(.white)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                UserProfileView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    private func login() {
    if email.isEmpty || password.isEmpty {
        alertMessage = "メールアドレスとパスワードを入力してください。"
        showAlert = true
        isLoading = false
    } else {
        AuthHelper.shared.logIn(email: email, password: password) { result in
            switch result {
            case .success(let authResult):
                let userId = authResult.user.uid
                db.collection("users").document(userId).getDocument { document, error in
                    if let error = error {
                        alertMessage = "ログインに失敗しました。"
                        showAlert = true
                        isLoading = false
                    } else if let document = document, document.exists {
                        do {
                            let userData = try JSONSerialization.data(withJSONObject: document.data()!, options: [])
                            var loadedUser = try JSONDecoder().decode(User.self, from: userData)
                            if let iconImageURL = loadedUser.iconImageURL, let url = URL(string: iconImageURL) {
                                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                                    if let data = data, let uiImage = UIImage(data: data) {
                                        DispatchQueue.main.async {
                                            loadedUser.iconImageURL = iconImageURL
                                            currentUser = loadedUser
                                            isLoggedIn = true
                                            isLoading = false
                                            UserDefaults.standard.set(userId, forKey: "loggedInUserId")
                                        }
                                    } else {
                                        alertMessage = "アイコンの読み込みに失敗しました。"
                                        showAlert = true
                                        isLoading = false
                                    }
                                }
                                task.resume()
                            } else {
                                currentUser = loadedUser
                                isLoggedIn = true
                                UserDefaults.standard.set(userId, forKey: "loggedInUserId")
                                isLoading = false
                            }
                        } catch {
                            alertMessage = "ログインに失敗しました。"
                            showAlert = true
                            isLoading = false
                        }
                    } else {
                        alertMessage = "ログインに失敗しました。"
                        showAlert = true
                        isLoading = false
                    }
                }
            case .failure(let error):
                alertMessage = "ログインに失敗しました。"
                showAlert = true
                isLoading = false
            }
        }
    }
}
}



