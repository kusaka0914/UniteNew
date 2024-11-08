import SwiftUI
import FirebaseFirestore

struct Course: Identifiable, Codable ,Hashable{
    let id = UUID().uuidString
    var name: String
    var day: String
    var period: Int
    var location: String
}

struct CourseRegistrationView: View {
    @Binding var user: User
    @Binding var currentUser: User
    @State private var isUserProfileViewActive = false
    @State private var isAnotherUserProfileViewActive = false
    @State private var selectedCourse: Course? = nil
    @State private var isCourseEditViewActive = false
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()

    init(user: Binding<User>, currentUser: Binding<User>) {
        self._user = user
        self._currentUser = currentUser
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let remainingWidth = totalWidth - 20 // 20は左側の時間列の幅
                let columnWidth = remainingWidth / 6 // 6列に分割

                VStack {
                    HStack {
                        Button(action: {
                            isUserProfileViewActive = true
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding(.leading, 10)
                                .padding(.trailing, 10)
                        }
                        
                        Text("2024年2学期")
                            .font(.subheadline)
                            .padding(.trailing, 30)
                            .foregroundColor(.white)
                        Text("週間時間割")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Text("")
                                .frame(width: 20, height: 30)
                                .background(Color.gray.opacity(0.2))
                                .border(Color.gray)
                            
                            ForEach(["月", "火", "水", "木", "金", "土"], id: \.self) { day in
                                Text(day)
                                    .frame(width: columnWidth, height: 30)
                                    .font(.caption)
                                    .background(Color.gray.opacity(0.2))
                                    .border(Color.gray)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        ForEach(1..<7) { period in
                            HStack(spacing: 0) {
                                Text("\(period)")
                                    .frame(width: 20, height: 80)
                                    .background(Color.gray.opacity(0.2))
                                    .border(Color.gray)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                ForEach(["月", "火", "水", "木", "金", "土"], id: \.self) { day in
                                    if let course = user.courses.first(where: { $0.day == day && $0.period == period }) {
                                        Button(action: {
                                            if user.id == currentUser.id {
                                                selectedCourse = course
                                                isCourseEditViewActive = true
                                            }
                                        }) {
                                            VStack {
                                                Text(course.name)
                                                    .font(.caption2)
                                                    .padding(5)
                                                    .foregroundColor(.white)
                                            }
                                            .frame(width: columnWidth - 10, height: 70) // 隙間を作るために幅と高さを調整
                                            .background(Color.blue.opacity(0.7))
                                            .cornerRadius(5)
                                            .padding(5) // 隙間を作るためにパディングを追加
                                            .border(Color.gray)
                                        }
                                    } else {
                                        Button(action: {
                                            if user.id == currentUser.id {
                                                selectedCourse = Course(name: "", day: day, period: period, location: "")
                                                isCourseEditViewActive = true
                                            }
                                        }) {
                                            Text("")
                                                .frame(width: columnWidth, height: 80)
                                                .border(Color.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if user.id == currentUser.id {
                        HStack {
                            Spacer()
                    Text("フィールドをタップで編集できます。")
                        .padding(.top, 20)
                        .foregroundColor(.white)
                    Spacer()
                        }
                    }
                }
            }
            .background(Color.black)
            .navigationBarHidden(true) // デフォルトのナビゲーションバーを非表示にする
            .navigationDestination(isPresented: $isCourseEditViewActive) {
                if let selectedCourse = selectedCourse {
                    CourseEditView(course: selectedCourse, currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
            }
            .navigationDestination(isPresented: $isAnotherUserProfileViewActive) {
                AnotherUserProfileView(user: $user, currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }.navigationDestination(isPresented: $isUserProfileViewActive) {
                UserProfileView(currentUser: $currentUser)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    
    private func saveUserToFirestore(_ user: User) {
        do {
            let userData = try JSONEncoder().encode(user)
            let userDict = try JSONSerialization.jsonObject(with: userData) as! [String: Any]
            db.collection("users").document(user.id).setData(userDict) { error in
                if let error = error {
                    print("Error saving user: \(error)")
                } else {
                    print("User successfully saved!")
                }
            }
        } catch {
            print("Error encoding user: \(error)")
        }
    }
}

