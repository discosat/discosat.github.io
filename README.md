# Documentation example

We use this example in the lesson
[How to document your research software](https://coderefinery.github.io/documentation/).

## Host the project for local development
Generating the documentation pages is based on [sphinx](https://www.sphinx-doc.org/en/master/) and the [sphinx_rtd_theme](https://sphinx-rtd-theme.readthedocs.io/en/stable/).

### Docker
For convenience, a [docker](https://www.docker.com/)-based setup is provided here. To get started, simply run:
```bash
docker compose up
```
after which the documentation pages will be hosted *with hot reload* on 127.0.0.1:8000

### Python
The following [PyPI](https://pypi.org/) packages are required:
- [Sphinx](https://pypi.org/project/Sphinx/)
- [sphinx_rtd_theme](https://pypi.org/project/sphinx-rtd-theme/)
- [myst_parser](https://pypi.org/project/myst_parser/)

When these are installed in your environment, you can run:
```bash
sphinx-build doc _build
python -m http.server 8000 --directory _build
```
after which the documentation pages will be hosted on 127.0.0.1:8000
