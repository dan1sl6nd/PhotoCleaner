//
//  OnboardingView.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-12.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswers: [Int: String] = [:]
    @State private var identifiedPainPoints: Set<PainPoint> = []
    @State private var showNextButton: Bool = false
    @State private var opacity: Double = 0
    @State private var progressOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var glowOpacity: Double = 0.3
    @State private var pulseScale: CGFloat = 1.0

    let onComplete: (Set<PainPoint>, [Int: String]) -> Void

    private var questions: [OnboardingQuestion] {
        OnboardingQuestion.questions
    }

    private var currentQuestion: OnboardingQuestion? {
        guard !questions.isEmpty && currentQuestionIndex < questions.count else {
            return nil
        }
        return questions[currentQuestionIndex]
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompactHeight = proxy.size.height < 700
            let isVeryCompactHeight = proxy.size.height < 630
            let horizontalPadding: CGFloat = 32
            let progressTopPadding: CGFloat = isVeryCompactHeight ? 10 : (isCompactHeight ? 16 : 24)
            let progressBottomPadding: CGFloat = isVeryCompactHeight ? 8 : (isCompactHeight ? 10 : 14)
            let questionFontSize: CGFloat = isVeryCompactHeight ? 25 : (isCompactHeight ? 27 : 29)
            let subtitleFontSize: CGFloat = isVeryCompactHeight ? 14 : (isCompactHeight ? 15 : 16)
            let iconOuterSize: CGFloat = isVeryCompactHeight ? 104 : (isCompactHeight ? 122 : 140)
            let iconMidSize: CGFloat = isVeryCompactHeight ? 80 : (isCompactHeight ? 95 : 108)
            let iconBackgroundSize: CGFloat = isVeryCompactHeight ? 64 : (isCompactHeight ? 72 : 80)
            let iconFontSize: CGFloat = isVeryCompactHeight ? 30 : (isCompactHeight ? 34 : 40)
            let buttonHeight: CGFloat = isVeryCompactHeight ? 50 : (isCompactHeight ? 56 : 60)
            let buttonBottomPadding: CGFloat = isCompactHeight ? 16 : 24
            let optionButtonSize: OptionButton.Size = isVeryCompactHeight ? .veryCompact : (isCompactHeight ? .compact : .regular)
            let optionsSpacing: CGFloat = isVeryCompactHeight ? 8 : (isCompactHeight ? 10 : 12)
            let totalQuestions = questions.count
            let questionNumber = totalQuestions > 0 ? currentQuestionIndex + 1 : 0
            let progressValue = totalQuestions > 0 ? Double(questionNumber) / Double(totalQuestions) : 0
            let sectionSpacing: CGFloat = isVeryCompactHeight ? 10 : (isCompactHeight ? 14 : 18)
            // Limit spacer expansion between icon and question for both iPad and iPhone
            let iconToQuestionSpacing: CGFloat = 16

            ZStack {
                // Electric gradient background
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.35),   // Deep purple
                            Color(red: 0.1, green: 0.15, blue: 0.4),    // Dark blue
                            Color(red: 0.05, green: 0.2, blue: 0.35)    // Deep teal
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Vibrant overlay with electric accents
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),  // Electric purple
                            Color.clear,
                            Color(red: 0.0, green: 0.7, blue: 0.9).opacity(0.2),  // Bright cyan
                            Color.clear,
                            Color(red: 0.5, green: 0.0, blue: 0.7).opacity(0.25)  // Magenta
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    VStack(spacing: 12) {
                        HStack {
                            Text("Question \(questionNumber) of \(totalQuestions)")
                                .font(.system(size: isVeryCompactHeight ? 14 : (isCompactHeight ? 15 : 16), weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))

                            Spacer()
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.5, green: 0.0, blue: 1.0),    // Electric purple
                                                Color(red: 0.0, green: 0.5, blue: 1.0),    // Electric blue
                                                Color(red: 0.0, green: 0.8, blue: 1.0),    // Bright cyan
                                                Color(red: 0.3, green: 1.0, blue: 0.9)     // Turquoise
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progressValue, height: 6)
                                    .shadow(color: Color.cyan.opacity(0.6), radius: 10, y: 3)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressValue)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, progressTopPadding)
                    .padding(.bottom, progressBottomPadding)
                    .opacity(progressOpacity)

                    Spacer(minLength: sectionSpacing)

                    // Icon with electric glow effects
                    ZStack {
                        // Outer pulsing glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.7, blue: 1.0).opacity(glowOpacity * 0.6),  // Bright cyan
                                        Color(red: 0.4, green: 0.3, blue: 1.0).opacity(glowOpacity * 0.4),  // Electric purple
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: isCompactHeight ? 6 : 8,
                                    endRadius: isCompactHeight ? 58 : 65
                                )
                            )
                            .frame(width: iconOuterSize, height: iconOuterSize)
                            .blur(radius: isCompactHeight ? 16 : 18)
                            .scaleEffect(pulseScale)

                        // Mid glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.4),  // Electric purple
                                        Color(red: 0.0, green: 0.8, blue: 1.0).opacity(0.3),  // Cyan
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: isCompactHeight ? 6 : 8,
                                    endRadius: isCompactHeight ? 44 : 50
                                )
                            )
                            .frame(width: iconMidSize, height: iconMidSize)
                            .blur(radius: isCompactHeight ? 10 : 12)

                        // Icon background with electric gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.2, blue: 1.0),  // Electric purple
                                        Color(red: 0.0, green: 0.6, blue: 1.0),  // Electric blue
                                        Color(red: 0.0, green: 0.8, blue: 0.9)   // Bright cyan
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: iconBackgroundSize, height: iconBackgroundSize)
                            .shadow(color: Color.cyan.opacity(0.6), radius: isCompactHeight ? 14 : 18, y: isCompactHeight ? 6 : 8)

                        if let currentQuestion = currentQuestion {
                            Image(systemName: currentQuestion.icon)
                                .font(.system(size: iconFontSize, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: isCompactHeight ? 5 : 6, y: isCompactHeight ? 2 : 3)
                        }
                    }
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                    .opacity(opacity)

                    Spacer(minLength: sectionSpacing)
                        .frame(maxHeight: iconToQuestionSpacing)

                    // Question text
                    if let currentQuestion = currentQuestion {
                        VStack(spacing: isCompactHeight ? 6 : 8) {
                            Text(currentQuestion.question)
                                .font(.system(size: questionFontSize, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(isVeryCompactHeight ? 3 : 4)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: false, vertical: true)
                                .allowsTightening(true)

                            if let subtitle = currentQuestion.subtitle {
                                Text(subtitle)
                                    .font(.system(size: subtitleFontSize, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(isVeryCompactHeight ? 2 : 3)
                                    .minimumScaleFactor(0.75)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .allowsTightening(true)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .opacity(opacity)
                    }

                    Spacer(minLength: sectionSpacing)

                    // Options
                    if let currentQuestion = currentQuestion {
                        VStack(spacing: optionsSpacing) {
                            ForEach(currentQuestion.options) { option in
                                OptionButton(
                                    option: option,
                                    isSelected: selectedAnswers[currentQuestionIndex] == option.id,
                                    size: optionButtonSize
                                ) {
                                    selectOption(option)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .opacity(opacity)
                    }

                    Spacer(minLength: sectionSpacing)

                    // Next/Continue button - Always visible, disabled when no selection
                    if !questions.isEmpty {
                        Button(action: {
                            nextQuestion()
                        }) {
                            HStack(spacing: 12) {
                                Text(currentQuestionIndex == questions.count - 1 ? "Continue" : "Next Question")
                                    .font(.system(size: isVeryCompactHeight ? 18 : (isCompactHeight ? 19 : 20), weight: .bold))

                                Image(systemName: currentQuestionIndex == questions.count - 1 ? "arrow.right.circle.fill" : "arrow.right")
                                    .font(.system(size: isVeryCompactHeight ? 20 : (isCompactHeight ? 21 : 22), weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: buttonHeight)
                            .background(
                                ZStack {
                                    // Button glow
                                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.5, green: 0.0, blue: 1.0),   // Electric purple
                                                    Color(red: 0.0, green: 0.6, blue: 1.0),   // Electric blue
                                                    Color(red: 0.0, green: 0.85, blue: 1.0)   // Bright cyan
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .blur(radius: isCompactHeight ? 16 : 20)
                                        .opacity(showNextButton ? 0.7 : 0.3)

                                    // Button background
                                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.5, green: 0.0, blue: 1.0),   // Electric purple
                                                    Color(red: 0.0, green: 0.6, blue: 1.0),   // Electric blue
                                                    Color(red: 0.0, green: 0.85, blue: 1.0)   // Bright cyan
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .opacity(showNextButton ? 1.0 : 0.5)
                                        .shadow(color: Color.cyan.opacity(showNextButton ? 0.7 : 0.3), radius: isCompactHeight ? 18 : 25, y: isCompactHeight ? 8 : 12)
                                }
                            )
                        }
                        .disabled(!showNextButton)
                        .animation(.easeInOut(duration: 0.3), value: showNextButton)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, buttonBottomPadding)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Fade in content
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                progressOpacity = 1
            }

            // Icon entrance animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                iconScale = 1.0
            }

            // Subtle rotation animation
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                iconRotation = 5
            }

            // Pulsing glow effect
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.8
                pulseScale = 1.15
            }
        }
    }

    // MARK: - Methods

    private func selectOption(_ option: OnboardingOption) {
        // Save answer
        selectedAnswers[currentQuestionIndex] = option.id

        // Track pain point
        if let painPoint = option.painPoint {
            identifiedPainPoints.insert(painPoint)
        }

        // Show next button with animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showNextButton = true
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            // Move to next question
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentQuestionIndex += 1

                // Update button state based on whether next question is already answered
                showNextButton = selectedAnswers[currentQuestionIndex] != nil

                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
        } else {
            // Complete onboarding - pass pain points and all answers
            onComplete(identifiedPainPoints, selectedAnswers)
        }
    }

    // Get selected answer ID for a specific question index
    func getSelectedAnswer(for questionIndex: Int) -> String? {
        return selectedAnswers[questionIndex]
    }
}

