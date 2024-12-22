//
//  UserService.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//

import Foundation

class UserService {
    private static let userIdKey = "userId"

    // Получить уникальный идентификатор пользователя
    static func getUserId() -> String {
        if let storedUserId = UserDefaults.standard.string(forKey: userIdKey) {
            return storedUserId
        } else {
            let newUserId = UUID().uuidString
            UserDefaults.standard.set(newUserId, forKey: userIdKey)
            return newUserId
        }
    }
}
