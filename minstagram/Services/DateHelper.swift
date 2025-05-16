//
//  DateHelper.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 12.05.2025.
//

import Foundation

final class DateHelper {

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full // "2 minutes ago"
        return formatter
    }()

    /// Converts ISO 8601 string (e.g. "2025-05-12T10:12:00Z") to Date
    static func date(from isoString: String) -> Date? {
        return isoFormatter.date(from: isoString)
    }

    /// Converts Date to "time ago" string (e.g. "2 hours ago")
    static func timeAgo(from date: Date) -> String {
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Full utility: from ISO 8601 string to "time ago" label
    static func timeAgo(from isoString: String) -> String {
        guard let date = date(from: isoString) else {
            return "unknown time"
        }
        return timeAgo(from: date)
    }
    
}
