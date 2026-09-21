//
//  ShowService.swift
//  MOVEI
//

import SwiftUI
import Combine

@MainActor
public final class ShowService: ObservableObject {
    public static let shared = ShowService()

    @Published public var shows: [Show] = []

    private init() {
        loadDefaultShows()
    }

    private func loadDefaultShows() {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now

        let start1 = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: tomorrow) ?? tomorrow
        let end1 = calendar.date(byAdding: .minute, value: 160, to: start1) ?? start1

        let start2 = calendar.date(bySettingHour: 20, minute: 00, second: 0, of: tomorrow) ?? tomorrow
        let end2 = calendar.date(byAdding: .minute, value: 148, to: start2) ?? start2

        self.shows = [
            Show(
                id: "show-wicked-01",
                movieID: "wicked",
                cinemaID: "cinemax-colombo",
                screenID: "cinemax-s04",
                startTime: start1,
                endTime: end1,
                priceStandard: 1000.0,
                pricePremium: 1500.0,
                priceVIP: 2000.0
            ),
            Show(
                id: "show-spiderman-01",
                movieID: "brand-new-day",
                cinemaID: "scope-cinemas",
                screenID: "scope-s02",
                startTime: start2,
                endTime: end2,
                priceStandard: 1200.0,
                pricePremium: 1600.0,
                priceVIP: 2200.0
            )
        ]
    }

    public func shows(for movieID: String) -> [Show] {
        let matched = shows.filter { $0.movieID == movieID && $0.status != "cancelled" }
        if !matched.isEmpty {
            return matched
        }
        return generateDefaultShows(for: movieID)
    }

    @discardableResult
    public func generateDefaultShows(for movieID: String) -> [Show] {
        let calendar = Calendar.current
        let today = Date()
        let cinema1 = "cinemax-colombo"
        let screen1 = "cinemax-s04"
        let cinema2 = "scope-cinemas"
        let screen2 = "scope-s02"

        let slots = [
            (14, 0, cinema1, screen1, 1200.0, 1800.0, 2500.0),
            (17, 30, cinema2, screen2, 1400.0, 2000.0, 2800.0),
            (20, 45, cinema1, screen1, 1500.0, 2200.0, 3000.0)
        ]

        var newShows: [Show] = []
        for (h, m, cId, sId, pStd, pPrem, pVip) in slots {
            let start = calendar.date(bySettingHour: h, minute: m, second: 0, of: today) ?? today
            let end = calendar.date(byAdding: .minute, value: 140, to: start) ?? start
            let show = Show(
                id: "show-\(movieID)-\(h)\(m)",
                movieID: movieID,
                cinemaID: cId,
                screenID: sId,
                startTime: start,
                endTime: end,
                priceStandard: pStd,
                pricePremium: pPrem,
                priceVIP: pVip
            )
            newShows.append(show)
        }
        self.shows.append(contentsOf: newShows)
        return newShows
    }

    public func checkCollision(screenID: String, start: Date, end: Date, excludingShowID: String? = nil) -> Bool {
        return shows.contains { show in
            guard show.screenID == screenID && show.status != "cancelled" else { return false }
            if let excluding = excludingShowID, show.id == excluding { return false }
            return (start < show.endTime) && (end > show.startTime)
        }
    }

    public func addShow(_ show: Show) -> (success: Bool, message: String) {
        if checkCollision(screenID: show.screenID, start: show.startTime, end: show.endTime) {
            return (false, "Show overlaps with an existing screening on this screen.")
        }
        shows.append(show)
        return (true, "Show successfully scheduled.")
    }

    public func duplicateShow(showID: String, offsetDays: Int = 1) -> Bool {
        guard let original = shows.first(where: { $0.id == showID }) else { return false }
        let calendar = Calendar.current
        guard let newStart = calendar.date(byAdding: .day, value: offsetDays, to: original.startTime),
              let newEnd = calendar.date(byAdding: .day, value: offsetDays, to: original.endTime) else { return false }

        let duplicated = Show(
            id: UUID().uuidString,
            movieID: original.movieID,
            cinemaID: original.cinemaID,
            screenID: original.screenID,
            startTime: newStart,
            endTime: newEnd,
            priceStandard: original.priceStandard,
            pricePremium: original.pricePremium,
            priceVIP: original.priceVIP
        )

        let (success, _) = addShow(duplicated)
        return success
    }

    public func cancelShow(showID: String) {
        if let idx = shows.firstIndex(where: { $0.id == showID }) {
            shows[idx].status = "cancelled"
        }
    }
}
