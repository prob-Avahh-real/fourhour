import SwiftUI

extension Color {
    static let fhDark    = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let fhCard    = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let fhGold    = Color(red: 0.95, green: 0.80, blue: 0.35)
    static let fhMint    = Color(red: 0.20, green: 0.85, blue: 0.65)
    static let fhCoral   = Color(red: 0.95, green: 0.35, blue: 0.30)
    static let fhBlue    = Color(red: 0.25, green: 0.55, blue: 0.95)
    static let fhPurple  = Color(red: 0.65, green: 0.40, blue: 0.95)
    static let fhText    = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let fhMuted   = Color(red: 0.55, green: 0.55, blue: 0.60)
}

struct DashboardView: View {
    @StateObject private var engine = FocusEngine()
    @State private var showTaskSheet = false
    @State private var showFocusSheet = false
    @State private var showReview = false
    @State private var selectedTask: PriorityTask?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fhDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 顶部 4 小时环形仪表
                        budgetRing
                            .padding(.top, 16)

                        // 专注状态按钮
                        focusButton

                        // 今日任务
                        taskSection

                        // 工作块建议
                        templateSection

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("每天工作 4 小时")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showReview = true } label: {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(.fhGold)
                    }
                }
            }
            .sheet(isPresented: $showTaskSheet) {
                AddTaskView(engine: engine)
            }
            .sheet(isPresented: $showFocusSheet) {
                FocusSessionView(engine: engine)
            }
            .sheet(isPresented: $showReview) {
                DailyReviewView(engine: engine)
            }
            .onAppear { engine.loadToday() }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Budget Ring

    private var budgetRing: some View {
        VStack(spacing: 0) {
            ZStack {
                // 背景环
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 22)
                    .frame(width: 220, height: 220)

                // 进度弧
                Circle()
                    .trim(from: 0, to: min(engine.budget.progress, 1.0))
                    .stroke(
                        AngularGradient(
                            colors: engine.budget.isOverBudget
                                ? [.fhCoral, .red]
                                : [.fhMint, .fhGold, .fhCoral],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: engine.budget.progress)

                // 中心数值
                VStack(spacing: 4) {
                    Text(engine.budget.formattedRemaining)
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundStyle(engine.budget.isOverBudget ? .fhCoral : .white)
                        .contentTransition(.numericText())

                    Text("剩余深度时间")
                        .font(.caption).foregroundStyle(.fhMuted)

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill").font(.caption2).foregroundStyle(.fhGold)
                        Text("已用 \(engine.budget.formattedUsed)")
                            .font(.caption2).foregroundStyle(.fhMuted)
                    }
                    .padding(.top, 2)
                }
            }

            // 统计行
            HStack(spacing: 32) {
                statItem(value: "\(engine.budget.focusSessions.count)", label: "专注段", icon: "target")
                statItem(value: "\(engine.budget.topTasks.filter(\.isCompleted).count)/\(engine.budget.topTasks.count)", label: "任务", icon: "checklist")
                statItem(value: "\(engine.budget.distractions)", label: "分心", icon: "wave.3.right")
            }
            .padding(.top, 20)
        }
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(.fhMuted)
            Text(value).font(.headline).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.fhMuted)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(.fhCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Focus Button

    private var focusButton: some View {
        Button {
            showFocusSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(engine.isInFocus ? Color.fhCoral.opacity(0.2) : Color.fhMint.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: engine.isInFocus ? "lock.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(engine.isInFocus ? .fhCoral : .fhMint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.isInFocus ? "深度工作中…" : "开始深度工作")
                        .font(.headline).foregroundStyle(.white)
                    Text(engine.isInFocus
                         ? "已专注 \(formatElapsed) · 点击结束"
                         : "选择一项重要任务，开始计时")
                        .font(.caption).foregroundStyle(.fhMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.fhMuted)
            }
            .padding(16)
            .background(.fhCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var formatElapsed: String {
        let m = Int(engine.elapsedInSession) / 60
        let s = Int(engine.elapsedInSession) % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Task Section

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日三件事").font(.headline).foregroundStyle(.white)
                Spacer()
                Button { showTaskSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3).foregroundStyle(.fhMint)
                }
            }

            if engine.sortedTasks.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill").foregroundStyle(.fhGold)
                    Text("\"最重要的事只有一件\" — 先定下今天的核心任务")
                        .font(.caption).foregroundStyle(.fhMuted)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fhCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(engine.sortedTasks) { task in
                    TaskRow(task: task, engine: engine)
                }
            }
        }
    }

    // MARK: - Template Section

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐时间块").font(.headline).foregroundStyle(.white)

            ForEach(WorkTemplate.earlyBird) { block in
                HStack(spacing: 12) {
                    Text(block.energyRequired.rawValue).font(.caption)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(block.title) · \(block.startHour):00")
                            .font(.subheadline).foregroundStyle(.white)
                        Text(block.tip).font(.caption).foregroundStyle(.fhMuted)
                            .lineLimit(2)
                    }
                    Spacer()
                    Text("\(block.durationMinutes)min")
                        .font(.caption).foregroundStyle(.fhGold)
                }
                .padding(12)
                .background(.fhCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: PriorityTask
    @ObservedObject var engine: FocusEngine

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    engine.toggleTask(task.id)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .fhMint : .fhMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline).foregroundStyle(.white)
                    .strikethrough(task.isCompleted)
                Text("\(task.quadrant.icon) \(task.quadrant.rawValue) · 预计 \(task.estimatedMinutes)min")
                    .font(.caption2).foregroundStyle(.fhMuted)
            }
            Spacer()

            if !task.isCompleted {
                Button {
                    engine.startFocus(task: task, minutes: task.estimatedMinutes)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title3).foregroundStyle(.fhGold)
                }
            }
        }
        .padding(12)
        .background(.fhCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(task.isCompleted ? 0.5 : 1)
    }
}

// MARK: - Add Task Sheet

struct AddTaskView: View {
    @ObservedObject var engine: FocusEngine
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var quadrant: PriorityTask.EisenhowerQuadrant = .notUrgentImportant
    @State private var minutes = 30

    var body: some View {
        NavigationStack {
            Form {
                Section("任务") {
                    TextField("做什么？", text: $title)
                    Picker("象限", selection: $quadrant) {
                        ForEach(PriorityTask.EisenhowerQuadrant.allCases, id: \.self) { q in
                            Text("\(q.icon) \(q.rawValue)").tag(q)
                        }
                    }
                    Stepper("预计 \(minutes) 分钟", value: $minutes, in: 5...180, step: 5)
                }

                Section {
                    HStack {
                        Image(systemName: "lightbulb.fill").foregroundStyle(.fhGold)
                        Text("Tip: 优先投入 💎 重要不紧急 的事情——这正是 4 小时工作法的核心。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("添加任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard !title.isEmpty else { return }
                        engine.addTask(title, quadrant: quadrant, minutes: minutes)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
