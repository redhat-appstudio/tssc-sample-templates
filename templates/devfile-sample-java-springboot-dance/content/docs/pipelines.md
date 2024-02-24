# docker-build-rhtap

## Shared Git resolver model for shared pipeline and tasks. 
 
This pipeline is used to create dockerfile based sscs builds. 
Tasks tasks references come from this repository ` ../pipelines` `../tasks` and are referenced by URL using the git resolver in tekton. 
 
When the pipleines in this repo are updated, all future runs are shared.

A developer can override these tasks with a local copy and updated annotations. 

Example 

 `pipelinesascode.tekton.dev/task: "./tasks/show-sbom.yaml `
   

## Templates 
These pipelines are in template format. The references to this repository in the PaC template is `{{values.rawUrl}}` which is updated to point to this repo or the fork of this repo.

