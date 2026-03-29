#include "AppController.h"

#include "CodeExportService.h"
#include "SegmentFitService.h"

#include <QClipboard>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QStringList>
#include <QRegularExpression>
#include <QTextStream>
#include <QUrl>

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

bool parseNumber(QString text, double &value)
{
    text = text.trimmed();
    if (text.isEmpty()) {
        return false;
    }

    bool ok = false;
    value = text.toDouble(&ok);
    if (ok) {
        return true;
    }

    text.replace(',', '.');
    value = text.toDouble(&ok);
    return ok;
}

QChar detectDelimiter(const QString &line)
{
    const int semicolons = line.count(QLatin1Char(';'));
    const int tabs = line.count(QLatin1Char('\t'));
    const int commas = line.count(QLatin1Char(','));

    if (semicolons >= commas && semicolons >= tabs && semicolons > 0) {
        return QLatin1Char(';');
    }

    if (tabs > commas && tabs > 0) {
        return QLatin1Char('\t');
    }

    return QLatin1Char(',');
}

QStringList splitCsvRow(const QString &line, const QChar delimiter)
{
    QStringList fields;
    QString current;
    bool inQuotes = false;

    for (int index = 0; index < line.size(); ++index) {
        const QChar character = line.at(index);

        if (character == QLatin1Char('"')) {
            if (inQuotes && index + 1 < line.size() && line.at(index + 1) == QLatin1Char('"')) {
                current.append(QLatin1Char('"'));
                ++index;
            } else {
                inQuotes = !inQuotes;
            }
            continue;
        }

        if (character == delimiter && !inQuotes) {
            fields.append(current.trimmed());
            current.clear();
            continue;
        }

        current.append(character);
    }

    fields.append(current.trimmed());
    return fields;
}

QString normalizePath(const QString &source)
{
    const QUrl url(source);
    if (url.isValid() && url.isLocalFile()) {
        return url.toLocalFile();
    }

    return source;
}

QString segmentColor(int index)
{
    static const QStringList palette = {
        QStringLiteral("#f97316"),
        QStringLiteral("#38bdf8"),
        QStringLiteral("#22c55e"),
        QStringLiteral("#f43f5e"),
        QStringLiteral("#eab308"),
        QStringLiteral("#a78bfa"),
        QStringLiteral("#14b8a6"),
        QStringLiteral("#fb7185")
    };

    return palette.at(index % palette.size());
}

QVariantMap buildPointItem(double x, double y, const QString &label = QString())
{
    QVariantMap item;
    item.insert(QStringLiteral("x"), x);
    item.insert(QStringLiteral("y"), y);
    if (!label.isEmpty()) {
        item.insert(QStringLiteral("label"), label);
    }

    return item;
}

QVariantMap buildSeriesItem(const QString &name,
                            const QString &color,
                            const QVariantList &points,
                            bool drawLine,
                            bool drawMarkers,
                            double lineWidth = 2.0,
                            int markerSize = 4,
                            bool showInLegend = true)
{
    QVariantMap series;
    series.insert(QStringLiteral("name"), name);
    series.insert(QStringLiteral("color"), color);
    series.insert(QStringLiteral("points"), points);
    series.insert(QStringLiteral("line"), drawLine);
    series.insert(QStringLiteral("markers"), drawMarkers);
    series.insert(QStringLiteral("lineWidth"), lineWidth);
    series.insert(QStringLiteral("markerSize"), markerSize);
    series.insert(QStringLiteral("showInLegend"), showInLegend);
    return series;
}

double maxAbsYValue(const QVector<DataPoint> &points)
{
    double maxAbsY = 0.0;
    for (const DataPoint &point : points) {
        if (point.y.has_value()) {
            maxAbsY = std::max(maxAbsY, std::abs(*point.y));
        }
    }

    return maxAbsY;
}

QVariantList buildSegmentedPointSeries(const QVector<DataPoint> &points, const QVariantList &segmentResults)
{
    QVariantList seriesItems;
    seriesItems.reserve(segmentResults.size());

    for (int index = 0; index < segmentResults.size(); ++index) {
        const QVariantMap segment = segmentResults.at(index).toMap();
        const int startIndex = segment.value(QStringLiteral("startIndex")).toInt();
        const int endIndex = segment.value(QStringLiteral("endIndex")).toInt();
        QVariantList pointItems;

        for (int pointIndex = startIndex; pointIndex <= endIndex && pointIndex < points.size(); ++pointIndex) {
            const DataPoint &point = points.at(pointIndex);
            if (!point.y.has_value()) {
                continue;
            }

            pointItems.append(buildPointItem(point.x, *point.y));
        }

        seriesItems.append(buildSeriesItem(QStringLiteral("Segment %1").arg(index + 1),
                                           segmentColor(index),
                                           pointItems,
                                           true,
                                           true,
                                           2.0,
                                           4,
                                           true));
    }

    return seriesItems;
}

