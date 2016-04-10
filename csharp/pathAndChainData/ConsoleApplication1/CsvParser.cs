using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using GenericParsing;
using System.Data;
using System.IO;

namespace ConsoleApplication1
{
    class CsvParser
    {
        static private void Parse(string fullPathToFileToParse)
        {
            string strID, strName, strStatus;
            using (GenericParser parser = new GenericParser())
            {
                parser.SetDataSource(fullPathToFileToParse);

                parser.ColumnDelimiter = '\t';
                parser.FirstRowHasHeader = true;
                parser.SkipStartingDataRows = 10;
                parser.MaxBufferSize = 4096;
                parser.MaxRows = 500;
                parser.TextQualifier = '\"';

                while (parser.Read())
                {
                    strID = parser["ID"];
                    strName = parser["Name"];
                    strStatus = parser["Status"];
                    int i = 0;
                    // Your code here ...
                }
            }
        }

        static public DataTable Parse1(string fullPathToFileToParse)
        {
            var reader = ReadAsLines(fullPathToFileToParse);

            var data = new DataTable();

            //this assume the first record is filled with the column names
            var headers = reader.First().Split(',');
            foreach (var header in headers)
            {
                data.Columns.Add(header);
            }

            var records = reader.Skip(1);
            foreach (var record in records)
            {
                data.Rows.Add(record.Split(','));
            }

            return data;
        }

        static IEnumerable<string> ReadAsLines(string filename)
        {
            using (StreamReader reader = new StreamReader(filename))
                while (!reader.EndOfStream)
                    yield return reader.ReadLine();
        }
    }
}
