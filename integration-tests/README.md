# Integration tests

This folder is required for running integration tests in the Konflux CI.

- The [rhads-config](./config/rhads-config) file specifies the components to be integrated during the installation of RHADS using [rhtap-cli](https://github.com/redhat-appstudio/rhtap-cli).

- The [testplan.json](./config/testplan.json) file contains the component matrix used to run [tssc-tests](https://github.com/redhat-appstudio/tssc-test).

- Modify testplan.json file to match your testing requirements. Refer [here](https://github.com/redhat-appstudio/tssc-test/blob/main/README.md#configuration-fields) for valid values of each component.

For more details about the pipeline used for integration tests in Konflux, refer to [this link](https://github.com/redhat-appstudio/rhtap-cli/blob/main/integration-tests/README.md#pipelines-used).