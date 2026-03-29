#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVector>

#include "PointTableModel.h"
#include "PointTypes.h"

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(PointTableModel *pointModel READ pointModel CONSTANT)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QString statusTone READ statusTone NOTIFY statusMessageChanged)
    Q_PROPERTY(bool hasPoints READ hasPoints NOTIFY pointsChanged)
    Q_PROPERTY(bool hasResults READ hasResults NOTIFY resultsChanged)
    Q_PROPERTY(int pointCount READ pointCount NOTIFY pointsChanged)
    Q_PROPERTY(int missingYCount READ missingYCount NOTIFY pointsChanged)
    Q_PROPERTY(QVariantList pointSeries READ pointSeries NOTIFY pointsChanged)
    Q_PROPERTY(QVariantList segmentedPointSeries READ segmentedPointSeries NOTIFY resultsChanged)
    Q_PROPERTY(QVariantList fittedLineSeries READ fittedLineSeries NOTIFY resultsChanged)
    Q_PROPERTY(QVariantList globalResidualSeries READ globalResidualSeries NOTIFY resultsChanged)
    Q_PROPERTY(QVariantList segmentResidualSeries READ segmentResidualSeries NOTIFY resultsChanged)
    Q_PROPERTY(QVariantList segmentErrorOutlierSeries READ segmentErrorOutlierSeries NOTIFY resultsChanged)
    Q_PROPERTY(double reviewTolerance READ reviewTolerance NOTIFY resultsChanged)
    Q_PROPERTY(QStringList exportTargets READ exportTargets CONSTANT)
    Q_PROPERTY(QString exportTarget READ exportTarget WRITE setExportTarget NOTIFY exportTargetChanged)
    Q_PROPERTY(QString exportCode READ exportCode NOTIFY exportCodeChanged)
    Q_PROPERTY(QString summaryText READ summaryText NOTIFY resultsChanged)
    Q_PROPERTY(QString plcCode READ plcCode NOTIFY resultsChanged)
    Q_PROPERTY(QVariantList segmentResults READ segmentResults NOTIFY resultsChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    PointTableModel *pointModel();
    QString statusMessage() const;
    QString statusTone() const;
    bool hasPoints() const;
    bool hasResults() const;
    int pointCount() const;
    int missingYCount() const;
    QVariantList pointSeries() const;
    QVariantList segmentedPointSeries() const;
    QVariantList fittedLineSeries() const;
    QVariantList globalResidualSeries() const;
    QVariantList segmentResidualSeries() const;
    QVariantList segmentErrorOutlierSeries() const;
    double reviewTolerance() const;
    QStringList exportTargets() const;
    QString exportTarget() const;
    void setExportTarget(const QString &target);
    QString exportCode() const;
    QString summaryText() const;
    QString plcCode() const;
    QVariantList segmentResults() const;

    Q_INVOKABLE void loadCsv(const QString &source);
    Q_INVOKABLE void generatePoints(double minimum, double maximum, int intervals);
    Q_INVOKABLE void clearPoints();
    Q_INVOKABLE void updatePointX(int row, const QString &value);
    Q_INVOKABLE void updatePointY(int row, const QString &value);
    Q_INVOKABLE bool addPoint(const QString &xValue, const QString &yValue = QString());
    Q_INVOKABLE bool removePoint(int row);
    Q_INVOKABLE void sortPointsByX();
    Q_INVOKABLE void runAnalysis();
    Q_INVOKABLE bool copyPlcCode();
    Q_INVOKABLE bool copyExportCode();

signals:
    void statusMessageChanged();
    void pointsChanged();
    void resultsChanged();
    void exportTargetChanged();
    void exportCodeChanged();

private:
    void setStatus(const QString &message, const QString &tone);
    void invalidateResults();

    PointTableModel m_pointModel;
    QString m_statusMessage;
    QString m_statusTone = QStringLiteral("neutral");
    QString m_summaryText;
    QString m_plcCode;
    QVariantList m_segmentedPointSeries;
    QVariantList m_fittedLineSeries;
    QVariantList m_globalResidualSeries;
    QVariantList m_segmentResidualSeries;
    QVariantList m_segmentErrorOutlierSeries;
    QVariantList m_segmentResults;
    double m_reviewTolerance = 0.0;
    QVector<SegmentResult> m_segments;
    QString m_exportTarget = QStringLiteral("PLC");
};
