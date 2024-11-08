import SwiftUI

struct RankingBoardView: View {
    @State private var selectedTab = 0
    @State private var topSolutionUsers: [User] = []
    @State private var topFollowerUsers: [User] = []
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    @State private var isHomeViewActive = false
    @State  var user: User
    @Binding var currentUser: User
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            Picker("ランキング", selection: $selectedTab) {
                Text("お助けランキング").tag(0)
                Text("人気者ランキング").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedTab == 0 {
                if topSolutionUsers.isEmpty {
                    Text("ランキングがありません")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    VStack {
                        Text("お助けランキング")
                            .font(.headline)
                            .padding(.bottom, 8)
                        ForEach(topSolutionUsers.prefix(5).indices, id: \.self) { index in
                            RankingBoardFollowerlistView(user: topSolutionUsers[index], index: index, currentUser: $currentUser)
                        }
                        Spacer()
                    }
                }
            } else {
                if topFollowerUsers.isEmpty {
                    Text("ランキングがありません")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    VStack {
                        Text("人気者ランキング")
                            .font(.headline)
                            .padding(.bottom, 8)
                        ForEach(topFollowerUsers.prefix(5).indices, id: \.self) { index in
                            RankingBoardlistView(user: topFollowerUsers[index], index: index, currentUser: $currentUser)
                        }
                        Spacer()
                    }
                }
            }
        }.background(Color.black)
        .onAppear {
            loadTopUsers()
        }
        .navigationTitle("ランキング掲示板")
        .navigationBarItems(leading: Button(action: {
                isHomeViewActive = true
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            })
            .navigationDestination(isPresented: $isHomeViewActive) {
                HomeView(currentUser: $currentUser,postUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], groupMessages: [], everythingBoards: [], points: 0))
                .navigationBarBackButtonHidden(true)
            }
    }

    func loadTopUsers() {
        FirestoreHelper.shared.loadUsers(userIds: []) { result in
            switch result {
            case .success(let users):
                topSolutionUsers = users.filter { $0.solution > 0 }.sorted { $0.solution > $1.solution }
                topFollowerUsers = users.filter { $0.followers.count > 0 }.sorted { $0.followers.count > $1.followers.count }
            case .failure(let error):
                print("Failed to load users: \(error)")
            }
        }
    }
}

struct RankingBoardlistView: View {
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    @State var user: User
    @State var index: Int
    @Binding var currentUser: User
    var body: some View {
            HStack {
                if index == 0 {
                    Image("top")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 1 {
                    Image("second")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 2 {
                    Image("third")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 3 {
                    Image("fourth")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 4 {
                    Image("fifth")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                VStack(alignment: .leading) {
                    Text(user.accountname)
                        .font(.headline)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                    Text(user.username)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                }
                Spacer()
                Text("フォロワー: \(user.followers.count)人")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.trailing, 16)
            }.navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                AnotherUserProfileView(user: $user, currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isUserProfileViewActive) {
                UserProfileView(currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
            }
            .padding(8)
    }
}

struct RankingBoardFollowerlistView: View {
    @State private var isAnotherUserProfileViewActive = false
    @State private var isUserProfileViewActive = false
    @State var user: User
    @State var index: Int
    @Binding var currentUser: User
    var body: some View {
            HStack {
                if index == 0 {
                    Image("top")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 1 {
                    Image("second")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 2 {
                    Image("third")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 3 {
                    Image("fourth")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                else if index == 4 {
                    Image("fifth")
                        .resizable()
                        .frame(width: 30, height: 43)
                        .padding(.trailing, 8)
                        .padding(.horizontal, 16)
                }
                VStack(alignment: .leading) {
                    Text(user.accountname)
                        .font(.headline)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                    Text(user.username)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            if user.id != currentUser.id {
                                isAnotherUserProfileViewActive = true
                            }else{
                                isUserProfileViewActive = true
                            }
                        }
                }
                Spacer()
                Text("解決数: \(user.solution)件")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.trailing, 16)
            }.navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                AnotherUserProfileView(user: $user, currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isUserProfileViewActive) {
                UserProfileView(currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
            }
            .padding(8)
    }
}
