# Security Policy

## Reporting a vulnerability

Report security issues privately to **security@alltuner.com**, or open a
[private vulnerability report](https://github.com/alltuner/factoryfloor/security/advisories/new)
on GitHub.

Please do not open a public issue for a security problem.

Useful things to include, as far as you have them:

- What an attacker can do, and what they need in order to do it
- The steps you actually verified, and the version or commit you tested
- Anything that helps reproduce it: a config file, a sample repository, a recording

You can expect an acknowledgement within three working days and an assessment
within a week. We will tell you what we found, what we intend to change, and
when we expect to ship it. If we disagree that something is a vulnerability we
will explain why rather than going quiet.

## Disclosure

We ask that you hold the details until a fixed release is out. After that,
publish whatever you like; we publish an advisory ourselves.

Reporters are credited in the release notes and in the GitHub advisory, with
whatever attribution they prefer, or anonymously if they would rather. Tell us
which. If you want a CVE, say so and we will coordinate.

## Supported versions

Fixes go into the latest release. There are no long-term support branches.

## Scope notes

Factory Floor runs coding agents, terminals, and dev servers on your machine, so
some behaviour that looks alarming is intended:

- **A terminal runs the commands you type.** That is the product.
- **The Coding Agent can modify files and run commands.** Its own permission
  prompts are the boundary, and turning on "Bypass permission prompts" removes
  that boundary deliberately.
- **Repository-provided `setup`, `run`, and `teardown` commands require your
  approval before they run.** Factory Floor reads them from `.factoryfloor.json`
  and from the `.emdash.json`, `conductor.json`, and `.superset/config.json`
  fallbacks. It shows you the commands and the file they came from, runs nothing
  until you approve, and asks again when the commands change. A path that
  executes any of them without approval is a vulnerability; please report it.

Anything that runs code from a repository without the user agreeing to it is in
scope, whatever the mechanism.
