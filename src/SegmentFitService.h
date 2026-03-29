#pragma once

#include <QString>
#include <QVector>

#include "PointTypes.h"

class SegmentFitService
{
public:
    struct Options
    {
        Options(int minimumPoints = 4, double fitTolerance = 0.01)
            : minimumPointsPerSegment(minimumPoints)
            , fitTolerancePercent(fitTolerance)
        {
        }

        int minimumPointsPerSegment;
        double fitTolerancePercent;
    };

    struct Result
    {
        QVector<SegmentResult> segments;
        double absoluteTolerance = 0.0;
        QString errorMessage;
    };

    static Result analyze(const QVector<DataPoint> &points, const Options &options = Options());
};
