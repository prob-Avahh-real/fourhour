import SwiftUI

/// 活跃专注会话界面 — 全屏沉浸式
struct FocusSessionView: View {
    @ObservedObject var engine: FocusEngine
    @Environment(\.dismiss) private var dismiss
    @State private var isEnding = false
    @State private var interruptionReason = ""

    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [Color.fhDark, Color(red: 0.04, green: 0.04, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if engine.isInFocus {
                    activeFocusView
                } else {
                    newFocusView
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundStyle(.fhMuted)
            }
            .padding(20)
        }
    }

    // MARK: - Active Focus

    private var activeFocusView: some View {
        VStack(spacing: 40) {
            // 脉冲环
            ZStack {
                // 外环脉动
                Circle()
                    .stroke(Color.fhMint.opacity(0.15), lineWidth: 3)
                    .frame(width: 200, height: 200)
                    .scaleEffect(1 + sin(elapsedPulse) * 0.04)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: elapsedPulse)

                // 进度弧
                Circle()
                    .trim(from: 0, to: sessionProgress)
                    .stroke(
                        AngularGradient(colors: [.fhMint, .fhGold], center: .center,
                                        startAngle: .degrees(-90), endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: elapsedInSession)

                // 中心计时
                VStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title).foregroundStyle(.fhMint)
                    Text(formatElapsed)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("深度工作中")
                        .font(.caption).foregroundStyle(.fhMuted)
                }
            }

            // 任务标签
            if let task = engine.activeSession?.taskTitle {
                VStack(spacing: 4) {
                    Text("当前任务").font(.caption).foregroundStyle(.fhMuted)
                    Text(task).font(.title3).fontWeight(.medium).foregroundStyle(.fhText)
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(.fhCard).clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 操作按钮
            VStack(spacing: 12) {
                // 结束专注
                Button {
                    isEnding = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("完成专注")
                    }
                    .font(.headline).foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.fhMint)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // 被打断
                Button {
                    engine.endFocus(interrupted: true, reason: "手动中断")
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text("被打断了")
                    }
                    .font(.subheadline).foregroundStyle(.fhCoral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.fhCoral.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // 分心记录
                Button {
                    engine.recordDistraction()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: "wave.3.right")
                        Text("记录分心 (\(engine.budget.distractions))")
                    }
                    .font(.caption).foregroundStyle(.fhMuted)
                }
            }
        }
        .sheet(isPresented: $isEnding) {
            endFocusConfirmation
        }
    }

    // MARK: - New Focus (pre-start)

    private var newFocusView: some View {
        VStack(spacing: 32) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 48)).foregroundStyle(.fhGold)

            Text("开始深度工作")
                .font(.title).fontWeight(.bold).foregroundStyle(.white)

            Text("在接下来的时间里，专注一件事。\n关闭通知，放下手机，进入心流。")
                .font(.subheadline).foregroundStyle(.fhMuted)
                .multilineTextAlignment(.center)

            // 时长选择
            VStack(spacing: 10) {
                Text("选择时长").font(.caption).foregroundStyle(.fhMuted)
                HStack(spacing: 12) {
                    ForEach([25, 45, 60, 90], id: \.self) { mins in
                        Button {
                            engine.startFocus(minutes: mins)
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(mins)").font(.title2).fontWeight(.bold)
                                Text("分钟").font(.caption2)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(.fhCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }

            // 快速开始
            Button {
                engine.startFocus(minutes: 25)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("快速开始 25 分钟")
                }
                .font(.headline).foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.fhGold)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - End Confirmation

    private var endFocusConfirmation: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56)).foregroundStyle(.fhMint)

            Text("专注完成！")
                .font(.title).fontWeight(.bold).foregroundStyle(.white)

            Text("已记录 \(Int(engine.elapsedInSession / 60)) 分钟深度工作")
                .font(.subheadline).foregroundStyle(.fhMuted)

            VStack(alignment: .leading, spacing: 6) {
                Text("这次专注的感受").font(.caption).foregroundStyle(.fhMuted)
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            engine.endFocus()
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // parent dismiss handled by sheet
                            }
                        } label: {
                            Text(["😤","😐","🙂","😊","🤩"][rating - 1])
                                .font(.title)
                                .opacity(1)
                        }
                    }
                }
            }
        }
        .padding(32)
        .presentationDetents([.medium])
    }

    // MARK: - Computed

    private var elapsedInSession: TimeInterval { engine.elapsedInSession }
    private var elapsedPulse: Double { engine.elapsedInSession }

    private var formatElapsed: String {
        let m = Int(elapsedInSession) / 60
        let s = Int(elapsedInSession) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var sessionProgress: CGFloat {
        guard let session = engine.activeSession else { return 0 }
        let total = TimeInterval(session.targetMinutes * 60)
        guard total > 0 else { return 0 }
        return min(1, engine.elapsedInSession / total)
    }
}
