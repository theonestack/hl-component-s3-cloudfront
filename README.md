# s3-cloudfront CfHighlander project
---

## Cfhighlander Setup

install cfhighlander [gem](https://github.com/theonestack/cfhighlander)

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```

compiling the templates

```bash
cfcompile s3-cloudfront
```

compiling with the vaildate fag to validate the templates

```bash
cfcompile s3-cloudfront --validate
```

publish the templates to s3

```bash
cfpublish s3-cloudfront --version latest
```
