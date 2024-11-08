import SwiftUI
import FirebaseFirestore

struct SearchView: View {
    @Binding var currentUser: User
    @Environment(\.dismiss) var dismiss
    @State private var selectedSearchMethod: String = "選択してください"
    @State private var selectedSearchCondition: String = "選択してください"
    @State private var selectedFaculty: String = "選択してください"
    @State private var selectedDepartment: String = "選択してください"
    @State private var selectedCourse: Course?
    @State private var isAllUserSearchActive = false
    @State private var isFacultySearchActive = false
    @State private var isDepartmentSearchActive = false
    @State private var isCourseSearchActive = false
    @State private var isHomeViewActive = false
    @State private var isUserProfileViewActive = false
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()
    
    let searchMethods = ["選択してください","学内全ユーザ検索","学部で検索", "学科で検索","履修科目で検索"]


    let faculties = ["選択してください","理工学部", "農学生命科学部", "教育学部", "人文社会科学部", "医学部"]
    let departments = ["選択してください","電子情報工学科", "機械化学科", "数物科学科", "物質創生科学科", "地球環境防災学科", "自然エネルギー学科","生物学科", "分子生命科学科", "農業化学科", "食料資源学科", "国際園芸農学科", "地球環境工学科","小学校コース", "中学校コース", "特別支援教育専攻",
    "文化資源学コース", "多文化共生コース", "経済法律コース", "企業戦略コース", "地域行動コース",
    "医学科", "保健学科", "心理支援科学科"]


    // 青森大学
    let aomoriUniversityFaculties = ["選択してください", "薬学部", "総合経営学部", "社会学部", "ソフトウェア情報学部"]
    let aomoriUniversityDepartments = [
        "選択してください", "薬学科", "経営学科", "ビジネスイノベーションコース", "会計コース",
        "スポーツビジネスコース", "フィールド・ツーリズムコース", "社会学科", "コミュニティ創生コース",
        "社会福祉コース", "ソフトウェア情報学科"
    ]

    // 青森公立大学
    let aomoriPublicUniversityFaculties = ["選択してください", "経営経済学部"]
    let aomoriPublicUniversityDepartments = ["選択してください", "経営学科", "経済学科", "地域みらい学科"]

    // 青森県立保健大学
    let aomoriHealthUniversityFaculties = ["選択してください", "健康科学部"]
    let aomoriHealthUniversityDepartments = ["選択してください", "看護学科", "理学療法学科", "社会福祉学科", "栄養学科"]

    // 弘前医療福祉大学
    let hirosakiMedicalWelfareUniversityFaculties = ["選択してください", "保健学部"]
    let hirosakiMedicalWelfareUniversityDepartments = ["選択してください", "看護学科", "作業療法学科", "言語聴覚学科"]

    // 柴田学園大学
    let shibataGakuenUniversityFaculties = ["選択してください", "生活創生学部"]
    let shibataGakuenUniversityDepartments = ["選択してください", "健康栄養学科", "こども発達学科", "フードマネジメント学科"]

    // 八戸学院大学
    let hachinoheGakuinUniversityFaculties = ["選択してください", "地域経営学部", "健康医療学部"]
    let hachinoheGakuinUniversityDepartments = ["選択してください", "地域経営学科", "人間健康学科", "看護学科"]

    // 弘前学院大学
    let hirosakiGakuinUniversityFaculties = ["選択してください", "文学部", "社会福祉学部", "看護学部"]
    let hirosakiGakuinUniversityDepartments = ["選択してください", "英語・英米文学科", "日本語・日本文学科", "社会福祉学科", "看護学科"]

    // 青森中央学院大学
    let aomoriChuoGakuinUniversityFaculties = ["選択してください", "経営法学部", "看護学部"]
    let aomoriChuoGakuinUniversityDepartments = ["選択してください", "経営法学科", "看護学科"]

