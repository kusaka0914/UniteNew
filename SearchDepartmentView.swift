// import SwiftUI
// import FirebaseFirestore

// struct SearchDepartmentView: View {
//     @Binding var currentUser: User
//     @Environment(\.dismiss) var dismiss
//     private var db = Firestore.firestore()

//     init(currentUser: Binding<User>) {
//         self._currentUser = currentUser
//     }

//     var body: some View {
//         NavigationStack {
//             VStack {
//                 Text("Unite with New Friends")
//                     .font(.title)
//                     .fontWeight(.bold)
                
//                 HStack {
//                     VStack {
//                         Text("①")
//                         Text("学部選択")
//                     }
//                     Image(systemName: "arrow.right")
//                     VStack {
//                         Text("❷")
//                         Text("学科選択")
//                             .underline()
//                     }
//                     Image(systemName: "arrow.right")
//                     VStack {
//                         Text("③")
//                         Text("完了")
//                     }
//                 }
//                 .font(.headline)
//                 .padding(.top, 10)
//                 .padding(.bottom, 10)
                
//                 VStack(spacing: 0) {
//                     DepartmentButton(departmentName: "機械科学科", destination: Text("機械科学科"))
//                     CustomDivider()
//                     DepartmentButton(departmentName: "数物科学科", destination: Text("数物科学科"))
//                     CustomDivider()
//                     DepartmentButton(departmentName: "物質創生科学科", destination: Text("物質創生科学科"))
//                     CustomDivider()
//                     DepartmentButton(departmentName: "電子情報工学科", destination: AllElectoricInformationView(user: $currentUser, currentUser: $currentUser,selectedUser: User(id: "", username: "", university: "", posts: [], texts: [], followers: [], following: [], accountname: "", faculty: "", department: "", club: "", bio: "", twitterHandle: "", email: "", stories: [], iconImageURL: "", notifications: [], messages: [], courses: [], groupMessages: [], points: 0))
//                         .navigationBarBackButtonHidden(true)
//                     )
//                     CustomDivider()
//                     DepartmentButton(departmentName: "地球環境防災学科", destination: Text("地球環境防災学科"))
//                     CustomDivider()
//                     DepartmentButton(departmentName: "自然エネルギー学科", destination: Text("自然エネルギー学科"))
//                 }
//                 .padding(.top, 20)
                
//                 Spacer()
                
//                 HStack {
//                     Spacer()
//                     NavigationLink(destination: HomeView(currentUser: $currentUser, postUser: User(
//                     id: "current_user_id",
//                     password: "password",
//                     username: "current_user",
//                     university: "current_university",
//                     posts: [],
//                     followers: [],
//                     following: [],
//                     accountname: "current_accountname",
//                     faculty: "current_faculty",
//                     department: "current_department",
//                     club: "current_club",
//                     bio: "current_bio",
//                     twitterHandle: "current_twitterHandle",
//                     email: "current@example.com",
//                     stories: [],
//                     iconImageURL: "https://example.com/icon.jpg",
//                     notifications: [],
//                     messages: [],
//                     courses: [],
//                     groupMessages: []
//                 ))
//                         .navigationBarBackButtonHidden(true)
//                     ) {
//                         Image(systemName: "house")
//                             .resizable()
//                             .frame(width: 24, height: 24)
//                             .padding()
//                     }
//                     Spacer()
//                     NavigationLink(destination: SearchView(currentUser: $currentUser)
//                         .navigationBarBackButtonHidden(true)
//                     ) {
//                         Image(systemName: "magnifyingglass")
//                             .resizable()
//                             .frame(width: 24, height: 24)
//                             .padding()
//                     }
//                     Spacer()
//                     Image(systemName: "plus")
//                         .resizable()
//                         .frame(width: 24, height: 24)
//                         .padding()
//                     Spacer()
//                     NavigationLink(destination: UserProfileView(currentUser: $currentUser)
//                         .navigationBarBackButtonHidden(true)
//                     ) {
//                         Image(systemName: "person")
//                             .resizable()
//                             .frame(width: 24, height: 24)
//                             .padding()
//                     }
//                 }
//                 .background(Color.black)
//                 .foregroundColor(.white)
//                 .padding(.trailing, 30)
//                 .navigationBarItems(leading: Button(action: {
//                     dismiss()
//                 }) {
//                     Image(systemName: "chevron.left")
//                         .foregroundColor(.white)
//                         .imageScale(.large)
//                 })
//             }
//             .background(Color.black)
//             .foregroundColor(.white)
//             .navigationBarBackButtonHidden(true)
//         }
//     }
// }

