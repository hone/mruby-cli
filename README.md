# mruby CLI
A utility for setting up a CLI with [mruby](https://www.mruby.org) for compiling binaries for Linux, OS X, and Windows.

## Docker Setup
You'll need [Docker](https://docs.docker.com/installation/) and [Docker Compose](https://docs.docker.com/compose/install/) installed first.

## Building a CLI app
This assumes you have a copy of the `mruby-cli` binary in your `PATH`.

To generate a new mruby CLI, there's a `--setup` option.

```sh
$ mruby-cli --setup <app name>
```

This will generate a folder `<app name>` containing a basic skeleton for getting started. Once you're in the folder, you can build all the binaries:

```sh
$ docker-compose run compile
```

You'll be able to find the binaries in the following directories:

* Linux: `mruby/build/host/bin`
* OS X: `mruby/build/x86_64-apple-darwin14/bin/`
* Windows: `mruby/build/x86_64-w64-mingw32/bin/`

You should be able to run the respective binary that's native on your platform. There's a `shell` service that can be used as well. In the example below, `mruby-cli --setup hello_world` was run.

```sh
$ docker-compose run shell
root@3da278e931fc:/home/mruby/code# mruby/build/host/bin/hello_world
Hello World
```

### Testing
By default, `mruby-cli` generates tests that go in the `bintest` directory. It'll execute any files in there. These are integration style tests. It tests the status and output of the host binary inside a docker container. To run them just execute:

```sh
$ docker-compose run bintest
```

Unit testing in mruby can by accomplished using [`mruby-mtest`](https://github.com/iij/mruby-mtest).

### CLI Architecture
The app is built from two parts a C wrapper in `tools/` and a mruby part in `mrblib/`. The C wrapper is fairly minimal and executes the `__main__` method in mruby and instantiates ARGV and passes it to the mruby code. The rest of the CLI is written in mruby.

## mruby-cli Development
This app is built as a mruby-cli app, so you just need to run: `docker-compose run compile` and find the binaries in the appropriate directories.
