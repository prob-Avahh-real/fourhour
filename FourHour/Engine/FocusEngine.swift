import Foundation
import Combine
import UserNotifications
import UIKit

/// 专注引擎 — 管理 4 小时预算和焦点会话
@MainActor
final class FocusEngine: ObservableObject {
    @Published var budget = DailyBudget(date: Date())
    @Published var activeSession: FocusSession?
    @Published var isInFocus = false
    @Published var elapsedInSession: TimeInterval = 0

    private var timer: Timer?
    private var sessionStart: Date?

    // MARK: - Today's Budget

    func loadToday() {
        let saved = StorageService.shared.loadBudget(for: Date())
        if let s = saved {
            budget = s
        } else {
            budget = DailyBudget(date: Date())
        }
    }

    func saveBudget() {
        StorageService.shared.saveBudget(budget)
    }

    // MARK: - Task Management

    func addTask(_ title: String, quadrant: PriorityTask.EisenhowerQuadrant, minutes: Int) {
        let order = budget.topTasks.count
        let task = PriorityTask(
            title: title,
            estimatedMinutes: minutes,
            quadrant: quadrant,
            order: order
        )
        budget.topTasks.append(task)
        saveBudget()
    }

    func toggleTask(_ id: UUID) {
        guard let idx = budget.topTasks.firstIndex(where: { $0.id == id }) else { return }
        budget.topTasks[idx].isCompleted.toggle()
        if budget.topTasks[idx].isCompleted {
            budget.topTasks[idx].actualMinutes = budget.topTasks[idx].estimatedMinutes
        }
        saveBudget()
    }

    func deleteTask(_ id: UUID) {
        budget.topTasks.removeAll { $0.id == id }
        saveBudget()
    }

    func reorderTasks(from: IndexSet, to: Int) {
        budget.topTasks.move(fromOffsets: from, toOffset: to)
        for i in budget.topTasks.indices { budget.topTasks[i].order = i }
        saveBudget()
    }

    var sortedTasks: [PriorityTask] {
        budget.topTasks.sorted { t1, t2 in
            if t1.isCompleted != t2.isCompleted { return !t1.isCompleted }
            return t1.order < t2.order
        }
    }

    // MARK: - Focus Session

    func startFocus(task: PriorityTask? = nil, minutes: Int = 25) {
        guard !isInFocus else { return }

        let session = FocusSession(
            startAt: Date(),
            targetMinutes: minutes,
            taskTitle: task?.title
        )
        activeSession = session
        sessionStart = Date()
        isInFocus = true
        elapsedInSession = 0

        // 发送专注模式通知
        sendNotification(title: "🔒 深度工作开始",
                         body: "\(minutes) 分钟内屏蔽干扰，专注当下。")

        // 启动计时
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func endFocus(interrupted: Bool = false, reason: String? = nil) {
        guard var session = activeSession else { return }

        timer?.invalidate()
        timer = nil

        session.endAt = Date()
        session.interrupted = interrupted
        session.interruptionReason = reason
        isInFocus = false

        // 只有完整完成的 session 才计入深度工作
        if !interrupted {
            let duration = Date().timeIntervalSince(session.startAt)
            budget.deepWorkUsed += duration
            budget.focusSessions.append(session)
        }

        activeSession = nil
        sessionStart = nil
        elapsedInSession = 0
        saveBudget()

        if !interrupted {
            sendNotification(title: "✅ 专注完成",
                             body: "\(session.actualMinutes) 分钟深度工作已记录，剩余 \(budget.formattedRemaining)")
        }
    }

    private func tick() {
        guard let start = sessionStart else { return }
        elapsedInSession = Date().timeIntervalSince(start)
    }

    // MARK: - Distraction

    func recordDistraction() {
        budget.distractions += 1
        saveBudget()
    }

    // MARK: - End of Day Review

    func submitReview(mood: Int, note: String, insight: String) {
        budget.mood = mood
        budget.note = note

        let summary = DaySummary(
            date: budget.date,
            deepWorkMinutes: Int(budget.deepWorkUsed / 60),
            tasksCompleted: budget.topTasks.filter(\.isCompleted).count,
            topTaskCompleted: budget.topTasks.first?.isCompleted ?? false,
            distractions: budget.distractions,
            mood: mood,
            note: note,
            insight: insight
        )
        StorageService.shared.saveSummary(summary)
        saveBudget()
    }

    // MARK: - Notifications

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
