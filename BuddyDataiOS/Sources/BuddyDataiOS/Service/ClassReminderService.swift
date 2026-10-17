//
//  ClassReminderService.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 17/10/2026.
//

import ActivityKit
import CryptoKit
import Foundation
import Moya
import os
import BuddyDomain
import BuddyDataCore

private let logger = Logger(subsystem: "org.sparcs.soap", category: "ClassReminder")

/// Uploads this device's schedule, reminder settings and Live Activity tokens to the feed
/// backend, which starts and updates the class Live Activity (or sends a notification) on its own.
public final class ClassReminderService: ClassReminderServiceProtocol, @unchecked Sendable {
  private let provider: MoyaProvider<ClassReminderTarget>
  private let timetableUseCase: TimetableUseCaseProtocol?
  private let state = SyncState()
  private let keychain = Keychain()

  private static let deviceIDKey = "fcmDeviceID"
  private static let fcmTokenKey = "classReminder.fcmToken"
  private static let lastSyncedHashKey = "classReminder.lastSyncedHash"

  public init(provider: MoyaProvider<ClassReminderTarget>, timetableUseCase: TimetableUseCaseProtocol?) {
    self.provider = provider
    self.timetableUseCase = timetableUseCase
    // Same keychain item as `FCMUseCase`, so the server can match this device's language.
    keychain.accessGroup = "N5V8W52U3U.org.sparcs.soap"
  }

  // MARK: - ClassReminderServiceProtocol

  public func start() {
    _Concurrency.Task { await state.startOnce { await self.observe() } }
  }

  public func updateFCMToken(_ token: String) {
    guard UserDefaults.standard.string(forKey: Self.fcmTokenKey) != token else { return }
    UserDefaults.standard.set(token, forKey: Self.fcmTokenKey)
    _Concurrency.Task { await sync() }
  }

  public func sync() async {
    await state.serialised {
      await self.performSync()
    }
  }

