#!/bin/bash
set -em
source ../../config/build-util.sh

ensure_bash_4

shopt -s globstar

## Delete the dist folder
rm -rf dist

compile_esm() {
    tsc -p tsconfig.esm.json
    linaria -r dist/esm/ -m esnext -o dist/esm/ dist/esm/**/*.js -t -i dist/esm -c ../../config/linaria.json
    remove_all_css_imports dist/esm
}

compile_cjs() {
    tsc -p tsconfig.cjs.json
    linaria -r dist/cjs/ -m commonjs -o dist/cjs/ dist/cjs/**/*.js -t -i dist/cjs -c ../../config/linaria.json
    ## run babel on cjs files
    babel dist/cjs --out-dir dist/cjs --extensions '.js' --config-file ../../babel.config.json
    remove_all_css_imports dist/cjs
}

run_in_parallel compile_esm compile_cjs


## Rename all .js files to .cjs in the dist/cjs/ folder
for file in dist/cjs/**/*.js; do
  cp -- "$file" "${file%.js}.cjs"
done
for file in dist/cjs/**/*.js.map; do
  cp -- "$file" "${file%.js.map}.cjs.map"
done
## Replace all local ./**/*.js imports with ./**/*.cjs in the dist/cjs/ folder
## Ignore the import path that does not start with ./
find dist/cjs -name '*.cjs' -exec sed -i -e 's|require("\(\.[^"]*\)\.js")|require("\1.cjs")|g' {} \;

generate_index_css