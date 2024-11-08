import SwiftUI

struct RuleView: View {
    @State private var isAgreed = false
    @State private var showAlert = false
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: User
    @State private var isLoginViewActive = false

    var body: some View {
        VStack {

            ScrollView {
                Text("""
                利用規約
                最終更新日: 2024年10月14日

                この利用規約（以下「本規約」）は、Unite（以下「当アプリ」）の利用に関して、ユーザーとUnite開発担当（以下「当社」）との間で締結される法的な契約です。当アプリをご利用いただく前に、本規約をよくお読みください。当アプリを利用することで、本規約に同意したものとみなされます。

                1. 利用条件

                1.1 ユーザーは、本規約に従って当アプリを利用するものとします。

                1.2 ユーザーが未成年の場合、保護者または法定代理人の同意を得て当アプリを利用してください。

                1.3 不適切な投稿をした際には、アカウント削除などの処罰を受けます。

                2. ユーザーアカウント

                2.1 当アプリを利用するためには、ユーザーアカウントを作成する必要があります。

                2.2 ユーザーは、アカウントの作成時に提供する情報が正確で最新であることを保証するものとします。

                2.3 アカウントの不正利用を防ぐため、ユーザーはログイン情報を安全に管理する責任を負います。

                3. ユーザー生成コンテンツ

                3.1 当アプリにはユーザーがコンテンツ（以下「ユーザーコンテンツ」）を投稿できる機能があります。ユーザーは、投稿するコンテンツが第三者の権利を侵害しないことを保証します。

                3.2 当社は、ユーザーコンテンツが不適切、攻撃的、または本規約に違反していると判断した場合、通知なく削除する権利を有します。

                3.3 ユーザーは、他のユーザーによる不適切なコンテンツを発見した場合、通報機能を使用して当社に報告することができます。

                4. 禁止事項

                ユーザーは、以下の行為を行わないものとします。

                4.1 不適切、侮辱的、または違法なコンテンツの投稿。

                4.2 他のユーザーを嫌がらせたり、脅迫したりする行為。

                4.3 スパムや不正アクセスを試みる行為。

                4.4 当アプリの正常な運営を妨げる行為。

                5. コイン獲得方法

                ユーザーは、当アプリ内で以下の方法でコインを獲得できます。

                5.1 助け合い掲示板の問題解決報酬

                6. アカウント削除

                ユーザーは、アカウント削除をいつでも行うことができます。アカウント削除を希望する場合、アプリ内の設定ページから削除手続きを行うか、サポートページにアクセスしてください。削除完了後は、すべてのユーザーデータが削除され、元に戻すことはできません。

                7. 免責事項

                7.1 当社は、当アプリの提供において最大限の努力を払いますが、エラーや中断が発生する可能性があります。当アプリの使用に関連して発生する損害に対して、当社は一切の責任を負いません。

                7.2 当社は、ユーザー生成コンテンツの内容に対して一切の責任を負いません。ユーザー自身が責任を持って投稿してください。

                8. プライバシー

                ユーザーの個人情報の取り扱いについては、当社のプライバシーポリシーに従うものとします。

                9. 本規約の変更

                当社は、本規約をいつでも変更することができるものとします。変更があった場合は、当アプリ内で通知いたします。変更後も当アプリを引き続き利用する場合、変更後の規約に同意したものとみなされます。

                10. 準拠法

                本規約は、日本国法に準拠し、解釈されるものとします。
                """)
                    .padding()
            }
            .frame(maxHeight: .infinity)
            .background(Color(red: 37/255, green: 37/255, blue: 38/255))
            
            .cornerRadius(10)
            .padding()

            Button(action: {
                if isAgreed {
                    UserDefaults.standard.set(true, forKey: "hasAgreedToTerms") // 同意状態を保存
                    isLoginViewActive = true
                } else {
                    showAlert = true
                }
            }) {
                Text("同意して続行")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isAgreed ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(!isAgreed)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("エラー"), message: Text("利用規約に同意してください"), dismissButton: .default(Text("OK")))
            }

            Toggle(isOn: $isAgreed) {
                Text("利用規約に同意します")
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationDestination(isPresented: $isLoginViewActive) {
            LoginView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
                .navigationBarBackButtonHidden(true)
        }
    }
}