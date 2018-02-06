# DataProcessingHierarchyTools
Tools to facilitate processing and visualization of data organized in a hierarchy

## Example 1
Query the name associated with a particular level
```julia
  using DataProcessingHierarchyTools
  const DPHT = DataProcessingHierarchyTools
  subject_name = DPHT.get_level_name("days","newWorkingMemory/Pancake/20130923/")
  session_name = subject_name = DPHT.get_level_name("day","newWorkingMemory/Pancake/20130923/")
```

## Example 2
Get the necessary relative path change to get from one level to another
```julia
using DataProcessingHierarchyTools
const DPHT = DataProcessingHierarchyTools
pth = DPHT.process_level("session", "Pancake/20130923/session01/array01/channel001")
```
