import SwiftUI
import FirebaseFirestore

struct CourseEditView: View {
    @State var course: Course
    @Binding var currentUser: User
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var courses: [Course] = []
    @State private var searchQuery = ""
    @State private var isCreateCourseViewActive = false
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()

    init(course: Course, currentUser: Binding<User>) {
        self._course = State(initialValue: course)
        self._currentUser = currentUser
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
                Text(course.day + "曜" + String(course.period) + "限")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    isCreateCourseViewActive = true
                }) {
                    Text("+ 科目作成")
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                }
                
                .padding(.leading, 8)
            }.padding(.top, 16)
                HStack {
                Text("科目名で検索")
                    .font(.headline)
                    .foregroundColor(Color(red: 247/255, green: 247/255, blue: 247/255))
                    .padding(.bottom, 8)
                    .padding(.leading, 8)
                    .padding(.top, 40)
                Spacer()    
                }
                HStack {
                    TextField("科目名で検索", text: $searchQuery)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .onChange(of: searchQuery) { newValue in
                            searchCourses(query: newValue)
                        }
                    Spacer()
                }
                
                if courses.isEmpty {
                    Text("まだ時間割が作成されていません")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                // コース一覧の表示
                List(courses) { course in
                    Button(action: {
                        currentUser.courses.removeAll(where: { $0.day == course.day && $0.period == course.period })
                        if let index = currentUser.courses.firstIndex(where: { $0.id == course.id }) {
                            currentUser.courses[index] = course
                        } else {
                            currentUser.courses.append(course)
                        }
                        saveUserToFirestore(currentUser) // Firestoreにユーザーデータを保存
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(course.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(course.day)曜 \(course.period)限")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    
                }
            }
                
                Spacer()
                .navigationDestination(isPresented: $isCreateCourseViewActive) {
                    CreateCourseView(currentUser: $currentUser, course: $course)
                        .navigationBarBackButtonHidden(true)
                }
            }
            .onAppear {
                    loadCourses()
                }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
    }
    
    private func saveUserToFirestore(_ user: User) {
        FirestoreHelper.shared.saveUser(user) { result in
            switch result {
            case .success:
                print("User successfully saved!")
            case .failure(let error):
                print("Error saving user: \(error)")
            }
        }
    }
    
    private func loadCourses() {
    db.collection("courses")
        .whereField("day", isEqualTo: course.day)
        .whereField("period", isEqualTo: course.period)
        .getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting courses: \(error.localizedDescription)")
                alertMessage = "コースの読み込みに失敗しました: \(error.localizedDescription)"
                showAlert = true
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("No courses found")
                alertMessage = "コースが見つかりませんでした"
                showAlert = true
                return
            }
            self.courses = documents.compactMap { queryDocumentSnapshot -> Course? in
                let data = queryDocumentSnapshot.data()
                print("Course data: \(data)")
                return decodeCourse(from: data)
            }
        }
}

    private func saveCourseToFirestore(_ course: Course) {
        do {
            let courseData = try JSONEncoder().encode(course)
            let courseDict = try JSONSerialization.jsonObject(with: courseData, options: .allowFragments) as! [String: Any]
            db.collection("courses").document(course.id).setData(courseDict) { error in
                if let error = error {
                    print("Error saving course: \(error)")
                } else {
                    print("Course successfully saved!")
                    // データベースに正常に保存された後にビューを遷移
                    
                }
            }
        } catch {
            print("Error encoding post: \(error)")
        }
    }
    
    private func checkCourseExistence(_ course: Course, completion: @escaping (Bool) -> Void) {
        db.collection("courses").whereField("name", isEqualTo: course.name).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error checking course existence: \(error)")
                completion(false)
                return
            }
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                completion(true) // コースが既に存在する
            } else {
                completion(false) // コースが存在しない
            }
        }
    }
    
    private func decodeCourse(from data: [String: Any]) -> Course? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let day = data["day"] as? String,
              let period = data["period"] as? Int,
              let location = data["location"] as? String else {
            return nil
        }
        return Course(name: name, day: day, period: period, location: location)
    }

    private func searchCourses(query: String) {
        db.collection("courses")
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThanOrEqualTo: query + "\u{f8ff}")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error searching courses: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("No courses found")
                    return
                }
                self.courses = documents.compactMap { queryDocumentSnapshot -> Course? in
                    let data = queryDocumentSnapshot.data()
                    return decodeCourse(from: data)
                }
            }
    }
}