QVariantList buildFittedLineSeries(const QVariantList &segmentResults)
{
    QVariantList seriesItems;
    seriesItems.reserve(segmentResults.size());

    for (int index = 0; index < segmentResults.size(); ++index) {
        const QVariantMap segment = segmentResults.at(index).toMap();
        const double xStart = segment.value(QStringLiteral("xStart")).toDouble();
        const double xEnd = segment.value(QStringLiteral("xEnd")).toDouble();
        const double slope = segment.value(QStringLiteral("slopeValue")).toDouble();
        const double intercept = segment.value(QStringLiteral("interceptValue")).toDouble();
        QVariantList pointItems;
        pointItems.append(buildPointItem(xStart, slope * xStart + intercept));
        pointItems.append(buildPointItem(xEnd, slope * xEnd + intercept));

        seriesItems.append(buildSeriesItem(QStringLiteral("Fit %1").arg(index + 1),
                                           segmentColor(index),
                                           pointItems,
                                           true,
                                           false,
                                           3.0,
                                           0,
                                           true));
    }

    return seriesItems;
}

QVariantList buildGlobalResidualSeries(const QVector<DataPoint> &points)
{
    QVariantList seriesItems;
    if (points.size() < 2) {
        return seriesItems;
    }

    int anchorIndex = points.size() > 2 ? 1 : 0;
    const int lastIndex = points.size() - 1;
    double denominator = points.at(anchorIndex).x - points.at(lastIndex).x;
    if (std::abs(denominator) < 1e-12 && anchorIndex != 0) {
        anchorIndex = 0;
        denominator = points.at(anchorIndex).x - points.at(lastIndex).x;
    }

    if (std::abs(denominator) < 1e-12 || !points.at(anchorIndex).y.has_value() || !points.at(lastIndex).y.has_value()) {
        return seriesItems;
    }

    const double slope = (*points.at(anchorIndex).y - *points.at(lastIndex).y) / denominator;
    const double intercept = *points.at(anchorIndex).y - slope * points.at(anchorIndex).x;
    QVariantList pointItems;
    pointItems.reserve(points.size());

    for (const DataPoint &point : points) {
        if (!point.y.has_value()) {
            continue;
        }

        const double residual = *point.y - (slope * point.x + intercept);
        pointItems.append(buildPointItem(point.x, residual));
    }

    seriesItems.append(buildSeriesItem(QStringLiteral("Global residual"),
                                       QStringLiteral("#ef4444"),
                                       pointItems,
                                       false,
                                       true,
                                       0.0,
                                       4,
                                       false));
    return seriesItems;
}

QVariantList buildSegmentResidualSeries(const QVector<DataPoint> &points,
                                        const QVariantList &segmentResults,
                                        QVariantList *outlierSeriesItems,
                                        double maxAbsY)
{
    QVariantList seriesItems;
    QVariantList outlierPoints;
    seriesItems.reserve(segmentResults.size());

    for (int index = 0; index < segmentResults.size(); ++index) {
        const QVariantMap segment = segmentResults.at(index).toMap();
        const int startIndex = segment.value(QStringLiteral("startIndex")).toInt();
        const int endIndex = segment.value(QStringLiteral("endIndex")).toInt();
        const double slope = segment.value(QStringLiteral("slopeValue")).toDouble();
        const double intercept = segment.value(QStringLiteral("interceptValue")).toDouble();
        QVariantList pointItems;

        for (int pointIndex = startIndex; pointIndex <= endIndex && pointIndex < points.size(); ++pointIndex) {
            const DataPoint &point = points.at(pointIndex);
            if (!point.y.has_value()) {
                continue;
            }

            const double predicted = slope * point.x + intercept;
            const double residual = *point.y - predicted;
            pointItems.append(buildPointItem(point.x, residual));

            double errorPercent = -0.1;
            if (*point.y > 0.0 && maxAbsY > 1e-12) {
                errorPercent = 100.0 * std::abs(residual) / maxAbsY;
            }

            if (errorPercent > 0.1) {
                outlierPoints.append(buildPointItem(point.x,
                                                    residual,
                                                    QStringLiteral("(%1, %2)")
                                                        .arg(formatNumber(point.x, 2),
                                                             formatNumber(*point.y, 2))));
            }
        }

        seriesItems.append(buildSeriesItem(QStringLiteral("Segment %1").arg(index + 1),
                                           segmentColor(index),
                                           pointItems,
                                           true,
                                           true,
                                           2.0,
                                           3,
                                           true));
    }

    if (outlierSeriesItems && !outlierPoints.isEmpty()) {
        outlierSeriesItems->append(buildSeriesItem(QStringLiteral("Out of tolerance"),
                                                   QStringLiteral("#ef4444"),
                                                   outlierPoints,
                                                   false,
                                                   true,
                                                   0.0,
                                                   5,
                                                   true));
    }

    return seriesItems;
}
} // namespace

