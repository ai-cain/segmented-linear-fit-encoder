#include "CodeExportService.h"

#include <cmath>

namespace
{
QString formatNumber(double value, int decimals = 7)
{
    if (std::abs(value) < 1e-12) {
        value = 0.0;
    }

    QString text = QString::number(value, 'f', decimals);
    while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
        if (text.endsWith('.')) {
            text.chop(1);
            break;
        }

        text.chop(1);
    }

    return text;
}

QString buildPlcCondition(const SegmentResult &segment, int index, int segmentCount, const QString &inputName)
{
    const QString keyword = index == 0 ? QStringLiteral("IF") : QStringLiteral("ELSIF");
    if (index < segmentCount - 1) {
        return QStringLiteral("%1 %2 >= %3 AND %2 < %4 THEN")
            .arg(keyword,
                 inputName,
                 formatNumber(segment.xStart, 6),
                 formatNumber(segment.xEnd, 6));
    }

    return QStringLiteral("%1 %2 >= %3 THEN")
        .arg(keyword,
             inputName,
             formatNumber(segment.xStart, 6));
}

QString buildClassicCondition(const SegmentResult &segment,
                              int index,
                              int segmentCount,
                              const QString &valueName,
                              const QString &firstKeyword,
                              const QString &elseIfKeyword)
{
    const QString keyword = index == 0 ? firstKeyword : elseIfKeyword;
    if (index < segmentCount - 1) {
        return QStringLiteral("%1 (%2 >= %3 && %2 < %4) {")
            .arg(keyword,
                 valueName,
                 formatNumber(segment.xStart, 6),
                 formatNumber(segment.xEnd, 6));
    }

    return QStringLiteral("%1 (%2 >= %3) {")
        .arg(keyword,
             valueName,
             formatNumber(segment.xStart, 6));
}

QString buildPythonCondition(const SegmentResult &segment, int index, int segmentCount, const QString &valueName)
{
    const QString keyword = index == 0 ? QStringLiteral("if") : QStringLiteral("elif");
    if (index < segmentCount - 1) {
        return QStringLiteral("%1 %2 >= %3 and %2 < %4:")
            .arg(keyword,
                 valueName,
                 formatNumber(segment.xStart, 6),
                 formatNumber(segment.xEnd, 6));
    }

    return QStringLiteral("%1 %2 >= %3:")
        .arg(keyword,
             valueName,
             formatNumber(segment.xStart, 6));
}

QString buildJavaScriptCondition(const SegmentResult &segment, int index, int segmentCount, const QString &valueName)
{
    const QString keyword = index == 0 ? QStringLiteral("if") : QStringLiteral("else if");
    if (index < segmentCount - 1) {
        return QStringLiteral("%1 (%2 >= %3 && %2 < %4) {")
            .arg(keyword,
                 valueName,
                 formatNumber(segment.xStart, 6),
                 formatNumber(segment.xEnd, 6));
    }

    return QStringLiteral("%1 (%2 >= %3) {")
        .arg(keyword,
             valueName,
             formatNumber(segment.xStart, 6));
}
} // namespace

QStringList CodeExportService::exportTargets()
{
    return {
        QStringLiteral("PLC"),
        QStringLiteral("Python"),
        QStringLiteral("C++"),
        QStringLiteral("JavaScript"),
        QStringLiteral("Java"),
        QStringLiteral("C#")
    };
}

QString CodeExportService::buildCode(const QVector<SegmentResult> &segments, const QString &target)
{
    const QString normalized = target.trimmed().toLower();

    if (normalized.isEmpty() || normalized == QStringLiteral("plc")) {
        return buildPlcCode(segments);
    }

    if (segments.isEmpty()) {
        return {};
    }

    QStringList lines;

    if (normalized == QStringLiteral("python")) {
        lines.append(QStringLiteral("def piecewise_linear_fit(in_value: float) -> float:"));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildPythonCondition(segment, index, segments.size(), QStringLiteral("in_value"))));
            lines.append(QStringLiteral("        return %1 * in_value + %2  # Segment %3")
                             .arg(formatNumber(segment.slope),
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
        }
        lines.append(QStringLiteral("    return 0.0"));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("c++")) {
        lines.append(QStringLiteral("double piecewiseLinearFit(double inValue) {"));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildClassicCondition(segment,
                                                        index,
                                                        segments.size(),
                                                        QStringLiteral("inValue"),
                                                        QStringLiteral("if"),
                                                        QStringLiteral("else if"))));
            lines.append(QStringLiteral("        return %1 * inValue + %2; // Segment %3")
                             .arg(formatNumber(segment.slope),
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("    }"));
        }
        lines.append(QStringLiteral("    return 0.0;"));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("javascript")) {
        lines.append(QStringLiteral("function piecewiseLinearFit(inValue) {"));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("  %1")
                             .arg(buildJavaScriptCondition(segment,
                                                           index,
                                                           segments.size(),
                                                           QStringLiteral("inValue"))));
            lines.append(QStringLiteral("    return %1 * inValue + %2; // Segment %3")
                             .arg(formatNumber(segment.slope),
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("  }"));
        }
        lines.append(QStringLiteral("  return 0.0;"));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("java")) {
        lines.append(QStringLiteral("public static double piecewiseLinearFit(double inValue) {"));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildClassicCondition(segment,
                                                        index,
                                                        segments.size(),
                                                        QStringLiteral("inValue"),
                                                        QStringLiteral("if"),
                                                        QStringLiteral("else if"))));
            lines.append(QStringLiteral("        return %1 * inValue + %2; // Segment %3")
                             .arg(formatNumber(segment.slope),
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("    }"));
        }
        lines.append(QStringLiteral("    return 0.0;"));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("c#")) {
        lines.append(QStringLiteral("public static double PiecewiseLinearFit(double inValue)"));
        lines.append(QStringLiteral("{"));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildClassicCondition(segment,
                                                        index,
                                                        segments.size(),
                                                        QStringLiteral("inValue"),
                                                        QStringLiteral("if"),
                                                        QStringLiteral("else if"))));
            lines.append(QStringLiteral("        return %1 * inValue + %2; // Segment %3")
                             .arg(formatNumber(segment.slope),
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("    }"));
        }
        lines.append(QStringLiteral("    return 0.0;"));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    return buildPlcCode(segments);
}

QString CodeExportService::buildPlcCode(const QVector<SegmentResult> &segments,
                                        const QString &inputName,
                                        const QString &outputName)
{
    if (segments.isEmpty()) {
        return {};
    }

    QStringList lines;
    for (int index = 0; index < segments.size(); ++index) {
        const SegmentResult &segment = segments.at(index);
        lines.append(buildPlcCondition(segment, index, segments.size(), inputName));
        lines.append(QStringLiteral("    %1 := %2 * %3 + %4;    // Tramo %5")
                         .arg(outputName,
                              formatNumber(segment.slope),
                              inputName,
                              formatNumber(segment.intercept),
                              QString::number(index + 1)));
    }

    lines.append(QStringLiteral("ELSE"));
    lines.append(QStringLiteral("    %1 := 0.0;").arg(outputName));
    lines.append(QStringLiteral("END_IF"));

    return lines.join(QLatin1Char('\n'));
}
