import SwiftUI
import FirebaseFirestore
import PhotosUI

struct CreateStoryView: View {
    @State private var selectedImages: [String] = []
    @State private var showImagePicker = false
    @State private var storyText = "Edit me"
    @Binding var currentUser: User
    var onStoryCreated: ((Story) -> Void)?
    
    @State private var textPosition: CGSize = .zero
    @State private var imagePosition: CGSize = .zero
    @State private var textScale: CGFloat = 1.0
    @Environment(\.presentationMode) var presentationMode
    private var db = Firestore.firestore()

    init(currentUser: Binding<User>, onStoryCreated: ((Story) -> Void)?) {
        self._currentUser = currentUser
        self.onStoryCreated = onStoryCreated
    }

    var body: some View {
    VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() 
                    }) {
                        Image(systemName: "chevron.left")
                            .padding(.leading, 16)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Spacer()
                    Text("ストーリー作成")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }.padding(.top, 16)
        ZStack {
            if !selectedImages.isEmpty {
                ForEach(selectedImages, id: \.self) { imageUrl in
                    if let url = URL(string: imageUrl), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .clipped()
                            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                            .offset(imagePosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        self.imagePosition = value.translation
                                    }
                            )
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: UIScreen.main.bounds.width)
                    .overlay(Text("Tap to select an image"))
                    .onTapGesture {
                        showImagePicker = true
                    }
            }

            Text(storyText)
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .scaleEffect(textScale)
                .offset(textPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.textPosition = value.translation
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            self.textScale = value.magnitude
                        }
                )
                .onTapGesture {
                    self.showTextEditAlert()
                }

            VStack {
                Spacer()
                // Button(action: {
                //     showImagePicker = true
                // }) {
                //     Text("Select Image")
                //         .padding()
                //         .background(Color.blue)
                //         .foregroundColor(.white)
                //         .cornerRadius(10)
                // }
                // .padding()
                
                Button(action: {
                    saveStory()
                }) {
                    Text("Save Story")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }}
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $selectedImages)
        }
    }
    
    // テキスト編集用のアラートを表示する関数
    func showTextEditAlert() {
        let alert = UIAlertController(title: "Edit Text", message: "Enter your story text", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.storyText
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newText = alert.textFields?.first?.text {
                self.storyText = newText
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if let controller = UIApplication.shared.windows.first?.rootViewController {
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
    // ストーリーを保存する関数
    private func saveStory() {
        let newStory = Story(
            id: UUID().uuidString,
            imageNames: selectedImages,
            texts: [DraggableText(id: UUID().uuidString, text: storyText, position: CGPoint(x: textPosition.width, y: textPosition.height))],
            imageOffset: imagePosition,
            imageScale: textScale,
            postedDate: Date()
        )
        
        currentUser.stories.append(newStory)
        saveStoryToFirestore(newStory)
        onStoryCreated?(newStory)
    }
    
    // Firestoreにストーリーを保存する関数
    private func saveStoryToFirestore(_ story: Story) {
        do {
            let storyData = try JSONEncoder().encode(story)
            let storyDict = try JSONSerialization.jsonObject(with: storyData) as! [String: Any]
            db.collection("stories").document(story.id).setData(storyDict) { error in
                if let error = error {
                    print("Error saving story: \(error)")
                } else {
                    print("Story successfully saved!")
                }
            }
        } catch {
            print("Error encoding story: \(error)")
        }
    }
}