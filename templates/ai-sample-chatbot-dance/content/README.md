# Creating an application with a Chatbot code sample

**Note:** The Chatbot code sample uses the **8501** HTTP port.

Before you begin creating an application with this `devfile` code sample, it's helpful to understand the relationship between the `devfile` and `Containerfile` and how they contribute to your build. You can find these files at the following URLs:

* [Chatbot `devfile.yaml`](https://github.com/redhat-appstudio/ai-sample-chatbot-dance/blob/main/devfile.yaml)
* [Chatbot `Containerfile`](https://github.com/redhat-appstudio/ai-sample-chatbot-dance/blob/main/Containerfile)

1. The `devfile.yaml` file has an [`image-build` component](https://github.com/redhat-appstudio/ai-sample-chatbot-dance/blob/main/devfile.yaml#L21-L27) that points to your `Containerfile`.
2. The [`Containerfile`](https://github.com/redhat-appstudio/ai-sample-chatbot-dance/blob/main/Containerfile) contains the instructions you need to build the code sample as a container image.
3. The `devfile.yaml` [`kubernetes-deploy` component](https://github.com/redhat-appstudio/ai-sample-chatbot-dance/blob/main/devfile.yaml#L28-L40) points to a `deploy.yaml` file that contains instructions for deploying the built container image.
4. The `devfile.yaml` [`deploy` command](https://github.com/redhat-appstudio/ai-sample-chatbot-dance/blob/main/devfile.yaml#L48-L55) completes the [outerloop](https://devfile.io/docs/2.2.2/innerloop-vs-outerloop) deployment phase by pointing to the `image-build` and `kubernetes-deploy` components to create your application.

### Additional resources
* For more information about the Chatbot AI Sample, see [redhat-ai-dev/ai-lab-samples repository](https://github.com/redhat-ai-dev/ai-lab-samples) or [Chatbot application document](https://github.com/redhat-ai-dev/ai-lab-template/blob/main/templates/chatbot/docs/application.md).
* For more information about devfiles, see [Devfile.io](https://devfile.io/).
* For more information about Containerfiles, see [Containerfile reference](https://github.com/containers/common/blob/main/docs/Containerfile.5.md).
