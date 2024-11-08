// import SwiftUI

// struct StoryEditView: View {
//     @State private var texts: [TextItem] = [] // 追加されたテキストのリスト
//     @State private var newText: String = ""
//     @State private var selectedFontSize: CGFloat = 20 // デフォルトのフォントサイズ
//     @State private var selectedColor: Color = .black // デフォルトの色

//     init() {
//         self.texts = [TextItem(text: "Hello, World!", position: CGSize.zero, fontSize: selectedFontSize, color: selectedColor)]
//     }

//     var body: some View {
//         ZStack {
//             Image("background_image") // 背景画像
//                 .resizable()
//                 .aspectRatio(contentMode: .fill)
//                 .edgesIgnoringSafeArea(.all)
            
//             // 追加されたすべてのテキストを表示
//             ForEach(texts.indices, id: \.self) { index in
//                 DraggableText(text: $texts[index])
//             }

//             VStack {
//                 Spacer()
                
//                 // テキストを追加するためのUI
//                 HStack {
//                     TextField("新しいテキストを入力", text: $newText)
//                         .textFieldStyle(RoundedBorderTextFieldStyle())
//                         .padding()

//                     Button(action: {
//                         if !newText.isEmpty {
//                             texts.append(TextItem(text: newText, position: CGSize.zero, fontSize: selectedFontSize, color: selectedColor))
//                             newText = ""
//                         }
//                     }) {
//                         Text("テキストを追加")
//                             .padding()
//                             .background(Color.blue)
//                             .foregroundColor(.white)
//                             .cornerRadius(10)
//                     }
//                 }
//                 .padding()

//                 // フォントサイズ変更用のPicker
//                 Picker("フォントサイズ", selection: $selectedFontSize) {
//                     ForEach([10, 20, 30, 40, 50], id: \.self) { size in
//                         Text("\(size)pt").tag(CGFloat(size))
//                     }
//                 }
//                 .pickerStyle(SegmentedPickerStyle())
//                 .padding()

//                 // 色変更用のColorPicker
//                 ColorPicker("テキストの色を選択", selection: $selectedColor)
//                     .padding()
//             }
//         }
//     }
// }

// struct DraggableText: View {
//     @Binding var text: TextItem
//     @State private var dragOffset: CGSize = .zero
//     @State private var scale: CGFloat = 1.0 // リサイズ用のスケール

//     var body: some View {
//         Text(text.text)
//             .font(.system(size: text.fontSize * scale)) // スケールでフォントサイズを調整
//             .foregroundColor(text.color)
//             .padding()
//             .background(Color.white.opacity(0.8))
//             .cornerRadius(8)
//             .offset(x: text.position.width + dragOffset.width, y: text.position.height + dragOffset.height)
//             .gesture(
//                 DragGesture()
//                     .onChanged { value in
//                         self.dragOffset = value.translation
//                     }
//                     .onEnded { value in
//                         self.text.position.width += value.translation.width
//                         self.text.position.height += value.translation.height
//                         self.dragOffset = .zero
//                     }
//             )
//             .gesture(
//                 MagnificationGesture()
//                     .onChanged { value in
//                         self.scale = value
//                     }
//             )
//     }
// }

// struct TextItem {
//     var text: String
//     var position: CGSize // 位置
//     var fontSize: CGFloat // フォントサイズ
//     var color: Color // テキストの色
// }

// struct StoryEditView_Previews: PreviewProvider {
//     static var previews: some View {
//         StoryEditView()
//     }
// }