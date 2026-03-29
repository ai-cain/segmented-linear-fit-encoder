#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

#include "PointTypes.h"

class CodeExportService
{
public:
    static QStringList exportTargets();
    static QString buildCode(const QVector<SegmentResult> &segments,
                             const QString &target,
                             const QString &inputName = QStringLiteral("IN_VALUE"),
                             const QString &outputName = QStringLiteral("OUT_LONG"));
    static QString buildPlcCode(const QVector<SegmentResult> &segments,
                                const QString &inputName = QStringLiteral("IN_VALUE"),
                                const QString &outputName = QStringLiteral("OUT_LONG"));
};