AppController::AppController(QObject *parent)
    : QObject(parent)
{
    connect(&m_pointModel, &PointTableModel::countChanged, this, &AppController::pointsChanged);
    connect(&m_pointModel, &QAbstractItemModel::modelReset, this, [this]() {
        emit pointsChanged();
        invalidateResults();
    });
    connect(&m_pointModel, &QAbstractItemModel::dataChanged, this, [this]() {
        emit pointsChanged();
        invalidateResults();
    });
}

PointTableModel *AppController::pointModel()
{
    return &m_pointModel;
}

QString AppController::statusMessage() const
{
    return m_statusMessage;
}

QString AppController::statusTone() const
{
    return m_statusTone;
}

bool AppController::hasPoints() const
{
    return m_pointModel.count() > 0;
}

bool AppController::hasResults() const
{
    return !m_segmentResults.isEmpty();
}

int AppController::pointCount() const
{
    return m_pointModel.count();
}

int AppController::missingYCount() const
{
    int missingValues = 0;
    const QVector<DataPoint> points = m_pointModel.points();
    for (const DataPoint &point : points) {
        if (!point.y.has_value()) {
            ++missingValues;
        }
    }

    return missingValues;
}

QVariantList AppController::pointSeries() const
{
    QVariantList items;
    const QVector<DataPoint> points = m_pointModel.points();
    items.reserve(points.size());

    for (const DataPoint &point : points) {
        if (!point.y.has_value()) {
            continue;
        }

        QVariantMap item;
        item.insert(QStringLiteral("x"), point.x);
        item.insert(QStringLiteral("y"), *point.y);
        items.append(item);
    }

    return items;
}

QVariantList AppController::segmentedPointSeries() const
{
    return m_segmentedPointSeries;
}

QVariantList AppController::fittedLineSeries() const
{
    return m_fittedLineSeries;
}

QVariantList AppController::globalResidualSeries() const
{
    return m_globalResidualSeries;
}

QVariantList AppController::segmentResidualSeries() const
{
    return m_segmentResidualSeries;
}

QVariantList AppController::segmentErrorOutlierSeries() const
{
    return m_segmentErrorOutlierSeries;
}

double AppController::reviewTolerance() const
{
    return m_reviewTolerance;
}

QStringList AppController::exportTargets() const
{
    return CodeExportService::exportTargets();
}

QString AppController::exportTarget() const
{
    return m_exportTarget;
}

void AppController::setExportTarget(const QString &target)
{
    const QString normalized = target.trimmed();
    if (normalized.isEmpty()) {
        return;
    }

    const QStringList targets = exportTargets();
    if (!targets.contains(normalized) || m_exportTarget == normalized) {
        return;
    }

    m_exportTarget = normalized;
    emit exportTargetChanged();
}

QString AppController::exportCode() const
{
    return CodeExportService::buildCode(m_segments, m_exportTarget);
}

QString AppController::summaryText() const
{
    return m_summaryText;
}

QString AppController::plcCode() const
{
    return m_plcCode;
}

QVariantList AppController::segmentResults() const
{
    return m_segmentResults;
}

