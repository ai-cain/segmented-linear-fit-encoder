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

bool isAsciiIdentifierCharacter(const QChar &character, bool allowDigit)
{
    const ushort code = character.unicode();
    if (character == QLatin1Char('_')) {
        return true;
    }

    if (code >= 'A' && code <= 'Z') {
        return true;
    }

    if (code >= 'a' && code <= 'z') {
        return true;
    }

    if (allowDigit && code >= '0' && code <= '9') {
        return true;
    }

    return false;
}

QString sanitizeIdentifier(const QString &text, const QString &fallback)
{
    QString result;
    result.reserve(text.size());

    for (const QChar character : text.trimmed()) {
        if (isAsciiIdentifierCharacter(character, !result.isEmpty())) {
            result.append(character);
        } else if (!result.endsWith(QLatin1Char('_'))) {
            result.append(QLatin1Char('_'));
        }
    }

    while (result.endsWith(QLatin1Char('_'))) {
        result.chop(1);
    }

    if (result.isEmpty()) {
        result = fallback;
    }

    if (result.front().isDigit()) {
        result.prepend(QLatin1Char('_'));
    }

    return result;
}

QString resolvedInputName(const QString &target, const QString &requestedName)
{
    const QString fallback = target == QStringLiteral("plc")
        ? QStringLiteral("IN_VALUE")
        : QStringLiteral("inValue");
    return sanitizeIdentifier(requestedName, fallback);
}

QString resolvedOutputName(const QString &target, const QString &requestedName)
{
    const QString fallback = target == QStringLiteral("plc")
        ? QStringLiteral("OUT_LONG")
        : QStringLiteral("outValue");
    return sanitizeIdentifier(requestedName, fallback);
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

QString CodeExportService::buildCode(const QVector<SegmentResult> &segments,
                                     const QString &target,
                                     const QString &inputName,
                                     const QString &outputName)
{
    const QString normalized = target.trimmed().toLower();

    if (normalized.isEmpty() || normalized == QStringLiteral("plc")) {
        return buildPlcCode(segments, inputName, outputName);
    }

    if (segments.isEmpty()) {
        return {};
    }

    const QString valueName = resolvedInputName(normalized, inputName);
    const QString resultName = resolvedOutputName(normalized, outputName);
    QStringList lines;

    if (normalized == QStringLiteral("python")) {
        lines.append(QStringLiteral("def piecewise_linear_fit(%1: float) -> float:").arg(valueName));
        lines.append(QStringLiteral("    %1 = 0.0").arg(resultName));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildPythonCondition(segment, index, segments.size(), valueName)));
            lines.append(QStringLiteral("        %1 = %2 * %3 + %4  # Segment %5")
                             .arg(resultName,
                                  formatNumber(segment.slope),
                                  valueName,
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("        return %1").arg(resultName));
        }
        lines.append(QStringLiteral("    return %1").arg(resultName));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("c++")) {
        lines.append(QStringLiteral("double piecewiseLinearFit(double %1) {").arg(valueName));
        lines.append(QStringLiteral("    double %1 = 0.0;").arg(resultName));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildClassicCondition(segment,
                                                        index,
                                                        segments.size(),
                                                        valueName,
                                                        QStringLiteral("if"),
                                                        QStringLiteral("else if"))));
            lines.append(QStringLiteral("        %1 = %2 * %3 + %4; // Segment %5")
                             .arg(resultName,
                                  formatNumber(segment.slope),
                                  valueName,
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("        return %1;").arg(resultName));
            lines.append(QStringLiteral("    }"));
        }
        lines.append(QStringLiteral("    return %1;").arg(resultName));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("javascript")) {
        lines.append(QStringLiteral("function piecewiseLinearFit(%1) {").arg(valueName));
        lines.append(QStringLiteral("  let %1 = 0.0;").arg(resultName));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("  %1")
                             .arg(buildJavaScriptCondition(segment,
                                                           index,
                                                           segments.size(),
                                                           valueName)));
            lines.append(QStringLiteral("    %1 = %2 * %3 + %4; // Segment %5")
                             .arg(resultName,
                                  formatNumber(segment.slope),
                                  valueName,
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("    return %1;").arg(resultName));
            lines.append(QStringLiteral("  }"));
        }
        lines.append(QStringLiteral("  return %1;").arg(resultName));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("java")) {
        lines.append(QStringLiteral("public static double piecewiseLinearFit(double %1) {").arg(valueName));
        lines.append(QStringLiteral("    double %1 = 0.0;").arg(resultName));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildClassicCondition(segment,
                                                        index,
                                                        segments.size(),
                                                        valueName,
                                                        QStringLiteral("if"),
                                                        QStringLiteral("else if"))));
            lines.append(QStringLiteral("        %1 = %2 * %3 + %4; // Segment %5")
                             .arg(resultName,
                                  formatNumber(segment.slope),
                                  valueName,
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("        return %1;").arg(resultName));
            lines.append(QStringLiteral("    }"));
        }
        lines.append(QStringLiteral("    return %1;").arg(resultName));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    if (normalized == QStringLiteral("c#")) {
        lines.append(QStringLiteral("public static double PiecewiseLinearFit(double %1)").arg(valueName));
        lines.append(QStringLiteral("{"));
        lines.append(QStringLiteral("    double %1 = 0.0;").arg(resultName));
        for (int index = 0; index < segments.size(); ++index) {
            const SegmentResult &segment = segments.at(index);
            lines.append(QStringLiteral("    %1")
                             .arg(buildClassicCondition(segment,
                                                        index,
                                                        segments.size(),
                                                        valueName,
                                                        QStringLiteral("if"),
                                                        QStringLiteral("else if"))));
            lines.append(QStringLiteral("        %1 = %2 * %3 + %4; // Segment %5")
                             .arg(resultName,
                                  formatNumber(segment.slope),
                                  valueName,
                                  formatNumber(segment.intercept),
                                  QString::number(index + 1)));
            lines.append(QStringLiteral("        return %1;").arg(resultName));
            lines.append(QStringLiteral("    }"));
        }
        lines.append(QStringLiteral("    return %1;").arg(resultName));
        lines.append(QStringLiteral("}"));
        return lines.join(QLatin1Char('\n'));
    }

    return buildPlcCode(segments, inputName, outputName);
}

QString CodeExportService::buildPlcCode(const QVector<SegmentResult> &segments,
                                        const QString &inputName,
                                        const QString &outputName)
{
    if (segments.isEmpty()) {
        return {};
    }

    const QString resolvedInput = resolvedInputName(QStringLiteral("plc"), inputName);
    const QString resolvedOutput = resolvedOutputName(QStringLiteral("plc"), outputName);
    QStringList lines;
    for (int index = 0; index < segments.size(); ++index) {
        const SegmentResult &segment = segments.at(index);
        lines.append(buildPlcCondition(segment, index, segments.size(), resolvedInput));
        lines.append(QStringLiteral("    %1 := %2 * %3 + %4;    // Tramo %5")
                         .arg(resolvedOutput,
                              formatNumber(segment.slope),
                              resolvedInput,
                              formatNumber(segment.intercept),
                              QString::number(index + 1)));
    }

    lines.append(QStringLiteral("ELSE"));
    lines.append(QStringLiteral("    %1 := 0.0;").arg(resolvedOutput));
    lines.append(QStringLiteral("END_IF"));

    return lines.join(QLatin1Char('\n'));
}
