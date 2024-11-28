import Foundation
import LoggingTime

// CustomJSONCoder struct provides custom JSON encoding and decoding functionality
public struct CustomJSONCoder {
    // For full precision timestamps (when needed)
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    // For date-only values
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()

    // Helper methods to make usage clearer
    public static func formatTimestamp(_ date: Date) -> Date {
        let dateString = timestampFormatter.string(from: date)
        return timestampFormatter.date(from: dateString) ?? date
    }

    public static func formatDateOnly(_ date: Date) -> Date {
        let dateString = dateOnlyFormatter.string(from: date)
        return dateOnlyFormatter.date(from: dateString) ?? date
    }

    private static func isDateOnly(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.hour, .minute, .second, .nanosecond], from: date)
        return components.hour == 0 && components.minute == 0 && components.second == 0
            && components.nanosecond == 0
    }

    // Update encoder/decoder to use appropriate formatter based on context
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            // Try date-only format first if the date has no time components
            let dateString =
                isDateOnly(date)
                ? dateOnlyFormatter.string(from: date)
                : timestampFormatter.string(from: date)
            try container.encode(dateString)
        }
        return encoder
    }()

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try date-only format first
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }

            // Fall back to timestamp format
            if let date = timestampFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        return decoder
    }()
}

// StandardJSONCoder provides JSON encoding/decoding with:
// 1. Snake case key conversion (camelCase <-> snake_case)
// 2. Custom date formatting (both full timestamps and date-only)
public struct StandardJSONCoder {
    // For full precision timestamps (when needed)
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    // For date-only values
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()

    // Helper methods to make usage clearer
    public static func formatTimestamp(_ date: Date) -> Date {
        let dateString = timestampFormatter.string(from: date)
        return timestampFormatter.date(from: dateString) ?? date
    }

    public static func formatDateOnly(_ date: Date) -> Date {
        let dateString = dateOnlyFormatter.string(from: date)
        return dateOnlyFormatter.date(from: dateString) ?? date
    }

    private static func isDateOnly(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.hour, .minute, .second, .nanosecond], from: date)
        return components.hour == 0 && components.minute == 0 && components.second == 0
            && components.nanosecond == 0
    }

    // Encoder with snake_case keys and custom date formatting
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let dateString =
                isDateOnly(date)
                ? dateOnlyFormatter.string(from: date)
                : timestampFormatter.string(from: date)
            try container.encode(dateString)
        }
        return encoder
    }()

    // Decoder with snake_case keys and custom date formatting
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try date-only format first
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }

            // Fall back to timestamp format
            if let date = timestampFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        return decoder
    }()
}
