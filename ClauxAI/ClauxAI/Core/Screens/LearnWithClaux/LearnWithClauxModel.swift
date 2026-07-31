//
//  LearnWithClauxModel.swift
//  CL.AI
//
//  Created by Yasir Shah on 09/06/2026.
//

import Foundation

// MARK: - Root response

struct LearnCoursesResponse: Codable {
    let courses: [LearnCourse]
}

// MARK: - Course list item

struct LearnCourse: Identifiable, Codable, Hashable {
    let id: String
    let category: String
    let title: String
    let subtitle: String
    let icon: String
    let detail: LearnCourseDetail
}

// MARK: - Detail

struct LearnCourseDetail: Codable, Hashable {
    let tabs: [LearnCourseTab]
}

struct LearnCourseTab: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let sections: [LearnContentSection]
}

enum LearnSectionKind: String, Codable {
    case heading
    case paragraph
    case bulletList
}

struct LearnContentSection: Identifiable, Codable, Hashable {
    let id: String
    let kind: LearnSectionKind
    let title: String?
    let text: String?
    let items: [LearnBulletItem]?
}

struct LearnBulletItem: Codable, Hashable {
    let term: String
    let definition: String
}

// MARK: - Data loader

enum LearnWithClauxData {

    static let courses: [LearnCourse] = loadCourses()

    private static func loadCourses() -> [LearnCourse] {
        guard
            let url = Bundle.main.url(forResource: "learn_courses", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let response = try? JSONDecoder().decode(LearnCoursesResponse.self, from: data)
        else {
            return fallbackCourses
        }

        return response.courses
    }

    static func course(withID id: String) -> LearnCourse? {
        courses.first { $0.id == id }
    }

    private static let fallbackCourses: [LearnCourse] = []
}
