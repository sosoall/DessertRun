import SwiftUI
import UIKit

/// 图片选择器协调器 - 处理UIImagePickerController的回调
class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    init(selectedImage: Binding<UIImage?>, isPresented: Binding<Bool>) {
        self._selectedImage = selectedImage
        self._isPresented = isPresented
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            selectedImage = image
        } else if let image = info[.originalImage] as? UIImage {
            selectedImage = image
        }
        isPresented = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isPresented = false
    }
}

/// 图片选择器视图 - 提供UIImagePickerController的SwiftUI封装
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeCoordinator() -> ImagePickerCoordinator {
        return ImagePickerCoordinator(selectedImage: $selectedImage, isPresented: $isPresented)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

/// 图片选择器管理器 - 提供图片选择和处理功能
class ImagePickerManager: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isImagePickerPresented: Bool = false
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    /// 选择图片（从相册）
    func selectImageFromLibrary() {
        sourceType = .photoLibrary
        isImagePickerPresented = true
    }
    
    /// 拍照
    func takePhoto() {
        sourceType = .camera
        isImagePickerPresented = true
    }
    
    /// 清除已选择的图片
    func clearSelectedImage() {
        selectedImage = nil
    }
    
    /// 将选择的图片保存到本地或上传到服务器（示例实现）
    func saveOrUploadImage(completion: @escaping (String?) -> Void) {
        guard let image = selectedImage else {
            completion(nil)
            return
        }
        
        // 压缩图片
        guard let compressedImageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        // 创建唯一文件名
        let fileName = "image_\(UUID().uuidString).jpg"
        
        // 获取临时目录路径
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // 保存文件到临时目录
        do {
            try compressedImageData.write(to: fileURL)
            
            // 返回文件URL字符串（在实际项目中，这里应该进行服务器上传）
            completion(fileURL.absoluteString)
        } catch {
            print("保存图片失败: \(error)")
            completion(nil)
        }
    }
} 