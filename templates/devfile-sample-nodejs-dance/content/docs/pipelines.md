# docker-build-rhtap

## Shared Git resolver model for shared pipeline and tasks. 
 
This pipeline is used to create dockerfile based sscs builds. The pipeline run by this runner will clone the source, build an image with SBOM, and attestations and push these to the users image registry.  

Tasks references come from this repository ` ../pipelines` `../tasks` and are referenced by URL using the git resolver in tekton. 
 
When the pipleines in this repo are updated, all future runs in existin pipelines are shared.

A developer can override these tasks with a local copy and updated annotations. 

Example 

To override the git-clone task, you may simply copy the git reference into your .tekton directory and then reference it from the remote task annotation. 

`pipelinesascode.tekton.dev/task-0: "./tekton/git-clone.yaml"` 

## Templates 
These pipelines are in template format. The references to this repository in the PaC template is `{{values.rawUrl}}` which is updated to point to this repo or the fork of this repo.

The intent of the template is to be able to fork this repository and update its use in the Developer Hub templates directory. 
