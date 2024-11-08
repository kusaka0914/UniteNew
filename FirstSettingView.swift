import SwiftUI
import FirebaseFirestore

struct FirstSettingView: View {
    @Binding var currentUser: User
    @State private var showUserProfile: Bool = false
    @State private var showAlert: Bool = false // アラート表示用の状態変数
    @State private var alertTitle: String = "" // アラートタイトル
    @State private var alertMessage: String = "" // アラートメッセージ
    @State private var alertType: AlertType = .error // アラートタイプ
    @State private var isLoading: Bool = false
    @FocusState private var isFocused: Bool
    private var db = Firestore.firestore()

    enum AlertType {
        case error
        case confirmation
    }

    init(currentUser: Binding<User>) {
        self._currentUser = currentUser
    }

    // 弘前大学
    let universities = ["選択してください","弘前大学","青森県立保健大学","青森公立大学","青森大学","弘前医療福祉大学","柴田学園大学","八戸学院大学","弘前学院大学","青森中央学院大学","八戸工業大学"]
    let faculties = ["選択してください","理工学部", "農学生命科学部", "教育学部", "人文社会科学部", "医学部"]
    let scienceDepartments = ["選択してください","電子情報工学科", "機械化学科", "数物科学科", "物質創生科学科", "地球環境防災学科", "自然エネルギー学科"]
    let agricultureDepartments = ["選択してください","生物学科", "分子生命科学科", "農業化学科", "食料資源学科", "国際園芸農学科", "地球環境工学科"]
    let educationDepartments = ["選択してください","小学校コース", "中学校コース", "特別支援教育専攻"]
    let humanitiesDepartments = ["選択してください","文化資源学コース", "多文化共生コース", "経済法律コース", "企業戦略コース", "地域行動コース"]
    let medicalDepartments = ["選択してください","医学科", "保健学科", "心理支援科学科"]


    // 青森大学
    let aomoriUniversityFaculties = ["選択してください","薬学部", "総合経営学部", "社会学部", "ソフトウェア情報学部"]
    let aomoriUniversityPharmacyDepartments = ["選択してください","薬学科"]
    let aomoriUniversityBusinessAdministrationDepartments = ["選択してください","経営学科", "ビジネスイノベーションコース", "会計コース", "スポーツビジネスコース", "フィールド・ツーリズムコース"]
    let aomoriUniversitySociologyDepartments = ["選択してください","社会学科", "コミュニティ創生コース", "社会福祉コース"]
    let aomoriUniversitySoftwareInformationDepartments = ["選択してください","ソフトウェア情報学科"]


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
    let hachinoheGakuinUniversityRegionalManagementDepartments = ["選択してください", "地域経営学科"]
    let hachinoheGakuinUniversityHealthMedicalDepartments = ["選択してください", "人間健康学科", "看護学科"]


    // 弘前学院大学
    let hirosakiGakuinUniversityFaculties = ["選択してください", "文学部", "社会福祉学部", "看護学部"]
    let hirosakiGakuinUniversityLiteratureDepartments = ["選択してください", "英語・英米文学科", "日本語・日本文学科"]
    let hirosakiGakuinUniversitySocialWelfareDepartments = ["選択してください", "社会福祉学科"]
    let hirosakiGakuinUniversityNursingDepartments = ["選択してください", "看護学科"]

    // 青森中央学院大学
    let aomoriChuoGakuinUniversityFaculties = ["選択してください", "経営法学部", "看護学部"]
    let aomoriChuoGakuinUniversityBusinessLawDepartments = ["選択してください", "経営法学科"]
    let aomoriChuoGakuinUniversityChuoNursingDepartments = ["選択してください", "看護学科"]


    // 八戸工業大学
    let hachinoheInstituteOfTechnologyFaculties = ["選択してください", "工学部", "感性デザイン学部"]

    let hachinoheInstituteOfTechnologyEngineeringDepartments = ["選択してください", "工学科"]
    let hachinoheInstituteOfTechnologyDesignDepartments = ["選択してください", "感性デザイン学科"]


    let clubs = ["選択してください","無所属","サッカー部", "テニス部", "バスケットボール部"]

