import Foundation

// MARK: - Core Concept

/// 每天 4 小时深度工作预算
struct DailyBudget {
    static let totalDeepWorkSeconds: TimeInterval = 4 * 3600 // 14,400 秒

    var date: Date
    var deepWorkUsed: TimeInterval = 0       // 已使用的深度工作时间
    var focusSessions: [FocusSession] = []
    var topTasks: [PriorityTask] = []
    var distractions: Int = 0                // 被打断次数
    var mood: Int?                           // 1-5 收工心情
    var note: String = ""

    var remaining: TimeInterval {
        max(0, Self.totalDeepWorkSeconds - deepWorkUsed)
    }

    var progress: Double {
        min(1, deepWorkUsed / Self.totalDeepWorkSeconds)
    }

    var isOverBudget: Bool { deepWorkUsed > Self.totalDeepWorkSeconds }
    var formattedRemaining: String { formatTime(remaining) }
    var formattedUsed: String { formatTime(deepWorkUsed) }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }
}

// MARK: - Priority Task (80/20)

struct PriorityTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var estimatedMinutes: Int       // 预计耗时
    var actualMinutes: Int?         // 实际耗时
    var quadrant: EisenhowerQuadrant
    var isCompleted: Bool = false
    var order: Int                  // 优先级排序

    /// 投入产出比自评
    var roi: Int?                   // 1-5，完成后自评

    enum EisenhowerQuadrant: String, Codable, CaseIterable {
        case urgentImportant     = "紧急且重要"
        case notUrgentImportant  = "重要不紧急"  // ← 4小时理念：优先投入这里
        case urgentNotImportant  = "紧急不重要"
        case notUrgentNotImportant = "不紧急不重要"

        var icon: String {
            switch self {
            case .urgentImportant:        "🔥"
            case .notUrgentImportant:     "💎"  // 核心价值观
            case .urgentNotImportant:     "📞"
            case .notUrgentNotImportant:  "🗑️"
            }
        }

        var color: String {
            switch self {
            case .urgentImportant:        "FF3B30"
            case .notUrgentImportant:     "007AFF"
            case .urgentNotImportant:     "FF9500"
            case .notUrgentNotImportant:  "8E8E93"
            }
        }
    }
}

// MARK: - Focus Session

struct FocusSession: Identifiable, Codable {
    var id = UUID()
    var startAt: Date
    var endAt: Date?
    var targetMinutes: Int
    var taskTitle: String?
    var interrupted: Bool = false
    var interruptionReason: String?

    var actualMinutes: Int {
        guard let end = endAt else { return 0 }
        return Int(end.timeIntervalSince(startAt) / 60)
    }

    var isComplete: Bool { endAt != nil && !interrupted }
}

// MARK: - Energy Level

enum EnergyLevel: String, CaseIterable, Codable {
    case peak    = "⚡️ 巅峰"
    case high    = "🔥 充沛"
    case normal  = "😐 平常"
    case low     = "🔋 低谷"
    case drained = "🪫 耗尽"
}

// MARK: - Work Block Template

struct WorkBlock: Identifiable {
    var id = UUID()
    var title: String
    var startHour: Int       // 建议开始时间（小时）
    var durationMinutes: Int
    var energyRequired: EnergyLevel
    var tip: String
}

/// 预设的 4 小时工作模板
enum WorkTemplate {
    static let earlyBird: [WorkBlock] = [
        WorkBlock(title: "深度创作", startHour: 6, durationMinutes: 90,
                  energyRequired: .peak,
                  tip: "大脑最清醒的 90 分钟 → 做最需要创造力的工作"),
        WorkBlock(title: "战略思考", startHour: 8, durationMinutes: 60,
                  energyRequired: .high,
                  tip: "处理需要判断力的决策，列出今日三件最重要的事"),
        WorkBlock(title: "执行推进", startHour: 14, durationMinutes: 60,
                  energyRequired: .normal,
                  tip: "批量处理邮件、消息、行政事务"),
        WorkBlock(title: "复盘学习", startHour: 16, durationMinutes: 30,
                  energyRequired: .low,
                  tip: "回顾今日产出，记录 1 个可以优化的流程"),
    ]

    static let nightOwl: [WorkBlock] = [
        WorkBlock(title: "规划预热", startHour: 10, durationMinutes: 30,
                  energyRequired: .normal, tip: "喝杯咖啡，列出今天的 3 个目标"),
        WorkBlock(title: "核心输出", startHour: 15, durationMinutes: 120,
                  energyRequired: .peak, tip: "下午到傍晚是夜猫子的黄金时段"),
        WorkBlock(title: "收尾整理", startHour: 20, durationMinutes: 60,
                  energyRequired: .high, tip: "趁精力回升处理杂务"),
        WorkBlock(title: "深度反思", startHour: 22, durationMinutes: 30,
                  energyRequired: .normal, tip: "夜深人静时复盘和创新"),
    ]
}

// MARK: - Day Summary (收工复盘)

struct DaySummary: Codable {
    var date: Date
    var deepWorkMinutes: Int
    var tasksCompleted: Int
    var topTaskCompleted: Bool
    var distractions: Int
    var mood: Int
    var note: String
    var insight: String    // 今天学到的一件事
}
