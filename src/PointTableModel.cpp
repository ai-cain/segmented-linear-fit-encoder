#include "PointTableModel.h"

#include <QLocale>
#include <cmath>

namespace
{
QString formatNumber(double value, int decimals = 6)
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
    value = QLocale::c().toDouble(text, &ok);
    if (ok) {
        return true;
    }

    text.replace(',', '.');
    value = text.toDouble(&ok);
    return ok;
}
} // namespace

PointTableModel::PointTableModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int PointTableModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_points.size();
}

QVariant PointTableModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_points.size()) {
        return {};
    }

    const DataPoint &point = m_points.at(index.row());

    switch (role) {
    case XRole:
        return point.x;
    case YRole:
        return point.y.has_value() ? QVariant(*point.y) : QVariant();
    case DisplayXRole:
        return formatNumber(point.x);
    case DisplayYRole:
        return point.y.has_value() ? QVariant(formatNumber(*point.y)) : QVariant(QString());
    case ValidYRole:
        return point.y.has_value();
    default:
        return {};
    }
}

QHash<int, QByteArray> PointTableModel::roleNames() const
{
    return {
        {XRole, "xValue"},
        {YRole, "yValue"},
        {DisplayXRole, "displayX"},
        {DisplayYRole, "displayY"},
        {ValidYRole, "validY"},
    };
}

int PointTableModel::count() const
{
    return m_points.size();
}

const QVector<DataPoint> &PointTableModel::points() const
{
    return m_points;
}

void PointTableModel::setPoints(const QVector<DataPoint> &points)
{
    beginResetModel();
    m_points = points;
    endResetModel();
    emit countChanged();
}

void PointTableModel::clear()
{
    if (m_points.isEmpty()) {
        return;
    }

    beginResetModel();
    m_points.clear();
    endResetModel();
    emit countChanged();
}

bool PointTableModel::setYValue(int row, const QString &text, QString *errorMessage)
{
    if (row < 0 || row >= m_points.size()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("The requested row does not exist.");
        }
        return false;
    }

    const QString trimmed = text.trimmed();
    if (trimmed.isEmpty()) {
        m_points[row].y.reset();
    } else {
        double parsedValue = 0.0;
        if (!parseNumber(trimmed, parsedValue)) {
            if (errorMessage) {
                *errorMessage = QStringLiteral("Enter a valid numeric Y value.");
            }
            return false;
        }
        m_points[row].y = parsedValue;
    }

    const QModelIndex changedIndex = index(row);
    emit dataChanged(changedIndex, changedIndex, {YRole, DisplayYRole, ValidYRole});
    return true;
}
