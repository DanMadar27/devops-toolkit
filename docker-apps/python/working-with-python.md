by default, `pip3 install <package>` with not work for caution reasons to avoid breaking Ubuntu python packages.
So can use `pip3 install <package> --break-system-packages` to force it.

But it is recommended to use a virtual environment for working with Python.
`PyCharm` handles it automatically, so work with `PyCharm` on Python projects.

If can't use PyCharm you can create a python virtual environment using:

```bash
python3 -m venv .venv
```

Then install dependencies:

```bash
.venv/bin/pip3 install <package>
```

And run your project:

```bash
.venv/bin/python3 main.py
```
