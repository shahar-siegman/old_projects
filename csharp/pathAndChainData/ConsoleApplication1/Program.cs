using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using FileHelpers;
using System.Text.RegularExpressions;

namespace ConsoleApplication1
{
    class Program
    {
        static void Main(string[] args)
        {
            var inputEngine = new FileHelperEngine<ChainPathRecord>();
            var inputData = inputEngine.ReadFile(@"C:\Shahar\Projects\Optimization\data_by_feature\ChainPaths.csv");
            var chainPathData = new ChainPathDataPlacements(inputData);

            var path1 = new ServingPathEntry(true, true);
            var path2 = new ServingPathEntry(false, true);
            var switchedPathData = new ChainPathDataPlacements(chainPathData.Data.ToDictionary(x => x.Key,
                x => new ChainPathDataDays(x.Value.Data.ToDictionary(y => y.Key, y => y.Value.SwitchBetweenPaths(path1, path2)))));
            var pathFillRecords = chainPathData.ToPathFillComparison();
            var switchedPathFillRecords = switchedPathData.ToPathFillComparison();
            var result = (from record in pathFillRecords
                         join otherRecord in switchedPathFillRecords on
                         new { record.PlacementId, record.Date, record.ServingPath } equals new { otherRecord.PlacementId, otherRecord.Date, otherRecord.ServingPath }
                         select new PathFillComparisonRecord
                         {
                             PlacementId = record.PlacementId,
                             Date = record.Date,
                             ServingPath = record.ServingPath,
                             UsedFeatureData = record.UsedFeatureData,
                             PathFill = record.PathFill,
                             PathInvertedAllocationFill = otherRecord.PathFill
                         }).ToArray();
            var outputEngine = new FileHelperEngine<PathFillComparisonRecord>();
            outputEngine.WriteFile(@"C:\Shahar\Projects\Optimization\data_by_feature\ChainPathsResult.csv", result);
        }

    }


    public class ServingPathEntry
    {
        public readonly bool IsMobile;
        public readonly bool Is15Countries;
        public ServingPathEntry(string str)
        {
            IsMobile = !Regex.Match(str, @"Not \(mobile\)").Success;
            Is15Countries = !Regex.Match(str, @"Not \(au \& br \& ca ").Success;
        }
        public ServingPathEntry(bool isMobile, bool is15Countries)
        {
            IsMobile = isMobile;
            Is15Countries = is15Countries;
        }
        public override string ToString()
        {
            return (IsMobile ? "mobile" : "Not (mobile)") + " & " + (Is15Countries ? "au & br" : "Not (au & br )");
        }
        public static bool operator ==(ServingPathEntry a, ServingPathEntry b)
        {
            if (ReferenceEquals(a, b))
            {
                return true;
            }
            // If one is null, but not both, return false.
            if (((object)a == null) || ((object)b == null))
            {
                return false;
            }
            return (a.IsMobile == b.IsMobile && a.Is15Countries == b.Is15Countries);
        }
        public static bool operator !=(ServingPathEntry a, ServingPathEntry b)
        {
            return !(a == b);
        }
    }
    public class ServingPathRecordConverter : ConverterBase
    {
        public override object StringToField(string from)
        {
            return new ServingPathEntry(from);
        }
        public override string FieldToString(object fieldValue)
        {
            return ((ServingPathEntry)fieldValue).ToString();
        }
    }

}
