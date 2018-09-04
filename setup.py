#!/usr/bin/env python

import glob
import itertools
import os

import versioneer
from setuptools import find_packages, setup

try:
    from pip._internal.req import parse_requirements
    from pip._internal.download import PipSession
except ImportError:
    from pip.req import parse_requirements
    from pip.download import PipSession


def setup_requirements(
        patterns=[
            'requirements.txt', 'requirements/*.txt', 'requirements/*.pip'
        ],
        combine=True,
):
    """
    Parse a glob of requirements and return a dictionary of setup() options.
    Create a dictionary that holds your options to setup() and update it using this.
    Pass that as kwargs into setup(), viola

    Any files that are not a standard option name (ie install, tests, setup) are added to extras_require with their
    basename minus ext. An extra key is added to extras_require: 'all', that contains all distinct reqs combined.

    If you're running this for a Docker build, set `combine=True`.
    This will set install_requires to all distinct reqs combined.

    Example:
    >>> _conf = dict(
    ...     name='mainline',
    ...     version='0.0.1',
    ...     description='Mainline',
    ...     author='Trevor Joynson <github@trevor.joynson,io>',
    ...     url='https://trevor.joynson.io',
    ...     namespace_packages=['mainline'],
    ...     packages=find_packages(),
    ...     zip_safe=False,
    ...     include_package_data=True,
    ... )
    ... _conf.update(setup_requirements())
    ... setup(**_conf)

    :param str pattern: Glob pattern to find requirements files
    :param bool combine: Set True to set install_requires to extras_require['all']
    :return dict: Dictionary of parsed setup() options
    """
    session = PipSession()

    # Handle setuptools insanity
    key_map = {
        'requirements': 'install_requires',
        'install': 'install_requires',
        'tests': 'tests_require',
        'setup': 'setup_requires',
    }
    ret = {v: [] for v in key_map.values()}
    extras = ret['extras_require'] = {}
    all_reqs = set()

    files = [glob.glob(pat) for pat in patterns]
    files = itertools.chain(*files)

    for full_fn in files:
        # Parse
        reqs = [
            str(r.req)
            for r in parse_requirements(full_fn, session=session)
            # Must match env marker, eg:
            #   yarl ; python_version >= '3.0'
            if r.match_markers()
        ]
        all_reqs.update(reqs)

        # Add in the right section
        fn = os.path.basename(full_fn)
        barefn, _ = os.path.splitext(fn)
        key = key_map.get(barefn)

        if key:
            ret[key].extend(reqs)
            extras[key] = reqs

        extras[barefn] = reqs

    if 'all' not in extras:
        extras['all'] = list(all_reqs)

    if combine:
        extras['install'] = ret['install_requires']
        ret['install_requires'] = list(all_reqs)

    return ret


readme = []
with open('README.rst', 'r') as fh:
    readme = fh.readlines()

_conf = dict(
    name='localshop',
    author='Michael van Tellingen',
    author_email='michaelvantellingen@gmail.com',
    url='http://github.com/mvantellingen/localshop',
    description='A private pypi server including auto-mirroring of pypi.',
    version=versioneer.get_version(),
    cmdclass=versioneer.get_cmdclass(),
    long_description='\n'.join(readme),
    zip_safe=False,
    license='BSD',
    include_package_data=True,
    package_dir={'': 'src'},
    packages=find_packages('src'),
    entry_points={'console_scripts': ['localshop = localshop.runner:main']},
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Framework :: Django',
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'Operating System :: OS Independent',
        'Topic :: Software Development',
        'Topic :: System',
        'Topic :: System :: Software Distribution',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
    ],
)

_conf.update(setup_requirements(combine=False))

if __name__ == '__main__':
    setup(**_conf)
