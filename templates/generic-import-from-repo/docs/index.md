# Trusted Application Pipeline Bring Your Own Source

This template implements an bring-your-own-repo secure software template. The flow prompts the use for a repository with source code. The template contains a default gitops based deployment for an http application with a service and route defined. The application has three enviroments for deployment 

The user repositories are required to use a container build model (Dockerfile) and will be prompted for the following information during the application creation. 

1. Dockerfile, the template will prompt the user for the location of the Dockerfile. The file can be anywhere in the repository.
2. The build directory (default is ., which is the root of the repository). You can make this this to any directory in the source repo for the build to take place
3. port number for the deployment 
 
A new git and gitops repo will be created during this flow.  