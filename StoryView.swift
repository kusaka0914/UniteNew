import SwiftUI

struct StoryView: View {
    var story: Story
    var user: User
    @Binding var currentUser: User
    @State var isCreateStoryViewActive: Bool = false

    var body: some View {
        VStack {
            ZStack {
                Image("icon")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(story.isViewed ? Color.gray : Color.blue, lineWidth: 2))
                
                // 画像の右下に+ボタンを配置
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isCreateStoryViewActive = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.blue)
                        }
                        .navigationDestination(isPresented: $isCreateStoryViewActive) {
                            CreateStoryView(currentUser: $currentUser, onStoryCreated: { newStory in
                                    currentUser.stories.append(newStory)
                                })
                            .navigationBarBackButtonHidden(true)
                        }
                    }
                }
                .frame(width: 60, height: 60)
            }
            Text(user.username)
                .font(.caption)
        }
    }
}