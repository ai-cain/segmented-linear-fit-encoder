#pragma once

#include <QObject>
#include <QVariantList>

#include "PointTableModel.h"

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
    QString summaryText() const;
    QString plcCode() const;
    QVariantList segmentResults() const;

    Q_INVOKABLE void loadCsv(const QString &source);
    Q_INVOKABLE void generatePoints(double minimum, double maximum, int intervals);
    Q_INVOKABLE void clearPoints();
    Q_INVOKABLE void updatePointY(int row, const QString &value);
    Q_INVOKABLE void runAnalysis();
    Q_INVOKABLE bool copyPlcCode();

signals:
    void statusMessageChanged();
    void pointsChanged();
    void resultsChanged();

private:
    void setStatus(const QString &message, const QString &tone);
    void invalidateResults();

    PointTableModel m_pointModel;
    QString m_statusMessage;
    QString m_statusTone = QStringLiteral("neutral");
    QString m_summaryText;
    QString m_plcCode;
    QVariantList m_segmentResults;
};
