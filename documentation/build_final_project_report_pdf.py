from pathlib import Path
import csv

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    PageBreak,
    Image,
    Table,
    TableStyle,
    KeepTogether,
)


ROOT = Path(__file__).resolve().parents[1]
DOC_DIR = ROOT / "documentation"
FIG_DIR = DOC_DIR / "figures"
OUT = DOC_DIR / "final_project_report.pdf"


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "TitleCustom",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=24,
            leading=29,
            textColor=colors.HexColor("#0B2545"),
            alignment=TA_CENTER,
            spaceAfter=10,
        ),
        "subtitle": ParagraphStyle(
            "SubtitleCustom",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=14,
            leading=18,
            textColor=colors.HexColor("#1F4D78"),
            alignment=TA_CENTER,
            spaceAfter=18,
        ),
        "h1": ParagraphStyle(
            "Heading1Custom",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=16,
            leading=20,
            textColor=colors.HexColor("#2E74B5"),
            spaceBefore=16,
            spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "Heading2Custom",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=13,
            leading=16,
            textColor=colors.HexColor("#2E74B5"),
            spaceBefore=12,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "BodyCustom",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=10.5,
            leading=13.2,
            alignment=TA_JUSTIFY,
            spaceAfter=7,
        ),
        "bullet": ParagraphStyle(
            "BulletCustom",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=10.5,
            leading=13.2,
            leftIndent=18,
            firstLineIndent=-9,
            spaceAfter=5,
        ),
        "caption": ParagraphStyle(
            "CaptionCustom",
            parent=base["BodyText"],
            fontName="Helvetica-Oblique",
            fontSize=8.5,
            leading=10.5,
            textColor=colors.HexColor("#555555"),
            alignment=TA_CENTER,
            spaceBefore=4,
            spaceAfter=10,
        ),
        "small": ParagraphStyle(
            "SmallCustom",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.5,
            leading=10,
            alignment=TA_LEFT,
        ),
    }


def page_footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#D0D7DE"))
    canvas.line(doc.leftMargin, 0.55 * inch, letter[0] - doc.rightMargin, 0.55 * inch)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#555555"))
    canvas.drawString(doc.leftMargin, 0.35 * inch, "Digital Transmission System - TLC Virtual Lab #2")
    canvas.drawRightString(letter[0] - doc.rightMargin, 0.35 * inch, f"Page {doc.page}")
    canvas.restoreState()


def paragraph(text, style):
    return Paragraph(text, style)


def bullet(text, style):
    return Paragraph(f"- {text}", style)


def figure(filename, caption, style, max_width=6.25 * inch, max_height=4.2 * inch):
    path = FIG_DIR / filename
    with PILImage.open(path) as img:
        width_px, height_px = img.size
    scale = min(max_width / width_px, max_height / height_px)
    img = Image(str(path), width=width_px * scale, height=height_px * scale)
    img.hAlign = "CENTER"
    return KeepTogether([img, Paragraph(caption, style), Spacer(1, 4)])


def figure_cell(filename, caption, style, max_width=3.05 * inch, max_height=2.25 * inch):
    path = FIG_DIR / filename
    with PILImage.open(path) as img:
        width_px, height_px = img.size
    scale = min(max_width / width_px, max_height / height_px)
    img = Image(str(path), width=width_px * scale, height=height_px * scale)
    img.hAlign = "CENTER"
    return [img, Paragraph(caption, style)]


def two_figures(left, left_caption, right, right_caption, style):
    left_group = figure_cell(left, left_caption, style)
    right_group = figure_cell(right, right_caption, style)
    table = Table([[left_group, right_group]], colWidths=[3.15 * inch, 3.15 * inch])
    table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 0),
                ("TOPPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
            ]
        )
    )
    return table


def metadata_table():
    data = [
        ["Modulations", "PAM-2, PAM-4, PAM-8, PAM-16"],
        ["Pulse shapes", "NRZ and Square Root Raised Cosine"],
        ["Channel", "Additive White Gaussian Noise"],
        ["Receiver cases", "Matched filter and single-pole low-pass filter"],
        ["Target metric", "BER = 10^-3 versus Eb/N0"],
    ]
    table = Table(data, colWidths=[1.75 * inch, 4.55 * inch])
    table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#B8C2CC")),
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#E8EEF5")),
                ("TEXTCOLOR", (0, 0), (0, -1), colors.HexColor("#0B2545")),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("FONTNAME", (1, 0), (1, -1), "Helvetica"),
                ("FONTSIZE", (0, 0), (-1, -1), 9.5),
                ("LEADING", (0, 0), (-1, -1), 12),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return table


