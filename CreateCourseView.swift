//
//  CreateCourseView.swift
//  Unite
//
//  Created by 日下拓海 on 2024/10/01.
//

import SwiftUI
import FirebaseFirestore

struct CreateCourseView: View {
    @Binding var currentUser: User
    @Binding var course: Course
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var courses: [Course] = []
    @State private var searchQuery = ""
    @State private var isSaving = false
    @State private var isCreateCourseViewActive = false
    @State private var isCourseRegistrationViewActive = false
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, course: Binding<Course>) {
        self._currentUser = currentUser
        self._course = course
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    if !isSaving {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding(.leading, 16)
                    }
                }
                Spacer()
                Text(course.day + "曜" + String(course.period) + "限")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    
                    if course.name.isEmpty {
                        alertMessage = "科目名を入力してください"
                        showAlert = true
                    } else {
                        isSaving = true
                        if let index = currentUser.courses.firstIndex(where: { $0.day == course.day && $0.period == course.period }) {
                            currentUser.courses.remove(at: index)
                        }
                        currentUser.courses.append(course)
                        saveUserToFirestore(currentUser)
                        saveCourseToFirestore(course)
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .padding()
                    }else{
                    Text("保存")
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
                }.navigationDestination(isPresented: $isCourseRegistrationViewActive) {
                    CourseRegistrationView(user: $currentUser,currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                }
                .padding(.trailing, 16)
                .padding(.leading, 8)
            }.padding(.top, 16)
             HStack {
                    Text("作成科目名")
                        .padding(.leading, 20)
                        .padding(.top, 30)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                HStack {
                    TextField("作成科目名", text: $course.name)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    Spacer()
                }.padding(.horizontal, 16)
            HStack {
                    
                    Button(action: {
                        if let index = currentUser.courses.firstIndex(where: { $0.id == course.id }) {
                            currentUser.courses.remove(at: index)
                        }
                        saveUserToFirestore(currentUser) // Firestoreにユーザーデータを保存
                        isCourseRegistrationViewActive = true
                    }) {
                        Text("履修科目から削除")
                            .fontWeight(.bold)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }.padding(.leading, 16)
                    .padding(.top, 16)
                    Spacer()
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                Spacer()
            }.background(Color.black)
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
                    print("Error getting courses: \(error)")
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

    private func saveCourseToFirestore(_ course: Course) {
    checkCourseExistence(course) { exists in
        if exists {
            isCourseRegistrationViewActive = true
        } else {
            do {
                let courseData = try JSONEncoder().encode(course)
                let courseDict = try JSONSerialization.jsonObject(with: courseData, options: .allowFragments) as! [String: Any]
                db.collection("courses").document(course.id).setData(courseDict) { error in
                    if let error = error {
                        print("Error saving course: \(error)")
                        alertMessage = "コースの保存に失敗しました: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        print("Course successfully saved!")
                        isSaving = false
                        isCourseRegistrationViewActive = true
                    }
                }
            } catch {
                print("Error encoding course: \(error)")
                alertMessage = "コースのエンコードに失敗しました: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

private func checkCourseExistence(_ course: Course, completion: @escaping (Bool) -> Void) {
    db.collection("courses")
        .whereField("name", isEqualTo: course.name)
        .whereField("day", isEqualTo: course.day)
        .whereField("period", isEqualTo: course.period)
        .getDocuments { querySnapshot, error in
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
