//
//  OnboardingQuestion.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-12.
//

import Foundation

struct OnboardingQuestion: Identifiable {
    let id: Int
    let question: String
    let subtitle: String?
    let options: [OnboardingOption]
    let icon: String
}

struct OnboardingOption: Identifiable {
    let id: String
    let text: String
    let painPoint: PainPoint?
}

enum PainPoint: String, Hashable {
    case storage = "Running out of storage"
    case organization = "Messy photo library"
    case duplicates = "Too many duplicates"
    case screenshots = "Too many screenshots"
    case videos = "Large video files"
    case overwhelmed = "Too many photos to manage"
}

extension OnboardingQuestion {
    static let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: 0,
            question: "What's your biggest photo challenge?",
            subtitle: "Help us understand your needs",
            options: [
                OnboardingOption(id: "storage", text: "Running out of storage space", painPoint: .storage),
                OnboardingOption(id: "organization", text: "My library is too messy", painPoint: .organization),
                OnboardingOption(id: "duplicates", text: "Too many duplicate photos", painPoint: .duplicates),
                OnboardingOption(id: "overwhelmed", text: "I have thousands of photos", painPoint: .overwhelmed)
            ],
            icon: "photo.stack"
        ),
        OnboardingQuestion(
            id: 1,
            question: "What takes up most space?",
            subtitle: "We'll help you target the right content",
            options: [
                OnboardingOption(id: "screenshots", text: "Screenshots I don't need", painPoint: .screenshots),
                OnboardingOption(id: "videos", text: "Large video files", painPoint: .videos),
                OnboardingOption(id: "old", text: "Old photos from years ago", painPoint: nil),
                OnboardingOption(id: "all", text: "Everything - I need a full cleanup", painPoint: nil)
            ],
            icon: "chart.bar.fill"
        ),
        OnboardingQuestion(
            id: 2,
            question: "How often do you clean your library?",
            subtitle: "Understanding your habits helps us serve you better",
            options: [
                OnboardingOption(id: "never", text: "Never - this is my first time", painPoint: nil),
                OnboardingOption(id: "rarely", text: "Once in a while when desperate", painPoint: nil),
                OnboardingOption(id: "monthly", text: "Monthly or so", painPoint: nil),
                OnboardingOption(id: "weekly", text: "Every week", painPoint: nil)
            ],
            icon: "calendar"
        )
    ]
}
