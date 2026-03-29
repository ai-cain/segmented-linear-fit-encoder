#pragma once

#include <QAbstractListModel>
#include <QVector>

#include "PointTypes.h"

class PointTableModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles
    {
        XRole = Qt::UserRole + 1,
        YRole,
        DisplayXRole,
        DisplayYRole,
        ValidYRole
    };

    explicit PointTableModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;
    const QVector<DataPoint> &points() const;

    void setPoints(const QVector<DataPoint> &points);
    void clear();
    bool setXValue(int row, const QString &text, QString *errorMessage = nullptr);
    bool setYValue(int row, const QString &text, QString *errorMessage = nullptr);

signals:
    void countChanged();

private:
    QVector<DataPoint> m_points;
};
