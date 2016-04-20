using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication1
{
    public class ChainPath
    {
        public string PlacementId;
        public string Site;
        public string CurrentGoal;
        public DateTime Date;
        public string chain;
        public bool isLearning;
        public double Allocation;
        public string Path;
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
        public ChainPath() { }
        public ChainPath Clone()
        {
            return new ChainPath
            {
                PlacementId = PlacementId,
                Site = Site,
                CurrentGoal = CurrentGoal,
                Date = Date,
                chain = chain,
                isLearning = isLearning,
                Allocation = Allocation,
                Path = Path,
                UsedFeatureData = UsedFeatureData,
                OptimizationOnDate = OptimizationOnDate,
                ReallocationOnDate = ReallocationOnDate,
                ImpressionsAllPaths = ImpressionsAllPaths,
                ServedAllPaths = ServedAllPaths,
                IncomeAllPaths = IncomeAllPaths,
                FillAllPaths = FillAllPaths,
                EcpmAllPaths = EcpmAllPaths,
                RcpmAllPaths = RcpmAllPaths,
                PathImpressions = PathImpressions,
                PathServed = PathServed,
                PathFill = PathFill
            };
        }
    }


    class ChainPathCollection
    {
        public List<ChainPath> data;
        public bool includeLearngChains = true;
        public ChainPathCollection()
        {
            data = new List<ChainPath>();
        }
        public ChainPathCollection(DataTable tableData)
        {
            data = new List<ChainPath>();
            foreach (DataRow row in tableData.Rows)
                data.Add(new ChainPath
                {
                    PlacementId = (string)row["PlacementId"],
                    Site = (string)row["Site"],
                    CurrentGoal = (string)row["CurrentGoal"],
                    Date = (DateTime) row["Date"],
                    chain = (string)row["chain"],
                    isLearning = (bool)row["isLearning"],
                    Allocation = (double)row["Allocation"],
                    Path = (string)row["Path"],
                    UsedFeatureData = (bool)row["UsedFeatureData"],
                    OptimizationOnDate = (bool)row["OptimizationOnDate"],
                    ReallocationOnDate = (bool)row["ReallocationOnDate"],
                    ImpressionsAllPaths = (int)row["ImpressionsAllPaths"],
                    ServedAllPaths = (int)row["ServedAllPaths"],
                    IncomeAllPaths = (double)row["IncomeAllPaths"],
                    FillAllPaths = (double)row["FillAllPaths"],
                    EcpmAllPaths = (double)row["EcpmAllPaths"],
                    RcpmAllPaths = (double)row["RcpmAllPaths"],
                    PathImpressions = (int)row["PathImpressions"],
                    PathServed = (int)row["PathServed"],
                    PathFill = (double)row["PathFill"],
                });
        }
    }
    public class PlacementPathDate
    {
        public string PlacementId;
        public string Path;
        public DateTime Date;
        public PlacementPathDate(ChainPath cp)
        {
            PlacementId = cp.PlacementId;
            Path = cp.Path;
            Date = cp.Date;
        }

    }

    class ChainPathAnalyzer
    {
        public static Dictionary<PlacementPathDate, double> getAllocationPerPathPerDay(ChainPathCollection data)
        {
            var allocGroups = data.data.GroupBy(x => new PlacementPathDate(x), x => x.Allocation);
            var result = allocGroups.ToDictionary(x => x.Key, x => x.Sum());
            return result;
        }

        public static ChainPathCollection NormalizeAllocation(ChainPathCollection inputCollection)
        {
            var result = new ChainPathCollection();
            var allocationTotal = ChainPathAnalyzer.getAllocationPerPathPerDay(inputCollection);
            foreach (var inputRow in inputCollection.data)
                if (inputCollection.includeLearngChains || !inputRow.isLearning)
                {
                    var outRow = inputRow.Clone();
                    double totalAllocation = allocationTotal[new PlacementPathDate(outRow)];
                    outRow.Allocation = outRow.Allocation / totalAllocation;
                    result.data.Add(outRow);
                }
            return result;
        }

    }

    class ChainPathAnalysis
    {

    }
}