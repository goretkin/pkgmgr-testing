# eco-npm — local npm registry with Verdaccio

Tests npm package management against a local [Verdaccio](https://verdaccio.org/) registry.

## Setup

### One-time: allow direnv

```sh
cd eco-npm
direnv allow
```

nix-direnv reads `.envrc`, evaluates the flake at `../flake.nix` to get a pinned
Node 22 environment, and caches the result. On subsequent `cd eco-npm` the cached
environment activates instantly.

### One-time: install Verdaccio

```sh
npm ci --prefix registry
direnv reload   # picks up registry/node_modules/.bin now that it exists
```

`npm ci` is deterministic: reads `registry/package-lock.json` exactly, never
resolves anything, fails if the lock file is out of date.

The `.envrc` line `PATH_add registry/node_modules/.bin` runs when direnv
activates (on `cd`), not when `npm ci` runs — so run `direnv reload` after
installing to pick up the newly created binaries.

## Running the registry

```sh
overmind start
```

Starts verdaccio at <http://localhost:4873>. Use `overmind stop` to stop it,
`overmind connect registry` to attach to its logs.

## Populating the registry

```sh
scripts/build-storage
```

Publishes all packages to the running registry, then commit `registry/storage/`
to capture the state in git.

## Installing a package

```sh
cd packages/pkg-a1
npm install     # .npmrc points this at localhost:4873
```

## Directory layout

```
eco-npm/
  registry/
    node_modules/       verdaccio binary and its deps (gitignored)
    package.json        verdaccio listed as a dev dependency
    package-lock.json   pins verdaccio and all transitive deps (~316 packages)
    storage/            verdaccio data (committed)
      pkg-c/
        pkg-c-0.1.0.tgz
        pkg-c-0.2.0.tgz
        package.json    packument: version metadata + SHA checksums
      pkg-a1/
      pkg-b1/
      .verdaccio-db.json
    verdaccio.yaml      verdaccio configuration
  packages/
    pkg-c-v0.1.0/       in the registry (pkg-c@0.1.0)
    pkg-c-v0.2.0/       in the registry (pkg-c@0.2.0)
    pkg-a1/             in the registry; depends on pkg-c@0.1.0
    pkg-b1/             in the registry; depends on pkg-c@0.2.0
    pkg-root1/          installs pkg-a1 and pkg-b1 from the registry
  Procfile              declares registry process for overmind
  scripts/
    build-storage       publishes packages/ to the running registry
  .envrc
  .gitignore
```

### Why are pkg-* packages local-only?

Real packages named `pkg-a`, `pkg-b`, `pkg-c` exist (or existed) on the public
npm registry. Without the `pkg-*` rule in `verdaccio.yaml`, verdaccio would proxy
to npmjs.org and either merge in that data or block local publishes with a 409.


# peer deps situation in NPM

```
(no flag): treet peer deps as "private" deps (npm v1-v2 behavior)
--legacy-peer-deps: ignore peer deps entirely (npm v3–v6 behavior)
default (no flags): enforce at root, warn and work around conflicts in transitive deps (npm v7+ behavior)
--strict-peer-deps: enforce at all levels, fail on any conflict
--force: always produce some tree, overriding conflicts arbitrarily with a warning
```

# commands

```sh
cd pkg-a1
npm install pkg-c@0.1.0
cd pkg-b2
npm install pkg-c@0.2.0
cd pkg-root1
npm install pkg-a1
````

```sh
cd pkg-a2
npm install --save-peer pkg-c@0.1.0
cd pkg-b2
npm install --save-peer pkg-c@0.2.0
```

```sh
cd pkg-root2
npm install pkg-a2
npm install pkg-b2
# expected a conflict here...
```