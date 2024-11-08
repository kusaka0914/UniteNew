import SwiftUI
import PhotosUI
import FirebaseFirestore
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [String]
    @Environment(\.presentationMode) var presentationMode

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    parent.presentationMode.wrappedValue.dismiss()

    for result in results {
        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                            try? imageData.write(to: tempURL)
                            self.parent.selectedImages.append(tempURL.absoluteString)
                        }
                    }
                }
            }
        } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                DispatchQueue.main.async {
                    if let url = url {
                        self.parent.selectedImages.append(url.absoluteString)
                    }
                }
            }
        }
    }
}
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos]) // 画像と動画の両方を選択可能に設定
        configuration.selectionLimit = 0 // 0に設定すると無制限に選択可能
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

struct ImagePickerWithSendView: View {
    @Binding var selectedImages: [String]
    @Binding var isPresented: Bool
    var onSend: () -> Void

    var body: some View {
        VStack {
            if !selectedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedImages, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .padding()
                            }
                        }
                    }
                }
                Button(action: {
                    onSend()
                    isPresented = false
                }) {
                    Text("送信")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                Button(action: {
                    isPresented = true
                }) {
                    Text("画像未選択")
                        .foregroundColor(.white)
                        .padding()
                }
                .padding()
                .sheet(isPresented: $isPresented) {
                    ImagePicker(selectedImages: $selectedImages)
                }
            }
            Spacer()
        }
        .onChange(of: selectedImages) { _ in
            if !selectedImages.isEmpty {
                onSend()
                isPresented = false
            }
        }
    }
}

extension ImagePickerWithSendView {
    private func saveImagesToFirestore(_ images: [UIImage]) {
        let dispatchGroup = DispatchGroup()
        var uploadError: Error?

        for image in images {
            dispatchGroup.enter()
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                uploadError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
                dispatchGroup.leave()
                continue
            }
            let imageId = UUID().uuidString
            let base64String = imageData.base64EncodedString()

            Firestore.firestore().collection("images").document(imageId).setData(["imageData": base64String]) { error in
                if let error = error {
                    uploadError = error
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let error = uploadError {
                print("Error saving images to Firestore: \(error)")
            } else {
                print("Images successfully saved to Firestore!")
            }
        }
    }
}