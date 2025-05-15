# Integration tests

This folder is required for running integration tests in the Konflux CI.

Update the values in [default.pict](./pict-models/default.pict) to reflect the PR changes you want to verify by running [rhtap-e2e](https://github.com/redhat-appstudio/rhtap-e2e) tests.

```
Registry: quay.io
SCM: github
Pipeline: actions  # If testing "actions" pipeline with PR changes
```

For more details about the pipeline used for integration tests in Konflux, refer to [this link](https://github.com/redhat-appstudio/rhtap-cli/blob/main/integration-tests/README.md#pipelines-used).
