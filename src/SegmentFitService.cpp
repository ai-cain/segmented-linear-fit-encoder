#include "SegmentFitService.h"

#include <QtGlobal>

#include <algorithm>
#include <cmath>

namespace
{
struct RegressionResult
{
    double slope = 0.0;
    double intercept = 0.0;
    double rSquared = 0.0;
    bool valid = false;
};

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

RegressionResult linearRegression(const QVector<DataPoint> &points, int startIndex, int count)
{
    RegressionResult result;

    if (count < 2 || startIndex < 0 || startIndex + count > points.size()) {
        return result;
    }

    const double n = static_cast<double>(count);
    double sumX = 0.0;
    double sumY = 0.0;
    double sumXX = 0.0;
    double sumXY = 0.0;

    for (int offset = 0; offset < count; ++offset) {
        const DataPoint &point = points.at(startIndex + offset);
        if (!point.y.has_value()) {
            return result;
        }

        const double x = point.x;
        const double y = *point.y;
        sumX += x;
        sumY += y;
        sumXX += x * x;
        sumXY += x * y;
    }

    const double denominator = n * sumXX - sumX * sumX;
    if (std::abs(denominator) < 1e-12) {
        return result;
    }

    result.slope = (n * sumXY - sumX * sumY) / denominator;
    result.intercept = (sumY - result.slope * sumX) / n;

    const double meanY = sumY / n;
    double ssTot = 0.0;
    double ssRes = 0.0;

    for (int offset = 0; offset < count; ++offset) {
        const DataPoint &point = points.at(startIndex + offset);
        const double y = *point.y;
        const double predicted = result.slope * point.x + result.intercept;
        ssRes += std::pow(y - predicted, 2.0);
        ssTot += std::pow(y - meanY, 2.0);
    }

    if (ssTot < 1e-12) {
        result.rSquared = ssRes < 1e-12 ? 1.0 : 0.0;
    } else {
        result.rSquared = std::clamp(1.0 - (ssRes / ssTot), 0.0, 1.0);
    }

    result.valid = true;
    return result;
}

int longestValidRun(const QVector<int> &sequence)
{
    int bestRun = 0;
    int currentRun = 0;

    for (const int value : sequence) {
        if (value == 1) {
            ++currentRun;
            bestRun = std::max(bestRun, currentRun);
        } else {
            currentRun = 0;
        }
    }

    return bestRun;
}
} // namespace

SegmentFitService::Result SegmentFitService::analyze(const QVector<DataPoint> &points, const Options &options)
{
    Result result;

    if (points.size() < 2) {
        result.errorMessage = QStringLiteral("At least two points are required to run the analysis.");
        return result;
    }

    for (const DataPoint &point : points) {
        if (!point.y.has_value()) {
            result.errorMessage = QStringLiteral("All points must have a Y value before analysis.");
            return result;
        }
    }

    const int minimumPoints = std::max(2, options.minimumPointsPerSegment);

    double maxAbsY = 0.0;
    for (const DataPoint &point : points) {
        maxAbsY = std::max(maxAbsY, std::abs(*point.y));
    }
    result.absoluteTolerance = options.fitTolerancePercent * maxAbsY / 100.0;

    QVector<int> segmentLengths;
    int cursor = 0;

    while (cursor < points.size()) {
        const int remaining = points.size() - cursor;
        if (remaining <= minimumPoints) {
            segmentLengths.append(remaining);
            break;
        }

        QVector<int> candidateCounts;
        QVector<int> candidateScores;
        QVector<double> candidateRSquared;

        for (int count = minimumPoints; count <= remaining; ++count) {
            const RegressionResult regression = linearRegression(points, cursor, count);
            if (!regression.valid) {
                continue;
            }

            QVector<int> acceptance;
            acceptance.reserve(count);

            for (int offset = 0; offset < count; ++offset) {
                const DataPoint &point = points.at(cursor + offset);
                const double predicted = regression.slope * point.x + regression.intercept;
                const double error = std::abs(predicted - *point.y);
                acceptance.append(error <= result.absoluteTolerance ? 1 : 0);
            }

            candidateCounts.append(count);
            candidateScores.append(longestValidRun(acceptance));
            candidateRSquared.append(regression.rSquared);
        }

        if (candidateCounts.isEmpty()) {
            segmentLengths.append(remaining);
            break;
        }

        int bestSequenceIndex = 0;
        for (int index = 1; index < candidateScores.size(); ++index) {
            if (candidateScores.at(index) > candidateScores.at(bestSequenceIndex)) {
                bestSequenceIndex = index;
            }
        }

        int bestR2Index = 0;
        for (int index = 1; index < candidateRSquared.size(); ++index) {
            if (candidateRSquared.at(index) > candidateRSquared.at(bestR2Index)) {
                bestR2Index = index;
            }
        }

        int chosenCount = std::min(candidateCounts.at(bestSequenceIndex), candidateCounts.at(bestR2Index));
        chosenCount = std::clamp(chosenCount, 2, remaining);

        if (remaining - chosenCount == 1) {
            ++chosenCount;
        }

        segmentLengths.append(chosenCount);
        cursor += chosenCount;
    }

    if (segmentLengths.size() > 1 && segmentLengths.last() < 2) {
        segmentLengths[segmentLengths.size() - 2] += segmentLengths.takeLast();
    }

    cursor = 0;
    for (const int count : std::as_const(segmentLengths)) {
        if (count < 2 || cursor + count > points.size()) {
            continue;
        }

        const RegressionResult regression = linearRegression(points, cursor, count);
        if (!regression.valid) {
            result.errorMessage = QStringLiteral("Could not compute a valid regression for one of the segments.");
            result.segments.clear();
            return result;
        }

        SegmentResult segment;
        segment.startIndex = cursor;
        segment.endIndex = cursor + count - 1;
        segment.xStart = points.at(segment.startIndex).x;
        segment.xEnd = points.at(segment.endIndex).x;
        segment.slope = regression.slope;
        segment.intercept = regression.intercept;
        segment.rSquared = regression.rSquared;
        result.segments.append(segment);

        cursor += count;
    }

    if (result.segments.isEmpty()) {
        result.errorMessage = QStringLiteral("No valid segments were generated.");
    }

    return result;
}

QString SegmentFitService::buildPlcCode(const QVector<SegmentResult> &segments,
                                        const QString &inputName,
                                        const QString &outputName)
{
    if (segments.isEmpty()) {
        return {};
    }

    QStringList lines;
    for (int index = 0; index < segments.size(); ++index) {
        const SegmentResult &segment = segments.at(index);
        const QString keyword = index == 0 ? QStringLiteral("IF") : QStringLiteral("ELSIF");

        if (index < segments.size() - 1) {
            lines.append(QStringLiteral("%1 %2 >= %3 AND %2 < %4 THEN")
                             .arg(keyword,
                                  inputName,
                                  formatNumber(segment.xStart, 6),
                                  formatNumber(segment.xEnd, 6)));
        } else {
            lines.append(QStringLiteral("%1 %2 >= %3 THEN")
                             .arg(keyword,
                                  inputName,
                                  formatNumber(segment.xStart, 6)));
        }

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
