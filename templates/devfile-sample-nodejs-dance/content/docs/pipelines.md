# docker-build-shared with shared pipeline references 
 
This component pipeline is used to create dockerfile builds. 
The task references come from [tssc-sample-pipeline](https://github.com/redhat-appstudio/tssc-sample-pipelines) repository , `pipelines` `tasks` and are referenced by URL 
 
When the pipleines in [tssc-sample-pipeline](https://github.com/redhat-appstudio/tssc-sample-pipelines) repo are updated, all future runs are shared.

A developer can override these tasks with a local copy and updated annotations. 

Example 

 `pipelinesascode.tekton.dev/task: "./tasks/show-sbom.yaml `
