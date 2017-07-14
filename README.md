# perfportsite
Website for Office of Science Performance Portability Across ALCF, NERSC, OLCF Facilities

## How to contribute

### Setup 

The site is built with the [mkdocs](http://www.mkdocs.org) static site generator, which is based on Markdown. 

1. Setup up the local environment 

`pip install --user -r requirements.txt`

2. Run a local server for a live preview of changes

`mkdocs serve`

3. Output a static site

`mkdocs build`

### Publishing

The site is deployed with `mkdocs gh-deploy`. This command should **only** be run from the master branch after you have merged any changes.

### Demo syntax

Please see docs/demo/ for some basic examples of LaTeX, source inclusion, etc.
