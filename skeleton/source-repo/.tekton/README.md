# docker-build-shared with shared pipeline references 
 
This pipeline is used to create dockerfile builds. 
The task references come from this repository ` ../pipelines` `../tasks` and are referenced by URL 
 
When the pipleines in this repo are updated, all future runs are shared.

A developer can override these tasks with a local copy and updated annotations. 

Example 

 `pipelinesascode.tekton.dev/task: "./tasks/show-sbom.yaml `
   


