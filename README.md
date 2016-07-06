# Diffshot

## Description
This script takes screenshots of every file diff through a Git repo's commit history, and outputs a markdown file containing the commit history with its images, annotations, and table of contents.

**[See this example, created with this repo.](_DIFFSHOTS.md)**

> Note: The links in the table of contents don't take into account the possibility of multiple commits having the same commit message. So be a good developer and make each commit message unique!

## Installation

#### 1. Install ImageMagick

```bash
$ brew install imagemagick
```

#### 2. Install system fonts in ImageMagick

```bash
$ cd $(dirname $(which convert))
$ cd $(dirname $(readlink $(which convert)))
$ cd ../etc/ImageMagick-6/
$ curl http://www.imagemagick.org/Usage/scripts/imagick_type_gen > find_fonts.sh
$ perl find_fonts.sh > type.xml
```

> This downloads a script that scans your system for fonts and compiles them into `type.xml`, which ImageMagick can parse. The end result should be `type.xml` exists on a path like `/usr/local/Cellar/imagemagick/6.9.3-0_2/etc/ImageMagick-6`

#### 3. Install Diffshot

```
$ gem install diffshot
```

#### 4. Try it out

Go to some Github repo, type `diffshot`, and you should see it print out the commits and files as it goes through them.

At the end, you'll have a [_DIFFSHOTS](/_DIFFSHOTS) folder with a bunch of images inside it, and a [_DIFFSHOTS.md](/_DIFFSHOTS.md)! Each image is named with this convention:

```
commit-message.file-name.png
```

(Non-alphanumeric characters are removed or replaced with `-`.)

#### Options

`$ diffshot hash..hash`

As with `git diff` and `git log`, you can pass a range of hashes to `diffshot` and it will iterate only over that range.

## Contributing

Yes, please!
