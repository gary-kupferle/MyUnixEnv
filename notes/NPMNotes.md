# NPM Notes

To browse the home page of an npm package
* npm home {name}
  * defaults to GitHub README.md

To browse the Github repo of an npm package
* npm repo {name}

To list any outdated dependencies in package.json in the current directory
* npm outdated

To list packages in node_modules that are
not listed as dependencies in package.json
and delete those directories from node_modules
* npm prume

To lock down dependencies to their current version
* npm shrinkwrap (generates npm-shrinkwrap.json)
* probably better to use yarn!

To install only regular dependencies, excluding devDependencies
* npm install --production

To list globally installed packages
* npm ls -g --depth 0

To change the log level for npm
* npm config set loglevel {level}
* valid levels are silent, error, warn, http, info, verbose, and silly

To change a package directory under node_modules to be a
symbolic link to a local directory for that package
for debugging purposes
* cd to directory with code to be debugged
* npm link
* cd to directory of code that has that as a dependency
* npm link {dependency-name}
