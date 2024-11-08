// import SwiftUI
// import PhotosUI

//   struct Photo: Identifiable {
//         let id = UUID()
//         let asset: PHAsset
//         var image: UIImage?
//     }

// struct CustomImagePicker: View {
//     @State private var photos: [Photo] = []
//     @State private var selectedImages: [UIImage] = []

  

//     var body: some View {
//         NavigationView {
//             ScrollView {
//                 LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
//                     ForEach(photos) { photo in
//                         if let image = photo.image {
//                             Image(uiImage: image)
//                                 .resizable()
//                                 .scaledToFit()
//                                 .frame(width: 100, height: 100)
//                                 .onTapGesture {
//                                     if let index = selectedImages.firstIndex(of: image) {
//                                         selectedImages.remove(at: index)
//                                     } else {
//                                         selectedImages.append(image)
//                                     }
//                                 }
//                                 .overlay(
//                                     selectedImages.contains(image) ? Color.black.opacity(0.5) : Color.clear
//                                 )
//                         }
//                     }
//                 }
//             }
//             .onAppear(perform: loadPhotos)
//             .navigationTitle("写真を選択")
//         }
//     }

//     private func loadPhotos() {
//         PHPhotoLibrary.requestAuthorization { status in
//             if status == .authorized {
//                 let fetchOptions = PHFetchOptions()
//                 let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
//                 assets.enumerateObjects { (asset, _, _) in
//                     let photo = Photo(asset: asset)
//                     self.photos.append(photo)
//                 }
//                 loadImages()
//             }
//         }
//     }

//     private func loadImages() {
//         let imageManager = PHCachingImageManager()
//         let options = PHImageRequestOptions()
//         options.isSynchronous = true
//         options.deliveryMode = .highQualityFormat

//         for index in photos.indices {
//             let asset = photos[index].asset
//             imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: options) { image, _ in
//                 if let image = image {
//                     photos[index].image = image
//                 }
//             }
//         }
//     }
// }