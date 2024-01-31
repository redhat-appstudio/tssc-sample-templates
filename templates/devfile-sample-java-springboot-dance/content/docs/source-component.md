# Creating an application with a Spring Boot code sample

**Note:** The Spring Boot code sample uses the **8081** HTTP port.

Before you begin creating an application with this `devfile` code sample, it's helpful to understand the relationship between the `devfile` and `Dockerfile` and how they contribute to your build. You can find these files at the following URLs:

* [Spring Boot `devfile.yaml`](https://github.com/redhat-appstudio/devfile-sample-java-springboot-dance/blob/main/devfile.yaml)
* [Spring Boot `Dockerfile`](https://github.com/redhat-appstudio/devfile-sample-java-springboot-dance/blob/main/docker/Dockerfile)

1. The `devfile.yaml` file has an [`image-build` component](https://github.com/redhat-appstudio/devfile-sample-java-springboot-dance/blob/main/devfile.yaml#L25-L31) that points to your `Dockerfile`.
2. The [`docker/Dockerfile`](https://github.com/redhat-appstudio/devfile-sample-java-springboot-dance/blob/main/docker/Dockerfile) contains the instructions you need to build the code sample as a container image.
3. The `devfile.yaml` [`kubernetes-deploy` component](https://github.com/redhat-appstudio/devfile-sample-java-springboot-dance/blob/main/devfile.yaml#L32-L44) points to a `deploy.yaml` file that contains instructions for deploying the built container image.
4. The `devfile.yaml` [`deploy` command](https://github.com/redhat-appstudio/devfile-sample-java-springboot-dance/blob/main/devfile.yaml#L46-L59) completes the [outerloop](https://devfile.io/docs/2.2.0/innerloop-vs-outerloop) deployment phase by pointing to the `image-build` and `kubernetes-deploy` components to create your application.

### Additional resources
* For more information about Spring Boot, see [Spring Boot](https://spring.io/projects/spring-boot).
* For more information about devfiles, see [Devfile.io](https://devfile.io/).
* For more information about the deployment outerloop, see [Devfile.io: Innerloop versus outerloop](https://devfile.io/docs/2.2.0/innerloop-vs-outerloop).
* For more information about Dockerfiles, see [Dockerfile reference](https://docs.docker.com/engine/reference/builder/).
