import Foundation

/// Fast, fully-offline assistant. Answers the questions an engineer asks all day
/// (standby battery sizing, sound levels, detector spacing, BS 5839-1 quick facts)
/// without a network round trip. Anything it can't handle is passed to CloudAssistant.
struct ButlerBrain {

    enum Reply {
        /// Answered locally.
        case answer(String)
        /// Not confident — hand the query to the cloud assistant.
        case escalate
    }

    func respond(to rawQuery: String) -> Reply {
        let query = rawQuery.lowercased()

        if let answer = batteryAnswer(for: query) { return .answer(answer) }
        if let answer = soundAnswer(for: query) { return .answer(answer) }
        if let answer = spacingAnswer(for: query) { return .answer(answer) }
        if let answer = categoryAnswer(for: query) { return .answer(answer) }
        if let answer = servicingAnswer(for: query) { return .answer(answer) }
        if let answer = cableAnswer(for: query) { return .answer(answer) }
        return .escalate
    }

    // MARK: Topic handlers

    private func batteryAnswer(for query: String) -> String? {
        guard query.contains("battery") || query.contains("standby") else { return nil }
        return """
        Standby battery capacity (BS 5839-1):
        C = 1.25 × (T1 × I1 + D × I2 × T2)
        • T1 = standby period, normally 24 h (72 h if unmonitored/no keyholder response)
        • I1 = quiescent current in amps
        • T2 = alarm period, 0.5 h
        • I2 = alarm current in amps, D = 1.75 de-rating factor
        The Battery calculator in Tools does this for you.
        """
    }

    private func soundAnswer(for query: String) -> String? {
        guard query.contains("db") || query.contains("sound") || query.contains("sounder") else { return nil }
        return """
        BS 5839-1 sound levels: 65 dB(A) generally, or 60 dB(A) in stairways, \
        enclosures under 60 m² and specific points of limited extent — and 75 dB(A) \
        at the bedhead where people sleep. Roughly −6 dB per doubling of distance from \
        the sounder; the Sound Level calculator in Tools estimates coverage.
        """
    }

    private func spacingAnswer(for query: String) -> String? {
        guard query.contains("spacing") || query.contains("coverage") || query.contains("detector") else { return nil }
        return """
        Detector coverage (BS 5839-1): smoke detectors protect a 7.5 m radius \
        (max ~10.6 m grid spacing), heat detectors 5.3 m radius (~7.5 m spacing). \
        Keep detectors at least 500 mm from walls/fittings and within 500 mm of the \
        ceiling apex rules. Use the Detector Spacing calculator for a room count.
        """
    }

    private func categoryAnswer(for query: String) -> String? {
        guard query.contains("category") || query.contains("l1") || query.contains("l2")
            || query.contains("p1") || query.contains("p2") else { return nil }
        return """
        BS 5839-1 categories — L (life): L1 whole building, L2 defined high-risk rooms \
        plus escape routes, L3 escape routes and adjoining rooms, L4 escape routes only, \
        L5 engineered/custom. P (property): P1 whole building, P2 defined parts. \
        M is manual call points only.
        """
    }

    private func servicingAnswer(for query: String) -> String? {
        guard query.contains("service") || query.contains("maintenance") || query.contains("inspection") else { return nil }
        return """
        BS 5839-1 recommends periodic inspection and servicing at intervals not \
        exceeding 6 months, with every device tested over a 12-month period. Weekly \
        user test: operate a manual call point during working hours and rotate the \
        call point used.
        """
    }

    private func cableAnswer(for query: String) -> String? {
        guard query.contains("cable") || query.contains("voltage drop") else { return nil }
        return """
        Fire alarm circuits should use fire-resistant cable (standard or enhanced to \
        BS 7629-1 / BS 8434), typically 1.0–2.5 mm². Check volt drop at full alarm \
        load — the Voltage Drop calculator in Tools uses loop resistance per km for \
        common CSAs.
        """
    }
}
