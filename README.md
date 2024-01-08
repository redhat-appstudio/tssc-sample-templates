#  Dance Sample Backstage Templates


## Samples

These samples have been imported from the RHTAP Devfile Samples and augmented with additional backstage content for demo purposes. The information has come from the devfiles and augmented with more information (tags and docs) for the sample apps as placeholders. 


## Usage in backstage 

Add the following to your `app-config.yaml` file in your backstage configuration 

``` 
    - type: url
      target:  https://github.com/redhat-appstudio/tssc-sample-templates/blob/main/all.yaml
      rules:
        - allow: [Location, Template]
```

This will add the samples into a set of backstage templates.

![Screenshot](backstage.png)


## Conributing

run `./generate.sh` to generate all the templates before commit to this repository

note: if your are on MacOS, the GNU version of `sed` is required to be installed
```
brew install gnu-sed
```
After this, alter PATH. For example, add the following line to your `~/.bash_profile`:
```
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
```