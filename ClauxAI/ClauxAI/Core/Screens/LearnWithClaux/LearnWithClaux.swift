//
//  LearnWithClaux.swift
//  CL.AI
//
//  Created by Yasir Shah on 09/06/2026.
//

import AppKit
import SwiftUI

struct LearnWithClaux: View {

    var onSettings: () -> Void = {}

    @State private var selectedCourse: LearnCourse?

    private enum Layout {
        static let cardHeight: CGFloat = 220
        static let topSectionHeight: CGFloat = 136
        static let gridSpacing: CGFloat = 16
        static let columnCount = 4
    }

    var body: some View {
        Group {
            if let selectedCourse {
                LearnWithClauxDetailView(course: selectedCourse) {
                    self.selectedCourse = nil
                }
            } else {
                courseGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
    }

    private var courseGrid: some View {
        VStack(spacing: 0) {
            learnHeader

            ScrollView {
                LazyVGrid(columns: columns, spacing: Layout.gridSpacing) {
                    ForEach(courses) { course in
                        LearnCourseCard(course: course) {
                            selectedCourse = course
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
        }
    }

    private var courses: [LearnCourse] {
        LearnWithClauxData.courses
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Layout.gridSpacing),
            count: Layout.columnCount
        )
    }

    private var learnHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 0) {
                Text("CL.AI")
                Text(" / Learn with Claux")
                 
            }
            .font(.sfProDisplaySemiBold(20))
            .foregroundStyle(Color.textWhite)
            Spacer()

            Button(action: onSettings) {
                Image(.settingIcon)
                    .resizable()
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(Color.appSecondarybg)
    }
}

// MARK: - Course card

private struct LearnCourseCard: View {

    let course: LearnCourse
    let onTap: () -> Void

    private enum Layout {
        static let cardHeight: CGFloat = 220
        static let topSectionHeight: CGFloat = 136
    }

    var body: some View {
        VStack(spacing: 0) {
            topSection
            bottomSection
        }
        .frame(height: Layout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)
    }

    private var topSection: some View {
        VStack(spacing: 12) {
            Text(course.category)
                .font(.sfProDisplayBold(18))
                .foregroundStyle(Color.textWhite)
                .padding(.top, 16)

            LearnCourseIconView(name: course.icon, category: course.category)
                .frame(width: 64, height: 64)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Layout.topSectionHeight)
        .background(Color(hex: "#2C2C2C"))
    }

    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.title)
                .font(.sfProDisplayBold(16))
                .foregroundStyle(Color.textWhite)
                .lineLimit(1)

            Text(course.subtitle)
                .font(.sfProDisplayRegular(13))
                .foregroundStyle(Color.tetxGray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(Color(hex: "#1E1E1E"))
    }
}

// MARK: - Icon

private struct LearnCourseIconView: View {

    let name: String
    let category: String

    var body: some View {
        Group {
            if NSImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                fallbackIcon
            }
        }
    }

    @ViewBuilder
    private var fallbackIcon: some View {
        switch category {
        case "HTML":
            Text("5")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 52, height: 52)
                .background(Color(hex: "#E44D26"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "CSS":
            Text("3")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 52, height: 52)
                .background(Color(hex: "#264DE4"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "JS":
            Text("JS")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(width: 52, height: 52)
                .background(Color(hex: "#F7DF1E"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case "Python":
            Image(systemName: "chevron.left.chevron.right")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#3776AB"), Color(hex: "#FFD43B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case "React":
            Image(systemName: "atom")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color(hex: "#61DAFB"))
        case "Backend":
            Image(systemName: "gearshape.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "#9B59B6"))
        case "Data Structure":
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 34))
                .foregroundStyle(Color(hex: "#2F80FF"))
        case "API":
            Image(systemName: "cloud.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "#11C5FF"))
        default:
            Image(systemName: "book.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.appOrange)
        }
    }
}

#Preview {
    LearnWithClaux()
        .frame(width: 1150, height: 600)
}
