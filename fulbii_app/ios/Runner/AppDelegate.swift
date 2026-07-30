import Flutter
import GoogleMaps
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
  private let watchChannelName = "fulbii/watch_bridge"
  private let authTokenKey = "watch_bridge_auth_token"
  private let authUserIdKey = "watch_bridge_user_id"
  private let upcomingMatchesKey = "watch_bridge_upcoming_matches"
  private let confirmedMatchesKey = "watch_bridge_confirmed_matches"
  private let pendingMatchesKey = "watch_bridge_pending_matches"
  private let userNickKey = "watch_bridge_user_nick"
  private let userNameKey = "watch_bridge_user_name"
  private let apiBaseUrlKey = "watch_bridge_api_base_url"
  private let incomingQueueKey = "watch_bridge_incoming_queue"
  private var watchChannelConfigured = false
  private var lastPushedContextSignature: String?
  private var incomingFlushTask: Task<Void, Never>?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
      !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      apiKey != "YOUR_GOOGLE_MAPS_API_KEY" {
      GMSServices.provideAPIKey(apiKey)
    }

    GeneratedPluginRegistrant.register(with: self)
    setupWatchConnectivity()
    setupWatchMethodChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if !watchChannelConfigured {
      setupWatchMethodChannel()
    }
    pushCurrentContextToWatch()
    scheduleIncomingQueueFlush(reason: "app_active")
  }

  private func setupWatchConnectivity() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
    pushCurrentContextToWatch()
  }

  private func setupWatchMethodChannel(retryCount: Int = 30) {
    if watchChannelConfigured {
      return
    }
    guard let controller = resolveFlutterViewController() else {
      if retryCount > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
          self?.setupWatchMethodChannel(retryCount: retryCount - 1)
        }
      }
      print("[WatchBridge] MethodChannel pending: FlutterViewController not ready")
      return
    }

    let channel = FlutterMethodChannel(
      name: watchChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "deallocated", message: "AppDelegate missing", details: nil))
        return
      }
      switch call.method {
      case "setWatchAuthContext":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Invalid args", details: nil))
          return
        }
        self.setAuthContext(args)
        self.pushCurrentContextToWatch()
        result(nil)
      case "clearWatchAuthContext":
        self.clearAuthContext()
        self.pushCurrentContextToWatch()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    watchChannelConfigured = true
    print("[WatchBridge] MethodChannel ready, pushing current context to watch")
    pushCurrentContextToWatch()
  }

  private func resolveFlutterViewController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }

    if let delegateWindow = (UIApplication.shared.delegate?.window ?? nil),
      let root = delegateWindow.rootViewController as? FlutterViewController
    {
      return root
    }

    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .filter { $0.isKeyWindow || $0.windowLevel == .normal }
    for sceneWindow in scenes {
      if let flutter = sceneWindow.rootViewController as? FlutterViewController {
        return flutter
      }
      if let nav = sceneWindow.rootViewController as? UINavigationController,
        let flutter = nav.viewControllers.first(where: { $0 is FlutterViewController }) as? FlutterViewController
      {
        return flutter
      }
      if let tab = sceneWindow.rootViewController as? UITabBarController,
        let flutter = tab.viewControllers?.first(where: { $0 is FlutterViewController }) as? FlutterViewController
      {
        return flutter
      }
      if let presented = sceneWindow.rootViewController?.presentedViewController as? FlutterViewController {
        return presented
      }
    }

    return nil
  }

  private func setAuthContext(_ args: [String: Any]) {
    let defaults = UserDefaults.standard
    if let token = args["auth_token"] as? String {
      defaults.set(token, forKey: authTokenKey)
    }
    if let userId = args["user_id"] as? NSNumber {
      defaults.set(userId.intValue, forKey: authUserIdKey)
    } else if let userId = args["user_id"] as? Int {
      defaults.set(userId, forKey: authUserIdKey)
    } else if
      let rawUserId = args["user_id"] as? String,
      let userId = Int(rawUserId)
    {
      defaults.set(userId, forKey: authUserIdKey)
    } else {
      defaults.removeObject(forKey: authUserIdKey)
    }
    if let upcoming = args["upcoming_matches"] as? [[String: Any]] {
      defaults.set(upcoming, forKey: upcomingMatchesKey)
    }
    if let confirmed = args["confirmed_matches"] as? [[String: Any]] {
      let existingConfirmed = defaults.array(forKey: confirmedMatchesKey) as? [[String: Any]] ?? []
      let resolvedConfirmed = confirmed.isEmpty && !existingConfirmed.isEmpty ? existingConfirmed : confirmed
      defaults.set(resolvedConfirmed, forKey: confirmedMatchesKey)
      // Keep legacy alias updated for old watch builds.
      defaults.set(resolvedConfirmed, forKey: upcomingMatchesKey)
    }
    if let pending = args["pending_matches"] as? [[String: Any]] {
      let existingPending = defaults.array(forKey: pendingMatchesKey) as? [[String: Any]] ?? []
      let resolvedPending = pending.isEmpty && !existingPending.isEmpty ? existingPending : pending
      defaults.set(resolvedPending, forKey: pendingMatchesKey)
    }
    if let userNick = args["user_nick"] as? String {
      defaults.set(userNick, forKey: userNickKey)
    }
    if let userName = args["user_name"] as? String {
      defaults.set(userName, forKey: userNameKey)
    }
    if let apiBaseUrl = args["api_base_url"] as? String {
      defaults.set(apiBaseUrl, forKey: apiBaseUrlKey)
    }
    scheduleIncomingQueueFlush(reason: "auth_context_updated")
  }

  private func clearAuthContext() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: authTokenKey)
    defaults.removeObject(forKey: authUserIdKey)
    defaults.removeObject(forKey: upcomingMatchesKey)
    defaults.removeObject(forKey: confirmedMatchesKey)
    defaults.removeObject(forKey: pendingMatchesKey)
    defaults.removeObject(forKey: userNickKey)
    defaults.removeObject(forKey: userNameKey)
    defaults.removeObject(forKey: apiBaseUrlKey)
    lastPushedContextSignature = nil
    defaults.removeObject(forKey: incomingQueueKey)
  }

  private func pushCurrentContextToWatch() {
    if !watchChannelConfigured {
      setupWatchMethodChannel()
    }
    guard WCSession.isSupported() else { return }
    let context = buildCurrentWatchContext()

    let userIdValue = context["user_id"] as? Int
    let token = (context["auth_token"] as? String) ?? ""
    let confirmed = (context["confirmed_matches"] as? [[String: Any]]) ?? []
    let pending = (context["pending_matches"] as? [[String: Any]]) ?? []
    let signature = contextSignature(context: context, confirmed: confirmed, pending: pending)

    print("[WatchBridge] Sending context user_id=\(userIdValue ?? -1) has_token=\(!token.isEmpty) confirmed=\(confirmed.count) pending=\(pending.count)")
    if signature == lastPushedContextSignature {
      print("[WatchBridge] push skipped (unchanged payload)")
      return
    }
    do {
      try WCSession.default.updateApplicationContext(context)
      print("[WatchBridge] updateApplicationContext success")
      lastPushedContextSignature = signature
    } catch {
      let nsError = error as NSError
      if nsError.domain == WCErrorDomain, nsError.code == 7014 {
        print("[WatchBridge] companion not installed in paired watch environment (simulator pairing issue)")
      }
      print("[WatchBridge] updateApplicationContext failed: \(error.localizedDescription)")
    }

    if WCSession.default.isReachable {
      WCSession.default.sendMessage(
        context,
        replyHandler: { _ in
          print("[WatchBridge] sendMessage context success")
        },
        errorHandler: { error in
          print("[WatchBridge] sendMessage context failed: \(error.localizedDescription)")
        }
      )
    } else {
      print("[WatchBridge] sendMessage skipped (watch not reachable)")
    }
  }

  private func contextSignature(context: [String: Any], confirmed: [[String: Any]], pending: [[String: Any]]) -> String {
    let userId = (context["user_id"] as? Int) ?? -1
    let token = (context["auth_token"] as? String) ?? ""
    let tokenFlag = token.isEmpty ? "0" : "1"
    let confirmedIds = confirmed.compactMap { extractMatchId(from: $0) }.sorted()
    let pendingIds = pending.compactMap { extractMatchId(from: $0) }.sorted()
    return "u:\(userId)|t:\(tokenFlag)|c:\(confirmedIds.map(String.init).joined(separator: ","))|p:\(pendingIds.map(String.init).joined(separator: ","))"
  }

  private func extractMatchId(from item: [String: Any]) -> Int? {
    if let intValue = item["id"] as? Int {
      return intValue
    }
    if let numberValue = item["id"] as? NSNumber {
      return numberValue.intValue
    }
    if let stringValue = item["id"] as? String {
      return Int(stringValue)
    }
    return nil
  }

  private func buildCurrentWatchContext() -> [String: Any] {
    let defaults = UserDefaults.standard
    let token = defaults.string(forKey: authTokenKey) ?? ""
    let confirmed = defaults.array(forKey: confirmedMatchesKey) as? [[String: Any]]
      ?? defaults.array(forKey: upcomingMatchesKey) as? [[String: Any]]
      ?? []
    let pending = defaults.array(forKey: pendingMatchesKey) as? [[String: Any]] ?? []
    let userNick = defaults.string(forKey: userNickKey) ?? ""
    let userName = defaults.string(forKey: userNameKey) ?? ""
    let apiBaseUrl = defaults.string(forKey: apiBaseUrlKey) ?? ""
    var context: [String: Any] = [
      "schema_version": 1,
      "auth_token": token,
      "upcoming_matches": confirmed,
      "confirmed_matches": confirmed,
      "pending_matches": pending,
      "user_nick": userNick,
      "user_name": userName,
      "api_base_url": apiBaseUrl
    ]
    let rawUserId = defaults.object(forKey: authUserIdKey)
    let userId: Int?
    if let value = rawUserId as? Int {
      userId = value
    } else if let value = rawUserId as? NSNumber {
      userId = value.intValue
    } else {
      userId = nil
    }
    if let userId {
      context["user_id"] = userId
    }
    return context
  }

  private func enqueueIncoming(_ message: [String: Any]) {
    guard let payload = extractWatchSyncPayload(from: message) else { return }
    let defaults = UserDefaults.standard
    var queue = defaults.array(forKey: incomingQueueKey) as? [[String: Any]] ?? []
    queue.append(payload)
    defaults.set(queue, forKey: incomingQueueKey)
    scheduleIncomingQueueFlush(reason: "watch_payload_enqueued")
  }

  func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if let error {
      print("[WatchBridge] WCSession activation error: \(error.localizedDescription)")
    } else {
      print("[WatchBridge] WCSession activation state=\(activationState.rawValue)")
    }
    pushCurrentContextToWatch()
    scheduleIncomingQueueFlush(reason: "wc_activation")
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    print("[WatchBridge] WCSession reachability changed isReachable=\(session.isReachable)")
    pushCurrentContextToWatch()
    if session.isReachable {
      scheduleIncomingQueueFlush(reason: "wc_reachability")
    }
  }

  func sessionDidBecomeInactive(_: WCSession) {}

  func sessionDidDeactivate(_: WCSession) {
    WCSession.default.activate()
  }

  func session(_: WCSession, didReceiveMessage message: [String: Any]) {
    handleIncomingWatchMessage(message)
  }

  func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    enqueueIncoming(applicationContext)
  }

  func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    enqueueIncoming(userInfo)
  }

  func session(
    _: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    if let type = message["type"] as? String, type == "watch_pull_context" {
      let reason = (message["reason"] as? String) ?? "unknown"
      print("[WatchBridge] pull_context received reason=\(reason)")
      let context = buildCurrentWatchContext()
      let userIdValue = context["user_id"] as? Int
      let confirmed = (context["confirmed_matches"] as? [[String: Any]]) ?? []
      let pending = (context["pending_matches"] as? [[String: Any]]) ?? []
      print("[WatchBridge] pull_context reply sent user_id=\(userIdValue ?? -1) confirmed=\(confirmed.count) pending=\(pending.count)")
      replyHandler(context)
      pushCurrentContextToWatch()
      return
    }

    let handled = handleIncomingWatchMessage(message)
    replyHandler(handled ? ["ok": true] : [:])
  }

  @discardableResult
  private func handleIncomingWatchMessage(_ message: [String: Any]) -> Bool {
    if let type = message["type"] as? String, type == "watch_pull_context" {
      let reason = (message["reason"] as? String) ?? "unknown"
      print("[WatchBridge] pull_context received reason=\(reason)")
      pushCurrentContextToWatch()
      return true
    }

    enqueueIncoming(message)
    return false
  }

  private func scheduleIncomingQueueFlush(reason: String) {
    if incomingFlushTask != nil { return }
    incomingFlushTask = Task { [weak self] in
      guard let self else { return }
      defer { self.incomingFlushTask = nil }
      await self.flushIncomingQueue(reason: reason)
    }
  }

  private func flushIncomingQueue(reason: String) async {
    let defaults = UserDefaults.standard
    let token = (defaults.string(forKey: authTokenKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let baseRaw = (defaults.string(forKey: apiBaseUrlKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let base = baseRaw.hasSuffix("/") ? String(baseRaw.dropLast()) : baseRaw
    guard !token.isEmpty, !base.isEmpty else { return }

    let queue = defaults.array(forKey: incomingQueueKey) as? [[String: Any]] ?? []
    guard !queue.isEmpty else { return }

    var remaining: [[String: Any]] = []
    for payload in queue {
      let ok = await uploadWatchPayload(payload, token: token, baseUrl: base)
      if !ok {
        remaining.append(payload)
      }
    }
    defaults.set(remaining, forKey: incomingQueueKey)
    print("[WatchBridge] iPhone relay flush reason=\(reason) queued=\(queue.count) remaining=\(remaining.count)")
  }

  private func uploadWatchPayload(_ payload: [String: Any], token: String, baseUrl: String) async -> Bool {
    guard
      let sessionId = parseString(payload["sessionId"]),
      let startTime = parseString(payload["startTime"])
    else {
      return false
    }

    let groupPichangaId = normalizePositiveInt(payload["groupPichangaId"])
    guard let groupPichangaId else {
      print("[WatchBridge] relay rejected store: invalid groupPichangaId session=\(sessionId)")
      return false
    }
    let fieldId = normalizePositiveInt(payload["fieldId"])
    let fieldGeometryId = normalizePositiveInt(payload["fieldGeometryId"])
    let endTime = parseString(payload["endTime"])
    let status = parseString(payload["status"]) ?? "finished"
    let distance = (payload["distanceMeters"] as? NSNumber)?.doubleValue
      ?? Double(parseString(payload["distanceMeters"]) ?? "")
      ?? 0
    let distanceFiltered = (payload["distanceMetersFiltered"] as? NSNumber)?.doubleValue
      ?? Double(parseString(payload["distanceMetersFiltered"]) ?? "")
      ?? distance
    let distanceRaw = (payload["distanceMetersRaw"] as? NSNumber)?.doubleValue
      ?? Double(parseString(payload["distanceMetersRaw"]) ?? "")
      ?? distanceFiltered
    let rawSamples = payload["samples"] as? [[String: Any]] ?? []
    let samples = rawSamples.map { sample -> [String: Any] in
      var normalized = sample
      if let accuracyNumber = sample["horizontalAccuracy"] as? NSNumber {
        if !accuracyNumber.doubleValue.isFinite {
          normalized["horizontalAccuracy"] = NSNull()
        }
      } else if let accuracyText = sample["horizontalAccuracy"] as? String,
        let accuracy = Double(accuracyText), !accuracy.isFinite
      {
        normalized["horizontalAccuracy"] = NSNull()
      }
      if let speedNumber = sample["speed"] as? NSNumber {
        if !speedNumber.doubleValue.isFinite || speedNumber.doubleValue < 0 {
          normalized["speed"] = NSNull()
        }
      } else if let speedText = sample["speed"] as? String,
        let speed = Double(speedText), (!speed.isFinite || speed < 0)
      {
        normalized["speed"] = NSNull()
      }
      return normalized
    }
    let events = payload["events"] as? [[String: Any]] ?? []

    let storeBody: [String: Any] = [
      "external_session_id": sessionId,
      "group_pichanga_id": groupPichangaId,
      "field_id": fieldId ?? NSNull(),
      "field_geometry_id": fieldGeometryId ?? NSNull(),
      "start_time": startTime,
      "status": "live",
      "device": "watchos",
      "source": "live",
      "distance_meters_raw": distanceRaw,
      "distance_meters_filtered": distanceFiltered,
      "device_payload": [
        "watch_session_id": sessionId,
        "schema_version": parseString(payload["schema_version"]) ?? "1",
        "relay": "iphone",
      ],
    ]

    guard
      let storeResponse = await postJSON(
        url: "\(baseUrl)/watch/match-sessions",
        token: token,
        body: storeBody,
        step: "relay_store"
      ),
      let createdSession = storeResponse["session"] as? [String: Any],
      let backendSessionId = parseInt(createdSession["id"])
    else {
      return false
    }

    if !samples.isEmpty {
      let samplesOk = await postJSON(
        url: "\(baseUrl)/watch/match-sessions/\(backendSessionId)/samples/batch",
        token: token,
        body: ["samples": samples],
        step: "relay_samples_batch"
      ) != nil
      if !samplesOk {
        return false
      }
    }

    if !events.isEmpty {
      let eventsOk = await postJSON(
        url: "\(baseUrl)/watch/match-sessions/\(backendSessionId)/events/batch",
        token: token,
        body: ["events": events],
        step: "relay_events_batch"
      ) != nil
      if !eventsOk {
        return false
      }
    }

    let finishStatus = status == "auto_finished" ? status : "finished"
    let finishDistance = (distanceFiltered <= 1 && distanceRaw > 5) ? distanceRaw : distanceFiltered
    let finishBody: [String: Any] = [
      "end_time": endTime ?? startTime,
      "status": finishStatus,
      "distance_meters": finishDistance,
      "distance_meters_raw": distanceRaw,
      "distance_meters_filtered": distanceFiltered,
    ]

    let finished = await postJSON(
      url: "\(baseUrl)/watch/match-sessions/\(backendSessionId)/finish",
      token: token,
      body: finishBody,
      step: "relay_finish"
    ) != nil

    if finished {
      print("[WatchBridge] iPhone relay uploaded session_id=\(sessionId) backend_id=\(backendSessionId)")
    }
    return finished
  }

  private func postJSON(url: String, token: String, body: [String: Any], step: String) async -> [String: Any]? {
    guard let endpoint = URL(string: url) else { return nil }
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
      print("[WatchBridge] \(step) payload serialization error: \(error.localizedDescription)")
      return nil
    }

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
        if let http = response as? HTTPURLResponse {
          let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8>"
          print("[WatchBridge] \(step) failed status=\(http.statusCode) body=\(bodyText)")
        } else {
          print("[WatchBridge] \(step) failed non-http response")
        }
        return nil
      }
      return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    } catch {
      print("[WatchBridge] \(step) network error: \(error.localizedDescription)")
      return nil
    }
  }

  private func extractWatchSyncPayload(from message: [String: Any]) -> [String: Any]? {
    if let type = message["type"] as? String, type == "watch_session_sync",
      let payload = message["payload"] as? [String: Any]
    {
      return payload
    }
    if let payload = message["payload"] as? [String: Any], payload["sessionId"] != nil {
      return payload
    }
    if message["sessionId"] != nil, message["startTime"] != nil {
      return message
    }
    return nil
  }

  private func parseString(_ value: Any?) -> String? {
    guard let value else { return nil }
    let parsed = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
    return parsed.isEmpty ? nil : parsed
  }

  private func parseInt(_ value: Any?) -> Int? {
    if let intValue = value as? Int {
      return intValue
    }
    if let numberValue = value as? NSNumber {
      return numberValue.intValue
    }
    if let stringValue = value as? String {
      if let direct = Int(stringValue) {
        return direct
      }
      if let range = stringValue.range(of: #"\d+"#, options: .regularExpression) {
        return Int(String(stringValue[range]))
      }
    }
    return nil
  }

  private func normalizePositiveInt(_ value: Any?) -> Int? {
    guard let parsed = parseInt(value), parsed > 0 else { return nil }
    return parsed
  }
}
