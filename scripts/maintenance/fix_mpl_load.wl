$HistoryLength = 0;
path = "series_agent/series_agent.wl";
code = Import[path, "Text"];

oldSub = "      If[mplBasisFile =!= None && mplIndices =!= {},
        (* Automatically resolve MPL text file based on convention: prefix + ext + suffix *)
        mplFile = mplPrefix <> ext <> sfxSuffix <> \".txt\";
        
        If[FileExistsQ[FileNameJoin[{dataDir, mplFile}]],
          mplList = ParseListString[Import[FileNameJoin[{dataDir, mplFile}], \"String\"]];
          mplList = mplList[[mplIndices]];
        ,
          (* fallback to .m format if .txt doesn't exist *)
          mplFile = mplPrefix <> ext <> sfxSuffix <> \".m\";
          mplList = Import[FileNameJoin[{dataDir, mplFile}]];
          mplList = mplList[[mplIndices]];
        ];
      ,
        mplList = {};
      ];";

newSub = "      If[mplBasisFile =!= None && mplIndices =!= {},
        (* For MPLs, we load the base exact expressions without inuv/inuvp suffix *)
        mplFile = mplPrefix <> ext <> \".m\";
        
        If[FileExistsQ[FileNameJoin[{dataDir, mplFile}]],
          mplList = Import[FileNameJoin[{dataDir, mplFile}]];
          mplList = mplList[[mplIndices]];
        ,
          Print[\"[Skill 1] ERROR: Missing MPL basis file \", mplFile];
          mplList = {};
        ];
      ,
        mplList = {};
      ];";

newCode = StringReplace[code, oldSub -> newSub];
Export[path, newCode, "Text"];
