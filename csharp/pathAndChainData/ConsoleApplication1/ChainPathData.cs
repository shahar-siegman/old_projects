using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace ConsoleApplication1
{
    public class ChainPathDataPlacements
    {
        private ChainPathRecord[] inputData;
        private Dictionary<string, ChainPathDataDays> data;

        public IReadOnlyDictionary<string, ChainPathDataDays> Data { get { return data; } }
        public ChainPathDataPlacements(ChainPathRecord[] data)
        {
            inputData = data;
            this.data = data.GroupBy(x => x.PlacementId).ToDictionary(x => x.Key, x => new ChainPathDataDays(x.ToList()));
        }
        public ChainPathDataPlacements(Dictionary<string, ChainPathDataDays> data)
        {
            this.data = data;
        }

        public PathFillComparisonRecord[] ToPathFillComparison()
        {
            var a = from placement in data
            from day in placement.Value.Data
            from path in day.Value.Data
            select new PathFillComparisonRecord
            {
                PlacementId = placement.Key,
                Date = day.Key,
                ServingPath = path.Key,
                UsedFeatureData = placement.Value.UsedFeatureData,
                PathFill = path.Value.EstimatedFill,
            };
            return a.ToArray();
        }
    }

    public class ChainPathDataDays
    {
        private Dictionary<DateTime, ChainPathDataPaths> data;
        public IReadOnlyDictionary<DateTime, ChainPathDataPaths> Data { get { return data; } }
        public readonly bool UsedFeatureData;
        public ChainPathDataDays(IEnumerable<ChainPathRecord> records)
        {
            data = records.GroupBy(x => x.Date).ToDictionary(x => x.Key, x => new ChainPathDataPaths(x.ToList()));
            UsedFeatureData = records.First().UsedFeatureData;
        }
        public ChainPathDataDays(Dictionary<DateTime, ChainPathDataPaths> data, bool usedFeatureData = false)
        {
            this.data = data;
            UsedFeatureData = usedFeatureData;
        }
    }

    public class ChainPathDataPaths
    {
        private Dictionary<ServingPathEntry, ChainPathDataChains> data;
        public IReadOnlyDictionary<ServingPathEntry, ChainPathDataChains> Data { get { return data; } }
        public ChainPathDataPaths(IEnumerable<ChainPathRecord> records)
        {
            data = records.GroupBy(x => x.ServingPath).ToDictionary(x => x.Key, x => new ChainPathDataChains(x.ToList()));
        }
        public ChainPathDataPaths()
        {
            data = new Dictionary<ServingPathEntry, ChainPathDataChains>();
        }
        public ChainPathDataPaths SwitchBetweenPaths(ServingPathEntry path1, ServingPathEntry path2)
        {
            var result = new ChainPathDataPaths();
            result.data = data.ToDictionary(
                x => { if (x.Key == path1) return path2; else if (x.Key == path2) return path1; else return x.Key; }, 
                x => x.Value);
            return result;
        }
    }

    public class ChainPathDataChains
    {
        private Dictionary<string, ChainPathDataPerformance> data;
        public double TotalAllocation
        {
            get; private set;
        }
        public double EstimatedFill
        {
            get; private set;
        }
        public ChainPathDataChains(IEnumerable<ChainPathRecord> records)
        {
            data = records.ToDictionary(x => x.chain, x => new ChainPathDataPerformance(x));
            TotalAllocation = records.Sum(x => x.Allocation);
            CalculateTotalAllocation();
            CalculateEstimatedPathFill();
        }
        private void CalculateTotalAllocation()
        {
            TotalAllocation = data.Values.Sum(x => x.Allocation);
        }
        private void CalculateEstimatedPathFill()
        {
            EstimatedFill = data.Values.Sum(x => x.Allocation * x.PathFill) / TotalAllocation;
        }
        private static bool IsChainValidForPath(ServingPathEntry path, string chain)
        {
            // no smaato on desktop
            if (!path.IsMobile && chain.Contains("z"))
                return false;
            if (!path.Is15Countries && chain.Contains("o"))
                return false;
            if (path.IsMobile && Regex.Match(chain, "C|d|D|f|F|K").Success)
                return false;
            return true;
        }
        void NullifyAllocationInvalidChains(ServingPathEntry path)
        {
            foreach (var datum in data)
                if (!IsChainValidForPath(path, datum.Key))
                    datum.Value.Allocation = 0;
            CalculateTotalAllocation();
            CalculateEstimatedPathFill();

        }
    }

    public class ChainPathDataPerformance
    {
        public double Allocation;
        public int ImpressionsAllPaths;
        public double FillAllPaths;
        public double PathFill;
        public ChainPathDataPerformance(ChainPathRecord record)
        {
            Allocation = record.Allocation;
            ImpressionsAllPaths = record.ImpressionsAllPaths;
            FillAllPaths = record.FillAllPaths;
            PathFill = record.PathFill;
        }
    }

}
