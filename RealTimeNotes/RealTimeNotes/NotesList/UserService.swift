//
//  UserService.swift
//  RealTimeNotes
//
//  Created by Anna Zaitsava on 22.12.24.
//

import Foundation

final class UserService {
    private static let userIdKey = "userId"

    // MARK: - Get user identifier
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
