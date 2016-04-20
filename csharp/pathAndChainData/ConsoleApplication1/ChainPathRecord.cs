using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using FileHelpers;

namespace ConsoleApplication1
{

    [DelimitedRecord(","), IgnoreFirst(1)]
    public class ChainPathRecord
    {
        public string PlacementId;
        public string Site;
        public string CurrentGoal;
        [FieldConverter(ConverterKind.Date, "yyyy-MM-dd")]
        public DateTime Date;
        public string chain;
        public bool isLearning;
        public double Allocation;
        [FieldConverter(typeof(ServingPathRecordConverter))]
        public ServingPathEntry ServingPath;
        public bool UsedFeatureData;
        public bool OptimizationOnDate;
        public bool ReallocationOnDate;
        public int ImpressionsAllPaths;
        public int ServedAllPaths;
        public double IncomeAllPaths;
        public double FillAllPaths;
        public double EcpmAllPaths;
        public double RcpmAllPaths;
        public int PathImpressions;
        public int PathServed;
        public double PathFill;
    }

    public class PathFillComparisonRecord
    {
        public string PlacementId;
        [FieldConverter(ConverterKind.Date, "yyyy-MM-dd")]
        public DateTime Date;
        [FieldConverter(typeof(ServingPathRecordConverter))]
        public ServingPathEntry ServingPath;
        public bool UsedFeatureData;
        public double PathFill;
        public double PathInvertedAllocationFill;
    }

}
