# Creating an application with a .NET60 code sample

**Note:** The Python code sample uses the **8080** HTTP port.

Before you begin creating an application with this `devfile` code sample, it's helpful to understand the relationship between the `devfile` and `Dockerfile` and how they contribute to your build. You can find these files at the following URLs:

* [.NET60 `devfile.yaml`](https://github.com/redhat-appstudio/devfile-sample-dotnet60-dance/blob/main/devfile.yaml)
* [.NET60 `Dockerfile`](https://github.com/redhat-appstudio/devfile-sample-dotnet60-dance/blob/main/docker/Dockerfile)

1. The `devfile.yaml` file has an [`image-build` component](https://github.com/redhat-appstudio/devfile-sample-dotnet60-dance/blob/main/devfile.yaml#L44-L50) that points to your `Dockerfile`.
2. The [`docker/Dockerfile`](https://github.com/redhat-appstudio/devfile-sample-dotnet60-dance/blob/main/docker/Dockerfile) contains the instructions you need to build the code sample as a container image.
3. The `devfile.yaml` [`kubernetes-deploy` component](https://github.com/redhat-appstudio/devfile-sample-dotnet60-dance/blob/main/devfile.yaml#L51-L63) and [`kubernetes-service` component](https://github.com/redhat-appstudio/devfile-sample-dotnet60-dance/blob/main/devfile.yaml#L64-L71) points to a `deployment.yaml` file and `service.yaml`that contains instructions for deploying the built container image.
4. The `devfile.yaml` [`deploy` command](https://github.com/redhat-appstudio/devfile-sample-dotnet60-dance/blob/main/devfile.yaml#L89-L106) completes the [outerloop](https://devfile.io/docs/2.2.0/innerloop-vs-outerloop) deployment phase by pointing to the `image-build` and `kubernetes-deploy` components to create your application.

### Additional resources
* For more information about .NET, see [.NET](https://dotnet.microsoft.com/en-us/learn/dotnet/what-is-dotnet).
* For more information about devfiles, see [Devfile.io](https://devfile.io/).
* For more information about Dockerfiles, see [Dockerfile reference](https://docs.docker.com/engine/reference/builder/).