    var body: some View {
        // NavigationStack {
            VStack {
                Spacer()
                Text("繋がりを広げよう")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                    .padding(.horizontal,40)
                HStack {
                    Text("ユーザー名")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    Spacer()
                }.padding(.leading,40)
                HStack {
                TextField("ユーザー名(半角英数字_のみ)", text: $currentUser.username)
                    .frame(width: 250)
                    .padding(.horizontal)
                    .padding(.vertical,8)
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    .foregroundColor(.white) // 文字色を黒に設定
                    .focused($isFocused)
                    .onTapGesture {
                        isFocused = true
                    }
                    Spacer()
                }.padding(.leading,40)
                HStack {
                    Text("所属大学")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }.padding(.leading,40)
                HStack {
                    Picker("大学", selection: $currentUser.university) {
                        ForEach(universities, id: \.self) { university in
                            Text(university)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                }.padding(.leading,40)
                HStack {
                    Text("所属学部")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }.padding(.leading,40)
                if currentUser.university == "弘前大学" {
                HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(faculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "青森大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(aomoriUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "青森公立大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(aomoriPublicUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "青森県立保健大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(aomoriHealthUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "弘前医療福祉大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(hirosakiMedicalWelfareUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "柴田学園大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(shibataGakuenUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "八戸学院大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(hachinoheGakuinUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)

                } else if currentUser.university == "弘前学院大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(hirosakiGakuinUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "青森中央学院大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(aomoriChuoGakuinUniversityFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                } else if currentUser.university == "八戸工業大学" {
                    HStack {
                    Picker("学部", selection: $currentUser.faculty) {
                        ForEach(hachinoheInstituteOfTechnologyFaculties, id: \.self) { faculty in
                            Text(faculty)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                    Spacer()
                    }.padding(.leading,40)
                }
                HStack {
                    Text("所属学科")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }.padding(.leading,40)
                if currentUser.faculty == "理工学部" && currentUser.university == "弘前大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(scienceDepartments, id: \.self) { scienceDepartment in
                                Text(scienceDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "農学生命科学部" && currentUser.university == "弘前大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(agricultureDepartments, id: \.self) { agricultureDepartment in
                                Text(agricultureDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "教育学部" && currentUser.university == "弘前大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(educationDepartments, id: \.self) { educationDepartment in
                                Text(educationDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "人文社会科学部" && currentUser.university == "弘前大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(humanitiesDepartments, id: \.self) { humanitiesDepartment in
                                Text(humanitiesDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "医学部" && currentUser.university == "弘前大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(medicalDepartments, id: \.self) { medicalDepartment in
                                Text(medicalDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "経営経済学部" && currentUser.university == "青森公立大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriPublicUniversityDepartments, id: \.self) { businessLawDepartment in
                                Text(businessLawDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                }else if currentUser.faculty == "健康科学部" && currentUser.university == "青森県立保健大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriHealthUniversityDepartments, id: \.self) { healthScienceDepartment in
                                Text(healthScienceDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                }else if currentUser.faculty == "薬学部" && currentUser.university == "青森大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriUniversityPharmacyDepartments, id: \.self) { pharmacyDepartment in
                                Text(pharmacyDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                }else if currentUser.faculty == "総合経営学部" && currentUser.university == "青森大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriUniversityBusinessAdministrationDepartments, id: \.self) { generalBusinessDepartment in
                                Text(generalBusinessDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "社会学部" && currentUser.university == "青森大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriUniversitySociologyDepartments, id: \.self) { sociologyDepartment in
                                Text(sociologyDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "ソフトウェア情報学部" && currentUser.university == "青森大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriUniversitySoftwareInformationDepartments, id: \.self) { softwareDepartment in
                                Text(softwareDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "保健学部" && currentUser.university == "弘前医療福祉大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hirosakiMedicalWelfareUniversityDepartments, id: \.self) { welfareDepartment in
                                Text(welfareDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "生活創生学部" && currentUser.university == "柴田学園大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(shibataGakuenUniversityDepartments, id: \.self) { shibataDepartment in
                                Text(shibataDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "地域経営学部" && currentUser.university == "八戸学院大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hachinoheGakuinUniversityRegionalManagementDepartments, id: \.self) { regionalDepartment in
                                Text(regionalDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "健康医療学部" && currentUser.university == "八戸学院大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hachinoheGakuinUniversityHealthMedicalDepartments, id: \.self) { healthDepartment in
                                Text(healthDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "文学部" && currentUser.university == "弘前学院大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hirosakiGakuinUniversityLiteratureDepartments, id: \.self) { literatureDepartment in
                                Text(literatureDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "社会福祉学部" && currentUser.university == "弘前学院大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hirosakiGakuinUniversitySocialWelfareDepartments, id: \.self) { welfareDepartment in
                                Text(welfareDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "看護学部" && currentUser.university == "弘前学院大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hirosakiGakuinUniversityNursingDepartments, id: \.self) { nursingDepartment in
                                Text(nursingDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "経営法学部" && currentUser.university == "青森中央学院大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriChuoGakuinUniversityBusinessLawDepartments, id: \.self) { businessLawDepartment in
                                Text(businessLawDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "看護学部" && currentUser.university == "青森中央学院大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(aomoriChuoGakuinUniversityChuoNursingDepartments, id: \.self) { chuoNursingDepartment in
                                Text(chuoNursingDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "工学部" && currentUser.university == "八戸工業大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hachinoheInstituteOfTechnologyEngineeringDepartments, id: \.self) { engineeringDepartment in
                                Text(engineeringDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                } else if currentUser.faculty == "感性デザイン学部" && currentUser.university == "八戸工業大学" {
                    HStack {
                        Picker("学科", selection: $currentUser.department) {
                            ForEach(hachinoheInstituteOfTechnologyDesignDepartments, id: \.self) { designDepartment in
                                Text(designDepartment)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .background(Color(red: 37/255, green: 37/255, blue: 38/255))
                        .cornerRadius(5.0)
                        .padding(.bottom, 20)
                        Spacer()
                    }.padding(.leading,40)
                }
                
                
                Button(action: {
                    if currentUser.university == "選択してください" || currentUser.faculty == "選択してください" || currentUser.department == "選択してください" || currentUser.faculty.isEmpty || currentUser.department.isEmpty {
                        alertTitle = "エラー"
                        alertMessage = "全てのフィールドを入力してください。"
                        alertType = .error
                        showAlert = true
                    } else if !isValidUsername(currentUser.username) {
                        alertTitle = "エラー"
                        alertMessage = "ユーザー名は半角英語、数字、アンダースコア(_)のみで構成してください。"
                        alertType = .error
                        showAlert = true
                    } else {
                        alertTitle = "確認"
                        alertMessage = "大学は変更することができませんがよろしいですか？"
                        alertType = .confirmation
                        showAlert = true // 確認アラートを表示
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("保存")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 40)
                            .background(Color.black)
                            .border(Color.white)
                    }
                }
                .padding(.bottom, 20)
                .alert(isPresented: $showAlert) {
                    switch alertType {
                    case .error:
                        return Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    case .confirmation:
                        return Alert(
                            title: Text(alertTitle),
                            message: Text(alertMessage),
                            primaryButton: .default(Text("OK")) {
                                isLoading = true
                                checkUsernameAvailability { isAvailable in
                                    if isAvailable {
                                        FirestoreHelper.shared.saveUser(currentUser) { result in
                                            switch result {
                                            case .success:
                                                createOrUpdateDepartmentGroup(userId: currentUser.id, department: currentUser.department) {
                                                    // createOrUpdateFacultyGroup(userId: currentUser.id, faculty: currentUser.faculty) {
                                                        showUserProfile = true
                                                        UserDefaults.standard.set(currentUser.id, forKey: "loggedInUserId")
                                                    // }
                                                }
                                                
                                            
                                                
                                            
                                            case .failure(let error):
                                                alertTitle = "エラー"
                                                alertMessage = "ユーザーの保存に失敗しました。"
                                                alertType = .error
                                                showAlert = true
                                                isLoading = false
                                            }
                                        }
                                    } else {
                                        alertTitle = "エラー"
                                        alertMessage = "このユーザー名は既に使用されています。別のユーザー名を選択してください。"
                                        alertType = .error
                                        showAlert = true
                                        isLoading = false
                                    }
                                }
                            },
                            secondaryButton: .cancel(Text("キャンセル"))
                        )
                    }
                }
                .navigationDestination(isPresented: $showUserProfile) {
                    UserProfileView(
                        currentUser: $currentUser
                    ).navigationBarBackButtonHidden(true)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black) // 背景色を黒に設定
            .foregroundColor(.white) // テキスト色を白に設定
            .onTapGesture {
                if isFocused {
                    isFocused = false
                }
            }
        // }
        .background(Color.black) // 余白の背景色を黒に設定
    }

//     private func createOrUpdateFacultyGroup(userId: String, faculty: String, completion: @escaping () -> Void) {
//     let groupMessageId = "group-\(faculty)"
//     let groupMessageRef = db.collection("groupMessages").document(groupMessageId)
    
//     groupMessageRef.getDocument { (document, error) in
//         if let document = document, document.exists {
//             do {
//                 var existingGroupMessage = try document.data(as: GroupMessage.self)
//                 existingGroupMessage.userIds.append(userId)
//                 print("既存のグループにユーザーを追加")
                
//                 try groupMessageRef.setData(from: existingGroupMessage) { error in
//                     if let error = error {
//                         print("グループメッセージの更新に失敗しました: \(error.localizedDescription)")
//                     } else {
//                         print("グループメッセージが正常に更新されました")
//                         updateUserGroupMessages(for: existingGroupMessage)
//                         completion()
//                     }
//                 }
//             } catch let error {
//                 print("グループメッセージのデコードエラー: \(error.localizedDescription)")
//             }
//         } else {
//             // 新しいグループを作成
//             print("新しいグループを作成")
//             let newGroupMessage = GroupMessage(id: groupMessageId, name: faculty, userIds: [userId], messages: [], iconImageURL: "")
//             do {
//                 try groupMessageRef.setData(from: newGroupMessage) { error in
//                     if let error = error {
//                         print("グループメッセージの作成に失敗しました: \(error.localizedDescription)")
//                     } else {
//                         print("グループメッセージが正常に作成されました")
//                         updateUserGroupMessages(for: newGroupMessage)
//                         completion()
//                     }
//                 }
//             } catch let error {
//                 print("グループメッセージのエンコードエラー: \(error.localizedDescription)")
//             }
//         }
//     }
// }

private func createOrUpdateDepartmentGroup(userId: String, department: String, completion: @escaping () -> Void) {
    let groupMessageId = "group-\(department)"
    let groupMessageRef = db.collection("groupMessages").document(groupMessageId)
    
    groupMessageRef.getDocument { (document, error) in
        if let document = document, document.exists {
            do {
                var existingGroupMessage = try document.data(as: GroupMessage.self)
                existingGroupMessage.userIds.append(userId)
                print("既存のグループにユーザーを追加")
                
                try groupMessageRef.setData(from: existingGroupMessage) { error in
                    if let error = error {
                        print("グループメッセージの更新に失敗しました: \(error.localizedDescription)")
                    } else {
                        print("グループメッセージが正常に更新されました")
                        updateUserGroupMessages(for: existingGroupMessage)
                        completion()
                    }
                }
            } catch let error {
                print("グループメッセージのデコードエラー: \(error.localizedDescription)")
            }
        } else {
            // 新しいグループを作成
            print("新しいグループを作成")
            let newGroupMessage = GroupMessage(id: groupMessageId, name: department, userIds: [userId], messages: [], iconImageURL: "")
            do {
                try groupMessageRef.setData(from: newGroupMessage) { error in
                    if let error = error {
                        print("グループメッセージの作成に失敗しました: \(error.localizedDescription)")
                    } else {
                        print("グループメッセージが正常に作成されました")
                        updateUserGroupMessages(for: newGroupMessage)
                        completion()
                    }
                }
            } catch let error {
                print("グループメッセージのエンコードエラー: \(error.localizedDescription)")
            }
        }
    }
}

   

    private func updateUserGroupMessages(for groupMessage: GroupMessage) {
            let userRef = db.collection("users").document(currentUser.id)
            
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if var user = try? document.data(as: User.self) {
                        user.groupMessages.append(groupMessage)
                        FirestoreHelper.shared.saveUser(user) { result in
                            switch result {
                            case .success:
                                print("User \(user.id) successfully updated!")
                                print("user: \(user.groupMessages.count)")
                            case .failure(let error):
                                print("Error updating user \(user.id): \(error)")
                            }
                        }
                    }
                } else {
                    print("User \(currentUser.id) does not exist")
                }
            }
        
    }

    private func checkUsernameAvailability(completion: @escaping (Bool) -> Void) {
        db.collection("users").whereField("username", isEqualTo: currentUser.username).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error checking username availability: \(error)")
                completion(false)
                return
            }
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                completion(false) // ユーザー名が既に存在する
            } else {
                completion(true) // ユーザー名が利用可能
            }
        }
    }

    private func isValidUsername(_ username: String) -> Bool {
        let regex = "^[a-zA-Z0-9_]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: username)
    }
}
