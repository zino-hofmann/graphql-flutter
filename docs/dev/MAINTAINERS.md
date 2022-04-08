# graphql-flutter HACKING guide

## Table of Content

- Introduction
- Code Style
- Commit Style
- How make the release

## Introduction

Welcome in the HACKING guide and how a day in a graphql-flutter maintainer looks like.

After this reading you should be ready to contribute to the repository and also be one of
the next maintainer in the future if you would like!

Let's begin

## Code style

To ensure consistency throughout the source code, keep these rules in mind as you are working:

- All features or bug fixes **must be tested** by one or more specs (unit-tests).
- All public API methods **must be documented**. (Details TBC).
- We follow [Effective Dart: Style Guidelines][dart-style-guide].

### If You Don’t Know The Right Thing, Do The Simplest Thing
Sometimes the right way is unclear, so it’s best not to spend time on it. It’s far easier to rewrite simple code than complex code, too.

### Use of `FIXME`

There are two cases in which you should use a `/* FIXME: */`
comment: one is where an optimization is possible, but it’s not clear that it’s yet worthwhile, 
and the second one is to note an ugly corner case which could be improved (and may be in a following patch).

There are always compromises in code: eventually it needs to ship. `FIXME` is grep-fodder for yourself and others, 
as well as useful warning signs if we later encounter an issue in some part of the code.

### Write For Today: Unused Code Is Buggy Code

Don’t overdesign: complexity is a killer. If you need a fancy data structure, start with a brute force linked list. Once that’s working,
perhaps consider your fancy structure, but don’t implement a generic thing. Use `/* FIXME: ...*/` to salve your conscience.

### Keep Your Patches Reviewable
Try to make a single change at a time. It’s tempting to do “drive-by” fixes as you see other things, and a minimal amount is unavoidable,
but you can end up shaving infinite yaks. This is a good time to drop a `/* FIXME: ...*/` comment and move on.


## Commit Style

The commit style is one of the more important concept to manage a monorepo like graphql-flutter, amd In particular
the commit style are used to generate the changelog for the next release.

The commits will follow a dart community guideline with the following rules.

Each commit message consists of a **header**, a **body** and a **footer**. The header has a special
format that includes a **type**, a **scope** and a **subject**:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

The **header** is mandatory and the **scope** of the header is optional.

Any line of the commit message cannot be longer 100 characters! This allows the message to be easier
to read on GitHub as well as in various git tools.

The footer should contain a [closing reference to an issue](https://help.github.com/articles/closing-issues-via-commit-messages/) if any.

A coupled of examples are:

```
docs(changelog): update changelog to beta.5
```

```
fix(release): need to depend on latest rxjs and zone.js

The version in our package.json gets copied to the one we publish, and users need the latest of these.
```

### Types

- **feat**: A new feature
- **fix**: A bug fix

### Scopes

- **graphql**: Changes related to the graphql client
- **graphql_flutter**: Changes related to the graphql_flutter package


### Subject

The subject contains a succinct description of the change:

- use the imperative, present tense: "change" not "changed" nor "changes"
- don't capitalize the first letter
- no dot (.) at the end

### Body

You are free to put all the content that you want inside the body, but if you are fixing
an exception or some wrong behavior you must put the details or stacktrace inside the body to make sure that
it is indexed from the search engine.

An example of commit body is the following one

```
checker: fixes overloading operation when the type is optimized

The stacktrace is the following one

} expected `Foo` not `Foo` - both operands must be the same type for operator overloading
   11 | }
   12 | 
   13 | fn (_ Foo) == (_ Foo) bool {
      |                  ~~~
   14 |     return true
   15 | }


Signed-off-by: Vincenzo Palazzo <vincenzopalazzodev@gmail.com>
```

## How make the release

This is the most funny part, and also is the most difficult one in a monorepo repository.

In particular, graphql-flutter has the possibility to release one single package at the time, or
all together.

To prepare the release the following steps are required:

- Bump the version number in the package before the release, and the version inside the `changelog.json` in the package root;
- Generate the changelog related to the package:
  - `export GITHUB_TOKEN="your_token"`
  - `make {changelog_client|changelog_flutter|changelog}`, where
      - `changelog_client`: generate the changelog for graphql;
      - `changelog_flutter`: generate the changelog for graphql_flutter;
      - `changelog`: generate both changelos.   
- Make the Github release: To release a single package we need to create a release with the following tag `{package_name}-v{version_number}`, and 
if we make a release with the tag `v{version_number}` this will release all the packages (useful for a major release of the package).



>Programs must be written for people to read, and only incidentally for machines to execute.
>                                                                            - Someone

Cheers!

[Vincent](https://github.com/vincenzopalazzo)