//
//  CreateCourseView.swift
//  Unite
//
//  Created by 日下拓海 on 2024/10/01.
//

import SwiftUI
import FirebaseFirestore

struct MenuView: View {
    @Binding var currentUser: User
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var selectedAlert: AlertType?
    @State private var showAlertType2 = false
    @State private var showAlertType3 = false
    @State private var isLoginViewActive = false
    @State private var isLoggedIn = false
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    enum AlertType {
        case type2
        case type3
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding(.leading, 16)
                    }
                Spacer()
                Text("メニュー")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }.padding(.top, 16)
            HStack {
                Image("logout")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                Text("ログアウト")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .onTapGesture {
                selectedAlert = .type2
                showAlertType2 = true
            }
            .padding(.top, 8)
            .padding(.leading, 16)
            HStack {
                Image("accountdelete")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                Text("アカウント削除")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .onTapGesture {
                selectedAlert = .type3
                showAlertType3 = true
            }
            .padding(.top, 8)
            .padding(.leading, 16)
            Spacer()
        }
        .navigationDestination(isPresented: $isLoginViewActive) {
            LoginView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
            .navigationBarHidden(true)
        }
        .alert(isPresented: Binding(
            get: {
                showAlertType2 || showAlertType3
            },
            set: { newValue in
                showAlertType2 = false
                showAlertType3 = false
            }
        )) {
            switch selectedAlert {
            case .type2:
                return Alert(title: Text("ログアウトしますか？"), message: Text(""), primaryButton: .destructive(Text("ログアウト")) {
                    logout()
                    showAlertType2 = false
                }, secondaryButton: .cancel(Text("キャンセル")) {
                    showAlertType2 = false
                })
            case .type3:
                return Alert(title: Text("アカウントを削除しますか？"), message: Text("この操作は取り消せません"), primaryButton: .destructive(Text("削除")) {
                    deleteAccount()
                    showAlertType3 = false
                }, secondaryButton: .cancel(Text("キャンセル")) {
                    showAlertType3 = false
                })
            case .none:
                return Alert(title: Text("Unknown Alert"))
            }
        }
    }

    private func logout() {
        UserDefaults.standard.removeObject(forKey: "loggedInUserId")
        db.collection("users").document(currentUser.id).updateData(["isLoggedIn": false]) { error in
            if let error = error {
                print("Error logging out: \(error)")
            } else {
                print("User successfully logged out!")
            }
        }
        isLoggedIn = false
        isLoginViewActive = true
    }
    
    private func deleteAccount() {
        FirestoreHelper.shared.deleteAccount(user: currentUser) { result in
            switch result {
            case .success:
                print("User successfully deleted!")
                isLoginViewActive = true
            case .failure(let error):
                print("Error deleting user: \(error)")
            }
        }
    }
}
