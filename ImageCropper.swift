import SwiftUI
import Mantis
import FirebaseFirestore

class CropCoordinator: NSObject, CropViewControllerDelegate {
    @Binding var image: UIImage?
    @Binding var isCropViewShowing: Bool // トリミングviewを出すかどうか
    private var db = Firestore.firestore()

    init(image: Binding<UIImage?>, isCropViewShowing: Binding<Bool>) {
        _image = image
        _isCropViewShowing = isCropViewShowing
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: Mantis.CropViewController, original: UIImage) {
    
    }
    
    func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
        isCropViewShowing = false
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: Mantis.CropViewController) {
        
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: Mantis.CropViewController, original: UIImage, cropInfo: Mantis.CropInfo) {
        
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
    guard let fixedCroppedImage = fixImageOrientation(cropped) else {
        print("Failed to fix image orientation")
        return
    }
    
    image = fixedCroppedImage
    isCropViewShowing = false
    saveCroppedImageToFirestore(fixedCroppedImage)
}
    
    private func saveCroppedImageToFirestore(_ croppedImage: UIImage) {
        guard let imageData = croppedImage.jpegData(compressionQuality: 0.8) else { return }
        let imageId = UUID().uuidString
        let base64String = imageData.base64EncodedString()
        
        db.collection("croppedImages").document(imageId).setData(["imageData": base64String]) { error in
            if let error = error {
                print("Error saving image data to Firestore: \(error)")
            } else {
                print("Image data successfully saved to Firestore!")
            }
        }
    }
    private func fixImageOrientation(_ image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }

    let width = image.size.width
    let height = image.size.height
    let bitsPerComponent = 16  // エラーの指摘に基づいて16ビットに変更
    let bytesPerRow = Int(width) * 8  // 16ビット×4（RGBA）= 8バイト/ピクセル
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue)  // 16ビットリトルエンディアンに変更

    guard let context = CGContext(data: nil,
                                  width: Int(width),
                                  height: Int(height),
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
        print("Failed to create bitmap context")
        return nil
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let newCgImage = context.makeImage() else { return nil }

    return UIImage(cgImage: newCgImage)
}

}

struct ImageCropper: UIViewControllerRepresentable {
    typealias Coordinator = CropCoordinator
    @Binding var image: UIImage?
    @Binding var isCropViewShowing: Bool
    @Binding var cropShapeType: Mantis.CropShapeType // トリミングの形(丸や四角)
        
    func makeCoordinator() -> Coordinator {
        return Coordinator(image: $image, isCropViewShowing: $isCropViewShowing)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImageCropper>) -> Mantis.CropViewController {
    guard let image = image else {
        fatalError("Image is nil")
    }
    var config = Mantis.Config()
    config.cropShapeType = cropShapeType // トリミングの形変更に必要
    let editor = Mantis.cropViewController(image: image, config: config)
    editor.delegate = context.coordinator
    return editor
}
}