// MARK: - Option Button

struct OptionButton: View {
    enum Size {
        case regular
        case compact
        case veryCompact
    }

    let option: OnboardingOption
    let isSelected: Bool
    let size: Size
    let action: () -> Void

    @State private var isPressed: Bool = false

    init(option: OnboardingOption, isSelected: Bool, size: Size = .regular, action: @escaping () -> Void) {
        self.option = option
        self.isSelected = isSelected
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
        }) {
            let isCompact = size != .regular
            let isVeryCompact = size == .veryCompact
            let indicatorSize: CGFloat = isCompact ? 20 : 22
            let indicatorFillSize: CGFloat = isCompact ? 12 : 14
            let optionFontSize: CGFloat = isVeryCompact ? 15 : (isCompact ? 16 : 17)
            let verticalPadding: CGFloat = isVeryCompact ? 10 : (isCompact ? 12 : 16)
            let horizontalPadding: CGFloat = isCompact ? 16 : 18

            HStack(spacing: isCompact ? 12 : 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                                ? LinearGradient(
                                    colors: [
                                        Color(red: 0.5, green: 0.0, blue: 1.0),   // Electric purple
                                        Color(red: 0.0, green: 0.7, blue: 1.0)    // Bright cyan
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  ),
                            lineWidth: 2
                        )
                        .frame(width: indicatorSize, height: indicatorSize)

                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.2, blue: 1.0),   // Electric purple
                                        Color(red: 0.0, green: 0.6, blue: 1.0),   // Electric blue
                                        Color(red: 0.0, green: 0.85, blue: 1.0)   // Bright cyan
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: indicatorFillSize, height: indicatorFillSize)
                            .shadow(color: Color.cyan.opacity(0.7), radius: isCompact ? 6 : 8, y: 2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                // Option text
                Text(option.text)
                    .font(.system(size: optionFontSize, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isVeryCompact ? 2 : 3)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.25),   // Electric purple
                                    Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.2),    // Electric blue
                                    Color(red: 0.0, green: 0.7, blue: 0.9).opacity(0.15)    // Cyan
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSelected
                                    ? LinearGradient(
                                        colors: [
                                            Color(red: 0.5, green: 0.0, blue: 1.0),   // Electric purple
                                            Color(red: 0.0, green: 0.6, blue: 1.0),   // Electric blue
                                            Color(red: 0.0, green: 0.85, blue: 1.0)   // Bright cyan
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.cyan.opacity(0.5) : .clear,
                        radius: 18,
                        y: 8
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

#Preview {
    OnboardingView { painPoints, answers in
        #if DEBUG
        print("Completed with pain points: \(painPoints)")
        print("Answers: \(answers)")
        #endif
    }
}
