import SwiftUI

/// 收工复盘 — 每日回顾 4 小时预算使用情况
struct DailyReviewView: View {
    @ObservedObject var engine: FocusEngine
    @Environment(\.dismiss) private var dismiss
    @State private var mood: Int = 3
    @State private var note: String = ""
    @State private var insight: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fhDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 标题
                        VStack(spacing: 8) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 40)).foregroundStyle(.fhGold)
                            Text("今日收工").font(.title).fontWeight(.bold).foregroundStyle(.white)
                            Text("回顾你的 4 小时")
                                .font(.subheadline).foregroundStyle(.fhMuted)
                        }
                        .padding(.top, 20)

                        // 统计摘要
                        summarySection

                        // 心情
                        moodSection

                        // 笔记
                        noteSection

                        // 洞见
                        insightSection

                        // 提交按钮
                        Button {
                            engine.submitReview(mood: mood, note: note, insight: insight)
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("完成收工")
                            }
                            .font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(.fhGold)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 8)

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("稍后") { dismiss() }.foregroundStyle(.fhMuted)
                }
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: 12) {
            Text("📊 今日数据").font(.headline).foregroundStyle(.white)

            HStack(spacing: 0) {
                summaryTile(
                    value: engine.budget.formattedUsed,
                    label: "深度工作",
                    color: .fhMint,
                    detail: "\(engine.budget.focusSessions.count) 个专注段"
                )
                summaryTile(
                    value: "\(engine.budget.topTasks.filter(\.isCompleted).count)/\(engine.budget.topTasks.count)",
                    label: "任务完成",
                    color: .fhBlue,
                    detail: engine.budget.topTasks.first?.title ?? "无"
                )
            }

            HStack(spacing: 0) {
                summaryTile(
                    value: "\(engine.budget.distractions)",
                    label: "被打断",
                    color: .fhCoral,
                    detail: engine.budget.distractions == 0 ? "完美！零干扰" : "还有优化空间"
                )
                summaryTile(
                    value: engine.budget.isOverBudget ? "超时" : "✓",
                    label: "预算状态",
                    color: engine.budget.isOverBudget ? .fhCoral : .fhMint,
                    detail: "剩余 \(engine.budget.formattedRemaining)"
                )
            }
        }
        .padding(16)
        .background(.fhCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func summaryTile(value: String, label: String, color: Color, detail: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title2).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.fhMuted)
            Text(detail).font(.caption2).foregroundStyle(.fhMuted).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Mood

    private var moodSection: some View {
        VStack(spacing: 12) {
            Text("今天收工心情").font(.headline).foregroundStyle(.white)
            HStack(spacing: 20) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { mood = i }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            Text(["😤","😐","🙂","😊","🤩"][i - 1])
                                .font(.system(size: 32))
                            Circle()
                                .fill(mood == i ? .fhGold : Color.clear)
                                .frame(width: 6, height: 6)
                        }
                        .scaleEffect(mood == i ? 1.2 : 1)
                    }
                }
            }
        }
        .padding(16)
        .background(.fhCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📝 今天做了什么").font(.headline).foregroundStyle(.white)
            TextField("记录今天的产出和收获…", text: $note, axis: .vertical)
                .font(.body)
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .lineLimit(3...6)
        }
        .padding(16)
        .background(.fhCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Insight

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("💡 今天学到的一件事").font(.headline).foregroundStyle(.white)
            TextField("可以是一个流程优化、一个想法、或一个教训", text: $insight, axis: .vertical)
                .font(.body)
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .lineLimit(2...4)
        }
        .padding(16)
        .background(.fhCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