def optimization_table():
    rows = list(csv.DictReader((DOC_DIR / "optimization_summary.csv").open()))
    data = [["Pulse", "M", "Best BW/Rs", "Best Eb/N0 dB", "Matched dB", "Penalty dB"]]
    for row in rows:
        data.append(
            [
                row["Pulse"],
                row["M"],
                format_num(row["BestBandwidthRs"]),
                format_num(row["BestEbN0dB"]),
                format_num(row["MatchedEbN0dB"]),
                format_num(row["PenaltydB"]),
            ]
        )
    table = Table(data, colWidths=[0.75 * inch, 0.45 * inch, 1.0 * inch, 1.25 * inch, 1.0 * inch, 0.95 * inch])
    table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#B8C2CC")),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E8EEF5")),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
                ("FONTSIZE", (0, 0), (-1, -1), 8.5),
                ("LEADING", (0, 0), (-1, -1), 10),
                ("ALIGN", (1, 1), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def format_num(value):
    try:
        v = float(value)
    except ValueError:
        return value
    if v != v:
        return "Not reached"
    return f"{v:.2f}"


def build():
    s = styles()
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        rightMargin=1 * inch,
        leftMargin=1 * inch,
        topMargin=0.85 * inch,
        bottomMargin=0.8 * inch,
        title="Digital Transmission System - Final Project Report",
        author="Mahadi Alif",
    )

    story = []
    story.append(Spacer(1, 0.6 * inch))
    story.append(Paragraph("Digital Transmission System", s["title"]))
    story.append(Paragraph("Final Project Report - TLC Virtual Lab #2", s["subtitle"]))
    story.append(
        Paragraph(
            "PAM-M modulation, AWGN channel modeling, matched-filter validation, and single-pole receiver optimization",
            s["subtitle"],
        )
    )
    story.append(Spacer(1, 0.25 * inch))
    story.append(metadata_table())
    story.append(PageBreak())

    story.append(Paragraph("Executive Summary", s["h1"]))
    story.append(
        paragraph(
            "This report presents a numerical simulator for a baseband digital transmission system using PAM-M modulation over an AWGN channel. The simulator validates matched-filter performance against theoretical BER curves, evaluates NRZ and SRRC pulse shaping in the spectral and time domains, and studies how a practical single-pole receiver filter changes the Eb/N0 required to reach BER = 10^-3.",
            s["body"],
        )
    )
    for item in [
        "Matched-filter simulations follow the expected theoretical PAM-M BER trend.",
        "NRZ and SRRC pulse shaping are compared through PSD and eye-diagram evidence.",
        "The single-pole receiver introduces ISI and noise-bandwidth tradeoffs, creating an optimum bandwidth for each tested case.",
        "For SRRC/PAM-16, the single-pole receiver remains ISI-limited in the tested sweep and does not reach BER = 10^-3.",
    ]:
        story.append(bullet(item, s["bullet"]))

    story.append(Paragraph("1. System Model", s["h1"]))
    story.append(
        paragraph(
            "The simulated chain follows the TLC Lab 2 structure: random bit generation, Gray-coded PAM-M symbol mapping, pulse shaping, AWGN addition, receiver filtering, optimum sampling, nearest-level decision, demapping, and error counting. Frequencies are normalized to the symbol rate Rs and time is normalized to the symbol interval.",
            s["body"],
        )
    )
    story.append(
        paragraph(
            "For each modulation order M, log2(M) bits form one symbol. The PAM alphabet is antipodal and normalized to unit average symbol energy. The noise variance is computed from Eb/N0 using Eb = Es/log2(M) and N0 = Eb/(Eb/N0), with real AWGN standard deviation sqrt(N0/2).",
            s["body"],
        )
    )

    story.append(Paragraph("2. Digital Filter Synthesis", s["h1"]))
    story.append(
        paragraph(
            "The lab requires evidence that the digital filter synthesis is accurate in the signal band. The SRRC pulse is synthesized by frequency sampling the square root of the raised-cosine spectrum and applying a finite-length time-domain window. The single-pole receiver is synthesized by impulse invariance, producing H(z) = (1-a)/(1-a z^-1), where a = exp(-2*pi*f3dB/SpS).",
            s["body"],
        )
    )
    story.append(figure("filter_synthesis_evidence.png", "Figure 1. Digital synthesis evidence for the single-pole filter and pulse-shaping filters.", s["caption"]))

    story.append(Paragraph("3. Spectral Analysis", s["h1"]))
    story.append(
        paragraph(
            "The PSD comparison verifies that the selected pulse shape controls the occupied bandwidth. NRZ is compact in implementation but has sinc-like spectral sidelobes, while SRRC is designed to confine the main occupied region according to the roll-off factor.",
            s["body"],
        )
    )
    story.append(figure("tx_psd.png", "Figure 2. Normalized transmit PSD for PAM-4 using NRZ and SRRC pulses.", s["caption"]))

    story.append(Paragraph("4. Matched-Filter Validation Against Theory", s["h1"]))
    story.append(
        paragraph(
            "The matched-filter receiver uses the time-reversed transmit pulse. This is the reference case because it maximizes sampled SNR in AWGN when the pulse model is known. BER curves are compared against the standard Gray-coded PAM-M theoretical approximation.",
            s["body"],
        )
    )
    story.append(figure("ber_matched_NRZ.png", "Figure 3. NRZ matched-filter BER validation for PAM-2, PAM-4, PAM-8, and PAM-16.", s["caption"]))
    story.append(figure("ber_matched_SRRC.png", "Figure 4. SRRC matched-filter BER validation for PAM-2, PAM-4, PAM-8, and PAM-16.", s["caption"]))
    story.append(
        paragraph(
            "The simulated points track the theoretical curves with the expected Monte Carlo scatter, especially at low BER where fewer errors are available for counting. Increasing the simulated bit count further would reduce variance in the lowest-BER region.",
            s["body"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("5. Eye-Diagram Evidence", s["h1"]))
    story.append(
        paragraph(
            "Eye diagrams are included for the noiseless waveform and for the Eb/N0 value corresponding to BER = 10^-3. PAM-4 is used as the representative visualization case because it shows multiple decision levels while remaining readable on the page.",
            s["body"],
        )
    )
    story.append(two_figures("eye_matched_NRZ_M4.png", "Figure 5. Matched-filter NRZ/PAM-4 eye diagrams.", "eye_matched_SRRC_M4.png", "Figure 6. Matched-filter SRRC/PAM-4 eye diagrams.", s["caption"]))

    story.append(Paragraph("6. Single-Pole Receiver Bandwidth Optimization", s["h1"]))
    story.append(
        paragraph(
            "The second experiment replaces the matched filter with a practical single-pole low-pass receiver. The -3 dB bandwidth is swept, and for each bandwidth the BER curve is interpolated to estimate the Eb/N0 required for BER = 10^-3. This exposes the tradeoff between noise rejection at low bandwidth and inter-symbol interference at poorly matched bandwidths.",
            s["body"],
        )
    )
    story.append(optimization_table())
    story.append(Spacer(1, 8))
    story.append(
        paragraph(
            "The penalty column is measured relative to the matched-filter theoretical Eb/N0 at the same target BER. The SRRC/PAM-16 case is reported as not reached because the focused extended sweep showed an error floor above 10^-3 for the tested single-pole receiver.",
            s["body"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("Bandwidth Sweep Plots", s["h2"]))
    for pulse in ["NRZ", "SRRC"]:
        story.append(Paragraph(f"{pulse} pulse shaping", s["h2"]))
        story.append(two_figures(f"single_pole_bw_{pulse}_M2.png", f"{pulse}, PAM-2.", f"single_pole_bw_{pulse}_M4.png", f"{pulse}, PAM-4.", s["caption"]))
        story.append(two_figures(f"single_pole_bw_{pulse}_M8.png", f"{pulse}, PAM-8.", f"single_pole_bw_{pulse}_M16.png", f"{pulse}, PAM-16.", s["caption"]))

    story.append(PageBreak())
    story.append(Paragraph("Optimized Single-Pole Eye Diagrams", s["h2"]))
    story.append(two_figures("eye_singlepole_NRZ_M4_best.png", "Optimized single-pole NRZ/PAM-4 eye diagrams.", "eye_singlepole_SRRC_M4_best.png", "Optimized single-pole SRRC/PAM-4 eye diagrams.", s["caption"]))

    story.append(Paragraph("7. Conclusions", s["h1"]))
    for item in [
        "The simulator satisfies the TLC Lab 2 matched-filter validation requirement for NRZ and SRRC shaping.",
        "The spectral plots provide direct evidence of digital synthesis quality in the occupied signal band.",
        "The single-pole receiver has a measurable Eb/N0 penalty relative to the matched filter because it is not matched to the transmit pulse.",
        "The optimum single-pole bandwidth depends on both pulse shape and PAM order, confirming that receiver bandwidth cannot be selected independently of modulation and shaping.",
        "The modular project structure separates configuration, filtering, modulation, simulation, plotting, and utility logic so the experiment can be extended cleanly.",
    ]:
        story.append(bullet(item, s["bullet"]))

    story.append(Paragraph("Appendix: Reproducibility", s["h1"]))
    story.append(
        paragraph(
            "Main project execution: run TLC_Lab2_Project.m from MATLAB. Report figure generation: run documentation/generate_report_figures.m. The report uses figures saved under documentation/figures and the optimization summary saved as documentation/optimization_summary.csv.",
            s["body"],
        )
    )

    doc.build(story, onFirstPage=page_footer, onLaterPages=page_footer)


if __name__ == "__main__":
    build()