void AppController::loadCsv(const QString &source)
{
    const QString filePath = normalizePath(source);
    QFile file(filePath);
    if (!file.exists()) {
        setStatus(QStringLiteral("The selected file was not found."), QStringLiteral("error"));
        return;
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        setStatus(QStringLiteral("Could not open the CSV file."), QStringLiteral("error"));
        return;
    }

    QTextStream stream(&file);
    QString content = stream.readAll();
    content.remove(QChar(0xFEFF));

    const QStringList rawLines = content.split(QRegularExpression(QStringLiteral("\\r\\n|\\n|\\r")),
                                               Qt::SkipEmptyParts);
    if (rawLines.isEmpty()) {
        setStatus(QStringLiteral("The CSV file is empty."), QStringLiteral("error"));
        return;
    }

    const QChar delimiter = detectDelimiter(rawLines.first());
    QVector<DataPoint> points;
    points.reserve(rawLines.size());

    bool headerSkipped = false;
    for (int lineIndex = 0; lineIndex < rawLines.size(); ++lineIndex) {
        const QString line = rawLines.at(lineIndex).trimmed();
        if (line.isEmpty()) {
            continue;
        }

        const QStringList fields = splitCsvRow(line, delimiter);
        if (fields.size() < 2) {
            setStatus(QStringLiteral("Row %1 does not contain at least two columns.")
                          .arg(lineIndex + 1),
                      QStringLiteral("error"));
            return;
        }

        double xValue = 0.0;
        double yValue = 0.0;
        const bool xOk = parseNumber(fields.at(0), xValue);
        const bool yOk = parseNumber(fields.at(1), yValue);

        if (lineIndex == 0 && (!xOk || !yOk) && !headerSkipped) {
            headerSkipped = true;
            continue;
        }

        if (!xOk || !yOk) {
            setStatus(QStringLiteral("Row %1 contains non-numeric values in the first two columns.")
                          .arg(lineIndex + 1),
                      QStringLiteral("error"));
            return;
        }

        points.append({xValue, yValue});
    }

    if (points.isEmpty()) {
        setStatus(QStringLiteral("No valid points were found in the CSV file."), QStringLiteral("error"));
        return;
    }

    m_pointModel.setPoints(points);
    invalidateResults();

    const QString fileName = QFileInfo(filePath).fileName();
    setStatus(QStringLiteral("CSV loaded: %1 (%2 points).").arg(fileName).arg(points.size()),
              QStringLiteral("success"));
}

void AppController::generatePoints(double minimum, double maximum, int intervals)
{
    if (!std::isfinite(minimum) || !std::isfinite(maximum)) {
        setStatus(QStringLiteral("Minimum and maximum must be valid numbers."), QStringLiteral("error"));
        return;
    }

    if (maximum <= minimum) {
        setStatus(QStringLiteral("Maximum must be greater than minimum."), QStringLiteral("error"));
        return;
    }

    if (intervals < 1) {
        setStatus(QStringLiteral("Intervals must be at least 1."), QStringLiteral("error"));
        return;
    }

    QVector<DataPoint> points;
    points.reserve(intervals + 1);

    const double step = (maximum - minimum) / static_cast<double>(intervals);
    for (int index = 0; index <= intervals; ++index) {
        const double xValue = index == intervals ? maximum : minimum + step * index;
        points.append({xValue, std::nullopt});
    }

    m_pointModel.setPoints(points);
    invalidateResults();

    setStatus(QStringLiteral("Generated %1 points between %2 and %3.")
                  .arg(points.size())
                  .arg(formatNumber(minimum, 4))
                  .arg(formatNumber(maximum, 4)),
              QStringLiteral("success"));
}

void AppController::clearPoints()
{
    m_pointModel.clear();
    invalidateResults();
    setStatus(QStringLiteral("Current points were cleared."), QStringLiteral("neutral"));
}

void AppController::updatePointY(int row, const QString &value)
{
    QString errorMessage;
    if (!m_pointModel.setYValue(row, value, &errorMessage)) {
        setStatus(errorMessage, QStringLiteral("error"));
        return;
    }

    if (!value.trimmed().isEmpty()) {
        setStatus(QStringLiteral("Y value updated."), QStringLiteral("neutral"));
    }
}

