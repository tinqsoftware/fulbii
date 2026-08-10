import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
      contentHandler(request.content)
      return
    }
    bestAttemptContent = content

    guard let rawUrl = content.userInfo["image_url"] as? String,
          let url = URL(string: rawUrl) else {
      contentHandler(content)
      return
    }

    URLSession.shared.downloadTask(with: url) { [weak self] temporaryUrl, _, _ in
      guard let self, let temporaryUrl else {
        contentHandler(content)
        return
      }
      let fileName = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
      let destination = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
      do {
        try FileManager.default.moveItem(at: temporaryUrl, to: destination)
        if let attachment = try? UNNotificationAttachment(identifier: "fulbii-image", url: destination) {
          content.attachments = [attachment]
        }
      } catch {
        // The title/body remain useful when the attachment cannot be stored.
      }
      contentHandler(content)
    }.resume()
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler, let bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}