    // 八戸工業大学
    let hachinoheInstituteOfTechnologyFaculties = ["選択してください", "工学部", "感性デザイン学部"]
    let hachinoheInstituteOfTechnologyDepartments = ["選択してください", "工学科", "感性デザイン学科"]

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    var body: some View {
        // NavigationStack {
            VStack {
                HStack{
                    Spacer()
                    Text("ユーザー検索")
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    Spacer()
                }
                VStack {
                Text("1.検索方法を選択")
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                Picker("検索方法", selection: $selectedSearchMethod) {
                    ForEach(searchMethods, id: \.self) { searchMethod in
                        Text(searchMethod)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
                .padding(.horizontal, 20)
                }
                .frame(width: 220,height: 110)
                .background(Color(red: 33/255, green: 33/255, blue: 33/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1.5)
                )

                Spacer()
            

                Button(action: {
                    isAllUserSearchActive = true
                    selectedSearchCondition = "学内の全ユーザ"
                }) {
                    if selectedSearchMethod == "学内全ユーザ検索" {
                        VStack {
                            Text("2.検索条件確認")
                                .fontWeight(.bold)
                                .padding(.top, 20)
                            Text("検索条件:学内の全ユーザ")
                                .padding(.top, 10)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            HStack {
                                Text("この条件で検索")
                                    .frame(width: 140, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.white, lineWidth: 1)
                                    ).padding(.bottom, 20)
                                    
                            }
                            
                        }.overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1.5)
                        )
                        .background(Color(red: 33/255, green: 33/255, blue: 33/255))
                        
                        .navigationDestination(isPresented: $isAllUserSearchActive) {
                            AllElectoricInformationView(
                                searchcondition: $selectedSearchCondition,
                                user: $currentUser,
                                currentUser: $currentUser,
                                selectedUser: User(
                                    id: "current_user_id",
                                    password: "password",
                                    username: "current_user",
                                    university: "current_university",
                                    posts: [],
                                    followers: [],
                                    following: [],
                                    accountname: "current_accountname",
                                    faculty: "current_faculty",
                                    department: "current_department",
                                    club: "current_club",
                                    bio: "current_bio",
                                    twitterHandle: "current_twitterHandle",
                                    email: "current@example.com",
                                    stories: [],
                                    iconImageURL: "https://example.com/icon.jpg",
                                    notifications: [],
                                    messages: [],
                                    courses: [],
                                    groupMessages: []
                                )
                            ).navigationBarBackButtonHidden(true)
                        }
                    }
                }

                if selectedSearchMethod == "学部で検索" {
                    VStack {
                    Text("2.検索したい学部")
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    if currentUser.university == "弘前大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(faculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(aomoriUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森公立大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(aomoriPublicUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森県立保健大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(aomoriHealthUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "弘前医療福祉大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(hirosakiMedicalWelfareUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "柴田学園大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(shibataGakuenUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "八戸学院大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(hachinoheGakuinUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "弘前学院大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(hirosakiGakuinUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森中央学院大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(aomoriChuoGakuinUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "八戸工業大学" {
                    Picker("学部", selection: $selectedFaculty) {
                        ForEach(hachinoheInstituteOfTechnologyFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }
                    }
                    .frame(width: 220,height: 100)
                    .background(Color(red: 33/255, green: 33/255, blue: 33/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1.5)
                    )
                    Spacer()
                    Button(action: {
                        isFacultySearchActive = true
                    }) {
                        if selectedFaculty != "選択してください" {
                            VStack {
                                Text("3.検索条件確認")
                                    .fontWeight(.bold)
                                    .padding(.bottom, 8)
                                Text("検索条件:" + selectedFaculty)
                                    
                                    .padding(.bottom, 8)
                                HStack {
                                    Text("この条件で検索")
                                        .frame(width: 140, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }.padding(.horizontal, 8)
                                
                            }
                            .frame(width: 220,height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1.5)
                            ).background(Color(red: 33/255, green: 33/255, blue: 33/255))
                        }
                    }
                    .navigationDestination(isPresented: $isFacultySearchActive) {
                        AllElectoricInformationView(
                            searchcondition: $selectedFaculty,
                            user: $currentUser,
                            currentUser: $currentUser,
                            selectedUser: User(
                                id: "current_user_id",
                                password: "password",
                                username: "current_user",
                                university: "current_university",
                                posts: [],
                                followers: [],
                                following: [],
                                accountname: "current_accountname",
                                faculty: "current_faculty",
                                department: "current_department",
                                club: "current_club",
                                bio: "current_bio",
                                twitterHandle: "current_twitterHandle",
                                email: "current@example.com",
                                stories: [],
                                iconImageURL: "https://example.com/icon.jpg",
                                notifications: [],
                                messages: [],
                                courses: [],
                                groupMessages: []
                            )
                        ).navigationBarBackButtonHidden(true)
                    }
                    Spacer()
                }

                if selectedSearchMethod == "学科で検索" {
                    VStack {
                    Text("2.検索したい学科")
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    if currentUser.university == "弘前大学"{
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(departments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(aomoriUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森公立大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(aomoriPublicUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森県立保健大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(aomoriHealthUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "弘前医療福祉大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(hirosakiMedicalWelfareUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "柴田学園大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(shibataGakuenUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "八戸学院大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(hachinoheGakuinUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "弘前学院大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(hirosakiGakuinUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "青森中央学院大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(aomoriChuoGakuinUniversityDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }else if currentUser.university == "八戸工業大学" {
                    Picker("学科", selection: $selectedDepartment) {
                        ForEach(hachinoheInstituteOfTechnologyDepartments, id: \.self) { department in
                            Text(department)
                        }
                    }.pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    }
                    }
                    .frame(width: 220,height: 100)
                    .background(Color(red: 33/255, green: 33/255, blue: 33/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1.5)
                    )
                    Spacer()
                    Button(action: {
                        isDepartmentSearchActive = true
                    }) {
                        if selectedDepartment != "選択してください" {
                            VStack {
                                Text("3.検索条件確認")
                                    .fontWeight(.bold)
                                    .padding(.bottom, 8)
                                Text("検索条件:" + selectedDepartment)
                                    .padding(.bottom, 8)
                                HStack {
                                    Text("この条件で検索")
                                        .frame(width: 140, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal, 8)
                            }
                            .frame(width: 220,height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1.5)
                            ).background(Color(red: 33/255, green: 33/255, blue: 33/255))
                        }
                    }
                    .navigationDestination(isPresented: $isDepartmentSearchActive) {
                        AllElectoricInformationView(
                            searchcondition: $selectedDepartment,
                            user: $currentUser,
                            currentUser: $currentUser,
                            selectedUser: User(
                                id: "current_user_id",
                                password: "password",
                                username: "current_user",
                                university: "current_university",
                                posts: [],
                                followers: [],
                                following: [],
                                accountname: "current_accountname",
                                faculty: "current_faculty",
                                department: "current_department",
                                club: "current_club",
                                bio: "current_bio",
                                twitterHandle: "current_twitterHandle",
                                email: "current@example.com",
                                stories: [],
                                iconImageURL: "https://example.com/icon.jpg",
                                notifications: [],
                                messages: [],
                                courses: [],
                                groupMessages: []
                            )
                        ).navigationBarBackButtonHidden(true)
                    }
                }

                if selectedSearchMethod == "履修科目で検索" {
                    VStack {
                    Text("2.検索したい科目")
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    Picker("科目", selection: $selectedCourse) {
                        Text("選択してください")
                        ForEach(currentUser.courses, id: \.self) { course in
                            Text(course.name)
                                .tag(course as Course?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    
                    }
                    .frame(width: 220,height: 110)
                    .background(Color(red: 33/255, green: 33/255, blue: 33/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 1.5)
                    )
                    Spacer()
                    Button(action: {
                        isCourseSearchActive = true
                    }) {
                        if let selectedCourse = selectedCourse {
                            VStack {
                                Text("3.検索条件確認")
                                    .fontWeight(.bold)
                                    .padding(.bottom, 8)
                                Text("検索条件: \(selectedCourse.name)")
                                    .padding(.bottom, 8)
                                HStack {
                                    Text("この条件で検索")
                                        .frame(width: 140, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal, 8)
                            }
                            .frame(width: 220,height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1.5)
                            ).background(Color(red: 33/255, green: 33/255, blue: 33/255))
                        }
                    }
                    .navigationDestination(isPresented: $isCourseSearchActive) {
                        AllElectoricInformationView(
                            searchcondition: .constant(selectedCourse?.name ?? ""),
                            user: $currentUser,
                            currentUser: $currentUser,
                            selectedUser: User(
                                id: "current_user_id",
                                password: "password",
                                username: "current_user",
                                university: "current_university",
                                posts: [],
                                followers: [],
                                following: [],
                                accountname: "current_accountname",
                                faculty: "current_faculty",
                                department: "current_department",
                                club: "current_club",
                                bio: "current_bio",
                                twitterHandle: "current_twitterHandle",
                                email: "current@example.com",
                                stories: [],
                                iconImageURL: "https://example.com/icon.jpg",
                                notifications: [],
                                messages: [],
                                courses: [],
                                groupMessages: []
                            )
                        ).navigationBarBackButtonHidden(true)
                    }
                }

                Spacer()
                Spacer()
            
                HStack {
                    Spacer()
                    Button(action: {
                        isHomeViewActive = true
                    }) {
                        Image(systemName: "house")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    .navigationDestination(isPresented: $isHomeViewActive) {
                        HomeView(currentUser: $currentUser, postUser: User(
                            id: "current_user_id",
                            password: "password",
                            username: "current_user",
                            university: "current_university",
                            posts: [],
                            followers: [],
                            following: [],
                            accountname: "current_accountname",
                            faculty: "current_faculty",
                            department: "current_department",
                            club: "current_club",
                            bio: "current_bio",
                            twitterHandle: "current_twitterHandle",
                            email: "current@example.com",
                            stories: [],
                            iconImageURL: "https://example.com/icon.jpg",
                            notifications: [],
                            messages: [],
                            courses: [],
                            groupMessages: []
                        ))
                        .navigationBarBackButtonHidden(true)
                    }
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                    Spacer()
                    NavigationLink(destination: CreatePostView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                    ) {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    Spacer()
                    Button(action: {
                        isUserProfileViewActive = true
                    }) {
                        Image(systemName: "person")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                    }
                    .navigationDestination(isPresented: $isUserProfileViewActive) {
                        UserProfileView(currentUser: $currentUser)
                        .navigationBarBackButtonHidden(true)
                    }
                    Spacer()
                }
                .foregroundColor(.white)
                .background(Color.black)
            }
            .background(Color.black)
            .foregroundColor(.white)
            .navigationBarBackButtonHidden(true)
        // }
        
    }
}