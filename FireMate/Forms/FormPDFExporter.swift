import UIKit

/// Renders a ServiceForm to a single-page A4 PDF in the temporary directory
/// and returns the file URL for sharing.
enum FormPDFExporter {

    private static let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 @ 72 dpi
    private static let margin: CGFloat = 40

    static func export(_ form: ServiceForm) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)

        let data = renderer.pdfData { context in
            context.beginPage()
            var cursor = margin

            cursor = draw("Fire Detection & Alarm System — Service Record",
                          font: .boldSystemFont(ofSize: 18), at: cursor)
            cursor = draw(form.companyName.isEmpty ? "FireMate" : form.companyName,
                          font: .systemFont(ofSize: 12), colour: .darkGray, at: cursor) + 12

            cursor = section("Site", at: cursor)
            cursor = field("Site", form.siteName, at: cursor)
            cursor = field("Address", form.siteAddress, at: cursor)
            cursor = field("Client", form.clientName, at: cursor) + 8

            cursor = section("System", at: cursor)
            cursor = field("Panel", form.panelMakeModel, at: cursor)
            cursor = field("Category", form.category.rawValue, at: cursor)
            cursor = field("Zones", "\(form.zoneCount)", at: cursor) + 8

            cursor = section("Visit", at: cursor)
            cursor = field("Date", form.visitDate.formatted(date: .long, time: .omitted), at: cursor)
            cursor = field("Devices tested", "\(form.devicesTested)", at: cursor)
            cursor = field("Work carried out", form.workCarriedOut, at: cursor)
            cursor = field("Outcome", form.outcome.rawValue, at: cursor) + 8

            if !form.defects.isEmpty {
                cursor = section("Defects", at: cursor)
                for defect in form.defects {
                    let status = defect.isResolved ? "[resolved]" : "[open]"
                    cursor = draw("• \(defect.description) \(status)",
                                  font: .systemFont(ofSize: 11), at: cursor)
                }
                cursor += 8
            }

            cursor = section("Sign-off", at: cursor)
            cursor = field("Engineer", form.engineerName, at: cursor)
            _ = field("Generated", Date().formatted(date: .abbreviated, time: .shortened), at: cursor)
        }

        let filename = "\(form.displayTitle.replacingOccurrences(of: "/", with: "-"))-service-record.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Drawing helpers — each returns the new cursor Y position.

    private static func draw(_ text: String,
                             font: UIFont,
                             colour: UIColor = .black,
                             at y: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: colour]
        let width = pageSize.width - margin * 2
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil)
        (text as NSString).draw(
            with: CGRect(x: margin, y: y, width: width, height: bounds.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil)
        return y + bounds.height + 4
    }

    private static func section(_ title: String, at y: CGFloat) -> CGFloat {
        draw(title.uppercased(), font: .boldSystemFont(ofSize: 12), colour: .systemRed, at: y + 4)
    }

    private static func field(_ label: String, _ value: String, at y: CGFloat) -> CGFloat {
        let text = value.isEmpty ? "\(label): —" : "\(label): \(value)"
        return draw(text, font: .systemFont(ofSize: 11), at: y)
    }
}