  public func unregister() async {
    await state.serialised {
      UserDefaults.standard.removeObject(forKey: Self.lastSyncedHashKey)
      await self.endAllActivities()
      do {
        _ = try await self.provider.request(.deleteDevice(deviceUUID: self.deviceUUID))
      } catch {
        logger.error("Unregister failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  // MARK: - Observation

  private func observe() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { await self.observePushToStartToken() }
      group.addTask { await self.observeActivities() }
      group.addTask { await self.observeAuthorisation() }
      group.addTask { await self.observeSettings() }
      group.addTask { await self.observeTheme() }
      group.addTask { await self.readTokensAfterLaunch() }
    }
  }

  private func observePushToStartToken() async {
    for await token in Activity<TimetableActivityAttributes>.pushToStartTokenUpdates {
      await state.setPushToStartToken(token.hexString)
      await sync()
    }
  }

  private func observeActivities() async {
    // Activities already running when the app launched, then any the system starts later
    // (a push-to-start launches the app in the background just long enough for this).
    for activity in Activity<TimetableActivityAttributes>.activities {
      let id = activity.id
      _Concurrency.Task { await self.observeToken(ofActivityWithID: id) }
    }
    for await activity in Activity<TimetableActivityAttributes>.activityUpdates {
      let id = activity.id
      _Concurrency.Task { await self.observeToken(ofActivityWithID: id) }
    }
  }

  // Looked up by id because `Activity` isn't Sendable across tasks.
  private func observeToken(ofActivityWithID id: String) async {
    guard let activity = Activity<TimetableActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
    for await token in activity.pushTokenUpdates {
      await upload(updateToken: token.hexString, for: activity)
    }
  }

  private func observeAuthorisation() async {
    for await _ in ActivityAuthorizationInfo().activityEnablementUpdates {
      await sync()
    }
  }

  private func observeSettings() async {
    for await _ in NotificationCenter.default.notifications(named: ClassReminderSettingsStore.didChangeNotification) {
      if ClassReminderSettingsStore().settings.mode != .liveActivity {
        await endAllActivities()
      }
      await sync()
    }
  }

  /// A running activity keeps the colours it was drawn with until something re-renders it; a
  /// local update re-renders it with the new theme, without a push.
  private func observeTheme() async {
    for await _ in NotificationCenter.default.notifications(named: TimetableThemeStore.didChangeNotification) {
      for activity in Activity<TimetableActivityAttributes>.activities {
        await activity.update(activity.content)
      }
    }
  }

  /// Before iOS 26 the token streams can come back empty at launch (fixed in iOS 26), so read
  /// the current values once more after a moment.
  private func readTokensAfterLaunch() async {
    try? await _Concurrency.Task.sleep(for: .seconds(2))
    if let token = Activity<TimetableActivityAttributes>.pushToStartToken {
      await state.setPushToStartToken(token.hexString)
    }
    for activity in Activity<TimetableActivityAttributes>.activities {
      if let token = activity.pushToken {
        await upload(updateToken: token.hexString, for: activity)
      }
    }
    await sync()
  }

  private func upload(updateToken: String, for activity: Activity<TimetableActivityAttributes>) async {
    let body = ClassReminderActivityRequestDTO(
      deviceUUID: deviceUUID,
      updateToken: updateToken,
      sessionDate: activity.attributes.sessionDate,
      sessionNo: activity.attributes.sessionNo
    )
    do {
      _ = try await provider.request(.putActivity(activityID: activity.id, body: body))
    } catch {
      logger.error("Activity token upload failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func endAllActivities() async {
    for activity in Activity<TimetableActivityAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }

  // MARK: - Sync

  private func performSync() async {
    let settings = ClassReminderSettingsStore().settings
    let body: ClassReminderDeviceRequestDTO
    if settings.mode == .off {
      body = ClassReminderDeviceRequestDTO(
        mode: settings.mode.rawValue, liveActivitiesEnabled: liveActivitiesEnabled, fcmToken: nil,
        pushToStartToken: nil, leadMinutes: settings.leadMinutes,
        includeCustomBlocks: settings.includeCustomBlocks, upNext: settings.upNext, sound: settings.sound,
        year: nil, semester: nil, slots: [], skipDates: []
      )
    } else {
      guard let fcmToken = UserDefaults.standard.string(forKey: Self.fcmTokenKey) else {
        logger.info("Sync skipped: no FCM token yet")
        return
      }
      guard let schedule = await loadSchedule() else { return }
      body = ClassReminderDeviceRequestDTO(
        mode: settings.mode.rawValue,
        liveActivitiesEnabled: liveActivitiesEnabled,
        fcmToken: fcmToken,
        pushToStartToken: await state.pushToStartToken,
        leadMinutes: settings.leadMinutes,
        includeCustomBlocks: settings.includeCustomBlocks,
        upNext: settings.upNext,
        sound: settings.sound,
        year: schedule.year,
        semester: schedule.semester,
        slots: schedule.slots,
        skipDates: []
      )
    }

    // The server dedupes too, but skipping here saves the request entirely.
    let hash = Self.hash(of: body)
    guard hash != UserDefaults.standard.string(forKey: Self.lastSyncedHashKey) else { return }
    do {
      _ = try await provider.request(.putDevice(deviceUUID: deviceUUID, body: body))
      UserDefaults.standard.set(hash, forKey: Self.lastSyncedHashKey)
      logger.info("Synced class reminders (\(body.slots.count) slots, mode \(body.mode, privacy: .public))")
    } catch {
      logger.error("Sync failed: \(error.localizedDescription, privacy: .public)")
    }
  }

  private struct Schedule {
    let year: Int
    let semester: Int
    let slots: [ClassReminderDeviceRequestDTO.Slot]
  }

  /// The timetable the app shows: the user's last selection for this semester, else My Table.
  private func loadSchedule() async -> Schedule? {
    guard let timetableUseCase else { return nil }
    do {
      let semester = try await timetableUseCase.getCurrentSemesters()
      let selection = TimetableSelectionStore().selection
      let timetable: Timetable = if let selection, selection.matches(semester), let id = selection.timetableID {
        try await timetableUseCase.getTable(id: id)
      } else {
        try await timetableUseCase.getMyTable(semester: semester)
      }
      var slots = ClassReminderSchedule.slots(of: timetable)
      #if DEBUG
      slots += Self.testSlots(from: slots)
      #endif
      return Schedule(
        year: semester.year,
        semester: ClassReminderSchedule.otlNumber(of: semester.semesterType),
        slots: slots
      )
    } catch {
      logger.error("Sync skipped: timetable unavailable: \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }

  #if DEBUG
  /// `-ClassReminderTestClassIn <minutes>` copies two of the timetable's lectures into today,
  /// the first starting that many minutes from now and the second 15 minutes after it ends, so
  /// the server's pushes can be watched on any day.
  private static func testSlots(from slots: [ClassReminderDeviceRequestDTO.Slot]) -> [ClassReminderDeviceRequestDTO.Slot] {
    let minutes = UserDefaults.standard.integer(forKey: "ClassReminderTestClassIn")
    guard minutes > 0 else { return [] }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    let now = calendar.dateComponents([.weekday, .hour, .minute], from: .now)
    let today = ((now.weekday ?? 2) + 5) % 7  // Calendar's Sunday = 1 → OTL's Monday = 0
    let firstBegin = (now.hour ?? 0) * 60 + (now.minute ?? 0) + minutes
    let lectures = slots.filter { $0.kind == "lecture" }
    return [0, 1].compactMap { index -> ClassReminderDeviceRequestDTO.Slot? in
      guard let source = lectures.indices.contains(index) ? lectures[index] : lectures.first else { return nil }
      let begin = firstBegin + index * 90
      guard begin + 75 <= 1440 else { return nil }
      return .init(
        id: "TEST:\(index)", day: today, begin: begin, end: begin + 75, title: source.title,
        buildingCode: source.buildingCode, buildingName: source.buildingName, room: source.room,
        kind: "lecture", colorID: source.colorID
      )
    }
  }
  #endif

  private static func hash(of body: ClassReminderDeviceRequestDTO) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let data = (try? encoder.encode(body)) ?? Data()
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  private var liveActivitiesEnabled: Bool {
    ActivityAuthorizationInfo().areActivitiesEnabled
  }

  private var deviceUUID: String {
    if let id = keychain.get(Self.deviceIDKey) { return id }
    let id = UUID().uuidString
    keychain.set(id, forKey: Self.deviceIDKey)
    return id
  }
}

/// Serialises syncs and holds the push-to-start token between them.
private actor SyncState {
  private(set) var pushToStartToken: String?
  private var started = false
  private var running: _Concurrency.Task<Void, Never>?

  func setPushToStartToken(_ token: String) {
    pushToStartToken = token
  }

  func startOnce(_ body: @escaping @Sendable () async -> Void) {
    guard !started else { return }
    started = true
    _Concurrency.Task { await body() }
  }

  /// Runs `body` after any sync already in flight, so two uploads never race.
  func serialised(_ body: @escaping @Sendable () async -> Void) async {
    let previous = running
    let task = _Concurrency.Task {
      await previous?.value
      await body()
    }
    running = task
    await task.value
  }
}

private extension Data {
  var hexString: String { map { String(format: "%02x", $0) }.joined() }
}
