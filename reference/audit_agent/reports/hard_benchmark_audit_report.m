(* Created with the Wolfram Language : www.wolfram.com *)
<|"Name" -> "hard-benchmark-audit", "CreatedAt" -> "2026-05-22 17:26:12", 
 "Status" -> "WARN", "Summary" -> <|"PASS" -> 212, "WARN" -> 3, 
   "FAIL" -> 0|>, "Metadata" -> 
  <|"Children" -> {"source-contracts", "boundary:I3Lhard", 
     "boundary:I3Lhardr", "boundary:I3Lhardt", "series:threeloophard1", 
     "series:threeloophard2", "solve:threeloophard1", 
     "solve:threeloophard2"}|>, 
 "Checks" -> {<|"Status" -> "PASS", "Check" -> "source-file", 
    "Message" -> "Source file exists.", "Details" -> 
     <|"File" -> "master_agent.wl"|>|>, <|"Status" -> "PASS", 
    "Check" -> "source-file", "Message" -> "Source file exists.", 
    "Details" -> <|"File" -> "series_agent/series_agent.wl"|>|>, 
   <|"Status" -> "PASS", "Check" -> "source-file", 
    "Message" -> "Source file exists.", "Details" -> 
     <|"File" -> "asym/boundary_agent/boundary_agent.wl"|>|>, 
   <|"Status" -> "PASS", "Check" -> "source-file", 
    "Message" -> "Source file exists.", "Details" -> 
     <|"File" -> "solve_agent/solve_agent.wl"|>|>, 
   <|"Status" -> "PASS", "Check" -> "master-call-order", 
    "Message" -> 
     "Master calls boundary, series, then solve in the expected order.", 
    "Details" -> <|"Positions" -> {5308, 5759, 6349}|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-functions", 
    "Message" -> 
     "Series agent contains all simple and double pole expansion functions.", 
    "Details" -> <|"Functions" -> {"SeriesExpansion0", "SeriesExpansion0P", 
        "SeriesExpansion1", "SeriesExpansion1P", "SeriesExpansionInf", 
        "SeriesExpansionInfP", "SeriesExpansion20", "SeriesExpansion20P", 
        "SeriesExpansion21", "SeriesExpansion21P", "SeriesExpansion2Inf", 
        "SeriesExpansion2InfP"}|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-suffixes", "Message" -> 
     "Series agent contains all six expected output suffixes.", 
    "Details" -> <|"Suffixes" -> {"e0uv", "e0uvp", "einfuv", "einfuvp", 
        "e1uv", "e1uvp"}|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-run-call", "Message" -> "Boundary agent calls \
RunAsymExpansionParallel with the configured integrand and permutations.", 
    "Details" -> <||>|>, <|"Status" -> "WARN", 
    "Check" -> "boundary-filepath-scope", "Message" -> "Boundary agent sets \
filepath locally; asym_new.wl uses a global filepath for exports, so output \
location should be audited after each run.", "Details" -> <||>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-system", 
    "Message" -> "Solve agent solves the accumulated system named sys.", 
    "Details" -> <||>|>, <|"Status" -> "PASS", 
    "Check" -> "permutation-order", "Message" -> 
     "Permutation order matches solve_agent's expected order.", 
    "Details" -> <|"Order" -> {{1, 2, 3, 4}, {2, 1, 3, 4}, {1, 3, 2, 4}, 
        {2, 3, 1, 4}, {3, 1, 2, 4}, {3, 2, 1, 4}}|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file", 
    "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "1234", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhard1234_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard1234_order3_asyexp.m", "Bytes" -> 394|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard1234_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhard1234_o\
rder3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard1234_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "2134", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhard2134_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard2134_order3_asyexp.m", "Bytes" -> 394|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard2134_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhard2134_o\
rder3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard2134_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "1324", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhard1324_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard1324_order3_asyexp.m", "Bytes" -> 436|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard1324_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhard1324_o\
rder3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard1324_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "2314", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhard2314_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard2314_order3_asyexp.m", "Bytes" -> 425|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard2314_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhard2314_o\
rder3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard2314_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "3124", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhard3124_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard3124_order3_asyexp.m", "Bytes" -> 436|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard3124_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhard3124_o\
rder3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard3124_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "3214", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhard3214_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard3214_order3_asyexp.m", "Bytes" -> 425|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard3214_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhard3214_o\
rder3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhard3214_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "permutation-order", "Message" -> 
     "Permutation order matches solve_agent's expected order.", 
    "Details" -> <|"Order" -> {{1, 2, 3, 4}, {2, 1, 3, 4}, {1, 3, 2, 4}, 
        {2, 3, 1, 4}, {3, 1, 2, 4}, {3, 2, 1, 4}}|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file", 
    "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "1234", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardr1234_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr1234_order3_asyexp.m", "Bytes" -> 394|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr1234_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardr1234_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr1234_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "2134", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardr2134_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr2134_order3_asyexp.m", "Bytes" -> 356|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr2134_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardr2134_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr2134_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "1324", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardr1324_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr1324_order3_asyexp.m", "Bytes" -> 60|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr1324_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardr1324_\
order3_asyexp.m", "Head" -> Integer|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr1324_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "2314", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardr2314_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr2314_order3_asyexp.m", "Bytes" -> 60|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr2314_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardr2314_\
order3_asyexp.m", "Head" -> Integer|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr2314_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "3124", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardr3124_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr3124_order3_asyexp.m", "Bytes" -> 411|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr3124_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardr3124_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr3124_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "3214", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardr3214_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr3214_order3_asyexp.m", "Bytes" -> 425|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr3214_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardr3214_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardr3214_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "permutation-order", "Message" -> 
     "Permutation order matches solve_agent's expected order.", 
    "Details" -> <|"Order" -> {{1, 2, 3, 4}, {2, 1, 3, 4}, {1, 3, 2, 4}, 
        {2, 3, 1, 4}, {3, 1, 2, 4}, {3, 2, 1, 4}}|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file", 
    "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "1234", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardt1234_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt1234_order3_asyexp.m", "Bytes" -> 484|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt1234_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardt1234_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt1234_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "2134", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardt2134_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt2134_order3_asyexp.m", "Bytes" -> 484|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt2134_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardt2134_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt2134_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "1324", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardt1324_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt1324_order3_asyexp.m", "Bytes" -> 358|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt1324_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardt1324_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt1324_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "2314", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardt2314_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt2314_order3_asyexp.m", "Bytes" -> 362|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt2314_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardt2314_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt2314_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "3124", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardt3124_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt3124_order3_asyexp.m", "Bytes" -> 358|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt3124_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardt3124_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt3124_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-file", "Message" -> "Boundary output file exists.", 
    "Details" -> <|"Permutation" -> "3214", "File" -> "/Users/songracs/Downlo\
ads/svbwalkthrough/checkI3Lhardt3214_order3_asyexp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-file-size", 
    "Message" -> "Boundary output is non-trivial.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt3214_order3_asyexp.m", "Bytes" -> 362|>|>, 
   <|"Status" -> "PASS", "Check" -> "boundary-freshness", 
    "Message" -> "Boundary output is fresh enough.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt3214_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-import", "Message" -> 
     "Boundary output imports cleanly.", "Details" -> 
     <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI3Lhardt3214_\
order3_asyexp.m", "Head" -> SeriesData|>|>, <|"Status" -> "PASS", 
    "Check" -> "boundary-series-format", "Message" -> 
     "Boundary output is either zero or contains SeriesData in Y.", 
    "Details" -> <|"File" -> "/Users/songracs/Downloads/svbwalkthrough/checkI\
3Lhardt3214_order3_asyexp.m"|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-sv-file", "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uv.m"|>\
|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uv.m"|>\
|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uv", "Bytes" -> 289335|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uv", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple0uv.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple0uv.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uv", "Bytes" -> 129499|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uv", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-file", 
    "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uvp.m"\
|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uvp.m"\
|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Bytes" -> 83150|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple0uvp\
.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple0uvp\
.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Bytes" -> 14539|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-file", 
    "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlisteinfuv.m\
"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlisteinfuv.m\
"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuv", "Bytes" -> 832857|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuv", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> "/Users/songracs/Downloads\
/svbwalkthrough/threeloophard_svlistmpleinfuv.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> "/Users/songracs/Downloads\
/svbwalkthrough/threeloophard_svlistmpleinfuv.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuv", "Bytes" -> 83154|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuv", "Length" -> 82, 
      "Expected" -> 82|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-sv-file", "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "einfuvp", 
      "File" -> "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlis\
teinfuvp.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuvp", 
      "File" -> "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlis\
teinfuvp.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Bytes" -> 642626|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "einfuvp", "File" -> "/Users/songracs/Download\
s/svbwalkthrough/threeloophard_svlistmpleinfuvp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuvp", "File" -> "/Users/songracs/Download\
s/svbwalkthrough/threeloophard_svlistmpleinfuvp.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Bytes" -> 266580|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Length" -> 82, 
      "Expected" -> 82|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-sv-file", "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uv.m"|>\
|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uv.m"|>\
|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uv", "Bytes" -> 274133|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uv", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple1uv.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple1uv.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uv", "Bytes" -> 130933|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uv", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-file", 
    "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uvp.m"\
|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uvp.m"\
|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Bytes" -> 213206|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple1uvp\
.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlistmple1uvp\
.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Bytes" -> 21307|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-y-order", 
    "Message" -> "Series audit used the requested Y truncation order.", 
    "Details" -> <|"YOrder" -> 4|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-sv-file", "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uv_2.m\
"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uv_2.m\
"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uv", "Bytes" -> 289355|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uv", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> "/Users/songracs/Downloads/s\
vbwalkthrough/threeloophard_svlistmple0uv_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uv", "File" -> "/Users/songracs/Downloads/s\
vbwalkthrough/threeloophard_svlistmple0uv_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uv", "Bytes" -> 130463|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uv", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-file", 
    "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uvp_2.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste0uvp_2.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Bytes" -> 83459|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> "/Users/songracs/Downloads/\
svbwalkthrough/threeloophard_svlistmple0uvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e0uvp", "File" -> "/Users/songracs/Downloads/\
svbwalkthrough/threeloophard_svlistmple0uvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Bytes" -> 14733|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e0uvp", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-file", 
    "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlisteinfuv_2\
.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svlisteinfuv_2\
.m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuv", "Bytes" -> 675720|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuv", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> "/Users/songracs/Downloads\
/svbwalkthrough/threeloophard_svlistmpleinfuv_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuv", "File" -> "/Users/songracs/Downloads\
/svbwalkthrough/threeloophard_svlistmpleinfuv_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuv", "Bytes" -> 60208|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuv", "Length" -> 82, 
      "Expected" -> 82|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-sv-file", "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "einfuvp", "File" -> "/Users/songracs/Download\
s/svbwalkthrough/threeloophard_svlisteinfuvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuvp", "File" -> "/Users/songracs/Download\
s/svbwalkthrough/threeloophard_svlisteinfuvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Bytes" -> 794347|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "einfuvp", "File" -> "/Users/songracs/Download\
s/svbwalkthrough/threeloophard_svlistmpleinfuvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "einfuvp", "File" -> "/Users/songracs/Download\
s/svbwalkthrough/threeloophard_svlistmpleinfuvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Bytes" -> 393593|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "einfuvp", "Length" -> 82, 
      "Expected" -> 82|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-sv-file", "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uv_2.m\
"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uv_2.m\
"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uv", "Bytes" -> 348498|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uv", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> "/Users/songracs/Downloads/s\
vbwalkthrough/threeloophard_svlistmple1uv_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uv", "File" -> "/Users/songracs/Downloads/s\
vbwalkthrough/threeloophard_svlistmple1uv_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uv", "Bytes" -> 187548|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uv", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-file", 
    "Message" -> "SV series file exists.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uvp_2.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-freshness", 
    "Message" -> "SV series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard_svliste1uvp_2.\
m"|>|>, <|"Status" -> "PASS", "Check" -> "series-sv-size", 
    "Message" -> "SV series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Bytes" -> 270877|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-sv-format", 
    "Message" -> "SV series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Length" -> 510, 
      "Expected" -> 510|>|>, <|"Status" -> "PASS", 
    "Check" -> "series-mpl-file", "Message" -> "MPL series file exists.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> "/Users/songracs/Downloads/\
svbwalkthrough/threeloophard_svlistmple1uvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-freshness", 
    "Message" -> "MPL series output is fresh enough.", 
    "Details" -> <|"Suffix" -> "e1uvp", "File" -> "/Users/songracs/Downloads/\
svbwalkthrough/threeloophard_svlistmple1uvp_2.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-size", 
    "Message" -> "MPL series file is non-trivial.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Bytes" -> 26213|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-mpl-format", 
    "Message" -> "MPL series imports as a list with the basis length.", 
    "Details" -> <|"Suffix" -> "e1uvp", "Length" -> 82, "Expected" -> 82|>|>, 
   <|"Status" -> "PASS", "Check" -> "series-y-order", 
    "Message" -> "Series audit used the requested Y truncation order.", 
    "Details" -> <|"YOrder" -> 4|>|>, <|"Status" -> "PASS", 
    "Check" -> "solve-file", "Message" -> "Solution file exists.", 
    "Details" -> <|"File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard1_sol.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-freshness", 
    "Message" -> "Solution output is fresh enough.", 
    "Details" -> <|"File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard1_sol.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-format", 
    "Message" -> "Solution imports as c[i] rules.", 
    "Details" -> <|"Length" -> 57|>|>, <|"Status" -> "PASS", 
    "Check" -> "solve-duplicates", "Message" -> 
     "No coefficient index is duplicated.", "Details" -> <||>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-completeness", 
    "Message" -> "Solution covers every ansatz coefficient.", 
    "Details" -> <|"Expected" -> 57, "Actual" -> 57|>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-values", 
    "Message" -> "Solution values contain no failed or infinite values.", 
    "Details" -> <||>|>, <|"Status" -> "WARN", 
    "Check" -> "solve-residual-skipped", "Message" -> 
     "Residual verification skipped because target data was not provided.", 
    "Details" -> <||>|>, <|"Status" -> "PASS", "Check" -> "solve-file", 
    "Message" -> "Solution file exists.", "Details" -> 
     <|"File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard2_sol.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-freshness", 
    "Message" -> "Solution output is fresh enough.", 
    "Details" -> <|"File" -> 
       "/Users/songracs/Downloads/svbwalkthrough/threeloophard2_sol.m"|>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-format", 
    "Message" -> "Solution imports as c[i] rules.", 
    "Details" -> <|"Length" -> 43|>|>, <|"Status" -> "PASS", 
    "Check" -> "solve-duplicates", "Message" -> 
     "No coefficient index is duplicated.", "Details" -> <||>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-completeness", 
    "Message" -> "Solution covers every ansatz coefficient.", 
    "Details" -> <|"Expected" -> 43, "Actual" -> 43|>|>, 
   <|"Status" -> "PASS", "Check" -> "solve-values", 
    "Message" -> "Solution values contain no failed or infinite values.", 
    "Details" -> <||>|>, <|"Status" -> "WARN", 
    "Check" -> "solve-residual-skipped", "Message" -> 
     "Residual verification skipped because target data was not provided.", 
    "Details" -> <||>|>}|>
