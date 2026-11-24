# Load HyperlogProcedures 0.8 first, with z and zz unassigned. Call
# ReadFourLoopBootstrap("/path/to/anc") from any working directory.
ReadFourLoopBootstrap := proc(directory::string)
 local filename;
 for filename in ["I26","R168","I110","I113","I142","J112","I112","I168",
                  "I144","I212","I214","I233","R260","I260","GramAuxiliaries"] do
   read FileTools:-JoinPath([directory,cat("fourloop",filename,".mpl")])
 end do:
 NULL
end proc:
