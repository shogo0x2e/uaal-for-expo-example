import ExpoModulesCore
import Metal
import UIKit

private let placeholderClearColor = MTLClearColor(red: 0, green: 1, blue: 0, alpha: 1)
private let placeholderUIColor = UIColor.green.cgColor

class ExpoUnityView: ExpoView {
  private static let device: MTLDevice? = MTLCreateSystemDefaultDevice()
  private static let commandQueue: MTLCommandQueue? = device?.makeCommandQueue()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    isUserInteractionEnabled = false // let React overlay handle touches

    // Base background so layer inspectorでも色が見える
    backgroundColor = .green
    layer.isOpaque = true

    guard let metalLayer = layer as? CAMetalLayer else { return }
    metalLayer.device = ExpoUnityView.device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = false
    metalLayer.backgroundColor = placeholderUIColor

    // Metal 未対応デバイス向けフォールバック
    if ExpoUnityView.device == nil {
      metalLayer.isOpaque = true
      return
    }

    drawPlaceholder()
  }

  override class var layerClass: AnyClass { CAMetalLayer.self }

  override func layoutSubviews() {
    super.layoutSubviews()
    if let metalLayer = layer as? CAMetalLayer {
      metalLayer.frame = bounds
      metalLayer.drawableSize = bounds.size
    }
  }

  private func drawPlaceholder() {
    guard
      let metalLayer = layer as? CAMetalLayer,
      let drawable = metalLayer.nextDrawable(),
      let commandQueue = ExpoUnityView.commandQueue,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let encoder = commandBuffer.makeRenderCommandEncoder(
        descriptor: {
          let desc = MTLRenderPassDescriptor()
          desc.colorAttachments[0].texture = drawable.texture
          desc.colorAttachments[0].loadAction = .clear
          desc.colorAttachments[0].storeAction = .store
          desc.colorAttachments[0].clearColor = placeholderClearColor
          return desc
        }()
      )
    else { return }

    encoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