void AppController::runAnalysis()
{
    if (!hasPoints()) {
        setStatus(QStringLiteral("Load a CSV or generate points first."), QStringLiteral("error"));
        return;
    }

    const int missingValues = missingYCount();
    if (missingValues > 0) {
        setStatus(QStringLiteral("%1 Y values are still missing before analysis.").arg(missingValues),
                  QStringLiteral("error"));
        return;
    }

    const SegmentFitService::Result result = SegmentFitService::analyze(m_pointModel.points());
    if (!result.errorMessage.isEmpty()) {
        setStatus(result.errorMessage, QStringLiteral("error"));
        return;
    }

    QVariantList segmentItems;
    segmentItems.reserve(result.segments.size());

    for (int index = 0; index < result.segments.size(); ++index) {
        const SegmentResult &segment = result.segments.at(index);
        QVariantMap item;
        item.insert(QStringLiteral("title"), QStringLiteral("Segment %1").arg(index + 1));
        item.insert(QStringLiteral("startIndex"), segment.startIndex);
        item.insert(QStringLiteral("endIndex"), segment.endIndex);
        item.insert(QStringLiteral("range"),
                    QStringLiteral("%1 -> %2")
                        .arg(formatNumber(segment.xStart, 4), formatNumber(segment.xEnd, 4)));
        item.insert(QStringLiteral("equation"),
                    QStringLiteral("OUT = %1 * IN + %2")
                        .arg(formatNumber(segment.slope), formatNumber(segment.intercept)));
        item.insert(QStringLiteral("rsquared"),
                    QStringLiteral("R^2 = %1").arg(formatNumber(segment.rSquared, 5)));
        item.insert(QStringLiteral("xStart"), segment.xStart);
        item.insert(QStringLiteral("xEnd"), segment.xEnd);
        item.insert(QStringLiteral("slopeValue"), segment.slope);
        item.insert(QStringLiteral("interceptValue"), segment.intercept);
        segmentItems.append(item);
    }

    m_segmentResults = segmentItems;
    m_segments = result.segments;
    const double maxAbsY = maxAbsYValue(m_pointModel.points());
    m_reviewTolerance = 0.2 * maxAbsY / 100.0;
    m_segmentedPointSeries = buildSegmentedPointSeries(m_pointModel.points(), m_segmentResults);
    m_fittedLineSeries = buildFittedLineSeries(m_segmentResults);
    m_globalResidualSeries = buildGlobalResidualSeries(m_pointModel.points());
    m_segmentErrorOutlierSeries.clear();
    m_segmentResidualSeries = buildSegmentResidualSeries(m_pointModel.points(),
                                                         m_segmentResults,
                                                         &m_segmentErrorOutlierSeries,
                                                         maxAbsY);
    m_plcCode = CodeExportService::buildPlcCode(result.segments);
    m_summaryText = QStringLiteral("%1 points processed, %2 segments, abs. tolerance %3")
                        .arg(pointCount())
                        .arg(result.segments.size())
                        .arg(formatNumber(result.absoluteTolerance, 6));

    emit resultsChanged();
    setStatus(QStringLiteral("Analysis completed with %1 segments.").arg(result.segments.size()),
              QStringLiteral("success"));
}

bool AppController::copyPlcCode()
{
    if (m_plcCode.trimmed().isEmpty()) {
        setStatus(QStringLiteral("No PLC code is available to copy yet."), QStringLiteral("error"));
        return false;
    }

    if (QClipboard *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(m_plcCode);
        setStatus(QStringLiteral("PLC code copied to the clipboard."), QStringLiteral("success"));
        return true;
    }

    setStatus(QStringLiteral("Clipboard is not available on this system."), QStringLiteral("error"));
    return false;
}

bool AppController::copyExportCode()
{
    const QString code = exportCode();
    if (code.trimmed().isEmpty()) {
        setStatus(QStringLiteral("No code is available to copy yet."), QStringLiteral("error"));
        return false;
    }

    if (QClipboard *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(code);
        setStatus(QStringLiteral("%1 code copied to the clipboard.").arg(m_exportTarget),
                  QStringLiteral("success"));
        return true;
    }

    setStatus(QStringLiteral("Clipboard is not available on this system."), QStringLiteral("error"));
    return false;
}

void AppController::setStatus(const QString &message, const QString &tone)
{
    const bool messageChanged = m_statusMessage != message;
    const bool toneChanged = m_statusTone != tone;

    m_statusMessage = message;
    m_statusTone = tone;

    if (messageChanged || toneChanged) {
        emit statusMessageChanged();
    }
}

void AppController::invalidateResults()
{
    const bool hadResults = !m_segmentResults.isEmpty() || !m_plcCode.isEmpty() || !m_summaryText.isEmpty();

    m_segmentResults.clear();
    m_segmentedPointSeries.clear();
    m_fittedLineSeries.clear();
    m_globalResidualSeries.clear();
    m_segmentResidualSeries.clear();
    m_segmentErrorOutlierSeries.clear();
    m_plcCode.clear();
    m_summaryText.clear();
    m_reviewTolerance = 0.0;
    m_segments.clear();

    if (hadResults) {
        emit resultsChanged();
    }
}
