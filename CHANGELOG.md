# Changelog

## [0.1.80](https://github.com/AndresGonzalez5/vibefloor/compare/v0.1.79...v0.1.80) (2026-09-06)


### Features

* add activity indicators and compact sidebar layout ([#406](https://github.com/AndresGonzalez5/vibefloor/issues/406)) ([e5fcb7e](https://github.com/AndresGonzalez5/vibefloor/commit/e5fcb7ee83c61e6eed3e8aa0456c1e9610738364)), closes [#399](https://github.com/AndresGonzalez5/vibefloor/issues/399)
* add anonymous usage telemetry via self-hosted Umami ([#186](https://github.com/AndresGonzalez5/vibefloor/issues/186)) ([392848c](https://github.com/AndresGonzalez5/vibefloor/commit/392848cfa8da966016f01bf7cc502f08ef59671f))
* add Changes tab with live git diff review and files-changed sidebar ([#6](https://github.com/AndresGonzalez5/vibefloor/issues/6)) ([ef4643f](https://github.com/AndresGonzalez5/vibefloor/commit/ef4643f94f0dc5b158fe95cb4d3096b3241eb17d))
* add emdash config support, FF_DEFAULT_BRANCH, and compatibility env var aliases ([#367](https://github.com/AndresGonzalez5/vibefloor/issues/367)) ([1bd820c](https://github.com/AndresGonzalez5/vibefloor/commit/1bd820c20e85f04b20c649764ce3f2670c590233))
* add file editor with Monaco integration ([#389](https://github.com/AndresGonzalez5/vibefloor/issues/389)) ([969d5c1](https://github.com/AndresGonzalez5/vibefloor/commit/969d5c10e6d9f0b2f5405ed48e5f1b582ca20e8f))
* add file-based logging for setup, run, and teardown scripts ([#198](https://github.com/AndresGonzalez5/vibefloor/issues/198)) ([949cf67](https://github.com/AndresGonzalez5/vibefloor/commit/949cf674bf60aba5b57d01bddf667ef39bd0ef64))
* add full build command for pixel-agents + app build and run ([0782ac6](https://github.com/AndresGonzalez5/vibefloor/commit/0782ac64ba6403e0cbb93869432bbcbdcd67c6ca))
* add German (de) localization for app and website ([#383](https://github.com/AndresGonzalez5/vibefloor/issues/383)) ([20d82a8](https://github.com/AndresGonzalez5/vibefloor/commit/20d82a8bf871d281ab2abf7bfcb7d8a775a39227))
* add keyboard shortcuts for Rebuild (⌃⇧S) and Start/Rerun (⌃⇧R) ([9d04703](https://github.com/AndresGonzalez5/vibefloor/commit/9d047035118f36bd3b435716ea1aa8460c161231))
* add launch at login toggle in Settings ([#227](https://github.com/AndresGonzalez5/vibefloor/issues/227)) ([6c5dd43](https://github.com/AndresGonzalez5/vibefloor/commit/6c5dd43e957001e675a9ba4ebb5fa92ab1744baa)), closes [#224](https://github.com/AndresGonzalez5/vibefloor/issues/224)
* add maintainer credit to sidebar and help screen ([8d423c9](https://github.com/AndresGonzalez5/vibefloor/commit/8d423c95e33694243848097c6e5caa5cf5625e88))
* add multi-harness support with OpenCode alongside Claude Code ([#14](https://github.com/AndresGonzalez5/vibefloor/issues/14)) ([84b22f2](https://github.com/AndresGonzalez5/vibefloor/commit/84b22f24f578337bff2b9dd53e77ad2678cd1313))
* add Open on GitHub button for projects with GitHub remotes ([#330](https://github.com/AndresGonzalez5/vibefloor/issues/330)) ([9c7c7f5](https://github.com/AndresGonzalez5/vibefloor/commit/9c7c7f5dcd28c12059c16018b6d0f483d4bc175c))
* add pixel agents panel with real-time Claude Code visualization ([63d09f8](https://github.com/AndresGonzalez5/vibefloor/commit/63d09f8d196d2bdbb6e68010a35dfa572a5a6f83))
* add Reveal in Finder and Open in External Terminal to sidebar context menus ([#310](https://github.com/AndresGonzalez5/vibefloor/issues/310)) ([775e188](https://github.com/AndresGonzalez5/vibefloor/commit/775e188b4b85706e59ed70e6782dca4e7b0aef1c))
* add run-script port detection ([360e453](https://github.com/AndresGonzalez5/vibefloor/commit/360e45343c411574bea435565b4027b957458655))
* add Sentry crash reporting, update privacy policy ([5a2f954](https://github.com/AndresGonzalez5/vibefloor/commit/5a2f9547eafb1c6378eb037c54f6bd4a863aa464))
* add setting to restrict agent filesystem writes to worktree ([#358](https://github.com/AndresGonzalez5/vibefloor/issues/358)) ([188d1ec](https://github.com/AndresGonzalez5/vibefloor/commit/188d1ecc1bf80fe6f7b201dcb2b6a66a7b204a13))
* add setup worker pixel agent and fix char_0 source of truth ([824f923](https://github.com/AndresGonzalez5/vibefloor/commit/824f9237e4e2765377bf3f26746f01d503f94756))
* add Spaces to group projects in the sidebar ([0a13367](https://github.com/AndresGonzalez5/vibefloor/commit/0a13367687374f907af2f8528f8d498a2112fdea))
* add Sparkle auto-update ([#39](https://github.com/AndresGonzalez5/vibefloor/issues/39)) ([#80](https://github.com/AndresGonzalez5/vibefloor/issues/80)) ([83acde7](https://github.com/AndresGonzalez5/vibefloor/commit/83acde778dce1d4963c1f06c7f83087ba303ecb1))
* add terraform/volume/prisma symlinks, default to development branch ([af8b2ec](https://github.com/AndresGonzalez5/vibefloor/commit/af8b2ece11e3727bcfd82ceca795e06ea8b7c04f))
* add worktree detail inspection with change viewer and force-remove ([d754749](https://github.com/AndresGonzalez5/vibefloor/commit/d75474997c213c4a6fc9c2571a47692aba59a504))
* adopt existing worktrees as workstreams and enrich worktree status ([#313](https://github.com/AndresGonzalez5/vibefloor/issues/313)) ([7f09a3f](https://github.com/AndresGonzalez5/vibefloor/commit/7f09a3f4074e802478e4a67be10e551456a179b6))
* auto-fetch origin/main before worktree creation ([#257](https://github.com/AndresGonzalez5/vibefloor/issues/257)) ([cfa8dc6](https://github.com/AndresGonzalez5/vibefloor/commit/cfa8dc640decdad5d7816f6a3826f79c5370885a)), closes [#253](https://github.com/AndresGonzalez5/vibefloor/issues/253)
* automate versions.json update in release workflow ([a5bfb02](https://github.com/AndresGonzalez5/vibefloor/commit/a5bfb02d799fc4578cd2f6f7a407b7de394e5a57))
* background fetch of origin default branch every 2 minutes ([#320](https://github.com/AndresGonzalez5/vibefloor/issues/320)) ([cd73dc5](https://github.com/AndresGonzalez5/vibefloor/commit/cd73dc5dd8b7ed722e420001834ed1ce8729ffed))
* bring pixel agents to life with tile grid, pathfinding, and animations ([3f151e9](https://github.com/AndresGonzalez5/vibefloor/commit/3f151e92cb49937f48f316123a7101fabfb4d761))
* **browser:** start the dev server on demand from a browser tab ([#11](https://github.com/AndresGonzalez5/vibefloor/issues/11)) ([ee0dc0d](https://github.com/AndresGonzalez5/vibefloor/commit/ee0dc0d18ddce6deaf53dcf28cc008f55f29c3ad))
* cache pixel agents WKWebViews across workstream switches ([45b7447](https://github.com/AndresGonzalez5/vibefloor/commit/45b744769f828b628c046c12d3a7f2f9a06e3040))
* **changes:** copy file path from sidebar and diff headers ([#10](https://github.com/AndresGonzalez5/vibefloor/issues/10)) ([be7ffb9](https://github.com/AndresGonzalez5/vibefloor/commit/be7ffb9715aa356f90b1879c7c15227b9c9220eb))
* **changes:** vscode-style inline edits, open-in-editor, git-aware delete, cmd+s ([#23](https://github.com/AndresGonzalez5/vibefloor/issues/23)) ([ceb8804](https://github.com/AndresGonzalez5/vibefloor/commit/ceb880424ebd98ebc29fa8eaa9a24677f7d2dd8d))
* Cmd+Click opens links in external browser and fix HTTP redirects ([#331](https://github.com/AndresGonzalez5/vibefloor/issues/331)) ([599253a](https://github.com/AndresGonzalez5/vibefloor/commit/599253a66066cc1ae4b586a3d04392bc7d9f7db2))
* collapse doc tabs by default and pin to bottom of info views ([#315](https://github.com/AndresGonzalez5/vibefloor/issues/315)) ([7c38c6e](https://github.com/AndresGonzalez5/vibefloor/commit/7c38c6eb55c50c947a4b07143e35c0cff26e8974))
* consolidate GitHub actions into contextual dropdown ([#405](https://github.com/AndresGonzalez5/vibefloor/issues/405)) ([fbfaabf](https://github.com/AndresGonzalez5/vibefloor/commit/fbfaabff259af0a4e9dd8082131b803b7016f7ee)), closes [#398](https://github.com/AndresGonzalez5/vibefloor/issues/398)
* credit contributors in release changelog entries ([#410](https://github.com/AndresGonzalez5/vibefloor/issues/410)) ([47817e9](https://github.com/AndresGonzalez5/vibefloor/commit/47817e954a90c0bf3b59004341a9986e2d4bf9ba))
* detect merged PRs and show archive prompt for completed workstreams ([#316](https://github.com/AndresGonzalez5/vibefloor/issues/316)) ([4c062ad](https://github.com/AndresGonzalez5/vibefloor/commit/4c062ad5f7b5d2b0a598058b7a6b1df1df346ddc))
* direct DMG download and styled installer ([#225](https://github.com/AndresGonzalez5/vibefloor/issues/225)) ([8fbafdf](https://github.com/AndresGonzalez5/vibefloor/commit/8fbafdfd7d1fc3dc0fa3c45de8d943b17d95b3cb))
* display agent-generated task descriptions in sidebar ([#336](https://github.com/AndresGonzalez5/vibefloor/issues/336)) ([6bac1fe](https://github.com/AndresGonzalez5/vibefloor/commit/6bac1fe9d625cd9710dd58433f9b79a867cca8b8))
* display app version on welcome screen and centralize version access ([#125](https://github.com/AndresGonzalez5/vibefloor/issues/125)) ([85d8856](https://github.com/AndresGonzalez5/vibefloor/commit/85d8856429c013bd125e94131496b9045eb355c9))
* **editor:** quick-open file finder (Cmd+P) and copy file path (Cmd+Shift+C) ([#8](https://github.com/AndresGonzalez5/vibefloor/issues/8)) ([da70868](https://github.com/AndresGonzalez5/vibefloor/commit/da708684937f82351029a6f305d1989f6a190616))
* handle ghostty desktop notifications and bell actions ([#264](https://github.com/AndresGonzalez5/vibefloor/issues/264)) ([fde32f5](https://github.com/AndresGonzalez5/vibefloor/commit/fde32f563e40bb00643dc0721043c774b3b1ef04))
* improve terminal spawning resilience ([#235](https://github.com/AndresGonzalez5/vibefloor/issues/235)) ([8313c13](https://github.com/AndresGonzalez5/vibefloor/commit/8313c13a03134c3800248c06a520afa7cee73c2d))
* improve update experience for Homebrew users ([#246](https://github.com/AndresGonzalez5/vibefloor/issues/246)) ([c4db1d2](https://github.com/AndresGonzalez5/vibefloor/commit/c4db1d2b8fce6d2ca8f6967ac2d1a6d54d810418))
* localize NS*UsageDescription privacy strings via InfoPlist.strings ([#173](https://github.com/AndresGonzalez5/vibefloor/issues/173)) ([98d4358](https://github.com/AndresGonzalez5/vibefloor/commit/98d4358733484b8be59a7a001aa73ce0b206438d)), closes [#172](https://github.com/AndresGonzalez5/vibefloor/issues/172)
* make run play icons clickable and style center start button ([#328](https://github.com/AndresGonzalez5/vibefloor/issues/328)) ([0007372](https://github.com/AndresGonzalez5/vibefloor/commit/0007372a18fb6e6a729ec39102602b2340fd8fe2))
* overhaul Changes tab with lazy diffs, unified load gate, and review state ([#20](https://github.com/AndresGonzalez5/vibefloor/issues/20)) ([e0ee3b3](https://github.com/AndresGonzalez5/vibefloor/commit/e0ee3b3ae815b01ff7e9172abd4863f056b6a666))
* per-workstream debug log files for launches ([#247](https://github.com/AndresGonzalez5/vibefloor/issues/247)) ([5c156f5](https://github.com/AndresGonzalez5/vibefloor/commit/5c156f5b27d9029d270b71dbd236a7aeab5b7ff0))
* personify workstream agents in the sidebar with context meters ([#15](https://github.com/AndresGonzalez5/vibefloor/issues/15)) ([5ebf3f7](https://github.com/AndresGonzalez5/vibefloor/commit/5ebf3f7ade61d24671e5a8428e787cb13e8267dd))
* **pixel-agents:** extend office to fill wide screens ([6dca8b4](https://github.com/AndresGonzalez5/vibefloor/commit/6dca8b48d78e6f2f3a8b700d18aa1774a87723fe))
* polish new workstream dialog with branded harness cards ([#17](https://github.com/AndresGonzalez5/vibefloor/issues/17)) ([6a63035](https://github.com/AndresGonzalez5/vibefloor/commit/6a630354d3d9b7c61a69027c5d7bc00dfd8fb864))
* prioritize task description over generated name across all views ([#380](https://github.com/AndresGonzalez5/vibefloor/issues/380)) ([45e66d4](https://github.com/AndresGonzalez5/vibefloor/commit/45e66d46393ab143aa6ec6fefe60ab8b44cbed7c))
* **project-overview:** add Pull button to Repository section ([2c51a7b](https://github.com/AndresGonzalez5/vibefloor/commit/2c51a7baf72064138823ddc1cd4a1af006786899))
* prompt for a workstream name before creating branch and worktree ([#9](https://github.com/AndresGonzalez5/vibefloor/issues/9)) ([9dd49e4](https://github.com/AndresGonzalez5/vibefloor/commit/9dd49e47b1c6e2e67fdbf3b354573eede096f323))
* quick actions, workspace UI improvements, and settings redesign ([#307](https://github.com/AndresGonzalez5/vibefloor/issues/307)) ([3842c21](https://github.com/AndresGonzalez5/vibefloor/commit/3842c21dd4be4877f82ed35b4e232a42b6c34857))
* rebind navigation to Opt+Cmd+arrows ([73b4ce3](https://github.com/AndresGonzalez5/vibefloor/commit/73b4ce3f9aa79fbd4b23c3f5636a73f2e6386d1e))
* rebind Toggle Pixel Agents from Cmd+Shift+P to Cmd+J ([c7ca615](https://github.com/AndresGonzalez5/vibefloor/commit/c7ca6157b07f5e298d5804f5842f8bdcfa896862))
* redesign workstream info page with native macOS grouped form ([#360](https://github.com/AndresGonzalez5/vibefloor/issues/360)) ([6ed3ac9](https://github.com/AndresGonzalez5/vibefloor/commit/6ed3ac951944ec612e6afaeb21b7f7c3d97cda2f))
* reorganize workspace tabs with Info as first tab ([#407](https://github.com/AndresGonzalez5/vibefloor/issues/407)) ([83cacaa](https://github.com/AndresGonzalez5/vibefloor/commit/83cacaaa6c989e27d70c8a310fb353decb88674d)), closes [#400](https://github.com/AndresGonzalez5/vibefloor/issues/400)
* replace pixel agents panel with sidebar agent roster ([#13](https://github.com/AndresGonzalez5/vibefloor/issues/13)) ([4df25a7](https://github.com/AndresGonzalez5/vibefloor/commit/4df25a7747f6f40af20591758da14664763fea9f))
* replace TranscriptWatcher with Claude Code hooks for pixel agent animations ([aeb8ca3](https://github.com/AndresGonzalez5/vibefloor/commit/aeb8ca390753babdd999ff3c9e4d63b10a42ea09))
* resolve git worktree paths to main repository when adding projects ([#127](https://github.com/AndresGonzalez5/vibefloor/issues/127)) ([780f26d](https://github.com/AndresGonzalez5/vibefloor/commit/780f26dafed1dc65aaf5fd4f95bca8ad79fb10fc))
* restore workspace tab state ([493facb](https://github.com/AndresGonzalez5/vibefloor/commit/493facb5ca593dc750b09c4a539615f6ce026ad6))
* restructure office layout with centered boss workstation ([b133b25](https://github.com/AndresGonzalez5/vibefloor/commit/b133b259efeb30ad4b1675b133d0748e342e6ab9))
* **roster:** show richer OpenCode subagent names inline ([#16](https://github.com/AndresGonzalez5/vibefloor/issues/16)) ([96c1238](https://github.com/AndresGonzalez5/vibefloor/commit/96c12383c5e95c6e7bc6bb485eb071842383d14f))
* setup agent works at desk during workstream setup and reports to Claude ([8358e55](https://github.com/AndresGonzalez5/vibefloor/commit/8358e553410635d70550c1a62b84e9bafda6f47e))
* setup script as blocking gate, tmux restore, menu cleanup ([#382](https://github.com/AndresGonzalez5/vibefloor/issues/382)) ([15d74b1](https://github.com/AndresGonzalez5/vibefloor/commit/15d74b19c6fbbd8c593e178792d4166fb4a4c7d1))
* show changelog in Sparkle update window ([#200](https://github.com/AndresGonzalez5/vibefloor/issues/200)) ([3daf92a](https://github.com/AndresGonzalez5/vibefloor/commit/3daf92af357e5f69ed804a5f9c388019e21b231b))
* show changelog in Sparkle update window ([#206](https://github.com/AndresGonzalez5/vibefloor/issues/206)) ([e32562c](https://github.com/AndresGonzalez5/vibefloor/commit/e32562cb719a3a3c674687e47cca89d6fe5bfd90))
* show cumulative changelog in update popover ([#418](https://github.com/AndresGonzalez5/vibefloor/issues/418)) ([12caa50](https://github.com/AndresGonzalez5/vibefloor/commit/12caa50d83bdcc7e585ec722fd243de1ce8b041d))
* show port indicator in sidebar and title bar ([#119](https://github.com/AndresGonzalez5/vibefloor/issues/119)) ([#123](https://github.com/AndresGonzalez5/vibefloor/issues/123)) ([cdb1731](https://github.com/AndresGonzalez5/vibefloor/commit/cdb1731c8c7b00a231c081a637a314421e540ff4))
* show task description in workstream title subtitle ([#339](https://github.com/AndresGonzalez5/vibefloor/issues/339)) ([3b475a9](https://github.com/AndresGonzalez5/vibefloor/commit/3b475a9e1de70060033e9257b03c043662e83964))
* show workstream description tooltip on sidebar hover ([#350](https://github.com/AndresGonzalez5/vibefloor/issues/350)) ([a89d090](https://github.com/AndresGonzalez5/vibefloor/commit/a89d090e42d35786840de2d211693dddbb47a71a))
* **sidebar:** add user-driven workstream rename (display-only) ([b908392](https://github.com/AndresGonzalez5/vibefloor/commit/b908392852931ce86954555b221cce27b78d3ad2))
* **sidebar:** show Claude agent state on each workstream ([a46ade3](https://github.com/AndresGonzalez5/vibefloor/commit/a46ade38e86558d77d0bf926e2bbd888019f153c))
* support conductor.json and superset config as script fallbacks ([#261](https://github.com/AndresGonzalez5/vibefloor/issues/261)) ([0a4f0bc](https://github.com/AndresGonzalez5/vibefloor/commit/0a4f0bc32c522b6053d843df1c3c0cc7f5076894)), closes [#256](https://github.com/AndresGonzalez5/vibefloor/issues/256)
* support drag-and-drop of files and text onto embedded terminal ([#312](https://github.com/AndresGonzalez5/vibefloor/issues/312)) ([1d568a6](https://github.com/AndresGonzalez5/vibefloor/commit/1d568a6602e9368a34396e780a4054e57e5957ab))
* sync terminal color scheme with system dark/light mode ([#362](https://github.com/AndresGonzalez5/vibefloor/issues/362)) ([a6dd299](https://github.com/AndresGonzalez5/vibefloor/commit/a6dd299c2fc3280d95847df51846fbd8447bae57)), closes [#359](https://github.com/AndresGonzalez5/vibefloor/issues/359)
* **telemetry:** enrich Umami payloads and broaden tracked events ([#450](https://github.com/AndresGonzalez5/vibefloor/issues/450)) ([7648189](https://github.com/AndresGonzalez5/vibefloor/commit/7648189bd5caa57fa884d9d499d79ce448b89e43))
* toggle sidebar with Cmd+Shift+C and move copy file path into editor toolbar ([#12](https://github.com/AndresGonzalez5/vibefloor/issues/12)) ([c99f947](https://github.com/AndresGonzalez5/vibefloor/commit/c99f9476d70854355195bba7fb37e725a1a77f51))
* update main branch and clean up after purging a workstream ([#369](https://github.com/AndresGonzalez5/vibefloor/issues/369)) ([f20b13c](https://github.com/AndresGonzalez5/vibefloor/commit/f20b13c14f5aed4776cb6315c51bcccd9ea21aeb))
* update pixel agent sprite and debug app icon with Claude orange theme ([01a8120](https://github.com/AndresGonzalez5/vibefloor/commit/01a8120850296cdf5a3147b4fab02cd82b61fa57))
* **website:** add changelog page with timeline layout ([#20](https://github.com/AndresGonzalez5/vibefloor/issues/20)) ([d0b38e5](https://github.com/AndresGonzalez5/vibefloor/commit/d0b38e50c5043a5da22c8525b6145c5c1e1c1c9a))
* **website:** add docs section, issue templates, and improve site navigation ([#342](https://github.com/AndresGonzalez5/vibefloor/issues/342)) ([a20d0f0](https://github.com/AndresGonzalez5/vibefloor/commit/a20d0f0ce7f38c995cdfed8374e0cba456bd536f)), closes [#338](https://github.com/AndresGonzalez5/vibefloor/issues/338)
* **website:** add download button to /get/ page ([#240](https://github.com/AndresGonzalez5/vibefloor/issues/240)) ([3f1b212](https://github.com/AndresGonzalez5/vibefloor/commit/3f1b212fdbdd18aee032053a16642271fe793fb8)), closes [#231](https://github.com/AndresGonzalez5/vibefloor/issues/231)
* **website:** add llms.txt for AI crawler discovery ([#156](https://github.com/AndresGonzalez5/vibefloor/issues/156)) ([1e4fcc2](https://github.com/AndresGonzalez5/vibefloor/commit/1e4fcc2d7fb9c3c2f13eaefd113ce0460c7d000e))
* **website:** embed YouTube demo video in hero section ([#185](https://github.com/AndresGonzalez5/vibefloor/issues/185)) ([fb94c51](https://github.com/AndresGonzalez5/vibefloor/commit/fb94c511f49dd09fdf1b7e3c25a80b347c1bfada))
* **website:** mobile screenshot layout and modal viewer ([#74](https://github.com/AndresGonzalez5/vibefloor/issues/74)) ([#78](https://github.com/AndresGonzalez5/vibefloor/issues/78)) ([7cf81e5](https://github.com/AndresGonzalez5/vibefloor/commit/7cf81e55ed7729cf7aa9f707861f75b5fda547cb))
* **website:** replace terminal simulation with real app screenshots ([93cef2f](https://github.com/AndresGonzalez5/vibefloor/commit/93cef2f0bfa4a003d440926ce2ec714b8b838ee8))
* **worktrees:** purge orphan worktrees from project overview ([d18eab5](https://github.com/AndresGonzalez5/vibefloor/commit/d18eab51b2389640e0caed13141c5d05e587f567))


### Bug Fixes

* add comprehensive debug logging for workspace creation ([#43](https://github.com/AndresGonzalez5/vibefloor/issues/43)) ([#44](https://github.com/AndresGonzalez5/vibefloor/issues/44)) ([9e52aa1](https://github.com/AndresGonzalez5/vibefloor/commit/9e52aa1665b7f1da5c7c8a86a2ef091f5df8d749))
* add privacy entitlements and TCC usage descriptions for embedded terminal ([#171](https://github.com/AndresGonzalez5/vibefloor/issues/171)) ([87c4216](https://github.com/AndresGonzalez5/vibefloor/commit/87c4216482fe07fe5c4797ab6ddf4829b8c0995f)), closes [#167](https://github.com/AndresGonzalez5/vibefloor/issues/167)
* align CFBundleVersion with semver so Sparkle detects updates ([#129](https://github.com/AndresGonzalez5/vibefloor/issues/129)) ([0bcb0aa](https://github.com/AndresGonzalez5/vibefloor/commit/0bcb0aa42c968725bb0efdc76b6f8c0b5b3bf9fd))
* align local release script signing with CI workflow ([#282](https://github.com/AndresGonzalez5/vibefloor/issues/282)) ([76a0dcf](https://github.com/AndresGonzalez5/vibefloor/commit/76a0dcfb7ceaba7d2db25614a1da33d39f3a13d2))
* async worktree creation with loading spinner ([#92](https://github.com/AndresGonzalez5/vibefloor/issues/92), [#87](https://github.com/AndresGonzalez5/vibefloor/issues/87)) ([#101](https://github.com/AndresGonzalez5/vibefloor/issues/101)) ([a0d8580](https://github.com/AndresGonzalez5/vibefloor/commit/a0d858063b742cb2721dfcbefb3f54d7c66842f1))
* auto-focus terminal when selecting workstream from sidebar ([#402](https://github.com/AndresGonzalez5/vibefloor/issues/402)) ([b87395c](https://github.com/AndresGonzalez5/vibefloor/commit/b87395c6cff7f4f33db05a7d6f31d4d092896df3)), closes [#394](https://github.com/AndresGonzalez5/vibefloor/issues/394)
* avoid main-actor notification callback crash ([#289](https://github.com/AndresGonzalez5/vibefloor/issues/289)) ([ec03f7d](https://github.com/AndresGonzalez5/vibefloor/commit/ec03f7d7cd2b1fcce5713de683b84b0060eb2d79))
* avoid stale status pill flashing alongside "Purging…" on worktree row ([28c1dec](https://github.com/AndresGonzalez5/vibefloor/commit/28c1dec55ab76696bc18dfd824f5b23df9b941de))
* break up complex ProjectSidebar body to fix release build failure ([#175](https://github.com/AndresGonzalez5/vibefloor/issues/175)) ([c49002a](https://github.com/AndresGonzalez5/vibefloor/commit/c49002a15646bebb7306db175a5fd0cdf25989c5))
* **browser:** enable passkey support in embedded browser ([#366](https://github.com/AndresGonzalez5/vibefloor/issues/366)) ([e940ffa](https://github.com/AndresGonzalez5/vibefloor/commit/e940ffac87aa5df41142e19edf05873312a7516c))
* **browser:** handle JavaScript alert, confirm, and prompt dialogs ([#184](https://github.com/AndresGonzalez5/vibefloor/issues/184)) ([e4e40bf](https://github.com/AndresGonzalez5/vibefloor/commit/e4e40bfaad9ab6347de3dac5050e7b188158ec68))
* **build:** restore ghostty submodule gitlink ([233c9c8](https://github.com/AndresGonzalez5/vibefloor/commit/233c9c848cdb35f51cf453a609d13614bad57b83))
* bundle ghostty terminfo and shell integration in app resources ([#283](https://github.com/AndresGonzalez5/vibefloor/issues/283)) ([bd4ea71](https://github.com/AndresGonzalez5/vibefloor/commit/bd4ea712cec51ae8d750dfc12afb10500e722eec))
* cache isGitRepo and port state to avoid main-thread I/O in sidebar ([#299](https://github.com/AndresGonzalez5/vibefloor/issues/299)) ([1a9999f](https://github.com/AndresGonzalez5/vibefloor/commit/1a9999f109d4f1a43480424ea85f95aeb972dc84))
* cache WKWebView instances to prevent browser tab reload on switch ([#183](https://github.com/AndresGonzalez5/vibefloor/issues/183)) ([b6bd587](https://github.com/AndresGonzalez5/vibefloor/commit/b6bd587cdb252eb849209af8e9e844449548137a))
* change toggle sidebar shortcut to Cmd+Shift+C ([bb530f1](https://github.com/AndresGonzalez5/vibefloor/commit/bb530f1a32f9fdbb8173d7c689df7e8987de8d4a))
* check Ghostty resources exist before building ([#297](https://github.com/AndresGonzalez5/vibefloor/issues/297)) ([c89ca5a](https://github.com/AndresGonzalez5/vibefloor/commit/c89ca5a2c1b22b472427a605eadc2d1683bb982c)), closes [#284](https://github.com/AndresGonzalez5/vibefloor/issues/284)
* **ci:** add --options=runtime to framework re-signing step ([#108](https://github.com/AndresGonzalez5/vibefloor/issues/108)) ([5dcb866](https://github.com/AndresGonzalez5/vibefloor/commit/5dcb8668426582d6d0c6bc19d085daafc3666dd5))
* **ci:** add actions:write permission for website deploy trigger ([#50](https://github.com/AndresGonzalez5/vibefloor/issues/50)) ([272903b](https://github.com/AndresGonzalez5/vibefloor/commit/272903b156793a96a8182143fe77adaa6ebef1d9))
* **ci:** build ghostty xcframework before release build ([#10](https://github.com/AndresGonzalez5/vibefloor/issues/10)) ([f7be824](https://github.com/AndresGonzalez5/vibefloor/commit/f7be824119e04304c3a9c46ae84eadbb1f63489d))
* **ci:** build Monaco editor before xcodegen in release workflow ([#415](https://github.com/AndresGonzalez5/vibefloor/issues/415)) ([ff7907f](https://github.com/AndresGonzalez5/vibefloor/commit/ff7907fa39f33af6c8c4a289033fae4d91e4f42e))
* **ci:** cache ghostty share dirs needed by xcodegen ([#285](https://github.com/AndresGonzalez5/vibefloor/issues/285)) ([7b243c3](https://github.com/AndresGonzalez5/vibefloor/commit/7b243c30e3f2d1dd5e1111099f2388e9e8b9177d))
* **ci:** correct xcodegen setup action name ([#32](https://github.com/AndresGonzalez5/vibefloor/issues/32)) ([a70ef8a](https://github.com/AndresGonzalez5/vibefloor/commit/a70ef8a0af8672665c46a851870e36257ea6d9db))
* **ci:** download appcast from previous release, not latest ([#423](https://github.com/AndresGonzalez5/vibefloor/issues/423)) ([062b328](https://github.com/AndresGonzalez5/vibefloor/commit/062b328ed43e0db770fdb8f3b67e0fe644c9f405))
* **ci:** enable hardened runtime and secure timestamps for notarization ([#16](https://github.com/AndresGonzalez5/vibefloor/issues/16)) ([5f52d57](https://github.com/AndresGonzalez5/vibefloor/commit/5f52d576c4ac87d1e88f6a002c291f9322fbafe7))
* **ci:** fetch Apple notarization log on failure ([#14](https://github.com/AndresGonzalez5/vibefloor/issues/14)) ([7fc381e](https://github.com/AndresGonzalez5/vibefloor/commit/7fc381ee029486c13ac6e38248396683570c6087))
* **ci:** increase Node heap size for Monaco editor build ([#416](https://github.com/AndresGonzalez5/vibefloor/issues/416)) ([ed37bdb](https://github.com/AndresGonzalez5/vibefloor/commit/ed37bdbf2ee8df457a7a4d967b10a7ed33e24ef9))
* **ci:** keep appcast history when a previous release has no assets ([#492](https://github.com/AndresGonzalez5/vibefloor/issues/492)) ([92eae05](https://github.com/AndresGonzalez5/vibefloor/commit/92eae051519c7e4520f17ce8b58c34ee615cbc86))
* **ci:** make dSYM upload non-blocking for releases ([#133](https://github.com/AndresGonzalez5/vibefloor/issues/133)) ([e73b829](https://github.com/AndresGonzalez5/vibefloor/commit/e73b8299924c5b0a05b6ee0672d7cc2bd1a17a9e))
* **ci:** match local and CI build environments ([#59](https://github.com/AndresGonzalez5/vibefloor/issues/59)), add SPM cache path ([#38](https://github.com/AndresGonzalez5/vibefloor/issues/38)) ([#60](https://github.com/AndresGonzalez5/vibefloor/issues/60)) ([771dc21](https://github.com/AndresGonzalez5/vibefloor/commit/771dc2117f98cc16b0b60ea78c232418c1ad7863))
* **ci:** prevent premature website deploy during releases ([#145](https://github.com/AndresGonzalez5/vibefloor/issues/145)) ([dd2967c](https://github.com/AndresGonzalez5/vibefloor/commit/dd2967c4a3b87a0eb225eaf1ae4797c95761e732))
* **ci:** remove --deep from app re-signing, add debug logging ([#23](https://github.com/AndresGonzalez5/vibefloor/issues/23)) ([d298fb8](https://github.com/AndresGonzalez5/vibefloor/commit/d298fb898d6eb081daf244371c0a735208e175c3))
* **ci:** skip ghostty app bundle build, only emit xcframework ([#12](https://github.com/AndresGonzalez5/vibefloor/issues/12)) ([c5844b3](https://github.com/AndresGonzalez5/vibefloor/commit/c5844b3b9203419281d0f61069b2dcb6307b1d9f))
* **ci:** use correct xcodegen action (xavierLowmiller/xcodegen-action) ([#34](https://github.com/AndresGonzalez5/vibefloor/issues/34)) ([abfcac3](https://github.com/AndresGonzalez5/vibefloor/commit/abfcac320332011b7cd50421a2b02e35fc53928c))
* **ci:** use correct xcodegen-action version tag (1.2.4, no v prefix) ([#36](https://github.com/AndresGonzalez5/vibefloor/issues/36)) ([70e79a6](https://github.com/AndresGonzalez5/vibefloor/commit/70e79a624e090429cb2e1e97a35ff67421dd76ed))
* close button on workspace tabs not intercepting clicks ([#208](https://github.com/AndresGonzalez5/vibefloor/issues/208)) ([e51bd82](https://github.com/AndresGonzalez5/vibefloor/commit/e51bd8233334eb07b0a37fb06dbd1f751683f424))
* close button on workspace tabs not working ([#203](https://github.com/AndresGonzalez5/vibefloor/issues/203)) ([571dab4](https://github.com/AndresGonzalez5/vibefloor/commit/571dab4ded1d133ef66d262d1537c6e44636a744))
* consolidate settings from 7 sections to 4 ([#242](https://github.com/AndresGonzalez5/vibefloor/issues/242)) ([9607073](https://github.com/AndresGonzalez5/vibefloor/commit/9607073d1155333d6c2270ac61b78b005728f361)), closes [#233](https://github.com/AndresGonzalez5/vibefloor/issues/233)
* correct embedded terminal selection coordinates ([80a72db](https://github.com/AndresGonzalez5/vibefloor/commit/80a72db0c546934a7decb958dd458ced558ec72d))
* correct TmuxSessionTests assertions to match actual output ([#138](https://github.com/AndresGonzalez5/vibefloor/issues/138)) ([76dbb87](https://github.com/AndresGonzalez5/vibefloor/commit/76dbb87cae1e2dbb6360dbebf35cf810324a8dae)), closes [#137](https://github.com/AndresGonzalez5/vibefloor/issues/137)
* create empty initial commit on git init to enable worktrees ([#252](https://github.com/AndresGonzalez5/vibefloor/issues/252)) ([656e5f3](https://github.com/AndresGonzalez5/vibefloor/commit/656e5f38a80530fa037b898b6a4a2cc4c0703961))
* create logs directory before revealing in Finder ([#201](https://github.com/AndresGonzalez5/vibefloor/issues/201)) ([86b8344](https://github.com/AndresGonzalez5/vibefloor/commit/86b83444ad8cfa52e93f23d6233feaca0b3208fc))
* deduplicate versions and filter noise in Sparkle changelog ([#425](https://github.com/AndresGonzalez5/vibefloor/issues/425)) ([30c48d9](https://github.com/AndresGonzalez5/vibefloor/commit/30c48d985ac3005582e8257862e8df4e2114089d))
* defer workstream selection to let @Binding propagate ([#43](https://github.com/AndresGonzalez5/vibefloor/issues/43)) ([#52](https://github.com/AndresGonzalez5/vibefloor/issues/52)) ([d687430](https://github.com/AndresGonzalez5/vibefloor/commit/d687430d81728eb84fcd2ba224cf2f665ac0721b))
* delay selection after projects mutation to ensure SwiftUI commits ([#43](https://github.com/AndresGonzalez5/vibefloor/issues/43)) ([#55](https://github.com/AndresGonzalez5/vibefloor/issues/55)) ([ef451ff](https://github.com/AndresGonzalez5/vibefloor/commit/ef451ff0536d632744185b48e7b91657f9418714))
* **deps:** update dependency @codingame/monaco-vscode-all-language-default-extensions to v30.0.1 ([#408](https://github.com/AndresGonzalez5/vibefloor/issues/408)) ([5b7a85f](https://github.com/AndresGonzalez5/vibefloor/commit/5b7a85f79ce63fae62186ac968d98adae574c4e6))
* **deps:** update dependency @codingame/monaco-vscode-api to v30.0.1 ([#409](https://github.com/AndresGonzalez5/vibefloor/issues/409)) ([a8e7f45](https://github.com/AndresGonzalez5/vibefloor/commit/a8e7f45786c779dab7dc0b2479deaf2898b06e33))
* **deps:** update dependency @codingame/monaco-vscode-languages-service-override to v30.0.1 ([#412](https://github.com/AndresGonzalez5/vibefloor/issues/412)) ([55acef4](https://github.com/AndresGonzalez5/vibefloor/commit/55acef4169279f00c1e07ecc04e279cdb655fac7))
* **deps:** update dependency @codingame/monaco-vscode-standalone-css-language-features to v30.0.1 ([#413](https://github.com/AndresGonzalez5/vibefloor/issues/413)) ([522052a](https://github.com/AndresGonzalez5/vibefloor/commit/522052a7565ada24dcf416d21fb9e4cab0065516))
* **deps:** update dependency @codingame/monaco-vscode-standalone-html-language-features to v30.0.1 ([#420](https://github.com/AndresGonzalez5/vibefloor/issues/420)) ([20517fd](https://github.com/AndresGonzalez5/vibefloor/commit/20517fd05a4054ceca73154cf61b527a1d260a31))
* **deps:** update dependency @codingame/monaco-vscode-standalone-json-language-features to v30.0.1 ([#421](https://github.com/AndresGonzalez5/vibefloor/issues/421)) ([821c6b6](https://github.com/AndresGonzalez5/vibefloor/commit/821c6b6c28e64f1a044a15d76a3c5a662dd7a65f))
* **deps:** update dependency @codingame/monaco-vscode-standalone-typescript-language-features to v30.0.1 ([#427](https://github.com/AndresGonzalez5/vibefloor/issues/427)) ([0f8f342](https://github.com/AndresGonzalez5/vibefloor/commit/0f8f3425148fcbebc43f60fbc66a630d807425c6))
* **deps:** update dependency @codingame/monaco-vscode-textmate-service-override to v30.0.1 ([#428](https://github.com/AndresGonzalez5/vibefloor/issues/428)) ([bdaf790](https://github.com/AndresGonzalez5/vibefloor/commit/bdaf79023b939604603c78b6a21b0ee51332b225))
* **deps:** update dependency @codingame/monaco-vscode-theme-defaults-default-extension to v30.0.1 ([#431](https://github.com/AndresGonzalez5/vibefloor/issues/431)) ([13ce269](https://github.com/AndresGonzalez5/vibefloor/commit/13ce269d433784c2a70c65d886258750863f6243))
* **deps:** update dependency @codingame/monaco-vscode-theme-service-override to v30.0.1 ([#432](https://github.com/AndresGonzalez5/vibefloor/issues/432)) ([cbb8137](https://github.com/AndresGonzalez5/vibefloor/commit/cbb8137e5831b987d034287f7f3d4f678204d30f))
* **deps:** update dependency monaco-editor to v30.0.1 ([#434](https://github.com/AndresGonzalez5/vibefloor/issues/434)) ([972fa25](https://github.com/AndresGonzalez5/vibefloor/commit/972fa25353350dd9e484b555c50dd64894dd9587))
* **deps:** update monaco-vscode to v31 ([#459](https://github.com/AndresGonzalez5/vibefloor/issues/459)) ([f1b1347](https://github.com/AndresGonzalez5/vibefloor/commit/f1b1347afb2b7a6694181279cad1e1200c1c2875))
* **deps:** update monaco-vscode to v33 ([#471](https://github.com/AndresGonzalez5/vibefloor/issues/471)) ([8ecc30e](https://github.com/AndresGonzalez5/vibefloor/commit/8ecc30e17e3f81e733805082ad9dc3c2d8c828dd))
* detect CLI tools in fish shell and Nix environments ([#300](https://github.com/AndresGonzalez5/vibefloor/issues/300)) ([2c2c5b1](https://github.com/AndresGonzalez5/vibefloor/commit/2c2c5b1e624fc284e9d86443b7066c8134e87ba1))
* detect Yarn v1 and use correct install flags for worktree setup ([#3](https://github.com/AndresGonzalez5/vibefloor/issues/3)) ([458e896](https://github.com/AndresGonzalez5/vibefloor/commit/458e896cae81a8e678e38b7ed231afca4b407be1))
* differentiate merged vs open PRs and make PR badges clickable in worktree list ([#321](https://github.com/AndresGonzalez5/vibefloor/issues/321)) ([58d9c73](https://github.com/AndresGonzalez5/vibefloor/commit/58d9c7385156090d7a329c2c973b076e81735b97))
* disable update checker in debug builds ([#209](https://github.com/AndresGonzalez5/vibefloor/issues/209)) ([ddb0e54](https://github.com/AndresGonzalez5/vibefloor/commit/ddb0e54414eaf84e82af172e5758025843af75a4))
* disable wait-after-command, fix restart, add favicon sizes ([a0ecbb9](https://github.com/AndresGonzalez5/vibefloor/commit/a0ecbb92e0d11e7e8496776bc152dc6de5b60171))
* discover CLI tools from user's login shell PATH ([#196](https://github.com/AndresGonzalez5/vibefloor/issues/196)) ([b00ae30](https://github.com/AndresGonzalez5/vibefloor/commit/b00ae30edefa0939a67767ec039537ebc3fc4ce1))
* dispatch notification authorization handler to main thread ([#275](https://github.com/AndresGonzalez5/vibefloor/issues/275)) ([fee40fc](https://github.com/AndresGonzalez5/vibefloor/commit/fee40fc4a99acc49d0243ed7d863927af6872202)), closes [#274](https://github.com/AndresGonzalez5/vibefloor/issues/274)
* DMG skyline clipped by Finder status bar ([#424](https://github.com/AndresGonzalez5/vibefloor/issues/424)) ([c087cb9](https://github.com/AndresGonzalez5/vibefloor/commit/c087cb9ede4313aaa3f0f6fcb21739cf73ffc2b3))
* don't double-escape tmux command argument ([#115](https://github.com/AndresGonzalez5/vibefloor/issues/115)) ([91aad5e](https://github.com/AndresGonzalez5/vibefloor/commit/91aad5eca06148d9739f41438fd5ea19e0ab77a5))
* double-quote tmux -e values to handle spaces and special chars ([#94](https://github.com/AndresGonzalez5/vibefloor/issues/94)) ([#104](https://github.com/AndresGonzalez5/vibefloor/issues/104)) ([a31a676](https://github.com/AndresGonzalez5/vibefloor/commit/a31a67668552fa27eba169f3c88a216c466d7b88))
* DRY path standardization and add defer cleanup for archiving ([2e8fc1d](https://github.com/AndresGonzalez5/vibefloor/commit/2e8fc1d3afa0099e37c5a23fc5ccdd0236c0a5ea))
* enable desktop notifications by adding UNUserNotificationCenterDelegate ([#269](https://github.com/AndresGonzalez5/vibefloor/issues/269)) ([0c5d9f1](https://github.com/AndresGonzalez5/vibefloor/commit/0c5d9f14edd352a9f84af8cafa476d2f2fca637f))
* enable extended-keys in tmux config for Shift+Enter support ([#441](https://github.com/AndresGonzalez5/vibefloor/issues/441)) ([4e54e75](https://github.com/AndresGonzalez5/vibefloor/commit/4e54e75d46b9223f599fb8cded1d2e873695712f))
* enable Option+Backspace word deletion in terminal ([3fe1049](https://github.com/AndresGonzalez5/vibefloor/commit/3fe1049ef8778679b60d8737f0aaf6204eef1339))
* explicitly free ghostty surface on restart to prevent launch failures ([a489892](https://github.com/AndresGonzalez5/vibefloor/commit/a4898929fb76a3d7242450ebc2a85505b1ac8d66))
* extend right work area floor zone to cover gap past last desk ([31220d2](https://github.com/AndresGonzalez5/vibefloor/commit/31220d2c48053fd864850600d0e6cc922cf04ecc))
* fade onboarding content so skyline remains visible in small windows ([#245](https://github.com/AndresGonzalez5/vibefloor/issues/245)) ([c0b998c](https://github.com/AndresGonzalez5/vibefloor/commit/c0b998c81827e0321f1cff9dc3e5e8e2ee03eb45))
* Fish 4.0 shell escaping breaks tmux and agent launch ([#324](https://github.com/AndresGonzalez5/vibefloor/issues/324)) ([323d136](https://github.com/AndresGonzalez5/vibefloor/commit/323d136350d1bd803f446d78031403765acb7b69))
* flatten tmux command to single sh -c level, eliminate nested escaping ([#114](https://github.com/AndresGonzalez5/vibefloor/issues/114)) ([c42631f](https://github.com/AndresGonzalez5/vibefloor/commit/c42631f113abf10e71498088391b011705b1cbb6))
* group Monaco VSCode packages in Renovate config ([#439](https://github.com/AndresGonzalez5/vibefloor/issues/439)) ([02e9569](https://github.com/AndresGonzalez5/vibefloor/commit/02e9569ad980d3c61070dd9b25da826353746b36)), closes [#436](https://github.com/AndresGonzalez5/vibefloor/issues/436)
* handle Claude Code versions without --name flag ([#191](https://github.com/AndresGonzalez5/vibefloor/issues/191)) ([18d805b](https://github.com/AndresGonzalez5/vibefloor/commit/18d805ba3c6b6aaec023b35ac91eb3ae01823f48))
* handle notification authorization on main thread ([#287](https://github.com/AndresGonzalez5/vibefloor/issues/287)) ([6376d3a](https://github.com/AndresGonzalez5/vibefloor/commit/6376d3a78e9a630f0bdf4a4d97811d9c18d0f9aa))
* handle notification delivery callback off main thread ([#293](https://github.com/AndresGonzalez5/vibefloor/issues/293)) ([d31f06f](https://github.com/AndresGonzalez5/vibefloor/commit/d31f06fcb42113e420fabb820d7104d237026157))
* hide add-workstream button for non-git projects ([#204](https://github.com/AndresGonzalez5/vibefloor/issues/204)) ([af30344](https://github.com/AndresGonzalez5/vibefloor/commit/af30344d62018e5015936a92576a799d6f67134d))
* hide PR badge on worktree row during purge ([eaa4d8f](https://github.com/AndresGonzalez5/vibefloor/commit/eaa4d8fd0318da9858325043329c0b492b178f26))
* host appcast on website to avoid Sparkle update race condition ([#149](https://github.com/AndresGonzalez5/vibefloor/issues/149)) ([5984c50](https://github.com/AndresGonzalez5/vibefloor/commit/5984c5012a7632df4d59e55bad03309cd5070d5a))
* **i18n:** add the missing German setup gate strings ([#493](https://github.com/AndresGonzalez5/vibefloor/issues/493)) ([fe042f2](https://github.com/AndresGonzalez5/vibefloor/commit/fe042f286f12d70cc4b1102244c9ff493bc968fc))
* increase DMG window height so skyline is visible ([#238](https://github.com/AndresGonzalez5/vibefloor/issues/238)) ([79e9a32](https://github.com/AndresGonzalez5/vibefloor/commit/79e9a32919973d639418d06a71929a0e83f2c360)), closes [#230](https://github.com/AndresGonzalez5/vibefloor/issues/230)
* init ghostty submodule properly instead of symlinking entire directory ([#323](https://github.com/AndresGonzalez5/vibefloor/issues/323)) ([702f786](https://github.com/AndresGonzalez5/vibefloor/commit/702f7867a634311eeff068e8674480add57da143)), closes [#322](https://github.com/AndresGonzalez5/vibefloor/issues/322)
* inject login shell PATH into dependency installer and shell commands ([dc03431](https://github.com/AndresGonzalez5/vibefloor/commit/dc034317683c2df12c7a7f8f84062dda9cd7bd5f))
* inject login shell PATH into terminal environment ([#205](https://github.com/AndresGonzalez5/vibefloor/issues/205)) ([2aa33aa](https://github.com/AndresGonzalez5/vibefloor/commit/2aa33aa111cfafaa42938f8da6009d9971b968ac))
* isolate test config storage from app roster ([e95916c](https://github.com/AndresGonzalez5/vibefloor/commit/e95916cfe38a3ae9807ded916c177e24a35f2328))
* keep agent surface alive when command drifts on workspace re-entry ([#19](https://github.com/AndresGonzalez5/vibefloor/issues/19)) ([7b5fac6](https://github.com/AndresGonzalez5/vibefloor/commit/7b5fac6b3a7225a44f58a48960cfc93e88cf4d1d))
* keep merged PR badge cached across project overview refresh ([96e5e2b](https://github.com/AndresGonzalez5/vibefloor/commit/96e5e2b5c6a3bc34f1444c94729320b3508fe403))
* keep workstream views alive across rapid Cmd+[/] switching ([#372](https://github.com/AndresGonzalez5/vibefloor/issues/372)) ([48642ab](https://github.com/AndresGonzalez5/vibefloor/commit/48642ab80d7cbd348d59e12025e507bb4d1e8120))
* kill dev server process tree and stop phantom Stop/Rerun state ([#22](https://github.com/AndresGonzalez5/vibefloor/issues/22)) ([ff4d093](https://github.com/AndresGonzalez5/vibefloor/commit/ff4d093211f8d1cb431643763c4b40927d12405e))
* let release-please bump version in Info.plist ([#22](https://github.com/AndresGonzalez5/vibefloor/issues/22)) ([1624a40](https://github.com/AndresGonzalez5/vibefloor/commit/1624a40be203c21b3723994b0fe1d3a2d4096fd4))
* localize all user-facing strings in alerts and prune UI ([#88](https://github.com/AndresGonzalez5/vibefloor/issues/88)) ([#103](https://github.com/AndresGonzalez5/vibefloor/issues/103)) ([4fabdb0](https://github.com/AndresGonzalez5/vibefloor/commit/4fabdb0c913eb9d6a31f9e1383cd6a6c12cde95c))
* make wait_after_command per-surface, restore agent respawn ([14689b3](https://github.com/AndresGonzalez5/vibefloor/commit/14689b30a65342a6fb228e5e2418cf30fbfb2dcb))
* match ghostty trackpad scroll speed and momentum ([#263](https://github.com/AndresGonzalez5/vibefloor/issues/263)) ([60996a2](https://github.com/AndresGonzalez5/vibefloor/commit/60996a2e26a8fae0df891e51babbfe527a2bba81)), closes [#262](https://github.com/AndresGonzalez5/vibefloor/issues/262)
* match WKUIDelegate completion handler signatures for concurrency ([#212](https://github.com/AndresGonzalez5/vibefloor/issues/212)) ([9d807a5](https://github.com/AndresGonzalez5/vibefloor/commit/9d807a5213049db058ca715c3d0b2c961a4d1944))
* migrate project storage from JSON files to UserDefaults ([#70](https://github.com/AndresGonzalez5/vibefloor/issues/70)) ([9a86fa5](https://github.com/AndresGonzalez5/vibefloor/commit/9a86fa5c14adacbfdaf111b58f31663a27924a59)), closes [#46](https://github.com/AndresGonzalez5/vibefloor/issues/46)
* migrate project storage from JSON files to UserDefaults ([#72](https://github.com/AndresGonzalez5/vibefloor/issues/72)) ([4a88ebe](https://github.com/AndresGonzalez5/vibefloor/commit/4a88ebe497b782bbd02ad4ffd6f1a4195f3f9551)), closes [#46](https://github.com/AndresGonzalez5/vibefloor/issues/46)
* move ghostty callbacks out of main actor init ([a0ec131](https://github.com/AndresGonzalez5/vibefloor/commit/a0ec1314c65b55fc33c11ad7d0ff9f97631b4889))
* move notification authorization to applicationDidFinishLaunching ([#277](https://github.com/AndresGonzalez5/vibefloor/issues/277)) ([6085ffd](https://github.com/AndresGonzalez5/vibefloor/commit/6085ffd0e0ed57d2ec82f579964c4499281285af)), closes [#274](https://github.com/AndresGonzalez5/vibefloor/issues/274)
* **opencode:** scope roster and context to the active session ([#21](https://github.com/AndresGonzalez5/vibefloor/issues/21)) ([eabef91](https://github.com/AndresGonzalez5/vibefloor/commit/eabef91ac71478f6f5cf2d19c9325dccd876c841))
* pass env vars to tmux sessions via -e flags ([#24](https://github.com/AndresGonzalez5/vibefloor/issues/24)) ([596f731](https://github.com/AndresGonzalez5/vibefloor/commit/596f7313c0a97dfb6ad092b3fb8ea2065d278681))
* persist pixel agents panel visibility across workspace switches ([1b21952](https://github.com/AndresGonzalez5/vibefloor/commit/1b2195275f949aac85e400865dfedd12c28ece9b))
* persist quick action runner across workstream navigation ([#317](https://github.com/AndresGonzalez5/vibefloor/issues/317)) ([3c04488](https://github.com/AndresGonzalez5/vibefloor/commit/3c0448804f373d5d91d8339be1347b3453cd8940))
* **pixel-agents:** keep agents seated at desk when idle, persist permission bubble ([c10b501](https://github.com/AndresGonzalez5/vibefloor/commit/c10b50150eb569bdca6260b8e99a5fa4343c9d59))
* PR number formatting and worktree zig-out symlink ([#301](https://github.com/AndresGonzalez5/vibefloor/issues/301)) ([d9b3a9b](https://github.com/AndresGonzalez5/vibefloor/commit/d9b3a9b68fd072a9d545fa254cdccee9111eab12))
* prefer login shell PATH for tool detection ([#250](https://github.com/AndresGonzalez5/vibefloor/issues/250)) ([407683d](https://github.com/AndresGonzalez5/vibefloor/commit/407683dccfcb27f3b00f30a989dc0b216a54b331))
* preserve active tab when cycling workstreams with Cmd+Shift+[/] ([#318](https://github.com/AndresGonzalez5/vibefloor/issues/318)) ([e4547be](https://github.com/AndresGonzalez5/vibefloor/commit/e4547be28a8d708996f2437450518b07588c075c))
* preserve run terminal visibility across workstream switching ([#375](https://github.com/AndresGonzalez5/vibefloor/issues/375)) ([2a9d37b](https://github.com/AndresGonzalez5/vibefloor/commit/2a9d37b05458076bea9e9449d28d2b58832ee8f0))
* preserve terminal and browser tabs across workspace navigation ([#168](https://github.com/AndresGonzalez5/vibefloor/issues/168)) ([be89532](https://github.com/AndresGonzalez5/vibefloor/commit/be89532f3fec4c23715bca40715306c665d5543d))
* prevent user tmux config from leaking into sessions ([#272](https://github.com/AndresGonzalez5/vibefloor/issues/272)) ([c7ccef9](https://github.com/AndresGonzalez5/vibefloor/commit/c7ccef93ed8236a6bcbb8ee277c6c1ffe4fa24b7))
* proc_listchildpids returns count not bytes, add Stop button ([70f24b3](https://github.com/AndresGonzalez5/vibefloor/commit/70f24b31ff22026aae794292f04b6d6288951d1e))
* propagate window resize to Ghostty ([#443](https://github.com/AndresGonzalez5/vibefloor/issues/443)) ([93f4da1](https://github.com/AndresGonzalez5/vibefloor/commit/93f4da143fa6a3937e95509484b58a059111afb7))
* **purge:** redirect to project view when purging from info panel ([96e5399](https://github.com/AndresGonzalez5/vibefloor/commit/96e53995467c371b92730b520a721da42fdaf178))
* re-sort sidebar projects when workstream activity updates lastAccessedAt ([#327](https://github.com/AndresGonzalez5/vibefloor/issues/327)) ([0005ed6](https://github.com/AndresGonzalez5/vibefloor/commit/0005ed624fc45ad87843a4960e6e59dadfe37c10))
* read Sparkle changelog from CHANGELOG.md instead of GitHub release ([#221](https://github.com/AndresGonzalez5/vibefloor/issues/221)) ([087afee](https://github.com/AndresGonzalez5/vibefloor/commit/087afee420dd88c7028870e5a571c8a19066b511))
* refresh git repo cache immediately when project is added via drag-drop ([#325](https://github.com/AndresGonzalez5/vibefloor/issues/325)) ([6921180](https://github.com/AndresGonzalez5/vibefloor/commit/692118070cf0254143ab297151aca7afb2489399))
* remove cat workaround, fix env script restart timing ([e98cd5b](https://github.com/AndresGonzalez5/vibefloor/commit/e98cd5b7becb56342dee25ef21409947aa6a7b9f))
* remove double shell-escaping of tmux -e env flags ([#64](https://github.com/AndresGonzalez5/vibefloor/issues/64)) ([be08aa4](https://github.com/AndresGonzalez5/vibefloor/commit/be08aa45420f6b380dfce87298f866cb47060258))
* remove prisma-generated-clients from default worktree symlinks ([#4](https://github.com/AndresGonzalez5/vibefloor/issues/4)) ([8001aa8](https://github.com/AndresGonzalez5/vibefloor/commit/8001aa8f074e3846263b2ecff9f2682276385c52))
* remove sendable requirement from notification request protocol ([#291](https://github.com/AndresGonzalez5/vibefloor/issues/291)) ([337ff89](https://github.com/AndresGonzalez5/vibefloor/commit/337ff893ede250ac3f8ccaa65d863696eaf0b14f))
* remove stale baseDirectory argument from MarkdownContentView call ([#106](https://github.com/AndresGonzalez5/vibefloor/issues/106)) ([1758aba](https://github.com/AndresGonzalez5/vibefloor/commit/1758aba868bd81b884a445f59162f641b0db3e2e))
* remove wait_after_command override, let ghostty use its default ([3610a86](https://github.com/AndresGonzalez5/vibefloor/commit/3610a86a9af31fc786738ce039d06975e0168310))
* remove web-browser entitlement that requires Apple approval ([#378](https://github.com/AndresGonzalez5/vibefloor/issues/378)) ([31c0578](https://github.com/AndresGonzalez5/vibefloor/commit/31c0578f862b7e49dda044be1f8b7c9a3c2d4456))
* rename Abandon PR to Close PR to match GitHub terminology ([#403](https://github.com/AndresGonzalez5/vibefloor/issues/403)) ([061a6c3](https://github.com/AndresGonzalez5/vibefloor/commit/061a6c3e7bff1fb708e5c8c04faee8b6727275f3)), closes [#397](https://github.com/AndresGonzalez5/vibefloor/issues/397)
* replace blocking runModal calls with async alternatives ([#148](https://github.com/AndresGonzalez5/vibefloor/issues/148)) ([a0d7e73](https://github.com/AndresGonzalez5/vibefloor/commit/a0d7e734bcf22de1f4a1d81ffc71b16d0457639d))
* replace favicon PNGs with alltuner icons, kill tmux on restart ([af7adc9](https://github.com/AndresGonzalez5/vibefloor/commit/af7adc91ebcd42dd5b10b8a9b9262a3e47530c3e))
* replace getImageData with clip-based MatrixEffect for WKWebView ([7b6ad04](https://github.com/AndresGonzalez5/vibefloor/commit/7b6ad04aa4c9ffc84b01419a005d4d820221fc0b))
* require user consent for factoryfloor:// URL scheme ([#98](https://github.com/AndresGonzalez5/vibefloor/issues/98)) ([#102](https://github.com/AndresGonzalez5/vibefloor/issues/102)) ([cfb2e77](https://github.com/AndresGonzalez5/vibefloor/commit/cfb2e775d3bdb3385af633317c6876aa7d6adb92))
* resolve build error and warnings in ContentView and TerminalApp ([#265](https://github.com/AndresGonzalez5/vibefloor/issues/265)) ([06d476d](https://github.com/AndresGonzalez5/vibefloor/commit/06d476d7fb54bd2d4d9b643fb13ad378824f93f2))
* resolve CI build failure and ff-run notarization ([#8](https://github.com/AndresGonzalez5/vibefloor/issues/8)) ([4e74409](https://github.com/AndresGonzalez5/vibefloor/commit/4e74409db010682053161d9f1c9bcffe263f1f3b))
* resolve compiler warnings in Launcher, BrowserView, and Updater ([#241](https://github.com/AndresGonzalez5/vibefloor/issues/241)) ([645ea15](https://github.com/AndresGonzalez5/vibefloor/commit/645ea15efdfd3e7a6424eff7a958fa2e5ebb04af)), closes [#228](https://github.com/AndresGonzalez5/vibefloor/issues/228)
* resolve LSP false positives for conditionally compiled AppConstants ([#213](https://github.com/AndresGonzalez5/vibefloor/issues/213)) ([a105cf6](https://github.com/AndresGonzalez5/vibefloor/commit/a105cf6964f123743a9b0abf6b2bf5e463c86763)), closes [#211](https://github.com/AndresGonzalez5/vibefloor/issues/211)
* resolve workspace creation failure in production builds ([#18](https://github.com/AndresGonzalez5/vibefloor/issues/18)) ([ece00ab](https://github.com/AndresGonzalez5/vibefloor/commit/ece00ab0c20b17f4e169c16e1a748804a1ea8222))
* respawn agent in tmux mode when process exits ([#267](https://github.com/AndresGonzalez5/vibefloor/issues/267)) ([f8e54a1](https://github.com/AndresGonzalez5/vibefloor/commit/f8e54a1c32152c064748540ed95550201824706f))
* restore last-active tab when switching between workstreams ([487cfd4](https://github.com/AndresGonzalez5/vibefloor/commit/487cfd4d3c544137e340c8444bad264001509c05))
* restore native mouse behavior in tmux terminals ([a455855](https://github.com/AndresGonzalez5/vibefloor/commit/a4558559fcc13e740f75b0b14becd71e8a90a286))
* restore tmux environment sessions ([d606c1d](https://github.com/AndresGonzalez5/vibefloor/commit/d606c1d87f0afdcf692dcc4c5a84692d4605aac0))
* restore workstream setup and fix branch prefix persistence ([bb92a30](https://github.com/AndresGonzalez5/vibefloor/commit/bb92a30628cb0b3a63b4707d921c4e61633d2f40))
* retry GitHub release asset uploads ([#295](https://github.com/AndresGonzalez5/vibefloor/issues/295)) ([f37aa7f](https://github.com/AndresGonzalez5/vibefloor/commit/f37aa7fbeab771937a8999ae191389a3041ac48d))
* revert worktree-create hook to symlink only xcframework ([#273](https://github.com/AndresGonzalez5/vibefloor/issues/273)) ([9ed32b5](https://github.com/AndresGonzalez5/vibefloor/commit/9ed32b5584ba69ce097bb7c8f10123b8a9568151))
* revert ZStack-all-workstreams to single active TerminalContainerView ([#374](https://github.com/AndresGonzalez5/vibefloor/issues/374)) ([e68cb0e](https://github.com/AndresGonzalez5/vibefloor/commit/e68cb0e2c08845fcb521809e14dabd45a049047f))
* rewrite ff-run to exec command directly for ghostty PTY compatibility ([#166](https://github.com/AndresGonzalez5/vibefloor/issues/166)) ([90871a9](https://github.com/AndresGonzalez5/vibefloor/commit/90871a9f87772ba24ad5400cd8a40e2e74cc9981))
* run build in worktree-create hook for SourceKit resolution ([#163](https://github.com/AndresGonzalez5/vibefloor/issues/163)) ([1184e7b](https://github.com/AndresGonzalez5/vibefloor/commit/1184e7bd3070ec75df62db098ee4fdc436e7092d)), closes [#161](https://github.com/AndresGonzalez5/vibefloor/issues/161)
* run setup/run/teardown scripts in user's login shell ([#135](https://github.com/AndresGonzalez5/vibefloor/issues/135)) ([b9d8340](https://github.com/AndresGonzalez5/vibefloor/commit/b9d8340a968ccd53859615d7087f869695dc3b2f))
* run worktree build in background to speed up creation ([#214](https://github.com/AndresGonzalez5/vibefloor/issues/214)) ([a2ed834](https://github.com/AndresGonzalez5/vibefloor/commit/a2ed83426974ec7a962e59a0e29d6e1c9c0adf5b))
* scope tmux respawn hook to agent sessions only ([#268](https://github.com/AndresGonzalez5/vibefloor/issues/268)) ([e4b57af](https://github.com/AndresGonzalez5/vibefloor/commit/e4b57af886f826acc73b30c1dd4c857ff2d7aaf4))
* **scripts:** require approval before running repository-provided commands ([a53903a](https://github.com/AndresGonzalez5/vibefloor/commit/a53903ae4426995c2b260aff580540c834d70834))
* separate debug entitlements to fix ad-hoc signed builds ([#368](https://github.com/AndresGonzalez5/vibefloor/issues/368)) ([c155ca4](https://github.com/AndresGonzalez5/vibefloor/commit/c155ca4d5a101476452fa3c26b1fa7967782096b))
* set manual signing and remove redundant debug entitlements ([#381](https://github.com/AndresGonzalez5/vibefloor/issues/381)) ([2881455](https://github.com/AndresGonzalez5/vibefloor/commit/28814551982b8ce72d4e6fe6cb94aa4a8a06b0c8))
* set run-state files to 0600 and directories to 0700 ([#97](https://github.com/AndresGonzalez5/vibefloor/issues/97)) ([#121](https://github.com/AndresGonzalez5/vibefloor/issues/121)) ([8009d0d](https://github.com/AndresGonzalez5/vibefloor/commit/8009d0db9fe1a479c6a2246450514e37ac3b80c4))
* show "Purging…" indicator on worktree row during background purge ([3e8ec3b](https://github.com/AndresGonzalez5/vibefloor/commit/3e8ec3bd06ff603eb076f53d8900463d56e6d91d))
* show archiving status for worktrees being removed instead of uncommitted changes ([4710edb](https://github.com/AndresGonzalez5/vibefloor/commit/4710edb0d6f5b45c1aadc7fcf38d5d87e15a7878))
* show correct shortcut numbers on closeable tabs ([#392](https://github.com/AndresGonzalez5/vibefloor/issues/392)) ([e9d4c3f](https://github.com/AndresGonzalez5/vibefloor/commit/e9d4c3fab3f6d8f55a904f952d75f5a437319459)), closes [#387](https://github.com/AndresGonzalez5/vibefloor/issues/387)
* show explicit desktop notifications even when app is active ([#266](https://github.com/AndresGonzalez5/vibefloor/issues/266)) ([f0b04ca](https://github.com/AndresGonzalez5/vibefloor/commit/f0b04caa4ab9bbda5c02b731ecf82184fb2ac301))
* show spinner when environment pane is restarting ([#89](https://github.com/AndresGonzalez5/vibefloor/issues/89)) ([#120](https://github.com/AndresGonzalez5/vibefloor/issues/120)) ([7bc3fc3](https://github.com/AndresGonzalez5/vibefloor/commit/7bc3fc398e506e88b09062f59a5ba2a810d5cffa))
* sidebar archive button fails due to stale workstream index cache ([#170](https://github.com/AndresGonzalez5/vibefloor/issues/170)) ([3727c40](https://github.com/AndresGonzalez5/vibefloor/commit/3727c40af9e3db31ce27018abec071ab382337f7))
* sidebar branch name delay and improve workstream row content ([#306](https://github.com/AndresGonzalez5/vibefloor/issues/306)) ([86b83cf](https://github.com/AndresGonzalez5/vibefloor/commit/86b83cfa62b70a941db72b16d55fcca5a9756346))
* **sidebar:** clear orange permission dot when tool activity resumes ([4996fc9](https://github.com/AndresGonzalez5/vibefloor/commit/4996fc9227ba41db839147266b5b832953d34198))
* **sidebar:** refresh agent-state lookup when worktree path is assigned ([d085718](https://github.com/AndresGonzalez5/vibefloor/commit/d085718c2e65bf805e7d154e6c569cf3c1e5b203))
* sign bundled ff-run and stabilize project identity ([aa2d863](https://github.com/AndresGonzalez5/vibefloor/commit/aa2d863c34338568d981dbcd5386e90864390a62))
* skip submodule dirty checks in git status ([#314](https://github.com/AndresGonzalez5/vibefloor/issues/314)) ([8ae6395](https://github.com/AndresGonzalez5/vibefloor/commit/8ae6395a24ad4a096a7fc2be8ba95e8f02af2203))
* skip symlinks when loading doc files in info panel ([#160](https://github.com/AndresGonzalez5/vibefloor/issues/160)) ([cd97a42](https://github.com/AndresGonzalez5/vibefloor/commit/cd97a42ec950d66da2bc04b5414d4b13d4286e23))
* sleep after env script exits instead of returning to shell ([bb147b2](https://github.com/AndresGonzalez5/vibefloor/commit/bb147b2d2e7f434084a912740a645ac2447420d0))
* split ProjectSidebar body into computed properties to fix type-check timeout ([#177](https://github.com/AndresGonzalez5/vibefloor/issues/177)) ([a48545c](https://github.com/AndresGonzalez5/vibefloor/commit/a48545cb22dc02eb6a585b4efb422d8585ca2f10))
* split tmux/non-tmux env terminal approach, fix rebuild loop ([cc5ee14](https://github.com/AndresGonzalez5/vibefloor/commit/cc5ee1482e0cf50fe0490dded9d2c5bf1733a8c8))
* stop overriding PATH and redirecting stderr in agent launch ([#248](https://github.com/AndresGonzalez5/vibefloor/issues/248)) ([cbc1d19](https://github.com/AndresGonzalez5/vibefloor/commit/cbc1d194999e706abbbb324dea71330ae5ae46ab))
* stop symlinking node_modules in worktrees, use yarn install instead ([3e97eac](https://github.com/AndresGonzalez5/vibefloor/commit/3e97eac6d456a070a80935cbc014e36085fe1292))
* strip raw HTML from markdown rendering, remove file:// base URL ([#95](https://github.com/AndresGonzalez5/vibefloor/issues/95)) ([#99](https://github.com/AndresGonzalez5/vibefloor/issues/99)) ([5c4dce5](https://github.com/AndresGonzalez5/vibefloor/commit/5c4dce584ddaddcd8ef0a58e04f0d8ab6e946b1b))
* suppress incomplete umbrella header warnings from GhosttyKit ([#199](https://github.com/AndresGonzalez5/vibefloor/issues/199)) ([9f4ad38](https://github.com/AndresGonzalez5/vibefloor/commit/9f4ad38c9e05b842898a8b8bb744c5d9af795336))
* swap env shortcuts (Rebuild ⌃⇧R, Start/Rerun ⌃⇧S) ([8efc198](https://github.com/AndresGonzalez5/vibefloor/commit/8efc198b45fc6a0992aaf448f4c6aa50cf8dbcad))
* sync IME preedit state with libghostty ([#458](https://github.com/AndresGonzalez5/vibefloor/issues/458)) ([a582cc2](https://github.com/AndresGonzalez5/vibefloor/commit/a582cc2048eb715576d86afb0a25c112c372d153))
* **terminal:** restore scrollback by reverting tmux alternate-screen overrides ([#479](https://github.com/AndresGonzalez5/vibefloor/issues/479)) ([e6491c7](https://github.com/AndresGonzalez5/vibefloor/commit/e6491c72ff3c9827512a0a7b8772b75aee2fd110)), closes [#395](https://github.com/AndresGonzalez5/vibefloor/issues/395)
* toolbar duplication and SourceKit-LSP false positives in worktrees ([#373](https://github.com/AndresGonzalez5/vibefloor/issues/373)) ([3bae95b](https://github.com/AndresGonzalez5/vibefloor/commit/3bae95b2b6ab81b06ec8fe4a28a44bd1980b2233))
* TranscriptWatcher path resolution, office scene, app rename to VibeFloor ([7033402](https://github.com/AndresGonzalez5/vibefloor/commit/7033402e2f01c4b7cce67dda98a8259f1109a58d))
* trigger Sparkle update from sidebar instead of opening website ([#237](https://github.com/AndresGonzalez5/vibefloor/issues/237)) ([5b74416](https://github.com/AndresGonzalez5/vibefloor/commit/5b7441650749205026c9316c49f2f03db976f4c8)), closes [#232](https://github.com/AndresGonzalez5/vibefloor/issues/232)
* update stale keyboard shortcut references across UI and docs ([#371](https://github.com/AndresGonzalez5/vibefloor/issues/371)) ([911d311](https://github.com/AndresGonzalez5/vibefloor/commit/911d31173ee51c842234415d704678b5d7674893))
* upload dSYMs to Sentry so crash reports are symbolicated ([#131](https://github.com/AndresGonzalez5/vibefloor/issues/131)) ([7f4f2b9](https://github.com/AndresGonzalez5/vibefloor/commit/7f4f2b9cc80efbd7e0e35b1d62da7b5a50aaf9ff))
* use atomic callbacks for project and workstream creation ([#43](https://github.com/AndresGonzalez5/vibefloor/issues/43)) ([#53](https://github.com/AndresGonzalez5/vibefloor/issues/53)) ([080bcb2](https://github.com/AndresGonzalez5/vibefloor/commit/080bcb2b9612934b6328aa7432e04d4d32e845c2))
* use cat to keep env terminals open, add Rebuild/Rerun/Start labels ([32286f5](https://github.com/AndresGonzalez5/vibefloor/commit/32286f5b0bf12e6b06df4bdb3a8c12f452b6f415))
* use heap-allocated C strings for ghostty env vars ([#159](https://github.com/AndresGonzalez5/vibefloor/issues/159)) ([3c66311](https://github.com/AndresGonzalez5/vibefloor/commit/3c6631153e95322e78baa490f5618564fb7889bc))
* use initialInput for agent tab to preserve terminal capabilities ([#1](https://github.com/AndresGonzalez5/vibefloor/issues/1)) ([a0f8f96](https://github.com/AndresGonzalez5/vibefloor/commit/a0f8f96c56c32f8c0e1269d1599d909dc9c97c76))
* use initialInput for all env terminals, fix tmux restart loop ([1e3b3cf](https://github.com/AndresGonzalez5/vibefloor/commit/1e3b3cf052e23732bf053c2acddefb4f6581471c))
* use initialInput instead of command for env scripts ([d7c70c9](https://github.com/AndresGonzalez5/vibefloor/commit/d7c70c9f47509365e0c3b3552d4430f02019a1dc))
* use interactive login shell (-lic) for tool version manager support ([#243](https://github.com/AndresGonzalez5/vibefloor/issues/243)) ([d48ee31](https://github.com/AndresGonzalez5/vibefloor/commit/d48ee3131ca760cfe2876bddb2c4a8ec2b2370b1))
* use local entitlements to bypass library validation in dev release builds ([#280](https://github.com/AndresGonzalez5/vibefloor/issues/280)) ([2f8161c](https://github.com/AndresGonzalez5/vibefloor/commit/2f8161cb99efb4e811eb58c7582453acbe65a8c2)), closes [#279](https://github.com/AndresGonzalez5/vibefloor/issues/279)
* use login shell for agent and tmux commands to load user PATH ([#174](https://github.com/AndresGonzalez5/vibefloor/issues/174)) ([debcaad](https://github.com/AndresGonzalez5/vibefloor/commit/debcaad4bb195ff070fcab0507839592c9826459))
* use notifications for project/workstream creation ([#43](https://github.com/AndresGonzalez5/vibefloor/issues/43)) ([#57](https://github.com/AndresGonzalez5/vibefloor/issues/57)) ([75ed058](https://github.com/AndresGonzalez5/vibefloor/commit/75ed058599bf263a43af98b5750f9457a1e21f5a))
* use ObservableObject for projects to fix Release @State timing ([#43](https://github.com/AndresGonzalez5/vibefloor/issues/43)) ([#63](https://github.com/AndresGonzalez5/vibefloor/issues/63)) ([c0568c8](https://github.com/AndresGonzalez5/vibefloor/commit/c0568c84ccccd8da0761b79b8347921326e4940d))
* use os_log Logger with public privacy for debug logging ([#43](https://github.com/AndresGonzalez5/vibefloor/issues/43)) ([#49](https://github.com/AndresGonzalez5/vibefloor/issues/49)) ([467d749](https://github.com/AndresGonzalez5/vibefloor/commit/467d74982622974bccfe8332e2d8a9b1f96d3859))
* use remote tracking ref for worktree creation instead of updating local main ([#404](https://github.com/AndresGonzalez5/vibefloor/issues/404)) ([5da6b98](https://github.com/AndresGonzalez5/vibefloor/commit/5da6b98d8eca3903d624e85fc49b61cc3c1686a5)), closes [#393](https://github.com/AndresGonzalez5/vibefloor/issues/393)
* **website:** add --cask to brew install commands ([efed35e](https://github.com/AndresGonzalez5/vibefloor/commit/efed35e39c6a91b550bcc1213d76e0fe43cd6b22))
* **website:** add brew update to upgrade instructions, trigger deploy after release ([#47](https://github.com/AndresGonzalez5/vibefloor/issues/47)) ([385f085](https://github.com/AndresGonzalez5/vibefloor/commit/385f085d5f96a711e3feabb456dffbafaa0f088a)), closes [#40](https://github.com/AndresGonzalez5/vibefloor/issues/40) [#42](https://github.com/AndresGonzalez5/vibefloor/issues/42)
* **website:** add Claude Code link in hero text, add tmux to credits ([822e712](https://github.com/AndresGonzalez5/vibefloor/commit/822e7129ba1b64801248ca282be2c7f62d02fae5))
* **website:** add copy-to-clipboard visual feedback on /get page ([6fef3b6](https://github.com/AndresGonzalez5/vibefloor/commit/6fef3b67315adac0539698338b57efe234d5846d))
* **website:** improve footer and nav responsiveness ([#357](https://github.com/AndresGonzalez5/vibefloor/issues/357)) ([d96557f](https://github.com/AndresGonzalez5/vibefloor/commit/d96557f2e839722a33b8e18f2d96f7591852f929))
* **website:** link changelog versions to GitHub releases instead of diffs ([#164](https://github.com/AndresGonzalez5/vibefloor/issues/164)) ([7f0ccd9](https://github.com/AndresGonzalez5/vibefloor/commit/7f0ccd99922f3973943ff18a4ab2c0fa57350a1f))
* **website:** prevent horizontal scroll on mobile Safari ([#218](https://github.com/AndresGonzalez5/vibefloor/issues/218)) ([8e68359](https://github.com/AndresGonzalez5/vibefloor/commit/8e683590c89c5498222c72dd761b901a9c7934f0))
* **website:** rebuild CSS ([4d8aaac](https://github.com/AndresGonzalez5/vibefloor/commit/4d8aaac3d49badbc2941df6b52d4e69ddfcdafe1))
* **website:** regenerate favicons from hi-res 1024x1024 source ([bab5c34](https://github.com/AndresGonzalez5/vibefloor/commit/bab5c34af0a3ab2e291367158d618b88b2c2e1e0))
* **website:** update built CSS ([f4a0153](https://github.com/AndresGonzalez5/vibefloor/commit/f4a015345077c64731d03a7e280b56fd16c276e9))
* **worktrees:** avoid prune prompt for newly created workstreams ([#384](https://github.com/AndresGonzalez5/vibefloor/issues/384)) ([a7d89d1](https://github.com/AndresGonzalez5/vibefloor/commit/a7d89d14aa5d79aca09124e16675de84300db41a))
* wrap preloaded setup script in login shell ([#143](https://github.com/AndresGonzalez5/vibefloor/issues/143)) ([a263d35](https://github.com/AndresGonzalez5/vibefloor/commit/a263d35f94a7befdaa19e6922bd88b57ddb5e2a7))


### Refactoring

* **ci:** embed Sparkle public key in project.yml ([#147](https://github.com/AndresGonzalez5/vibefloor/issues/147)) ([6465fb7](https://github.com/AndresGonzalez5/vibefloor/commit/6465fb7258e490a1f663432f8938e3b0c3c82278))
* **ci:** embed Sparkle public key in project.yml ([#147](https://github.com/AndresGonzalez5/vibefloor/issues/147)) ([f7870fa](https://github.com/AndresGonzalez5/vibefloor/commit/f7870fabe94d26be60d52bcb054822743fefbe86))
* generate Info.plist via XcodeGen and versions.json at deploy time ([#141](https://github.com/AndresGonzalez5/vibefloor/issues/141)) ([c1d624b](https://github.com/AndresGonzalez5/vibefloor/commit/c1d624b9f5f3192b20213917bdfd33b8c936a153))
* move run-state and tmux.conf to ~/Library/Caches/factoryfloor/ ([#75](https://github.com/AndresGonzalez5/vibefloor/issues/75)) ([#76](https://github.com/AndresGonzalez5/vibefloor/issues/76)) ([a1de232](https://github.com/AndresGonzalez5/vibefloor/commit/a1de232cf57d9eb2754ebcf9c29a1abb05e3149a))
* rebuild Sparkle changelog from CHANGELOG.md on every release ([#430](https://github.com/AndresGonzalez5/vibefloor/issues/430)) ([51d9c92](https://github.com/AndresGonzalez5/vibefloor/commit/51d9c922f2e8a5823fe95a0c46a0d058b324f53c))
* remove branch prefix feature, prefix Linear issues in auto-rename ([#5](https://github.com/AndresGonzalez5/vibefloor/issues/5)) ([5f4cae6](https://github.com/AndresGonzalez5/vibefloor/commit/5f4cae6b39a2dd62d389491b3adcfddee28f7cea))
* remove legacy JSON file migration code ([#93](https://github.com/AndresGonzalez5/vibefloor/issues/93)) ([#122](https://github.com/AndresGonzalez5/vibefloor/issues/122)) ([3b5041c](https://github.com/AndresGonzalez5/vibefloor/commit/3b5041ca4f6bca93aa09ef722c3544be1904298d))
* remove redundant Workstreams section from project overview ([4ee05f1](https://github.com/AndresGonzalez5/vibefloor/commit/4ee05f177ea1275b63e6625dbac1b52eca2f3a45))
* remove ScriptLogger and move logging toggle to privacy section ([#216](https://github.com/AndresGonzalez5/vibefloor/issues/216)) ([3858229](https://github.com/AndresGonzalez5/vibefloor/commit/385822910afd9ab3d9ac6b549938d0a6cb144932))
* revamp keyboard shortcuts to follow macOS conventions ([#365](https://github.com/AndresGonzalez5/vibefloor/issues/365)) ([c18ef6f](https://github.com/AndresGonzalez5/vibefloor/commit/c18ef6f3ec0c1b36a06d92f12541eaaa0545dd17))


### Performance

* **ci:** cache ghostty xcframework between builds ([#26](https://github.com/AndresGonzalez5/vibefloor/issues/26)) ([1d51987](https://github.com/AndresGonzalez5/vibefloor/commit/1d519873cecf52acf6ffee39c0d47ddd7f52b5a9))
* **ci:** cache SPM packages between builds ([#29](https://github.com/AndresGonzalez5/vibefloor/issues/29)) ([960b037](https://github.com/AndresGonzalez5/vibefloor/commit/960b03734755023fa4086987a4dfd15031f843a1))
* **ci:** replace brew with dedicated setup actions for zig and xcodegen ([#30](https://github.com/AndresGonzalez5/vibefloor/issues/30)) ([d438aaf](https://github.com/AndresGonzalez5/vibefloor/commit/d438aafae5a83a6b5f74c917abe08781f982e3ea))
* instant workstream switching ([#377](https://github.com/AndresGonzalez5/vibefloor/issues/377)) ([3f987a9](https://github.com/AndresGonzalez5/vibefloor/commit/3f987a94cc22c20004eaf84bba58522f3a042fcf))
* reduce SwiftUI main-thread churn from AppEnvironment ([#453](https://github.com/AndresGonzalez5/vibefloor/issues/453)) ([6d16635](https://github.com/AndresGonzalez5/vibefloor/commit/6d1663532cc75f06bbc0597ef74510b747b74498))
* share SPM package cache across worktrees ([#158](https://github.com/AndresGonzalez5/vibefloor/issues/158)) ([e531a5a](https://github.com/AndresGonzalez5/vibefloor/commit/e531a5a5aeb5f66db72b8c29141d00d5b4ed80bb))
* show workstream UI instantly during worktree creation ([#258](https://github.com/AndresGonzalez5/vibefloor/issues/258)) ([8f31121](https://github.com/AndresGonzalez5/vibefloor/commit/8f31121cf49c260b08119c109ab41c1e6c987b85)), closes [#254](https://github.com/AndresGonzalez5/vibefloor/issues/254)


### Miscellaneous

* add __pycache__ to .gitignore ([#223](https://github.com/AndresGonzalez5/vibefloor/issues/223)) ([015d9ec](https://github.com/AndresGonzalez5/vibefloor/commit/015d9ec53554bceead26d10f4973e5891acea72a)), closes [#222](https://github.com/AndresGonzalez5/vibefloor/issues/222)
* add prek pre-commit hooks ([#82](https://github.com/AndresGonzalez5/vibefloor/issues/82)) ([#83](https://github.com/AndresGonzalez5/vibefloor/issues/83)) ([19f08f3](https://github.com/AndresGonzalez5/vibefloor/commit/19f08f3218f56b875e0734a53b53a51c735c8637))
* add SwiftFormat hook and update AGENTS.md ([#84](https://github.com/AndresGonzalez5/vibefloor/issues/84), [#85](https://github.com/AndresGonzalez5/vibefloor/issues/85)) ([#86](https://github.com/AndresGonzalez5/vibefloor/issues/86)) ([8656ea8](https://github.com/AndresGonzalez5/vibefloor/commit/8656ea81659f318906874885a011c83cb7055841))
* clean up TODO, deduplicate, record terminal lifecycle fixes ([c1ab179](https://github.com/AndresGonzalez5/vibefloor/commit/c1ab17979581712a1d43609b2098497642b815d8))
* **deps:** update actions/cache action to v5 ([#27](https://github.com/AndresGonzalez5/vibefloor/issues/27)) ([c506297](https://github.com/AndresGonzalez5/vibefloor/commit/c50629746d9936178b63399901f82dde0bbb14a2))
* **deps:** update actions/checkout action to v6 ([#271](https://github.com/AndresGonzalez5/vibefloor/issues/271)) ([0ac67a2](https://github.com/AndresGonzalez5/vibefloor/commit/0ac67a28ac9d8bc53a349db69ec48878434b75c5))
* **deps:** update actions/checkout action to v6 ([#305](https://github.com/AndresGonzalez5/vibefloor/issues/305)) ([1dc5605](https://github.com/AndresGonzalez5/vibefloor/commit/1dc5605a0cd8212e01b11a3c6575aefa6cdcf5ce))
* **deps:** update actions/checkout action to v6 ([#390](https://github.com/AndresGonzalez5/vibefloor/issues/390)) ([327844d](https://github.com/AndresGonzalez5/vibefloor/commit/327844debdff94e6128ac768da378c2c3e5fcdf6))
* **deps:** update actions/deploy-pages action to v5 ([#187](https://github.com/AndresGonzalez5/vibefloor/issues/187)) ([82fa566](https://github.com/AndresGonzalez5/vibefloor/commit/82fa566265dcaa9bb4b21d742f1a58162e46b2fc))
* **deps:** update actions/upload-pages-artifact action to v5 ([#437](https://github.com/AndresGonzalez5/vibefloor/issues/437)) ([5b2ad22](https://github.com/AndresGonzalez5/vibefloor/commit/5b2ad2242f293817aced382b3386d9b08ce26aa1))
* **deps:** update astral-sh/setup-uv action to v7 ([#207](https://github.com/AndresGonzalez5/vibefloor/issues/207)) ([8b2cfda](https://github.com/AndresGonzalez5/vibefloor/commit/8b2cfda4bbfe0afdbcb6f3965e56e0c9de4608eb))
* **deps:** update astral-sh/setup-uv action to v8 ([#452](https://github.com/AndresGonzalez5/vibefloor/issues/452)) ([76752aa](https://github.com/AndresGonzalez5/vibefloor/commit/76752aa880890af7aab05ad6b243cd7f50b4b482))
* **deps:** update dependency macos to v26 ([#472](https://github.com/AndresGonzalez5/vibefloor/issues/472)) ([411d724](https://github.com/AndresGonzalez5/vibefloor/commit/411d724388c200f0b70279e5584aa3196b410264))
* **deps:** update dependency sentry to v9.10.0 ([#446](https://github.com/AndresGonzalez5/vibefloor/issues/446)) ([1917c85](https://github.com/AndresGonzalez5/vibefloor/commit/1917c85b6be8712bc344a8c5fbcbce0ad5bc2485))
* **deps:** update dependency sentry to v9.11.0 ([#456](https://github.com/AndresGonzalez5/vibefloor/issues/456)) ([4fbd7da](https://github.com/AndresGonzalez5/vibefloor/commit/4fbd7da9ac051c60ce05be24e38ef3748a084ea1))
* **deps:** update dependency sentry to v9.12.0 ([#460](https://github.com/AndresGonzalez5/vibefloor/issues/460)) ([dca1ee8](https://github.com/AndresGonzalez5/vibefloor/commit/dca1ee867bb0d0f7836f96dea0f53253362deae8))
* **deps:** update dependency sentry to v9.15.0 ([#464](https://github.com/AndresGonzalez5/vibefloor/issues/464)) ([dddafad](https://github.com/AndresGonzalez5/vibefloor/commit/dddafadd8cd762278c57670971bf2d6df8cbb2d2))
* **deps:** update dependency sparkle to v2.9.1 ([#445](https://github.com/AndresGonzalez5/vibefloor/issues/445)) ([18bcdd6](https://github.com/AndresGonzalez5/vibefloor/commit/18bcdd6782f23a6eeebf5197438cbcebfabf90ae))
* **deps:** update dependency sparkle to v2.9.2 ([#475](https://github.com/AndresGonzalez5/vibefloor/issues/475)) ([f90feab](https://github.com/AndresGonzalez5/vibefloor/commit/f90feabc40e4c9c50555e93cf73371b15317caf5))
* **deps:** update dependency swift-cmark to v0.7.1 ([#447](https://github.com/AndresGonzalez5/vibefloor/issues/447)) ([b278da9](https://github.com/AndresGonzalez5/vibefloor/commit/b278da914d2d975dd84e36e27474d7dc97852624))
* **deps:** update dependency swift-cmark to v0.8.0 ([#466](https://github.com/AndresGonzalez5/vibefloor/issues/466)) ([f3b9845](https://github.com/AndresGonzalez5/vibefloor/commit/f3b9845d89b8d89e320fcaea66d1c0de2a35e45f))
* **deps:** update dependency vite to v8 ([#435](https://github.com/AndresGonzalez5/vibefloor/issues/435)) ([4fac286](https://github.com/AndresGonzalez5/vibefloor/commit/4fac286452035f0e92f1f1ff9e325f9ee717a587))
* **deps:** update googleapis/release-please-action action to v5 ([#455](https://github.com/AndresGonzalez5/vibefloor/issues/455)) ([bae2bc3](https://github.com/AndresGonzalez5/vibefloor/commit/bae2bc332407cb431ab8e55353532aaf4a733962))
* enable strict concurrency checks ([4b95cbe](https://github.com/AndresGonzalez5/vibefloor/commit/4b95cbeafe9308a7321475e697b0ef577cfe1945))
* flip project to swift 6 ([bf0c227](https://github.com/AndresGonzalez5/vibefloor/commit/bf0c227347349f7386310a65e22182f4ba546080))
* ignore dirty state in ghostty submodule ([#346](https://github.com/AndresGonzalez5/vibefloor/issues/346)) ([400dcc0](https://github.com/AndresGonzalez5/vibefloor/commit/400dcc0f09446047a79716c4dec0918d2ef38e69))
* **main:** release 0.1.1 ([#5](https://github.com/AndresGonzalez5/vibefloor/issues/5)) ([ea73a9d](https://github.com/AndresGonzalez5/vibefloor/commit/ea73a9d468fb3ad70c545b45942790446f4386b7))
* **main:** release 0.1.10 ([#28](https://github.com/AndresGonzalez5/vibefloor/issues/28)) ([136eeb2](https://github.com/AndresGonzalez5/vibefloor/commit/136eeb202231c2eeedc7ad902dc5f04c538c7471))
* **main:** release 0.1.11 ([#31](https://github.com/AndresGonzalez5/vibefloor/issues/31)) ([797c1ee](https://github.com/AndresGonzalez5/vibefloor/commit/797c1eef18d7f96ec4d51599011283a52f18585e))
* **main:** release 0.1.12 ([#33](https://github.com/AndresGonzalez5/vibefloor/issues/33)) ([e9787f7](https://github.com/AndresGonzalez5/vibefloor/commit/e9787f7c2952326450afb2d3936748b9f112d0e8))
* **main:** release 0.1.13 ([#35](https://github.com/AndresGonzalez5/vibefloor/issues/35)) ([06aa9a0](https://github.com/AndresGonzalez5/vibefloor/commit/06aa9a0a00087c41fae26b01f87833239d3bfc04))
* **main:** release 0.1.14 ([#37](https://github.com/AndresGonzalez5/vibefloor/issues/37)) ([39c9449](https://github.com/AndresGonzalez5/vibefloor/commit/39c9449c87d15be00ba662a4643b449bb41e2d10))
* **main:** release 0.1.15 ([#45](https://github.com/AndresGonzalez5/vibefloor/issues/45)) ([a291e2b](https://github.com/AndresGonzalez5/vibefloor/commit/a291e2b31f50d6e3b8e0ece7e82bd770887a3c1e))
* **main:** release 0.1.16 ([#48](https://github.com/AndresGonzalez5/vibefloor/issues/48)) ([f78d016](https://github.com/AndresGonzalez5/vibefloor/commit/f78d0160d822e41fe9d75cc4051f9485b222e7be))
* **main:** release 0.1.17 ([#51](https://github.com/AndresGonzalez5/vibefloor/issues/51)) ([8cfd64a](https://github.com/AndresGonzalez5/vibefloor/commit/8cfd64a6f6caed489f3110e8142f89b717538af0))
* **main:** release 0.1.18 ([#54](https://github.com/AndresGonzalez5/vibefloor/issues/54)) ([f26a40d](https://github.com/AndresGonzalez5/vibefloor/commit/f26a40d1d213708d895b20b02c4a8308d0071c3e))
* **main:** release 0.1.19 ([#56](https://github.com/AndresGonzalez5/vibefloor/issues/56)) ([210ce5d](https://github.com/AndresGonzalez5/vibefloor/commit/210ce5d4f5e77859fccd3ef22115df3cabe54ad0))
* **main:** release 0.1.2 ([#9](https://github.com/AndresGonzalez5/vibefloor/issues/9)) ([a714f97](https://github.com/AndresGonzalez5/vibefloor/commit/a714f976c9617f9815b9f4956564496b70c432f5))
* **main:** release 0.1.20 ([#58](https://github.com/AndresGonzalez5/vibefloor/issues/58)) ([47bb909](https://github.com/AndresGonzalez5/vibefloor/commit/47bb909e7c2f2a1397d6e797a25e361ec9a802f8))
* **main:** release 0.1.21 ([#61](https://github.com/AndresGonzalez5/vibefloor/issues/61)) ([8bbb68d](https://github.com/AndresGonzalez5/vibefloor/commit/8bbb68d2ad33027f5715a7bd1647402b4608383e))
* **main:** release 0.1.22 ([#65](https://github.com/AndresGonzalez5/vibefloor/issues/65)) ([f935d04](https://github.com/AndresGonzalez5/vibefloor/commit/f935d04f89deef93f1bd3b648d2cac775cca80dd))
* **main:** release 0.1.23 ([#71](https://github.com/AndresGonzalez5/vibefloor/issues/71)) ([7bbdb27](https://github.com/AndresGonzalez5/vibefloor/commit/7bbdb272440bcb53c25a92224928a66a6a3aafcc))
* **main:** release 0.1.24 ([#77](https://github.com/AndresGonzalez5/vibefloor/issues/77)) ([3848d72](https://github.com/AndresGonzalez5/vibefloor/commit/3848d72077da79d95117dc109c6ef89a8ce141b8))
* **main:** release 0.1.25 ([#107](https://github.com/AndresGonzalez5/vibefloor/issues/107)) ([334ae29](https://github.com/AndresGonzalez5/vibefloor/commit/334ae29b0f3bf0b8f69351897926b749b1a6a4e9))
* **main:** release 0.1.26 ([#109](https://github.com/AndresGonzalez5/vibefloor/issues/109)) ([c80d86b](https://github.com/AndresGonzalez5/vibefloor/commit/c80d86b94e0ed6e178cf3524dd19b0f56db020e2))
* **main:** release 0.1.27 ([#111](https://github.com/AndresGonzalez5/vibefloor/issues/111)) ([dfe5e38](https://github.com/AndresGonzalez5/vibefloor/commit/dfe5e38411fec3a2894b95a2d8173bb4c190299d))
* **main:** release 0.1.28 ([#116](https://github.com/AndresGonzalez5/vibefloor/issues/116)) ([1fc32d4](https://github.com/AndresGonzalez5/vibefloor/commit/1fc32d4d04a005c702861687a52eaf0563d4e713))
* **main:** release 0.1.29 ([#118](https://github.com/AndresGonzalez5/vibefloor/issues/118)) ([e5d598f](https://github.com/AndresGonzalez5/vibefloor/commit/e5d598fe80ce1ef8d607f3f82965fa9cdd23b4b8))
* **main:** release 0.1.3 ([#11](https://github.com/AndresGonzalez5/vibefloor/issues/11)) ([8c4b6c1](https://github.com/AndresGonzalez5/vibefloor/commit/8c4b6c1c8730b87a174e4c9fc196c1c90cc11055))
* **main:** release 0.1.30 ([#126](https://github.com/AndresGonzalez5/vibefloor/issues/126)) ([2b341bc](https://github.com/AndresGonzalez5/vibefloor/commit/2b341bc93adeaa0d8747391e1e06000eec6ba45b))
* **main:** release 0.1.31 ([#130](https://github.com/AndresGonzalez5/vibefloor/issues/130)) ([4b70c8a](https://github.com/AndresGonzalez5/vibefloor/commit/4b70c8aa1d710c6bd8e7f55504f9b91c160171a6))
* **main:** release 0.1.32 ([#132](https://github.com/AndresGonzalez5/vibefloor/issues/132)) ([2e7054e](https://github.com/AndresGonzalez5/vibefloor/commit/2e7054ecc93b8b143872ccd8ab60f53dfb724989))
* **main:** release 0.1.33 ([#134](https://github.com/AndresGonzalez5/vibefloor/issues/134)) ([25c8e41](https://github.com/AndresGonzalez5/vibefloor/commit/25c8e41eb65216b36eb82848e77412c538902409))
* **main:** release 0.1.34 ([#136](https://github.com/AndresGonzalez5/vibefloor/issues/136)) ([65f7913](https://github.com/AndresGonzalez5/vibefloor/commit/65f79132b04e3b58b319533e6accb556b937d91a))
* **main:** release 0.1.35 ([#139](https://github.com/AndresGonzalez5/vibefloor/issues/139)) ([2edb527](https://github.com/AndresGonzalez5/vibefloor/commit/2edb5274605b3d8f1a4194c7259a49951167519f))
* **main:** release 0.1.36 ([#142](https://github.com/AndresGonzalez5/vibefloor/issues/142)) ([1cb5bc0](https://github.com/AndresGonzalez5/vibefloor/commit/1cb5bc0541cea733f0685612848a52ca72ddfa8c))
* **main:** release 0.1.37 ([#144](https://github.com/AndresGonzalez5/vibefloor/issues/144)) ([2fe2877](https://github.com/AndresGonzalez5/vibefloor/commit/2fe2877a6f4ac1f1f292b4dc29e0a0e45c6d2f2b))
* **main:** release 0.1.38 ([#146](https://github.com/AndresGonzalez5/vibefloor/issues/146)) ([47888b3](https://github.com/AndresGonzalez5/vibefloor/commit/47888b3a6d24f25730c3345c3d0501246669200a))
* **main:** release 0.1.39 ([#155](https://github.com/AndresGonzalez5/vibefloor/issues/155)) ([c9c5250](https://github.com/AndresGonzalez5/vibefloor/commit/c9c52509064fe707bab556c7d2c6ca772da30adb))
* **main:** release 0.1.4 ([#13](https://github.com/AndresGonzalez5/vibefloor/issues/13)) ([29e2c1a](https://github.com/AndresGonzalez5/vibefloor/commit/29e2c1a75f9f699d6d0822f7a2ae60794139ff8d))
* **main:** release 0.1.40 ([#157](https://github.com/AndresGonzalez5/vibefloor/issues/157)) ([3bea521](https://github.com/AndresGonzalez5/vibefloor/commit/3bea52142c5c7ba8eb093b9fc8ef6f806150f457))
* **main:** release 0.1.41 ([#162](https://github.com/AndresGonzalez5/vibefloor/issues/162)) ([2044668](https://github.com/AndresGonzalez5/vibefloor/commit/204466804fcc8af1f276e4562839c32b9f9418a2))
* **main:** release 0.1.42 ([#169](https://github.com/AndresGonzalez5/vibefloor/issues/169)) ([913d88b](https://github.com/AndresGonzalez5/vibefloor/commit/913d88bbe0989087a9cfeff5b65a1033c77d24c0))
* **main:** release 0.1.43 ([#176](https://github.com/AndresGonzalez5/vibefloor/issues/176)) ([d76f139](https://github.com/AndresGonzalez5/vibefloor/commit/d76f1391061825c9a195d269c3fdc45fce00a999))
* **main:** release 0.1.44 ([#178](https://github.com/AndresGonzalez5/vibefloor/issues/178)) ([8c66b3e](https://github.com/AndresGonzalez5/vibefloor/commit/8c66b3e65e01242a6641c84143288375bd90edc1))
* **main:** release 0.1.45 ([#180](https://github.com/AndresGonzalez5/vibefloor/issues/180)) ([0a2a423](https://github.com/AndresGonzalez5/vibefloor/commit/0a2a42324941640da1b4654ea936d6580a21f2c6))
* **main:** release 0.1.46 ([#190](https://github.com/AndresGonzalez5/vibefloor/issues/190)) ([b2ebfb5](https://github.com/AndresGonzalez5/vibefloor/commit/b2ebfb5ddabc867a983d967906225f2e840526e8))
* **main:** release 0.1.47 ([#197](https://github.com/AndresGonzalez5/vibefloor/issues/197)) ([f379d05](https://github.com/AndresGonzalez5/vibefloor/commit/f379d05f7e1ca18a8a03ade5a16abc59b81cb302))
* **main:** release 0.1.48 ([#202](https://github.com/AndresGonzalez5/vibefloor/issues/202)) ([e21cf55](https://github.com/AndresGonzalez5/vibefloor/commit/e21cf55a9f4316b83a44f1be89f0b43fdc7970b8))
* **main:** release 0.1.49 ([#210](https://github.com/AndresGonzalez5/vibefloor/issues/210)) ([1cf3b7a](https://github.com/AndresGonzalez5/vibefloor/commit/1cf3b7a57b74562391a69d8fb683b1ad7e527163))
* **main:** release 0.1.5 ([#15](https://github.com/AndresGonzalez5/vibefloor/issues/15)) ([0834b40](https://github.com/AndresGonzalez5/vibefloor/commit/0834b4084713c2bd99900ba7d6b7c9212cd4cb31))
* **main:** release 0.1.50 ([#239](https://github.com/AndresGonzalez5/vibefloor/issues/239)) ([e6a8f44](https://github.com/AndresGonzalez5/vibefloor/commit/e6a8f44525223f76743b35317779fddeda3b2f3e))
* **main:** release 0.1.51 ([#249](https://github.com/AndresGonzalez5/vibefloor/issues/249)) ([e1f06fe](https://github.com/AndresGonzalez5/vibefloor/commit/e1f06fe93e8e4ab8b60c009b5c9b891f12416100))
* **main:** release 0.1.52 ([#251](https://github.com/AndresGonzalez5/vibefloor/issues/251)) ([5e42923](https://github.com/AndresGonzalez5/vibefloor/commit/5e429234aab37c348fdad9f1f56cec0385aed568))
* **main:** release 0.1.53 ([#260](https://github.com/AndresGonzalez5/vibefloor/issues/260)) ([9e041a0](https://github.com/AndresGonzalez5/vibefloor/commit/9e041a00865e3b20a2acd628c70c3a5d5eec0cbe))
* **main:** release 0.1.54 ([#276](https://github.com/AndresGonzalez5/vibefloor/issues/276)) ([72529c2](https://github.com/AndresGonzalez5/vibefloor/commit/72529c20f94cc9ada853ecd2187148696c62a7e9))
* **main:** release 0.1.55 ([#278](https://github.com/AndresGonzalez5/vibefloor/issues/278)) ([cfaed98](https://github.com/AndresGonzalez5/vibefloor/commit/cfaed98941eaea7e8b53f70028aed1d542b841f7))
* **main:** release 0.1.56 ([#281](https://github.com/AndresGonzalez5/vibefloor/issues/281)) ([e3bd873](https://github.com/AndresGonzalez5/vibefloor/commit/e3bd873aa9ccd8c4423a02877a7387624316a1bd))
* **main:** release 0.1.57 ([#286](https://github.com/AndresGonzalez5/vibefloor/issues/286)) ([337e544](https://github.com/AndresGonzalez5/vibefloor/commit/337e5443236ba15d6a2266cdb3b1220c9d8e90d0))
* **main:** release 0.1.58 ([#288](https://github.com/AndresGonzalez5/vibefloor/issues/288)) ([b846552](https://github.com/AndresGonzalez5/vibefloor/commit/b846552d3d5d48181432cb74450d09a0fec39f6f))
* **main:** release 0.1.59 ([#290](https://github.com/AndresGonzalez5/vibefloor/issues/290)) ([a636558](https://github.com/AndresGonzalez5/vibefloor/commit/a636558cd22031fe890ead786245ff6e821c8d3e))
* **main:** release 0.1.6 ([#17](https://github.com/AndresGonzalez5/vibefloor/issues/17)) ([b913922](https://github.com/AndresGonzalez5/vibefloor/commit/b913922a713236a9b5b0a2f6a7242197d1bd50b5))
* **main:** release 0.1.60 ([#292](https://github.com/AndresGonzalez5/vibefloor/issues/292)) ([1b0df16](https://github.com/AndresGonzalez5/vibefloor/commit/1b0df160bebf11dd4aa4d872717cb90f9374888f))
* **main:** release 0.1.61 ([#294](https://github.com/AndresGonzalez5/vibefloor/issues/294)) ([b4402b0](https://github.com/AndresGonzalez5/vibefloor/commit/b4402b071b6017bfe84db1063ee6b53fbfef0213))
* **main:** release 0.1.62 ([#296](https://github.com/AndresGonzalez5/vibefloor/issues/296)) ([a307e3a](https://github.com/AndresGonzalez5/vibefloor/commit/a307e3a3166e5835ddfa57302fbdaf2ae6fe6016))
* **main:** release 0.1.63 ([#298](https://github.com/AndresGonzalez5/vibefloor/issues/298)) ([f68bd09](https://github.com/AndresGonzalez5/vibefloor/commit/f68bd09b9cd7ac65a3dc3a04cc93fb82b04534f0))
* **main:** release 0.1.64 ([#311](https://github.com/AndresGonzalez5/vibefloor/issues/311)) ([cb3d3d9](https://github.com/AndresGonzalez5/vibefloor/commit/cb3d3d96cd284136c904c344d36176d56695a750))
* **main:** release 0.1.65 ([#326](https://github.com/AndresGonzalez5/vibefloor/issues/326)) ([3fb96b7](https://github.com/AndresGonzalez5/vibefloor/commit/3fb96b71bb260f5747bcd21770335e423d634150))
* **main:** release 0.1.66 ([#351](https://github.com/AndresGonzalez5/vibefloor/issues/351)) ([a4d7bd6](https://github.com/AndresGonzalez5/vibefloor/commit/a4d7bd63359ac3b2ab062bf0f721ae3f0addff08))
* **main:** release 0.1.67 ([#379](https://github.com/AndresGonzalez5/vibefloor/issues/379)) ([e1a42f2](https://github.com/AndresGonzalez5/vibefloor/commit/e1a42f2f29b34d108e8bb9fb0c3783b45bc27f48))
* **main:** release 0.1.68 ([#391](https://github.com/AndresGonzalez5/vibefloor/issues/391)) ([136f7be](https://github.com/AndresGonzalez5/vibefloor/commit/136f7bea7d625782eac24fe9f44a7b1d7a8b3e48))
* **main:** release 0.1.69 ([#414](https://github.com/AndresGonzalez5/vibefloor/issues/414)) ([5387b8d](https://github.com/AndresGonzalez5/vibefloor/commit/5387b8d0a99d279d27a921b3b77473b430d649f1))
* **main:** release 0.1.7 ([#19](https://github.com/AndresGonzalez5/vibefloor/issues/19)) ([9e58e6a](https://github.com/AndresGonzalez5/vibefloor/commit/9e58e6acd3053a52d66988fa0722e1dbea2584ef))
* **main:** release 0.1.70 ([#417](https://github.com/AndresGonzalez5/vibefloor/issues/417)) ([3e8faf0](https://github.com/AndresGonzalez5/vibefloor/commit/3e8faf0944eb2cfa68b0f567abe830221bde967e))
* **main:** release 0.1.71 ([#419](https://github.com/AndresGonzalez5/vibefloor/issues/419)) ([ba2675c](https://github.com/AndresGonzalez5/vibefloor/commit/ba2675c714dde9ff0bf3d4bb752afc0d31546732))
* **main:** release 0.1.72 ([#422](https://github.com/AndresGonzalez5/vibefloor/issues/422)) ([2ff7d13](https://github.com/AndresGonzalez5/vibefloor/commit/2ff7d13d1e39b66e5d3b9ceee672f1a5d88f3d0a))
* **main:** release 0.1.73 ([#426](https://github.com/AndresGonzalez5/vibefloor/issues/426)) ([3a6ffd9](https://github.com/AndresGonzalez5/vibefloor/commit/3a6ffd940c31d8ae567ca905cd775f6bbc3bed71))
* **main:** release 0.1.74 ([#429](https://github.com/AndresGonzalez5/vibefloor/issues/429)) ([b277e40](https://github.com/AndresGonzalez5/vibefloor/commit/b277e40bc26efe7c92c86bdd377453be40e42580))
* **main:** release 0.1.75 ([#438](https://github.com/AndresGonzalez5/vibefloor/issues/438)) ([ec588ef](https://github.com/AndresGonzalez5/vibefloor/commit/ec588ef86832d66d9879a6fecf8647a270d85755))
* **main:** release 0.1.76 ([#448](https://github.com/AndresGonzalez5/vibefloor/issues/448)) ([18cbecb](https://github.com/AndresGonzalez5/vibefloor/commit/18cbecb60dc32e0c0ca04bb20a9455091540917e))
* **main:** release 0.1.76 ([#481](https://github.com/AndresGonzalez5/vibefloor/issues/481)) ([a5fed2e](https://github.com/AndresGonzalez5/vibefloor/commit/a5fed2ef38c7a5c10ae3b3ae44b02f5348162b3a))
* **main:** release 0.1.77 ([#489](https://github.com/AndresGonzalez5/vibefloor/issues/489)) ([9d281c5](https://github.com/AndresGonzalez5/vibefloor/commit/9d281c5adaacde0fabdd784f970612776a1d1578))
* **main:** release 0.1.78 ([#490](https://github.com/AndresGonzalez5/vibefloor/issues/490)) ([7660ee0](https://github.com/AndresGonzalez5/vibefloor/commit/7660ee0f277f7210e2822b59751bf497a04acd7a))
* **main:** release 0.1.79 ([#494](https://github.com/AndresGonzalez5/vibefloor/issues/494)) ([b91f313](https://github.com/AndresGonzalez5/vibefloor/commit/b91f313d69c9840be2fc6ec44cfb0b793c6b2b5f))
* **main:** release 0.1.8 ([#21](https://github.com/AndresGonzalez5/vibefloor/issues/21)) ([61844ca](https://github.com/AndresGonzalez5/vibefloor/commit/61844cab88e70d94218dc5fddfaa55470a7f401a))
* **main:** release 0.1.9 ([#25](https://github.com/AndresGonzalez5/vibefloor/issues/25)) ([b09208d](https://github.com/AndresGonzalez5/vibefloor/commit/b09208d3cd98b061d26796ad02b8e51be16f02cd))
* mark port detection as implemented, update TODO ([7f530be](https://github.com/AndresGonzalez5/vibefloor/commit/7f530befd7a6d0f9b7051ca249c3a8e5932fc73e))
* update todo ([77bbdcf](https://github.com/AndresGonzalez5/vibefloor/commit/77bbdcfba75da3db14cf07b78cbd7dc1082a71e6))
* update versions.json to v0.1.14 ([b4c06bc](https://github.com/AndresGonzalez5/vibefloor/commit/b4c06bc849f1451a0a5507197d128c1f375ae16a))
* update versions.json to v0.1.15 ([e898537](https://github.com/AndresGonzalez5/vibefloor/commit/e898537e0c959c4f36edb346df47e480cc5f4c05))
* update versions.json to v0.1.16 ([ff602af](https://github.com/AndresGonzalez5/vibefloor/commit/ff602af9f8b7c59e551478d25382429b9e25eed4))
* update versions.json to v0.1.17 ([65042c2](https://github.com/AndresGonzalez5/vibefloor/commit/65042c20894d7c95ef70519009ab287f785a4556))
* update versions.json to v0.1.18 ([5297fc7](https://github.com/AndresGonzalez5/vibefloor/commit/5297fc7a83ef28c566f86a84c898415bfa387899))
* update versions.json to v0.1.19 ([0aed24f](https://github.com/AndresGonzalez5/vibefloor/commit/0aed24f1b5ff5a656f803d819cdf22b35f988cf8))
* update versions.json to v0.1.20 ([88939d1](https://github.com/AndresGonzalez5/vibefloor/commit/88939d16b69dd24981be021ea4fc8de3bca76052))
* update versions.json to v0.1.21 ([db0a820](https://github.com/AndresGonzalez5/vibefloor/commit/db0a820ee71fa496a9999e63b851079556862769))
* update versions.json to v0.1.22 ([51075bb](https://github.com/AndresGonzalez5/vibefloor/commit/51075bb96d8fb9430239461201d092385e4e4de5))
* update versions.json to v0.1.23 ([1f0ef5d](https://github.com/AndresGonzalez5/vibefloor/commit/1f0ef5d489abaa737bbd1255db2aedb84dce33be))
* update versions.json to v0.1.26 ([0776e67](https://github.com/AndresGonzalez5/vibefloor/commit/0776e678857a34597729058bd7b25a49ffced837))
* update versions.json to v0.1.27 ([2daee40](https://github.com/AndresGonzalez5/vibefloor/commit/2daee401eed245da006fe552f3ce64b8eecb7842))
* update versions.json to v0.1.28 ([1507e37](https://github.com/AndresGonzalez5/vibefloor/commit/1507e37d77a4e65753793b8e23abe2215a90bddc))
* update versions.json to v0.1.29 ([4649027](https://github.com/AndresGonzalez5/vibefloor/commit/4649027154a37bd29fd256193ad8170ddfd800ed))
* update versions.json to v0.1.30 ([a319936](https://github.com/AndresGonzalez5/vibefloor/commit/a31993680a3a5f5ed6abb9b8f2bd7064ccb2a696))
* update versions.json to v0.1.31 ([5b0cbbe](https://github.com/AndresGonzalez5/vibefloor/commit/5b0cbbea2197b50b8da6d5f020735c825d49a165))
* update versions.json to v0.1.32 ([a5a400b](https://github.com/AndresGonzalez5/vibefloor/commit/a5a400bd6f8ba7848fd304a187943729b973dedf))
* update versions.json to v0.1.33 ([27ea914](https://github.com/AndresGonzalez5/vibefloor/commit/27ea91456cf15ec4d83429e8e0f8e0e15dceb745))
* update versions.json to v0.1.34 ([4b58179](https://github.com/AndresGonzalez5/vibefloor/commit/4b58179dae5c2343039dbe2cc1a907d76df78cdc))
* update versions.json to v0.1.35 ([4e0a3ac](https://github.com/AndresGonzalez5/vibefloor/commit/4e0a3ac0b8411d4380660ebcce7564ef243df083))
* update versions.json to v0.1.6 ([b0acea2](https://github.com/AndresGonzalez5/vibefloor/commit/b0acea2441e1fd2dc70ff7035b8b8afa12554fbc))
* update versions.json to v0.1.7 ([7a67bf2](https://github.com/AndresGonzalez5/vibefloor/commit/7a67bf2ebb8cea5dc998e788a5c79e17e2f01687))


### Documentation

* add architecture and security review, updated for v0.1.65 ([#355](https://github.com/AndresGonzalez5/vibefloor/issues/355)) ([46013da](https://github.com/AndresGonzalez5/vibefloor/commit/46013da22f1782587ff8fb1544a3b428d7b40051))
* add Corner Office and mobile app design docs ([#361](https://github.com/AndresGonzalez5/vibefloor/issues/361)) ([e6285a9](https://github.com/AndresGonzalez5/vibefloor/commit/e6285a9790442c3b8ec5eb8a7ddf80103d345c5e))
* add ghostty xcframework build guide for macOS 26 ([eee5b85](https://github.com/AndresGonzalez5/vibefloor/commit/eee5b85fc5a3a7ad4a5b363b07deabe933560c1c))
* add hybrid adoption strategy to SwiftGitX analysis ([#112](https://github.com/AndresGonzalez5/vibefloor/issues/112)) ([668b3cd](https://github.com/AndresGonzalez5/vibefloor/commit/668b3cdae7502609409d795ec692474d85460312))
* add pixel agents architecture documentation ([d57c1df](https://github.com/AndresGonzalez5/vibefloor/commit/d57c1df9113829c818c141e02931c5290a52cc37))
* add release command to build instructions ([#62](https://github.com/AndresGonzalez5/vibefloor/issues/62)) ([4ed8099](https://github.com/AndresGonzalez5/vibefloor/commit/4ed80997b166a35a9ba80262c2c4b38dc37715d7))
* add slow background polling fallback for port detection ([37a9cec](https://github.com/AndresGonzalez5/vibefloor/commit/37a9cecd5d1f3151e4c18b3270f7152444516bd9))
* add Sparkle scoping doc; fix(website): native changelog rendering ([#41](https://github.com/AndresGonzalez5/vibefloor/issues/41)) ([#73](https://github.com/AndresGonzalez5/vibefloor/issues/73)) ([ee9805b](https://github.com/AndresGonzalez5/vibefloor/commit/ee9805b6ba1d6400d5ddf45bf76748bcccf5421c))
* add Swift 6 strict concurrency migration plan ([97193fd](https://github.com/AndresGonzalez5/vibefloor/commit/97193fdb753a26e036bc16e60b4b714e69d922b0))
* add SwiftGit2 feasibility analysis (recommendation: don't adopt) ([#105](https://github.com/AndresGonzalez5/vibefloor/issues/105)) ([38fce35](https://github.com/AndresGonzalez5/vibefloor/commit/38fce358fc98c59d66e401726e6b2dc69348d47c))
* add SwiftGitX feasibility analysis ([#110](https://github.com/AndresGonzalez5/vibefloor/issues/110)) ([2970473](https://github.com/AndresGonzalez5/vibefloor/commit/297047352b56e656ae618829dcfb2463ea3add61))
* add terminal resilience design doc ([#219](https://github.com/AndresGonzalez5/vibefloor/issues/219)) ([06ab89a](https://github.com/AndresGonzalez5/vibefloor/commit/06ab89ad0ba0a14f6250ea77e1e6a6246da4da1d))
* add terminal spawning architecture reference ([#217](https://github.com/AndresGonzalez5/vibefloor/issues/217)) ([77b11c3](https://github.com/AndresGonzalez5/vibefloor/commit/77b11c3c21ae58dc7f592ffa20b651f0d1282c5c))
* add translation contribution guide and sponsor page updates ([#356](https://github.com/AndresGonzalez5/vibefloor/issues/356)) ([67e4add](https://github.com/AndresGonzalez5/vibefloor/commit/67e4addc4faefd733b7d0dba4b25aa6952afc043))
* awesome lists submission guide and README install improvements ([#179](https://github.com/AndresGonzalez5/vibefloor/issues/179)) ([ae855a1](https://github.com/AndresGonzalez5/vibefloor/commit/ae855a1d0c8314aeb10f5039b9672ef0615e7c31))
* clarify ff-run crash recovery (user hits Rerun, no special handling) ([78cffae](https://github.com/AndresGonzalez5/vibefloor/commit/78cffae2aaa014bb8a24a80003368754f3e4f204))
* consolidate distribution docs ([9678046](https://github.com/AndresGonzalez5/vibefloor/commit/9678046f447707208eb68fabd3ab7a3f870ce7ed))
* consolidate port detection into final implementation plan ([3f351c4](https://github.com/AndresGonzalez5/vibefloor/commit/3f351c4e3db96b9db755e7d8f16182a7687cec21))
* credit the script approval fix in the changelog ([c5614bb](https://github.com/AndresGonzalez5/vibefloor/commit/c5614bbd29728ecd007f2988e89e5507ad80ec12))
* document .factoryfloor.json script configuration ([#259](https://github.com/AndresGonzalez5/vibefloor/issues/259)) ([d52c0a2](https://github.com/AndresGonzalez5/vibefloor/commit/d52c0a2878a273c75118b950c7cb295d5c2b334a)), closes [#255](https://github.com/AndresGonzalez5/vibefloor/issues/255)
* document Hugo AllTranslations bug in AGENTS.md ([#345](https://github.com/AndresGonzalez5/vibefloor/issues/345)) ([abbc136](https://github.com/AndresGonzalez5/vibefloor/commit/abbc1365a6bcb9d57c6741f61e418b52e6df5954))
* document ProjectList ObservableObject audit results ([#91](https://github.com/AndresGonzalez5/vibefloor/issues/91)) ([#100](https://github.com/AndresGonzalez5/vibefloor/issues/100)) ([b38e2b7](https://github.com/AndresGonzalez5/vibefloor/commit/b38e2b77b55f42f33822ce4be24f1c84d9a9b70d))
* document tmux external access for [#396](https://github.com/AndresGonzalez5/vibefloor/issues/396) ([#401](https://github.com/AndresGonzalez5/vibefloor/issues/401)) ([16af5cf](https://github.com/AndresGonzalez5/vibefloor/commit/16af5cfa5b90fb799545464521a6abbb7ae1299d))
* fix the reporter credit links in the changelog ([e482665](https://github.com/AndresGonzalez5/vibefloor/commit/e48266578eff6a0212d1343323d9bcf46878e879))
* remove port detection disable setting question (not needed) ([3f1757b](https://github.com/AndresGonzalez5/vibefloor/commit/3f1757b686ed01197ab119d378b6614afc075ad6))
* rename CLAUDE.md to AGENTS.md, update README and TODO ([26dd2ad](https://github.com/AndresGonzalez5/vibefloor/commit/26dd2ad9de8591ad91cbb15b92c2eb291d37c6f6))
* replace CLI-centric Get Started with in-app workflow ([#181](https://github.com/AndresGonzalez5/vibefloor/issues/181)) ([dd6347d](https://github.com/AndresGonzalez5/vibefloor/commit/dd6347d48a125f0d391e8a1d9272c93b26fff327))
* scope crash reporting options and implementation plan ([e19d437](https://github.com/AndresGonzalez5/vibefloor/commit/e19d437d7204e55bc018cca41220c5f1d5900d09))
* scope port detection for run scripts ([bd49c43](https://github.com/AndresGonzalez5/vibefloor/commit/bd49c433db94049a72cbffc4530f053e8814ae78))
* update awesome lists tracking table with submission status ([#182](https://github.com/AndresGonzalez5/vibefloor/issues/182)) ([a91bee1](https://github.com/AndresGonzalez5/vibefloor/commit/a91bee19e6900cd572bc5da698d454c47908feff))
* update README to reference vibefloor fork ([560fe3d](https://github.com/AndresGonzalez5/vibefloor/commit/560fe3d77f1823923d6948c6a99c15ca4ee58685))
* update README, AGENTS.md, website, TODO for port detection ([5e63d17](https://github.com/AndresGonzalez5/vibefloor/commit/5e63d171bb3a66ce52c984be168aebe98550b7b9))
* update xcframework build guide with library repack steps ([d5fb780](https://github.com/AndresGonzalez5/vibefloor/commit/d5fb780a06e9777b4ba0ac5ca9ad33bd881c527e))
* use AppIconDebug 256.png for README image ([65edafa](https://github.com/AndresGonzalez5/vibefloor/commit/65edafa13bbaa0565b8665beedd3fd825d67f808))
* use FSEvents instead of polling for port detection state ([2510b6f](https://github.com/AndresGonzalez5/vibefloor/commit/2510b6f3222b016917b1a471ab858aef75c50ef9))
* **website:** translate docs to Catalan, Spanish, and Swedish ([#344](https://github.com/AndresGonzalez5/vibefloor/issues/344)) ([b0794b6](https://github.com/AndresGonzalez5/vibefloor/commit/b0794b676a85abefbb431bff8a5a80485fb1b2d6)), closes [#340](https://github.com/AndresGonzalez5/vibefloor/issues/340)


### CI/CD

* allow revert as a conventional PR title type ([#463](https://github.com/AndresGonzalez5/vibefloor/issues/463)) ([009971c](https://github.com/AndresGonzalez5/vibefloor/commit/009971c7d6a765f7f4669cd0a2c2b06c2cca1a79))
* fix build warnings and improve CI caching ([#154](https://github.com/AndresGonzalez5/vibefloor/issues/154)) ([1c2db0b](https://github.com/AndresGonzalez5/vibefloor/commit/1c2db0b6d18e5c059aa72b14e705e4df6f88297c))
* make Ghostty compat test manual-only and arm64-only ([#165](https://github.com/AndresGonzalez5/vibefloor/issues/165)) ([2e56331](https://github.com/AndresGonzalez5/vibefloor/commit/2e56331d3d5648969a5ce0b8794016f4a76d78a1))
* replace deprecated Node 20 actions with controlled install steps ([#478](https://github.com/AndresGonzalez5/vibefloor/issues/478)) ([865cdb2](https://github.com/AndresGonzalez5/vibefloor/commit/865cdb2d29944df379547a1780af95af1c3651b6)), closes [#151](https://github.com/AndresGonzalez5/vibefloor/issues/151) [#229](https://github.com/AndresGonzalez5/vibefloor/issues/229)
* revert release runners to macos-15 ([#480](https://github.com/AndresGonzalez5/vibefloor/issues/480)) ([b90489a](https://github.com/AndresGonzalez5/vibefloor/commit/b90489ac29ef40498f8890d8939143c8b603a60d))
* validate PR titles as conventional commits ([#462](https://github.com/AndresGonzalez5/vibefloor/issues/462)) ([5207d20](https://github.com/AndresGonzalez5/vibefloor/commit/5207d2030937c3c3478441acf862baea984dbd71))
* **website:** generate the German changelog page ([e049960](https://github.com/AndresGonzalez5/vibefloor/commit/e0499609660b09e91cb726cb5dbd1db4a11f81b2))

## [0.1.79](https://github.com/alltuner/factoryfloor/compare/v0.1.78...v0.1.79) (2026-07-30)


### Bug Fixes

* **ci:** keep appcast history when a previous release has no assets ([#492](https://github.com/alltuner/factoryfloor/issues/492)) ([92eae05](https://github.com/alltuner/factoryfloor/commit/92eae051519c7e4520f17ce8b58c34ee615cbc86))
* **i18n:** add the missing German setup gate strings ([#493](https://github.com/alltuner/factoryfloor/issues/493)) ([fe042f2](https://github.com/alltuner/factoryfloor/commit/fe042f286f12d70cc4b1102244c9ff493bc968fc))


### Documentation

* credit the script approval fix in the changelog ([c5614bb](https://github.com/alltuner/factoryfloor/commit/c5614bbd29728ecd007f2988e89e5507ad80ec12))
* fix the reporter credit links in the changelog ([e482665](https://github.com/alltuner/factoryfloor/commit/e48266578eff6a0212d1343323d9bcf46878e879))


### CI/CD

* **website:** generate the German changelog page ([e049960](https://github.com/alltuner/factoryfloor/commit/e0499609660b09e91cb726cb5dbd1db4a11f81b2))

## [0.1.78](https://github.com/alltuner/factoryfloor/compare/v0.1.77...v0.1.78) (2026-07-30)


### Security

* **Repository-provided `setup`, `run` and `teardown` commands now require your approval before they run.** Earlier versions ran `setup` automatically the first time a workstream's workspace opened, and `teardown` automatically when a workstream was archived, with its output discarded. Neither asked for approval, so adding an untrusted repository and creating a workstream for it could execute a command that the repository supplied, under your user account, with no prompt. Advisory: GHSA-923q-2hmp-prq3 (High, CVSS 7.8).
* The workspace now shows every command and the config file it was read from, and runs nothing until you approve it. Approval is bound to the command text, so an edited config is presented for approval again rather than inheriting the earlier decision, and it can be withdrawn from the Info tab. Repositories you had already added are not carried over; they are presented for approval the next time you create a workstream.
* Reported by AI Census Labs, https://github.com/aicensus-labs, and Junjie He, https://github.com/glmgbj233. Thank you both.


### Bug Fixes

* **build:** restore ghostty submodule gitlink ([233c9c8](https://github.com/alltuner/factoryfloor/commit/233c9c848cdb35f51cf453a609d13614bad57b83))

## [0.1.77](https://github.com/alltuner/factoryfloor/compare/v0.1.76...v0.1.77) (2026-07-30)


### Bug Fixes

* **scripts:** require approval before running repository-provided commands ([a53903a](https://github.com/alltuner/factoryfloor/commit/a53903ae4426995c2b260aff580540c834d70834))

### Note

* This version has no downloadable build, because its release build failed. The same fix ships in 0.1.78, which is the first installable release carrying it.

## [0.1.76](https://github.com/alltuner/factoryfloor/compare/v0.1.75...v0.1.76) (2026-05-29)


### Features

* **telemetry:** enrich Umami payloads and broaden tracked events ([#450](https://github.com/alltuner/factoryfloor/issues/450)) ([7648189](https://github.com/alltuner/factoryfloor/commit/7648189bd5caa57fa884d9d499d79ce448b89e43))


### Bug Fixes

* **deps:** update monaco-vscode to v31 ([#459](https://github.com/alltuner/factoryfloor/issues/459)) ([f1b1347](https://github.com/alltuner/factoryfloor/commit/f1b1347afb2b7a6694181279cad1e1200c1c2875))
* **deps:** update monaco-vscode to v33 ([#471](https://github.com/alltuner/factoryfloor/issues/471)) ([8ecc30e](https://github.com/alltuner/factoryfloor/commit/8ecc30e17e3f81e733805082ad9dc3c2d8c828dd))
* enable extended-keys in tmux config for Shift+Enter support ([#441](https://github.com/alltuner/factoryfloor/issues/441)) ([4e54e75](https://github.com/alltuner/factoryfloor/commit/4e54e75d46b9223f599fb8cded1d2e873695712f))
* propagate window resize to Ghostty ([#443](https://github.com/alltuner/factoryfloor/issues/443)) ([93f4da1](https://github.com/alltuner/factoryfloor/commit/93f4da143fa6a3937e95509484b58a059111afb7))
* sync IME preedit state with libghostty ([#458](https://github.com/alltuner/factoryfloor/issues/458)) ([a582cc2](https://github.com/alltuner/factoryfloor/commit/a582cc2048eb715576d86afb0a25c112c372d153))
* **terminal:** restore scrollback by reverting tmux alternate-screen overrides ([#479](https://github.com/alltuner/factoryfloor/issues/479)) ([e6491c7](https://github.com/alltuner/factoryfloor/commit/e6491c72ff3c9827512a0a7b8772b75aee2fd110)), closes [#395](https://github.com/alltuner/factoryfloor/issues/395)


### Performance

* reduce SwiftUI main-thread churn from AppEnvironment ([#453](https://github.com/alltuner/factoryfloor/issues/453)) ([6d16635](https://github.com/alltuner/factoryfloor/commit/6d1663532cc75f06bbc0597ef74510b747b74498))


### Miscellaneous

* **deps:** update astral-sh/setup-uv action to v8 ([#452](https://github.com/alltuner/factoryfloor/issues/452)) ([76752aa](https://github.com/alltuner/factoryfloor/commit/76752aa880890af7aab05ad6b243cd7f50b4b482))
* **deps:** update dependency macos to v26 ([#472](https://github.com/alltuner/factoryfloor/issues/472)) ([411d724](https://github.com/alltuner/factoryfloor/commit/411d724388c200f0b70279e5584aa3196b410264))
* **deps:** update dependency sentry to v9.10.0 ([#446](https://github.com/alltuner/factoryfloor/issues/446)) ([1917c85](https://github.com/alltuner/factoryfloor/commit/1917c85b6be8712bc344a8c5fbcbce0ad5bc2485))
* **deps:** update dependency sentry to v9.11.0 ([#456](https://github.com/alltuner/factoryfloor/issues/456)) ([4fbd7da](https://github.com/alltuner/factoryfloor/commit/4fbd7da9ac051c60ce05be24e38ef3748a084ea1))
* **deps:** update dependency sentry to v9.12.0 ([#460](https://github.com/alltuner/factoryfloor/issues/460)) ([dca1ee8](https://github.com/alltuner/factoryfloor/commit/dca1ee867bb0d0f7836f96dea0f53253362deae8))
* **deps:** update dependency sentry to v9.15.0 ([#464](https://github.com/alltuner/factoryfloor/issues/464)) ([dddafad](https://github.com/alltuner/factoryfloor/commit/dddafadd8cd762278c57670971bf2d6df8cbb2d2))
* **deps:** update dependency sparkle to v2.9.1 ([#445](https://github.com/alltuner/factoryfloor/issues/445)) ([18bcdd6](https://github.com/alltuner/factoryfloor/commit/18bcdd6782f23a6eeebf5197438cbcebfabf90ae))
* **deps:** update dependency sparkle to v2.9.2 ([#475](https://github.com/alltuner/factoryfloor/issues/475)) ([f90feab](https://github.com/alltuner/factoryfloor/commit/f90feabc40e4c9c50555e93cf73371b15317caf5))
* **deps:** update dependency swift-cmark to v0.7.1 ([#447](https://github.com/alltuner/factoryfloor/issues/447)) ([b278da9](https://github.com/alltuner/factoryfloor/commit/b278da914d2d975dd84e36e27474d7dc97852624))
* **deps:** update dependency swift-cmark to v0.8.0 ([#466](https://github.com/alltuner/factoryfloor/issues/466)) ([f3b9845](https://github.com/alltuner/factoryfloor/commit/f3b9845d89b8d89e320fcaea66d1c0de2a35e45f))
* **deps:** update googleapis/release-please-action action to v5 ([#455](https://github.com/alltuner/factoryfloor/issues/455)) ([bae2bc3](https://github.com/alltuner/factoryfloor/commit/bae2bc332407cb431ab8e55353532aaf4a733962))
* **main:** release 0.1.76 ([#448](https://github.com/alltuner/factoryfloor/issues/448)) ([18cbecb](https://github.com/alltuner/factoryfloor/commit/18cbecb60dc32e0c0ca04bb20a9455091540917e))


### CI/CD

* allow revert as a conventional PR title type ([#463](https://github.com/alltuner/factoryfloor/issues/463)) ([009971c](https://github.com/alltuner/factoryfloor/commit/009971c7d6a765f7f4669cd0a2c2b06c2cca1a79))
* replace deprecated Node 20 actions with controlled install steps ([#478](https://github.com/alltuner/factoryfloor/issues/478)) ([865cdb2](https://github.com/alltuner/factoryfloor/commit/865cdb2d29944df379547a1780af95af1c3651b6)), closes [#151](https://github.com/alltuner/factoryfloor/issues/151) [#229](https://github.com/alltuner/factoryfloor/issues/229)
* revert release runners to macos-15 ([#480](https://github.com/alltuner/factoryfloor/issues/480)) ([b90489a](https://github.com/alltuner/factoryfloor/commit/b90489ac29ef40498f8890d8939143c8b603a60d))
* validate PR titles as conventional commits ([#462](https://github.com/alltuner/factoryfloor/issues/462)) ([5207d20](https://github.com/alltuner/factoryfloor/commit/5207d2030937c3c3478441acf862baea984dbd71))

## [0.1.75](https://github.com/alltuner/factoryfloor/compare/v0.1.74...v0.1.75) (2026-04-13)


### Bug Fixes

* **deps:** update dependency monaco-editor to v30.0.1 ([#434](https://github.com/alltuner/factoryfloor/issues/434)) ([972fa25](https://github.com/alltuner/factoryfloor/commit/972fa25353350dd9e484b555c50dd64894dd9587))
* group Monaco VSCode packages in Renovate config ([#439](https://github.com/alltuner/factoryfloor/issues/439)) ([02e9569](https://github.com/alltuner/factoryfloor/commit/02e9569ad980d3c61070dd9b25da826353746b36)), closes [#436](https://github.com/alltuner/factoryfloor/issues/436)


### Miscellaneous

* **deps:** update actions/upload-pages-artifact action to v5 ([#437](https://github.com/alltuner/factoryfloor/issues/437)) ([5b2ad22](https://github.com/alltuner/factoryfloor/commit/5b2ad2242f293817aced382b3386d9b08ce26aa1))
* **deps:** update dependency vite to v8 ([#435](https://github.com/alltuner/factoryfloor/issues/435)) ([4fac286](https://github.com/alltuner/factoryfloor/commit/4fac286452035f0e92f1f1ff9e325f9ee717a587))

## [0.1.74](https://github.com/alltuner/factoryfloor/compare/v0.1.73...v0.1.74) (2026-04-13)


### Bug Fixes

* **deps:** update dependency @codingame/monaco-vscode-standalone-typescript-language-features to v30.0.1 ([#427](https://github.com/alltuner/factoryfloor/issues/427)) ([0f8f342](https://github.com/alltuner/factoryfloor/commit/0f8f3425148fcbebc43f60fbc66a630d807425c6))
* **deps:** update dependency @codingame/monaco-vscode-textmate-service-override to v30.0.1 ([#428](https://github.com/alltuner/factoryfloor/issues/428)) ([bdaf790](https://github.com/alltuner/factoryfloor/commit/bdaf79023b939604603c78b6a21b0ee51332b225))
* **deps:** update dependency @codingame/monaco-vscode-theme-service-override to v30.0.1 ([#432](https://github.com/alltuner/factoryfloor/issues/432)) ([cbb8137](https://github.com/alltuner/factoryfloor/commit/cbb8137e5831b987d034287f7f3d4f678204d30f))


### Refactoring

* rebuild Sparkle changelog from CHANGELOG.md on every release ([#430](https://github.com/alltuner/factoryfloor/issues/430)) ([51d9c92](https://github.com/alltuner/factoryfloor/commit/51d9c922f2e8a5823fe95a0c46a0d058b324f53c))

## [0.1.73](https://github.com/alltuner/factoryfloor/compare/v0.1.72...v0.1.73) (2026-04-13)


### Bug Fixes

* deduplicate versions and filter noise in Sparkle changelog ([#425](https://github.com/alltuner/factoryfloor/issues/425)) ([30c48d9](https://github.com/alltuner/factoryfloor/commit/30c48d985ac3005582e8257862e8df4e2114089d))

## [0.1.72](https://github.com/alltuner/factoryfloor/compare/v0.1.71...v0.1.72) (2026-04-13)


### Bug Fixes

* **ci:** download appcast from previous release, not latest ([#423](https://github.com/alltuner/factoryfloor/issues/423)) ([062b328](https://github.com/alltuner/factoryfloor/commit/062b328ed43e0db770fdb8f3b67e0fe644c9f405))
* **deps:** update dependency @codingame/monaco-vscode-standalone-html-language-features to v30.0.1 ([#420](https://github.com/alltuner/factoryfloor/issues/420)) ([20517fd](https://github.com/alltuner/factoryfloor/commit/20517fd05a4054ceca73154cf61b527a1d260a31))
* **deps:** update dependency @codingame/monaco-vscode-standalone-json-language-features to v30.0.1 ([#421](https://github.com/alltuner/factoryfloor/issues/421)) ([821c6b6](https://github.com/alltuner/factoryfloor/commit/821c6b6c28e64f1a044a15d76a3c5a662dd7a65f))
* DMG skyline clipped by Finder status bar ([#424](https://github.com/alltuner/factoryfloor/issues/424)) ([c087cb9](https://github.com/alltuner/factoryfloor/commit/c087cb9ede4313aaa3f0f6fcb21739cf73ffc2b3))

## [0.1.71](https://github.com/alltuner/factoryfloor/compare/v0.1.70...v0.1.71) (2026-04-13)


### Features

* show cumulative changelog in update popover ([#418](https://github.com/alltuner/factoryfloor/issues/418)) ([12caa50](https://github.com/alltuner/factoryfloor/commit/12caa50d83bdcc7e585ec722fd243de1ce8b041d))

## [0.1.70](https://github.com/alltuner/factoryfloor/compare/v0.1.69...v0.1.70) (2026-04-13)


### Bug Fixes

* **ci:** increase Node heap size for Monaco editor build ([#416](https://github.com/alltuner/factoryfloor/issues/416)) ([ed37bdb](https://github.com/alltuner/factoryfloor/commit/ed37bdbf2ee8df457a7a4d967b10a7ed33e24ef9))

## [0.1.69](https://github.com/alltuner/factoryfloor/compare/v0.1.68...v0.1.69) (2026-04-13)


### Bug Fixes

* **ci:** build Monaco editor before xcodegen in release workflow ([#415](https://github.com/alltuner/factoryfloor/issues/415)) ([ff7907f](https://github.com/alltuner/factoryfloor/commit/ff7907fa39f33af6c8c4a289033fae4d91e4f42e))
* **deps:** update dependency @codingame/monaco-vscode-languages-service-override to v30.0.1 ([#412](https://github.com/alltuner/factoryfloor/issues/412)) ([55acef4](https://github.com/alltuner/factoryfloor/commit/55acef4169279f00c1e07ecc04e279cdb655fac7))
* **deps:** update dependency @codingame/monaco-vscode-standalone-css-language-features to v30.0.1 ([#413](https://github.com/alltuner/factoryfloor/issues/413)) ([522052a](https://github.com/alltuner/factoryfloor/commit/522052a7565ada24dcf416d21fb9e4cab0065516))

## [0.1.68](https://github.com/alltuner/factoryfloor/compare/v0.1.67...v0.1.68) (2026-04-13)


### Features

* add activity indicators and compact sidebar layout ([#406](https://github.com/alltuner/factoryfloor/issues/406)) ([e5fcb7e](https://github.com/alltuner/factoryfloor/commit/e5fcb7ee83c61e6eed3e8aa0456c1e9610738364)), closes [#399](https://github.com/alltuner/factoryfloor/issues/399)
* add file editor with Monaco integration ([#389](https://github.com/alltuner/factoryfloor/issues/389)) ([969d5c1](https://github.com/alltuner/factoryfloor/commit/969d5c10e6d9f0b2f5405ed48e5f1b582ca20e8f))
* consolidate GitHub actions into contextual dropdown ([#405](https://github.com/alltuner/factoryfloor/issues/405)) ([fbfaabf](https://github.com/alltuner/factoryfloor/commit/fbfaabff259af0a4e9dd8082131b803b7016f7ee)), closes [#398](https://github.com/alltuner/factoryfloor/issues/398)
* credit contributors in release changelog entries ([#410](https://github.com/alltuner/factoryfloor/issues/410)) ([47817e9](https://github.com/alltuner/factoryfloor/commit/47817e954a90c0bf3b59004341a9986e2d4bf9ba))
* reorganize workspace tabs with Info as first tab ([#407](https://github.com/alltuner/factoryfloor/issues/407)) ([83cacaa](https://github.com/alltuner/factoryfloor/commit/83cacaaa6c989e27d70c8a310fb353decb88674d)), closes [#400](https://github.com/alltuner/factoryfloor/issues/400)


### Bug Fixes

* auto-focus terminal when selecting workstream from sidebar ([#402](https://github.com/alltuner/factoryfloor/issues/402)) ([b87395c](https://github.com/alltuner/factoryfloor/commit/b87395c6cff7f4f33db05a7d6f31d4d092896df3)), closes [#394](https://github.com/alltuner/factoryfloor/issues/394)
* **deps:** update dependency @codingame/monaco-vscode-all-language-default-extensions to v30.0.1 ([#408](https://github.com/alltuner/factoryfloor/issues/408)) ([5b7a85f](https://github.com/alltuner/factoryfloor/commit/5b7a85f79ce63fae62186ac968d98adae574c4e6))
* **deps:** update dependency @codingame/monaco-vscode-api to v30.0.1 ([#409](https://github.com/alltuner/factoryfloor/issues/409)) ([a8e7f45](https://github.com/alltuner/factoryfloor/commit/a8e7f45786c779dab7dc0b2479deaf2898b06e33))
* rename Abandon PR to Close PR to match GitHub terminology ([#403](https://github.com/alltuner/factoryfloor/issues/403)) ([061a6c3](https://github.com/alltuner/factoryfloor/commit/061a6c3e7bff1fb708e5c8c04faee8b6727275f3)), closes [#397](https://github.com/alltuner/factoryfloor/issues/397)
* show correct shortcut numbers on closeable tabs ([#392](https://github.com/alltuner/factoryfloor/issues/392)) ([e9d4c3f](https://github.com/alltuner/factoryfloor/commit/e9d4c3fab3f6d8f55a904f952d75f5a437319459)), closes [#387](https://github.com/alltuner/factoryfloor/issues/387)
* use remote tracking ref for worktree creation instead of updating local main ([#404](https://github.com/alltuner/factoryfloor/issues/404)) ([5da6b98](https://github.com/alltuner/factoryfloor/commit/5da6b98d8eca3903d624e85fc49b61cc3c1686a5)), closes [#393](https://github.com/alltuner/factoryfloor/issues/393)
* **worktrees:** avoid prune prompt for newly created workstreams ([#384](https://github.com/alltuner/factoryfloor/issues/384)) ([a7d89d1](https://github.com/alltuner/factoryfloor/commit/a7d89d14aa5d79aca09124e16675de84300db41a))


### Miscellaneous

* **deps:** update actions/checkout action to v6 ([#390](https://github.com/alltuner/factoryfloor/issues/390)) ([327844d](https://github.com/alltuner/factoryfloor/commit/327844debdff94e6128ac768da378c2c3e5fcdf6))


### Documentation

* document tmux external access for [#396](https://github.com/alltuner/factoryfloor/issues/396) ([#401](https://github.com/alltuner/factoryfloor/issues/401)) ([16af5cf](https://github.com/alltuner/factoryfloor/commit/16af5cfa5b90fb799545464521a6abbb7ae1299d))

## [0.1.67](https://github.com/alltuner/factoryfloor/compare/v0.1.66...v0.1.67) (2026-04-08)


### Features

* add German (de) localization for app and website ([#383](https://github.com/alltuner/factoryfloor/issues/383)) ([20d82a8](https://github.com/alltuner/factoryfloor/commit/20d82a8bf871d281ab2abf7bfcb7d8a775a39227))
* prioritize task description over generated name across all views ([#380](https://github.com/alltuner/factoryfloor/issues/380)) ([45e66d4](https://github.com/alltuner/factoryfloor/commit/45e66d46393ab143aa6ec6fefe60ab8b44cbed7c))
* setup script as blocking gate, tmux restore, menu cleanup ([#382](https://github.com/alltuner/factoryfloor/issues/382)) ([15d74b1](https://github.com/alltuner/factoryfloor/commit/15d74b19c6fbbd8c593e178792d4166fb4a4c7d1))


### Bug Fixes

* remove web-browser entitlement that requires Apple approval ([#378](https://github.com/alltuner/factoryfloor/issues/378)) ([31c0578](https://github.com/alltuner/factoryfloor/commit/31c0578f862b7e49dda044be1f8b7c9a3c2d4456))
* set manual signing and remove redundant debug entitlements ([#381](https://github.com/alltuner/factoryfloor/issues/381)) ([2881455](https://github.com/alltuner/factoryfloor/commit/28814551982b8ce72d4e6fe6cb94aa4a8a06b0c8))

## [0.1.66](https://github.com/alltuner/factoryfloor/compare/v0.1.65...v0.1.66) (2026-04-08)


### Features

* add emdash config support, FF_DEFAULT_BRANCH, and compatibility env var aliases ([#367](https://github.com/alltuner/factoryfloor/issues/367)) ([1bd820c](https://github.com/alltuner/factoryfloor/commit/1bd820c20e85f04b20c649764ce3f2670c590233))
* add setting to restrict agent filesystem writes to worktree ([#358](https://github.com/alltuner/factoryfloor/issues/358)) ([188d1ec](https://github.com/alltuner/factoryfloor/commit/188d1ecc1bf80fe6f7b201dcb2b6a66a7b204a13))
* redesign workstream info page with native macOS grouped form ([#360](https://github.com/alltuner/factoryfloor/issues/360)) ([6ed3ac9](https://github.com/alltuner/factoryfloor/commit/6ed3ac951944ec612e6afaeb21b7f7c3d97cda2f))
* show workstream description tooltip on sidebar hover ([#350](https://github.com/alltuner/factoryfloor/issues/350)) ([a89d090](https://github.com/alltuner/factoryfloor/commit/a89d090e42d35786840de2d211693dddbb47a71a))
* sync terminal color scheme with system dark/light mode ([#362](https://github.com/alltuner/factoryfloor/issues/362)) ([a6dd299](https://github.com/alltuner/factoryfloor/commit/a6dd299c2fc3280d95847df51846fbd8447bae57)), closes [#359](https://github.com/alltuner/factoryfloor/issues/359)
* update main branch and clean up after purging a workstream ([#369](https://github.com/alltuner/factoryfloor/issues/369)) ([f20b13c](https://github.com/alltuner/factoryfloor/commit/f20b13c14f5aed4776cb6315c51bcccd9ea21aeb))


### Bug Fixes

* **browser:** enable passkey support in embedded browser ([#366](https://github.com/alltuner/factoryfloor/issues/366)) ([e940ffa](https://github.com/alltuner/factoryfloor/commit/e940ffac87aa5df41142e19edf05873312a7516c))
* keep workstream views alive across rapid Cmd+[/] switching ([#372](https://github.com/alltuner/factoryfloor/issues/372)) ([48642ab](https://github.com/alltuner/factoryfloor/commit/48642ab80d7cbd348d59e12025e507bb4d1e8120))
* preserve run terminal visibility across workstream switching ([#375](https://github.com/alltuner/factoryfloor/issues/375)) ([2a9d37b](https://github.com/alltuner/factoryfloor/commit/2a9d37b05458076bea9e9449d28d2b58832ee8f0))
* revert ZStack-all-workstreams to single active TerminalContainerView ([#374](https://github.com/alltuner/factoryfloor/issues/374)) ([e68cb0e](https://github.com/alltuner/factoryfloor/commit/e68cb0e2c08845fcb521809e14dabd45a049047f))
* separate debug entitlements to fix ad-hoc signed builds ([#368](https://github.com/alltuner/factoryfloor/issues/368)) ([c155ca4](https://github.com/alltuner/factoryfloor/commit/c155ca4d5a101476452fa3c26b1fa7967782096b))
* toolbar duplication and SourceKit-LSP false positives in worktrees ([#373](https://github.com/alltuner/factoryfloor/issues/373)) ([3bae95b](https://github.com/alltuner/factoryfloor/commit/3bae95b2b6ab81b06ec8fe4a28a44bd1980b2233))
* update stale keyboard shortcut references across UI and docs ([#371](https://github.com/alltuner/factoryfloor/issues/371)) ([911d311](https://github.com/alltuner/factoryfloor/commit/911d31173ee51c842234415d704678b5d7674893))
* **website:** improve footer and nav responsiveness ([#357](https://github.com/alltuner/factoryfloor/issues/357)) ([d96557f](https://github.com/alltuner/factoryfloor/commit/d96557f2e839722a33b8e18f2d96f7591852f929))


### Refactoring

* revamp keyboard shortcuts to follow macOS conventions ([#365](https://github.com/alltuner/factoryfloor/issues/365)) ([c18ef6f](https://github.com/alltuner/factoryfloor/commit/c18ef6f3ec0c1b36a06d92f12541eaaa0545dd17))


### Performance

* instant workstream switching ([#377](https://github.com/alltuner/factoryfloor/issues/377)) ([3f987a9](https://github.com/alltuner/factoryfloor/commit/3f987a94cc22c20004eaf84bba58522f3a042fcf))


### Documentation

* add architecture and security review, updated for v0.1.65 ([#355](https://github.com/alltuner/factoryfloor/issues/355)) ([46013da](https://github.com/alltuner/factoryfloor/commit/46013da22f1782587ff8fb1544a3b428d7b40051))
* add Corner Office and mobile app design docs ([#361](https://github.com/alltuner/factoryfloor/issues/361)) ([e6285a9](https://github.com/alltuner/factoryfloor/commit/e6285a9790442c3b8ec5eb8a7ddf80103d345c5e))
* add translation contribution guide and sponsor page updates ([#356](https://github.com/alltuner/factoryfloor/issues/356)) ([67e4add](https://github.com/alltuner/factoryfloor/commit/67e4addc4faefd733b7d0dba4b25aa6952afc043))

## [0.1.65](https://github.com/alltuner/factoryfloor/compare/v0.1.64...v0.1.65) (2026-04-03)


### Features

* add Open on GitHub button for projects with GitHub remotes ([#330](https://github.com/alltuner/factoryfloor/issues/330)) ([9c7c7f5](https://github.com/alltuner/factoryfloor/commit/9c7c7f5dcd28c12059c16018b6d0f483d4bc175c))
* Cmd+Click opens links in external browser and fix HTTP redirects ([#331](https://github.com/alltuner/factoryfloor/issues/331)) ([599253a](https://github.com/alltuner/factoryfloor/commit/599253a66066cc1ae4b586a3d04392bc7d9f7db2))
* display agent-generated task descriptions in sidebar ([#336](https://github.com/alltuner/factoryfloor/issues/336)) ([6bac1fe](https://github.com/alltuner/factoryfloor/commit/6bac1fe9d625cd9710dd58433f9b79a867cca8b8))
* make run play icons clickable and style center start button ([#328](https://github.com/alltuner/factoryfloor/issues/328)) ([0007372](https://github.com/alltuner/factoryfloor/commit/0007372a18fb6e6a729ec39102602b2340fd8fe2))
* show task description in workstream title subtitle ([#339](https://github.com/alltuner/factoryfloor/issues/339)) ([3b475a9](https://github.com/alltuner/factoryfloor/commit/3b475a9e1de70060033e9257b03c043662e83964))
* **website:** add docs section, issue templates, and improve site navigation ([#342](https://github.com/alltuner/factoryfloor/issues/342)) ([a20d0f0](https://github.com/alltuner/factoryfloor/commit/a20d0f0ce7f38c995cdfed8374e0cba456bd536f)), closes [#338](https://github.com/alltuner/factoryfloor/issues/338)


### Bug Fixes

* re-sort sidebar projects when workstream activity updates lastAccessedAt ([#327](https://github.com/alltuner/factoryfloor/issues/327)) ([0005ed6](https://github.com/alltuner/factoryfloor/commit/0005ed624fc45ad87843a4960e6e59dadfe37c10))
* refresh git repo cache immediately when project is added via drag-drop ([#325](https://github.com/alltuner/factoryfloor/issues/325)) ([6921180](https://github.com/alltuner/factoryfloor/commit/692118070cf0254143ab297151aca7afb2489399))


### Miscellaneous

* ignore dirty state in ghostty submodule ([#346](https://github.com/alltuner/factoryfloor/issues/346)) ([400dcc0](https://github.com/alltuner/factoryfloor/commit/400dcc0f09446047a79716c4dec0918d2ef38e69))


### Documentation

* document Hugo AllTranslations bug in AGENTS.md ([#345](https://github.com/alltuner/factoryfloor/issues/345)) ([abbc136](https://github.com/alltuner/factoryfloor/commit/abbc1365a6bcb9d57c6741f61e418b52e6df5954))
* **website:** translate docs to Catalan, Spanish, and Swedish ([#344](https://github.com/alltuner/factoryfloor/issues/344)) ([b0794b6](https://github.com/alltuner/factoryfloor/commit/b0794b676a85abefbb431bff8a5a80485fb1b2d6)), closes [#340](https://github.com/alltuner/factoryfloor/issues/340)

## [0.1.64](https://github.com/alltuner/factoryfloor/compare/v0.1.63...v0.1.64) (2026-04-03)


### Features

* add Reveal in Finder and Open in External Terminal to sidebar context menus ([#310](https://github.com/alltuner/factoryfloor/issues/310)) ([775e188](https://github.com/alltuner/factoryfloor/commit/775e188b4b85706e59ed70e6782dca4e7b0aef1c))
* adopt existing worktrees as workstreams and enrich worktree status ([#313](https://github.com/alltuner/factoryfloor/issues/313)) ([7f09a3f](https://github.com/alltuner/factoryfloor/commit/7f09a3f4074e802478e4a67be10e551456a179b6))
* background fetch of origin default branch every 2 minutes ([#320](https://github.com/alltuner/factoryfloor/issues/320)) ([cd73dc5](https://github.com/alltuner/factoryfloor/commit/cd73dc5dd8b7ed722e420001834ed1ce8729ffed))
* collapse doc tabs by default and pin to bottom of info views ([#315](https://github.com/alltuner/factoryfloor/issues/315)) ([7c38c6e](https://github.com/alltuner/factoryfloor/commit/7c38c6eb55c50c947a4b07143e35c0cff26e8974))
* detect merged PRs and show archive prompt for completed workstreams ([#316](https://github.com/alltuner/factoryfloor/issues/316)) ([4c062ad](https://github.com/alltuner/factoryfloor/commit/4c062ad5f7b5d2b0a598058b7a6b1df1df346ddc))
* support drag-and-drop of files and text onto embedded terminal ([#312](https://github.com/alltuner/factoryfloor/issues/312)) ([1d568a6](https://github.com/alltuner/factoryfloor/commit/1d568a6602e9368a34396e780a4054e57e5957ab))


### Bug Fixes

* differentiate merged vs open PRs and make PR badges clickable in worktree list ([#321](https://github.com/alltuner/factoryfloor/issues/321)) ([58d9c73](https://github.com/alltuner/factoryfloor/commit/58d9c7385156090d7a329c2c973b076e81735b97))
* Fish 4.0 shell escaping breaks tmux and agent launch ([#324](https://github.com/alltuner/factoryfloor/issues/324)) ([323d136](https://github.com/alltuner/factoryfloor/commit/323d136350d1bd803f446d78031403765acb7b69))
* init ghostty submodule properly instead of symlinking entire directory ([#323](https://github.com/alltuner/factoryfloor/issues/323)) ([702f786](https://github.com/alltuner/factoryfloor/commit/702f7867a634311eeff068e8674480add57da143)), closes [#322](https://github.com/alltuner/factoryfloor/issues/322)
* persist quick action runner across workstream navigation ([#317](https://github.com/alltuner/factoryfloor/issues/317)) ([3c04488](https://github.com/alltuner/factoryfloor/commit/3c0448804f373d5d91d8339be1347b3453cd8940))
* preserve active tab when cycling workstreams with Cmd+Shift+[/] ([#318](https://github.com/alltuner/factoryfloor/issues/318)) ([e4547be](https://github.com/alltuner/factoryfloor/commit/e4547be28a8d708996f2437450518b07588c075c))
* skip submodule dirty checks in git status ([#314](https://github.com/alltuner/factoryfloor/issues/314)) ([8ae6395](https://github.com/alltuner/factoryfloor/commit/8ae6395a24ad4a096a7fc2be8ba95e8f02af2203))

## [0.1.63](https://github.com/alltuner/factoryfloor/compare/v0.1.62...v0.1.63) (2026-04-02)


### Features

* quick actions, workspace UI improvements, and settings redesign ([#307](https://github.com/alltuner/factoryfloor/issues/307)) ([3842c21](https://github.com/alltuner/factoryfloor/commit/3842c21dd4be4877f82ed35b4e232a42b6c34857))


### Bug Fixes

* cache isGitRepo and port state to avoid main-thread I/O in sidebar ([#299](https://github.com/alltuner/factoryfloor/issues/299)) ([1a9999f](https://github.com/alltuner/factoryfloor/commit/1a9999f109d4f1a43480424ea85f95aeb972dc84))
* check Ghostty resources exist before building ([#297](https://github.com/alltuner/factoryfloor/issues/297)) ([c89ca5a](https://github.com/alltuner/factoryfloor/commit/c89ca5a2c1b22b472427a605eadc2d1683bb982c)), closes [#284](https://github.com/alltuner/factoryfloor/issues/284)
* detect CLI tools in fish shell and Nix environments ([#300](https://github.com/alltuner/factoryfloor/issues/300)) ([2c2c5b1](https://github.com/alltuner/factoryfloor/commit/2c2c5b1e624fc284e9d86443b7066c8134e87ba1))
* PR number formatting and worktree zig-out symlink ([#301](https://github.com/alltuner/factoryfloor/issues/301)) ([d9b3a9b](https://github.com/alltuner/factoryfloor/commit/d9b3a9b68fd072a9d545fa254cdccee9111eab12))
* sidebar branch name delay and improve workstream row content ([#306](https://github.com/alltuner/factoryfloor/issues/306)) ([86b83cf](https://github.com/alltuner/factoryfloor/commit/86b83cfa62b70a941db72b16d55fcca5a9756346))


### Miscellaneous

* **deps:** update actions/checkout action to v6 ([#305](https://github.com/alltuner/factoryfloor/issues/305)) ([1dc5605](https://github.com/alltuner/factoryfloor/commit/1dc5605a0cd8212e01b11a3c6575aefa6cdcf5ce))

## [0.1.62](https://github.com/alltuner/factoryfloor/compare/v0.1.61...v0.1.62) (2026-04-01)


### Bug Fixes

* retry GitHub release asset uploads ([#295](https://github.com/alltuner/factoryfloor/issues/295)) ([f37aa7f](https://github.com/alltuner/factoryfloor/commit/f37aa7fbeab771937a8999ae191389a3041ac48d))

## [0.1.61](https://github.com/alltuner/factoryfloor/compare/v0.1.60...v0.1.61) (2026-04-01)


### Bug Fixes

* handle notification delivery callback off main thread ([#293](https://github.com/alltuner/factoryfloor/issues/293)) ([d31f06f](https://github.com/alltuner/factoryfloor/commit/d31f06fcb42113e420fabb820d7104d237026157))

## [0.1.60](https://github.com/alltuner/factoryfloor/compare/v0.1.59...v0.1.60) (2026-04-01)


### Bug Fixes

* remove sendable requirement from notification request protocol ([#291](https://github.com/alltuner/factoryfloor/issues/291)) ([337ff89](https://github.com/alltuner/factoryfloor/commit/337ff893ede250ac3f8ccaa65d863696eaf0b14f))

## [0.1.59](https://github.com/alltuner/factoryfloor/compare/v0.1.58...v0.1.59) (2026-04-01)


### Bug Fixes

* avoid main-actor notification callback crash ([#289](https://github.com/alltuner/factoryfloor/issues/289)) ([ec03f7d](https://github.com/alltuner/factoryfloor/commit/ec03f7d7cd2b1fcce5713de683b84b0060eb2d79))

## [0.1.58](https://github.com/alltuner/factoryfloor/compare/v0.1.57...v0.1.58) (2026-04-01)


### Bug Fixes

* handle notification authorization on main thread ([#287](https://github.com/alltuner/factoryfloor/issues/287)) ([6376d3a](https://github.com/alltuner/factoryfloor/commit/6376d3a78e9a630f0bdf4a4d97811d9c18d0f9aa))

## [0.1.57](https://github.com/alltuner/factoryfloor/compare/v0.1.56...v0.1.57) (2026-04-01)


### Bug Fixes

* **ci:** cache ghostty share dirs needed by xcodegen ([#285](https://github.com/alltuner/factoryfloor/issues/285)) ([7b243c3](https://github.com/alltuner/factoryfloor/commit/7b243c30e3f2d1dd5e1111099f2388e9e8b9177d))

## [0.1.56](https://github.com/alltuner/factoryfloor/compare/v0.1.55...v0.1.56) (2026-04-01)


### Bug Fixes

* align local release script signing with CI workflow ([#282](https://github.com/alltuner/factoryfloor/issues/282)) ([76a0dcf](https://github.com/alltuner/factoryfloor/commit/76a0dcfb7ceaba7d2db25614a1da33d39f3a13d2))
* bundle ghostty terminfo and shell integration in app resources ([#283](https://github.com/alltuner/factoryfloor/issues/283)) ([bd4ea71](https://github.com/alltuner/factoryfloor/commit/bd4ea712cec51ae8d750dfc12afb10500e722eec))
* use local entitlements to bypass library validation in dev release builds ([#280](https://github.com/alltuner/factoryfloor/issues/280)) ([2f8161c](https://github.com/alltuner/factoryfloor/commit/2f8161cb99efb4e811eb58c7582453acbe65a8c2)), closes [#279](https://github.com/alltuner/factoryfloor/issues/279)

## [0.1.55](https://github.com/alltuner/factoryfloor/compare/v0.1.54...v0.1.55) (2026-03-31)


### Bug Fixes

* move notification authorization to applicationDidFinishLaunching ([#277](https://github.com/alltuner/factoryfloor/issues/277)) ([6085ffd](https://github.com/alltuner/factoryfloor/commit/6085ffd0e0ed57d2ec82f579964c4499281285af)), closes [#274](https://github.com/alltuner/factoryfloor/issues/274)

## [0.1.54](https://github.com/alltuner/factoryfloor/compare/v0.1.53...v0.1.54) (2026-03-31)


### Bug Fixes

* dispatch notification authorization handler to main thread ([#275](https://github.com/alltuner/factoryfloor/issues/275)) ([fee40fc](https://github.com/alltuner/factoryfloor/commit/fee40fc4a99acc49d0243ed7d863927af6872202)), closes [#274](https://github.com/alltuner/factoryfloor/issues/274)

## [0.1.53](https://github.com/alltuner/factoryfloor/compare/v0.1.52...v0.1.53) (2026-03-31)


### Features

* auto-fetch origin/main before worktree creation ([#257](https://github.com/alltuner/factoryfloor/issues/257)) ([cfa8dc6](https://github.com/alltuner/factoryfloor/commit/cfa8dc640decdad5d7816f6a3826f79c5370885a)), closes [#253](https://github.com/alltuner/factoryfloor/issues/253)
* handle ghostty desktop notifications and bell actions ([#264](https://github.com/alltuner/factoryfloor/issues/264)) ([fde32f5](https://github.com/alltuner/factoryfloor/commit/fde32f563e40bb00643dc0721043c774b3b1ef04))
* support conductor.json and superset config as script fallbacks ([#261](https://github.com/alltuner/factoryfloor/issues/261)) ([0a4f0bc](https://github.com/alltuner/factoryfloor/commit/0a4f0bc32c522b6053d843df1c3c0cc7f5076894)), closes [#256](https://github.com/alltuner/factoryfloor/issues/256)


### Bug Fixes

* enable desktop notifications by adding UNUserNotificationCenterDelegate ([#269](https://github.com/alltuner/factoryfloor/issues/269)) ([0c5d9f1](https://github.com/alltuner/factoryfloor/commit/0c5d9f14edd352a9f84af8cafa476d2f2fca637f))
* match ghostty trackpad scroll speed and momentum ([#263](https://github.com/alltuner/factoryfloor/issues/263)) ([60996a2](https://github.com/alltuner/factoryfloor/commit/60996a2e26a8fae0df891e51babbfe527a2bba81)), closes [#262](https://github.com/alltuner/factoryfloor/issues/262)
* prevent user tmux config from leaking into sessions ([#272](https://github.com/alltuner/factoryfloor/issues/272)) ([c7ccef9](https://github.com/alltuner/factoryfloor/commit/c7ccef93ed8236a6bcbb8ee277c6c1ffe4fa24b7))
* resolve build error and warnings in ContentView and TerminalApp ([#265](https://github.com/alltuner/factoryfloor/issues/265)) ([06d476d](https://github.com/alltuner/factoryfloor/commit/06d476d7fb54bd2d4d9b643fb13ad378824f93f2))
* respawn agent in tmux mode when process exits ([#267](https://github.com/alltuner/factoryfloor/issues/267)) ([f8e54a1](https://github.com/alltuner/factoryfloor/commit/f8e54a1c32152c064748540ed95550201824706f))
* revert worktree-create hook to symlink only xcframework ([#273](https://github.com/alltuner/factoryfloor/issues/273)) ([9ed32b5](https://github.com/alltuner/factoryfloor/commit/9ed32b5584ba69ce097bb7c8f10123b8a9568151))
* scope tmux respawn hook to agent sessions only ([#268](https://github.com/alltuner/factoryfloor/issues/268)) ([e4b57af](https://github.com/alltuner/factoryfloor/commit/e4b57af886f826acc73b30c1dd4c857ff2d7aaf4))
* show explicit desktop notifications even when app is active ([#266](https://github.com/alltuner/factoryfloor/issues/266)) ([f0b04ca](https://github.com/alltuner/factoryfloor/commit/f0b04caa4ab9bbda5c02b731ecf82184fb2ac301))


### Performance

* show workstream UI instantly during worktree creation ([#258](https://github.com/alltuner/factoryfloor/issues/258)) ([8f31121](https://github.com/alltuner/factoryfloor/commit/8f31121cf49c260b08119c109ab41c1e6c987b85)), closes [#254](https://github.com/alltuner/factoryfloor/issues/254)


### Miscellaneous

* **deps:** update actions/checkout action to v6 ([#271](https://github.com/alltuner/factoryfloor/issues/271)) ([0ac67a2](https://github.com/alltuner/factoryfloor/commit/0ac67a28ac9d8bc53a349db69ec48878434b75c5))


### Documentation

* document .factoryfloor.json script configuration ([#259](https://github.com/alltuner/factoryfloor/issues/259)) ([d52c0a2](https://github.com/alltuner/factoryfloor/commit/d52c0a2878a273c75118b950c7cb295d5c2b334a)), closes [#255](https://github.com/alltuner/factoryfloor/issues/255)

## [0.1.52](https://github.com/alltuner/factoryfloor/compare/v0.1.51...v0.1.52) (2026-03-31)


### Bug Fixes

* create empty initial commit on git init to enable worktrees ([#252](https://github.com/alltuner/factoryfloor/issues/252)) ([656e5f3](https://github.com/alltuner/factoryfloor/commit/656e5f38a80530fa037b898b6a4a2cc4c0703961))
* prefer login shell PATH for tool detection ([#250](https://github.com/alltuner/factoryfloor/issues/250)) ([407683d](https://github.com/alltuner/factoryfloor/commit/407683dccfcb27f3b00f30a989dc0b216a54b331))

## [0.1.51](https://github.com/alltuner/factoryfloor/compare/v0.1.50...v0.1.51) (2026-03-31)


### Bug Fixes

* stop overriding PATH and redirecting stderr in agent launch ([#248](https://github.com/alltuner/factoryfloor/issues/248)) ([cbc1d19](https://github.com/alltuner/factoryfloor/commit/cbc1d194999e706abbbb324dea71330ae5ae46ab))

## [0.1.50](https://github.com/alltuner/factoryfloor/compare/v0.1.49...v0.1.50) (2026-03-31)


### Features

* improve terminal spawning resilience ([#235](https://github.com/alltuner/factoryfloor/issues/235)) ([8313c13](https://github.com/alltuner/factoryfloor/commit/8313c13a03134c3800248c06a520afa7cee73c2d))
* improve update experience for Homebrew users ([#246](https://github.com/alltuner/factoryfloor/issues/246)) ([c4db1d2](https://github.com/alltuner/factoryfloor/commit/c4db1d2b8fce6d2ca8f6967ac2d1a6d54d810418))
* per-workstream debug log files for launches ([#247](https://github.com/alltuner/factoryfloor/issues/247)) ([5c156f5](https://github.com/alltuner/factoryfloor/commit/5c156f5b27d9029d270b71dbd236a7aeab5b7ff0))
* **website:** add download button to /get/ page ([#240](https://github.com/alltuner/factoryfloor/issues/240)) ([3f1b212](https://github.com/alltuner/factoryfloor/commit/3f1b212fdbdd18aee032053a16642271fe793fb8)), closes [#231](https://github.com/alltuner/factoryfloor/issues/231)


### Bug Fixes

* consolidate settings from 7 sections to 4 ([#242](https://github.com/alltuner/factoryfloor/issues/242)) ([9607073](https://github.com/alltuner/factoryfloor/commit/9607073d1155333d6c2270ac61b78b005728f361)), closes [#233](https://github.com/alltuner/factoryfloor/issues/233)
* fade onboarding content so skyline remains visible in small windows ([#245](https://github.com/alltuner/factoryfloor/issues/245)) ([c0b998c](https://github.com/alltuner/factoryfloor/commit/c0b998c81827e0321f1cff9dc3e5e8e2ee03eb45))
* increase DMG window height so skyline is visible ([#238](https://github.com/alltuner/factoryfloor/issues/238)) ([79e9a32](https://github.com/alltuner/factoryfloor/commit/79e9a32919973d639418d06a71929a0e83f2c360)), closes [#230](https://github.com/alltuner/factoryfloor/issues/230)
* resolve compiler warnings in Launcher, BrowserView, and Updater ([#241](https://github.com/alltuner/factoryfloor/issues/241)) ([645ea15](https://github.com/alltuner/factoryfloor/commit/645ea15efdfd3e7a6424eff7a958fa2e5ebb04af)), closes [#228](https://github.com/alltuner/factoryfloor/issues/228)
* trigger Sparkle update from sidebar instead of opening website ([#237](https://github.com/alltuner/factoryfloor/issues/237)) ([5b74416](https://github.com/alltuner/factoryfloor/commit/5b7441650749205026c9316c49f2f03db976f4c8)), closes [#232](https://github.com/alltuner/factoryfloor/issues/232)
* use interactive login shell (-lic) for tool version manager support ([#243](https://github.com/alltuner/factoryfloor/issues/243)) ([d48ee31](https://github.com/alltuner/factoryfloor/commit/d48ee3131ca760cfe2876bddb2c4a8ec2b2370b1))

## [0.1.49](https://github.com/alltuner/factoryfloor/compare/v0.1.48...v0.1.49) (2026-03-30)


### Features

* add launch at login toggle in Settings ([#227](https://github.com/alltuner/factoryfloor/issues/227)) ([6c5dd43](https://github.com/alltuner/factoryfloor/commit/6c5dd43e957001e675a9ba4ebb5fa92ab1744baa)), closes [#224](https://github.com/alltuner/factoryfloor/issues/224)
* direct DMG download and styled installer ([#225](https://github.com/alltuner/factoryfloor/issues/225)) ([8fbafdf](https://github.com/alltuner/factoryfloor/commit/8fbafdfd7d1fc3dc0fa3c45de8d943b17d95b3cb))


### Bug Fixes

* disable update checker in debug builds ([#209](https://github.com/alltuner/factoryfloor/issues/209)) ([ddb0e54](https://github.com/alltuner/factoryfloor/commit/ddb0e54414eaf84e82af172e5758025843af75a4))
* match WKUIDelegate completion handler signatures for concurrency ([#212](https://github.com/alltuner/factoryfloor/issues/212)) ([9d807a5](https://github.com/alltuner/factoryfloor/commit/9d807a5213049db058ca715c3d0b2c961a4d1944))
* read Sparkle changelog from CHANGELOG.md instead of GitHub release ([#221](https://github.com/alltuner/factoryfloor/issues/221)) ([087afee](https://github.com/alltuner/factoryfloor/commit/087afee420dd88c7028870e5a571c8a19066b511))
* resolve LSP false positives for conditionally compiled AppConstants ([#213](https://github.com/alltuner/factoryfloor/issues/213)) ([a105cf6](https://github.com/alltuner/factoryfloor/commit/a105cf6964f123743a9b0abf6b2bf5e463c86763)), closes [#211](https://github.com/alltuner/factoryfloor/issues/211)
* run worktree build in background to speed up creation ([#214](https://github.com/alltuner/factoryfloor/issues/214)) ([a2ed834](https://github.com/alltuner/factoryfloor/commit/a2ed83426974ec7a962e59a0e29d6e1c9c0adf5b))
* **website:** prevent horizontal scroll on mobile Safari ([#218](https://github.com/alltuner/factoryfloor/issues/218)) ([8e68359](https://github.com/alltuner/factoryfloor/commit/8e683590c89c5498222c72dd761b901a9c7934f0))


### Refactoring

* remove ScriptLogger and move logging toggle to privacy section ([#216](https://github.com/alltuner/factoryfloor/issues/216)) ([3858229](https://github.com/alltuner/factoryfloor/commit/385822910afd9ab3d9ac6b549938d0a6cb144932))


### Miscellaneous

* add __pycache__ to .gitignore ([#223](https://github.com/alltuner/factoryfloor/issues/223)) ([015d9ec](https://github.com/alltuner/factoryfloor/commit/015d9ec53554bceead26d10f4973e5891acea72a)), closes [#222](https://github.com/alltuner/factoryfloor/issues/222)


### Documentation

* add terminal resilience design doc ([#219](https://github.com/alltuner/factoryfloor/issues/219)) ([06ab89a](https://github.com/alltuner/factoryfloor/commit/06ab89ad0ba0a14f6250ea77e1e6a6246da4da1d))
* add terminal spawning architecture reference ([#217](https://github.com/alltuner/factoryfloor/issues/217)) ([77b11c3](https://github.com/alltuner/factoryfloor/commit/77b11c3c21ae58dc7f592ffa20b651f0d1282c5c))

## [0.1.48](https://github.com/alltuner/factoryfloor/compare/v0.1.47...v0.1.48) (2026-03-29)


### Features

* show changelog in Sparkle update window ([#206](https://github.com/alltuner/factoryfloor/issues/206)) ([e32562c](https://github.com/alltuner/factoryfloor/commit/e32562cb719a3a3c674687e47cca89d6fe5bfd90))


### Bug Fixes

* close button on workspace tabs not intercepting clicks ([#208](https://github.com/alltuner/factoryfloor/issues/208)) ([e51bd82](https://github.com/alltuner/factoryfloor/commit/e51bd8233334eb07b0a37fb06dbd1f751683f424))
* close button on workspace tabs not working ([#203](https://github.com/alltuner/factoryfloor/issues/203)) ([571dab4](https://github.com/alltuner/factoryfloor/commit/571dab4ded1d133ef66d262d1537c6e44636a744))
* create logs directory before revealing in Finder ([#201](https://github.com/alltuner/factoryfloor/issues/201)) ([86b8344](https://github.com/alltuner/factoryfloor/commit/86b83444ad8cfa52e93f23d6233feaca0b3208fc))
* hide add-workstream button for non-git projects ([#204](https://github.com/alltuner/factoryfloor/issues/204)) ([af30344](https://github.com/alltuner/factoryfloor/commit/af30344d62018e5015936a92576a799d6f67134d))
* inject login shell PATH into terminal environment ([#205](https://github.com/alltuner/factoryfloor/issues/205)) ([2aa33aa](https://github.com/alltuner/factoryfloor/commit/2aa33aa111cfafaa42938f8da6009d9971b968ac))


### Miscellaneous

* **deps:** update astral-sh/setup-uv action to v7 ([#207](https://github.com/alltuner/factoryfloor/issues/207)) ([8b2cfda](https://github.com/alltuner/factoryfloor/commit/8b2cfda4bbfe0afdbcb6f3965e56e0c9de4608eb))

## [0.1.47](https://github.com/alltuner/factoryfloor/compare/v0.1.46...v0.1.47) (2026-03-29)


### Features

* add file-based logging for setup, run, and teardown scripts ([#198](https://github.com/alltuner/factoryfloor/issues/198)) ([949cf67](https://github.com/alltuner/factoryfloor/commit/949cf674bf60aba5b57d01bddf667ef39bd0ef64))
* show changelog in Sparkle update window ([#200](https://github.com/alltuner/factoryfloor/issues/200)) ([3daf92a](https://github.com/alltuner/factoryfloor/commit/3daf92af357e5f69ed804a5f9c388019e21b231b))


### Bug Fixes

* discover CLI tools from user's login shell PATH ([#196](https://github.com/alltuner/factoryfloor/issues/196)) ([b00ae30](https://github.com/alltuner/factoryfloor/commit/b00ae30edefa0939a67767ec039537ebc3fc4ce1))
* suppress incomplete umbrella header warnings from GhosttyKit ([#199](https://github.com/alltuner/factoryfloor/issues/199)) ([9f4ad38](https://github.com/alltuner/factoryfloor/commit/9f4ad38c9e05b842898a8b8bb744c5d9af795336))

## [0.1.46](https://github.com/alltuner/factoryfloor/compare/v0.1.45...v0.1.46) (2026-03-27)


### Bug Fixes

* handle Claude Code versions without --name flag ([#191](https://github.com/alltuner/factoryfloor/issues/191)) ([18d805b](https://github.com/alltuner/factoryfloor/commit/18d805ba3c6b6aaec023b35ac91eb3ae01823f48))


### Miscellaneous

* **deps:** update actions/deploy-pages action to v5 ([#187](https://github.com/alltuner/factoryfloor/issues/187)) ([82fa566](https://github.com/alltuner/factoryfloor/commit/82fa566265dcaa9bb4b21d742f1a58162e46b2fc))

## [0.1.45](https://github.com/alltuner/factoryfloor/compare/v0.1.44...v0.1.45) (2026-03-25)


### Features

* add anonymous usage telemetry via self-hosted Umami ([#186](https://github.com/alltuner/factoryfloor/issues/186)) ([392848c](https://github.com/alltuner/factoryfloor/commit/392848cfa8da966016f01bf7cc502f08ef59671f))
* **website:** embed YouTube demo video in hero section ([#185](https://github.com/alltuner/factoryfloor/issues/185)) ([fb94c51](https://github.com/alltuner/factoryfloor/commit/fb94c511f49dd09fdf1b7e3c25a80b347c1bfada))


### Bug Fixes

* **browser:** handle JavaScript alert, confirm, and prompt dialogs ([#184](https://github.com/alltuner/factoryfloor/issues/184)) ([e4e40bf](https://github.com/alltuner/factoryfloor/commit/e4e40bfaad9ab6347de3dac5050e7b188158ec68))
* cache WKWebView instances to prevent browser tab reload on switch ([#183](https://github.com/alltuner/factoryfloor/issues/183)) ([b6bd587](https://github.com/alltuner/factoryfloor/commit/b6bd587cdb252eb849209af8e9e844449548137a))


### Documentation

* awesome lists submission guide and README install improvements ([#179](https://github.com/alltuner/factoryfloor/issues/179)) ([ae855a1](https://github.com/alltuner/factoryfloor/commit/ae855a1d0c8314aeb10f5039b9672ef0615e7c31))
* replace CLI-centric Get Started with in-app workflow ([#181](https://github.com/alltuner/factoryfloor/issues/181)) ([dd6347d](https://github.com/alltuner/factoryfloor/commit/dd6347d48a125f0d391e8a1d9272c93b26fff327))
* update awesome lists tracking table with submission status ([#182](https://github.com/alltuner/factoryfloor/issues/182)) ([a91bee1](https://github.com/alltuner/factoryfloor/commit/a91bee19e6900cd572bc5da698d454c47908feff))

## [0.1.44](https://github.com/alltuner/factoryfloor/compare/v0.1.43...v0.1.44) (2026-03-24)


### Bug Fixes

* split ProjectSidebar body into computed properties to fix type-check timeout ([#177](https://github.com/alltuner/factoryfloor/issues/177)) ([a48545c](https://github.com/alltuner/factoryfloor/commit/a48545cb22dc02eb6a585b4efb422d8585ca2f10))

## [0.1.43](https://github.com/alltuner/factoryfloor/compare/v0.1.42...v0.1.43) (2026-03-24)


### Bug Fixes

* break up complex ProjectSidebar body to fix release build failure ([#175](https://github.com/alltuner/factoryfloor/issues/175)) ([c49002a](https://github.com/alltuner/factoryfloor/commit/c49002a15646bebb7306db175a5fd0cdf25989c5))

## [0.1.42](https://github.com/alltuner/factoryfloor/compare/v0.1.41...v0.1.42) (2026-03-24)


### Features

* localize NS*UsageDescription privacy strings via InfoPlist.strings ([#173](https://github.com/alltuner/factoryfloor/issues/173)) ([98d4358](https://github.com/alltuner/factoryfloor/commit/98d4358733484b8be59a7a001aa73ce0b206438d)), closes [#172](https://github.com/alltuner/factoryfloor/issues/172)


### Bug Fixes

* add privacy entitlements and TCC usage descriptions for embedded terminal ([#171](https://github.com/alltuner/factoryfloor/issues/171)) ([87c4216](https://github.com/alltuner/factoryfloor/commit/87c4216482fe07fe5c4797ab6ddf4829b8c0995f)), closes [#167](https://github.com/alltuner/factoryfloor/issues/167)
* preserve terminal and browser tabs across workspace navigation ([#168](https://github.com/alltuner/factoryfloor/issues/168)) ([be89532](https://github.com/alltuner/factoryfloor/commit/be89532f3fec4c23715bca40715306c665d5543d))
* sidebar archive button fails due to stale workstream index cache ([#170](https://github.com/alltuner/factoryfloor/issues/170)) ([3727c40](https://github.com/alltuner/factoryfloor/commit/3727c40af9e3db31ce27018abec071ab382337f7))
* use login shell for agent and tmux commands to load user PATH ([#174](https://github.com/alltuner/factoryfloor/issues/174)) ([debcaad](https://github.com/alltuner/factoryfloor/commit/debcaad4bb195ff070fcab0507839592c9826459))

## [0.1.41](https://github.com/alltuner/factoryfloor/compare/v0.1.40...v0.1.41) (2026-03-23)


### Bug Fixes

* rewrite ff-run to exec command directly for ghostty PTY compatibility ([#166](https://github.com/alltuner/factoryfloor/issues/166)) ([90871a9](https://github.com/alltuner/factoryfloor/commit/90871a9f87772ba24ad5400cd8a40e2e74cc9981))
* run build in worktree-create hook for SourceKit resolution ([#163](https://github.com/alltuner/factoryfloor/issues/163)) ([1184e7b](https://github.com/alltuner/factoryfloor/commit/1184e7bd3070ec75df62db098ee4fdc436e7092d)), closes [#161](https://github.com/alltuner/factoryfloor/issues/161)
* skip symlinks when loading doc files in info panel ([#160](https://github.com/alltuner/factoryfloor/issues/160)) ([cd97a42](https://github.com/alltuner/factoryfloor/commit/cd97a42ec950d66da2bc04b5414d4b13d4286e23))
* **website:** link changelog versions to GitHub releases instead of diffs ([#164](https://github.com/alltuner/factoryfloor/issues/164)) ([7f0ccd9](https://github.com/alltuner/factoryfloor/commit/7f0ccd99922f3973943ff18a4ab2c0fa57350a1f))


### CI/CD

* make Ghostty compat test manual-only and arm64-only ([#165](https://github.com/alltuner/factoryfloor/issues/165)) ([2e56331](https://github.com/alltuner/factoryfloor/commit/2e56331d3d5648969a5ce0b8794016f4a76d78a1))

## [0.1.40](https://github.com/alltuner/factoryfloor/compare/v0.1.39...v0.1.40) (2026-03-19)


### Features

* **website:** add llms.txt for AI crawler discovery ([#156](https://github.com/alltuner/factoryfloor/issues/156)) ([1e4fcc2](https://github.com/alltuner/factoryfloor/commit/1e4fcc2d7fb9c3c2f13eaefd113ce0460c7d000e))


### Bug Fixes

* use heap-allocated C strings for ghostty env vars ([#159](https://github.com/alltuner/factoryfloor/issues/159)) ([3c66311](https://github.com/alltuner/factoryfloor/commit/3c6631153e95322e78baa490f5618564fb7889bc))


### Performance

* share SPM package cache across worktrees ([#158](https://github.com/alltuner/factoryfloor/issues/158)) ([e531a5a](https://github.com/alltuner/factoryfloor/commit/e531a5a5aeb5f66db72b8c29141d00d5b4ed80bb))

## [0.1.39](https://github.com/alltuner/factoryfloor/compare/v0.1.38...v0.1.39) (2026-03-19)


### CI/CD

* fix build warnings and improve CI caching ([#154](https://github.com/alltuner/factoryfloor/issues/154)) ([1c2db0b](https://github.com/alltuner/factoryfloor/commit/1c2db0b6d18e5c059aa72b14e705e4df6f88297c))

## [0.1.38](https://github.com/alltuner/factoryfloor/compare/v0.1.37...v0.1.38) (2026-03-19)


### Bug Fixes

* **ci:** prevent premature website deploy during releases ([#145](https://github.com/alltuner/factoryfloor/issues/145)) ([dd2967c](https://github.com/alltuner/factoryfloor/commit/dd2967c4a3b87a0eb225eaf1ae4797c95761e732))
* host appcast on website to avoid Sparkle update race condition ([#149](https://github.com/alltuner/factoryfloor/issues/149)) ([5984c50](https://github.com/alltuner/factoryfloor/commit/5984c5012a7632df4d59e55bad03309cd5070d5a))
* replace blocking runModal calls with async alternatives ([#148](https://github.com/alltuner/factoryfloor/issues/148)) ([a0d7e73](https://github.com/alltuner/factoryfloor/commit/a0d7e734bcf22de1f4a1d81ffc71b16d0457639d))


### Refactoring

* **ci:** embed Sparkle public key in project.yml ([#147](https://github.com/alltuner/factoryfloor/issues/147)) ([6465fb7](https://github.com/alltuner/factoryfloor/commit/6465fb7258e490a1f663432f8938e3b0c3c82278))
* **ci:** embed Sparkle public key in project.yml ([#147](https://github.com/alltuner/factoryfloor/issues/147)) ([f7870fa](https://github.com/alltuner/factoryfloor/commit/f7870fabe94d26be60d52bcb054822743fefbe86))

## [0.1.37](https://github.com/alltuner/factoryfloor/compare/v0.1.36...v0.1.37) (2026-03-19)


### Bug Fixes

* wrap preloaded setup script in login shell ([#143](https://github.com/alltuner/factoryfloor/issues/143)) ([a263d35](https://github.com/alltuner/factoryfloor/commit/a263d35f94a7befdaa19e6922bd88b57ddb5e2a7))

## [0.1.36](https://github.com/alltuner/factoryfloor/compare/v0.1.35...v0.1.36) (2026-03-19)


### Refactoring

* generate Info.plist via XcodeGen and versions.json at deploy time ([#141](https://github.com/alltuner/factoryfloor/issues/141)) ([c1d624b](https://github.com/alltuner/factoryfloor/commit/c1d624b9f5f3192b20213917bdfd33b8c936a153))


### Miscellaneous

* update versions.json to v0.1.35 ([4e0a3ac](https://github.com/alltuner/factoryfloor/commit/4e0a3ac0b8411d4380660ebcce7564ef243df083))

## [0.1.35](https://github.com/alltuner/factoryfloor/compare/v0.1.34...v0.1.35) (2026-03-19)


### Bug Fixes

* correct TmuxSessionTests assertions to match actual output ([#138](https://github.com/alltuner/factoryfloor/issues/138)) ([76dbb87](https://github.com/alltuner/factoryfloor/commit/76dbb87cae1e2dbb6360dbebf35cf810324a8dae)), closes [#137](https://github.com/alltuner/factoryfloor/issues/137)


### Miscellaneous

* update versions.json to v0.1.34 ([4b58179](https://github.com/alltuner/factoryfloor/commit/4b58179dae5c2343039dbe2cc1a907d76df78cdc))

## [0.1.34](https://github.com/alltuner/factoryfloor/compare/v0.1.33...v0.1.34) (2026-03-19)


### Bug Fixes

* run setup/run/teardown scripts in user's login shell ([#135](https://github.com/alltuner/factoryfloor/issues/135)) ([b9d8340](https://github.com/alltuner/factoryfloor/commit/b9d8340a968ccd53859615d7087f869695dc3b2f))


### Miscellaneous

* update versions.json to v0.1.33 ([27ea914](https://github.com/alltuner/factoryfloor/commit/27ea91456cf15ec4d83429e8e0f8e0e15dceb745))

## [0.1.33](https://github.com/alltuner/factoryfloor/compare/v0.1.32...v0.1.33) (2026-03-19)


### Bug Fixes

* **ci:** make dSYM upload non-blocking for releases ([#133](https://github.com/alltuner/factoryfloor/issues/133)) ([e73b829](https://github.com/alltuner/factoryfloor/commit/e73b8299924c5b0a05b6ee0672d7cc2bd1a17a9e))

## [0.1.32](https://github.com/alltuner/factoryfloor/compare/v0.1.31...v0.1.32) (2026-03-19)


### Bug Fixes

* upload dSYMs to Sentry so crash reports are symbolicated ([#131](https://github.com/alltuner/factoryfloor/issues/131)) ([7f4f2b9](https://github.com/alltuner/factoryfloor/commit/7f4f2b9cc80efbd7e0e35b1d62da7b5a50aaf9ff))


### Miscellaneous

* update versions.json to v0.1.31 ([5b0cbbe](https://github.com/alltuner/factoryfloor/commit/5b0cbbea2197b50b8da6d5f020735c825d49a165))

## [0.1.31](https://github.com/alltuner/factoryfloor/compare/v0.1.30...v0.1.31) (2026-03-19)


### Bug Fixes

* align CFBundleVersion with semver so Sparkle detects updates ([#129](https://github.com/alltuner/factoryfloor/issues/129)) ([0bcb0aa](https://github.com/alltuner/factoryfloor/commit/0bcb0aa42c968725bb0efdc76b6f8c0b5b3bf9fd))


### Miscellaneous

* update versions.json to v0.1.30 ([a319936](https://github.com/alltuner/factoryfloor/commit/a31993680a3a5f5ed6abb9b8f2bd7064ccb2a696))

## [0.1.30](https://github.com/alltuner/factoryfloor/compare/v0.1.29...v0.1.30) (2026-03-19)


### Features

* display app version on welcome screen and centralize version access ([#125](https://github.com/alltuner/factoryfloor/issues/125)) ([85d8856](https://github.com/alltuner/factoryfloor/commit/85d8856429c013bd125e94131496b9045eb355c9))
* resolve git worktree paths to main repository when adding projects ([#127](https://github.com/alltuner/factoryfloor/issues/127)) ([780f26d](https://github.com/alltuner/factoryfloor/commit/780f26dafed1dc65aaf5fd4f95bca8ad79fb10fc))


### Miscellaneous

* update versions.json to v0.1.29 ([4649027](https://github.com/alltuner/factoryfloor/commit/4649027154a37bd29fd256193ad8170ddfd800ed))

## [0.1.29](https://github.com/alltuner/factoryfloor/compare/v0.1.28...v0.1.29) (2026-03-18)


### Features

* show port indicator in sidebar and title bar ([#119](https://github.com/alltuner/factoryfloor/issues/119)) ([#123](https://github.com/alltuner/factoryfloor/issues/123)) ([cdb1731](https://github.com/alltuner/factoryfloor/commit/cdb1731c8c7b00a231c081a637a314421e540ff4))


### Bug Fixes

* set run-state files to 0600 and directories to 0700 ([#97](https://github.com/alltuner/factoryfloor/issues/97)) ([#121](https://github.com/alltuner/factoryfloor/issues/121)) ([8009d0d](https://github.com/alltuner/factoryfloor/commit/8009d0db9fe1a479c6a2246450514e37ac3b80c4))
* show spinner when environment pane is restarting ([#89](https://github.com/alltuner/factoryfloor/issues/89)) ([#120](https://github.com/alltuner/factoryfloor/issues/120)) ([7bc3fc3](https://github.com/alltuner/factoryfloor/commit/7bc3fc398e506e88b09062f59a5ba2a810d5cffa))


### Refactoring

* remove legacy JSON file migration code ([#93](https://github.com/alltuner/factoryfloor/issues/93)) ([#122](https://github.com/alltuner/factoryfloor/issues/122)) ([3b5041c](https://github.com/alltuner/factoryfloor/commit/3b5041ca4f6bca93aa09ef722c3544be1904298d))


### Miscellaneous

* update versions.json to v0.1.28 ([1507e37](https://github.com/alltuner/factoryfloor/commit/1507e37d77a4e65753793b8e23abe2215a90bddc))

## [0.1.28](https://github.com/alltuner/factoryfloor/compare/v0.1.27...v0.1.28) (2026-03-18)


### Bug Fixes

* don't double-escape tmux command argument ([#115](https://github.com/alltuner/factoryfloor/issues/115)) ([91aad5e](https://github.com/alltuner/factoryfloor/commit/91aad5eca06148d9739f41438fd5ea19e0ab77a5))


### Miscellaneous

* update versions.json to v0.1.27 ([2daee40](https://github.com/alltuner/factoryfloor/commit/2daee401eed245da006fe552f3ce64b8eecb7842))

## [0.1.27](https://github.com/alltuner/factoryfloor/compare/v0.1.26...v0.1.27) (2026-03-18)


### Bug Fixes

* flatten tmux command to single sh -c level, eliminate nested escaping ([#114](https://github.com/alltuner/factoryfloor/issues/114)) ([c42631f](https://github.com/alltuner/factoryfloor/commit/c42631f113abf10e71498088391b011705b1cbb6))


### Miscellaneous

* update versions.json to v0.1.26 ([0776e67](https://github.com/alltuner/factoryfloor/commit/0776e678857a34597729058bd7b25a49ffced837))


### Documentation

* add hybrid adoption strategy to SwiftGitX analysis ([#112](https://github.com/alltuner/factoryfloor/issues/112)) ([668b3cd](https://github.com/alltuner/factoryfloor/commit/668b3cdae7502609409d795ec692474d85460312))
* add SwiftGitX feasibility analysis ([#110](https://github.com/alltuner/factoryfloor/issues/110)) ([2970473](https://github.com/alltuner/factoryfloor/commit/297047352b56e656ae618829dcfb2463ea3add61))

## [0.1.26](https://github.com/alltuner/factoryfloor/compare/v0.1.25...v0.1.26) (2026-03-18)


### Bug Fixes

* **ci:** add --options=runtime to framework re-signing step ([#108](https://github.com/alltuner/factoryfloor/issues/108)) ([5dcb866](https://github.com/alltuner/factoryfloor/commit/5dcb8668426582d6d0c6bc19d085daafc3666dd5))

## [0.1.25](https://github.com/alltuner/factoryfloor/compare/v0.1.24...v0.1.25) (2026-03-18)


### Bug Fixes

* remove stale baseDirectory argument from MarkdownContentView call ([#106](https://github.com/alltuner/factoryfloor/issues/106)) ([1758aba](https://github.com/alltuner/factoryfloor/commit/1758aba868bd81b884a445f59162f641b0db3e2e))

## [0.1.24](https://github.com/alltuner/factoryfloor/compare/v0.1.23...v0.1.24) (2026-03-18)


### Features

* add Sparkle auto-update ([#39](https://github.com/alltuner/factoryfloor/issues/39)) ([#80](https://github.com/alltuner/factoryfloor/issues/80)) ([83acde7](https://github.com/alltuner/factoryfloor/commit/83acde778dce1d4963c1f06c7f83087ba303ecb1))
* **website:** mobile screenshot layout and modal viewer ([#74](https://github.com/alltuner/factoryfloor/issues/74)) ([#78](https://github.com/alltuner/factoryfloor/issues/78)) ([7cf81e5](https://github.com/alltuner/factoryfloor/commit/7cf81e55ed7729cf7aa9f707861f75b5fda547cb))


### Bug Fixes

* async worktree creation with loading spinner ([#92](https://github.com/alltuner/factoryfloor/issues/92), [#87](https://github.com/alltuner/factoryfloor/issues/87)) ([#101](https://github.com/alltuner/factoryfloor/issues/101)) ([a0d8580](https://github.com/alltuner/factoryfloor/commit/a0d858063b742cb2721dfcbefb3f54d7c66842f1))
* double-quote tmux -e values to handle spaces and special chars ([#94](https://github.com/alltuner/factoryfloor/issues/94)) ([#104](https://github.com/alltuner/factoryfloor/issues/104)) ([a31a676](https://github.com/alltuner/factoryfloor/commit/a31a67668552fa27eba169f3c88a216c466d7b88))
* localize all user-facing strings in alerts and prune UI ([#88](https://github.com/alltuner/factoryfloor/issues/88)) ([#103](https://github.com/alltuner/factoryfloor/issues/103)) ([4fabdb0](https://github.com/alltuner/factoryfloor/commit/4fabdb0c913eb9d6a31f9e1383cd6a6c12cde95c))
* require user consent for factoryfloor:// URL scheme ([#98](https://github.com/alltuner/factoryfloor/issues/98)) ([#102](https://github.com/alltuner/factoryfloor/issues/102)) ([cfb2e77](https://github.com/alltuner/factoryfloor/commit/cfb2e775d3bdb3385af633317c6876aa7d6adb92))
* strip raw HTML from markdown rendering, remove file:// base URL ([#95](https://github.com/alltuner/factoryfloor/issues/95)) ([#99](https://github.com/alltuner/factoryfloor/issues/99)) ([5c4dce5](https://github.com/alltuner/factoryfloor/commit/5c4dce584ddaddcd8ef0a58e04f0d8ab6e946b1b))


### Refactoring

* move run-state and tmux.conf to ~/Library/Caches/factoryfloor/ ([#75](https://github.com/alltuner/factoryfloor/issues/75)) ([#76](https://github.com/alltuner/factoryfloor/issues/76)) ([a1de232](https://github.com/alltuner/factoryfloor/commit/a1de232cf57d9eb2754ebcf9c29a1abb05e3149a))


### Miscellaneous

* add prek pre-commit hooks ([#82](https://github.com/alltuner/factoryfloor/issues/82)) ([#83](https://github.com/alltuner/factoryfloor/issues/83)) ([19f08f3](https://github.com/alltuner/factoryfloor/commit/19f08f3218f56b875e0734a53b53a51c735c8637))
* add SwiftFormat hook and update AGENTS.md ([#84](https://github.com/alltuner/factoryfloor/issues/84), [#85](https://github.com/alltuner/factoryfloor/issues/85)) ([#86](https://github.com/alltuner/factoryfloor/issues/86)) ([8656ea8](https://github.com/alltuner/factoryfloor/commit/8656ea81659f318906874885a011c83cb7055841))
* update versions.json to v0.1.23 ([1f0ef5d](https://github.com/alltuner/factoryfloor/commit/1f0ef5d489abaa737bbd1255db2aedb84dce33be))


### Documentation

* add SwiftGit2 feasibility analysis (recommendation: don't adopt) ([#105](https://github.com/alltuner/factoryfloor/issues/105)) ([38fce35](https://github.com/alltuner/factoryfloor/commit/38fce358fc98c59d66e401726e6b2dc69348d47c))
* document ProjectList ObservableObject audit results ([#91](https://github.com/alltuner/factoryfloor/issues/91)) ([#100](https://github.com/alltuner/factoryfloor/issues/100)) ([b38e2b7](https://github.com/alltuner/factoryfloor/commit/b38e2b77b55f42f33822ce4be24f1c84d9a9b70d))

## [0.1.23](https://github.com/alltuner/factoryfloor/compare/v0.1.22...v0.1.23) (2026-03-18)


### Bug Fixes

* migrate project storage from JSON files to UserDefaults ([#70](https://github.com/alltuner/factoryfloor/issues/70)) ([9a86fa5](https://github.com/alltuner/factoryfloor/commit/9a86fa5c14adacbfdaf111b58f31663a27924a59)), closes [#46](https://github.com/alltuner/factoryfloor/issues/46)
* migrate project storage from JSON files to UserDefaults ([#72](https://github.com/alltuner/factoryfloor/issues/72)) ([4a88ebe](https://github.com/alltuner/factoryfloor/commit/4a88ebe497b782bbd02ad4ffd6f1a4195f3f9551)), closes [#46](https://github.com/alltuner/factoryfloor/issues/46)


### Miscellaneous

* update versions.json to v0.1.22 ([51075bb](https://github.com/alltuner/factoryfloor/commit/51075bb96d8fb9430239461201d092385e4e4de5))


### Documentation

* add Sparkle scoping doc; fix(website): native changelog rendering ([#41](https://github.com/alltuner/factoryfloor/issues/41)) ([#73](https://github.com/alltuner/factoryfloor/issues/73)) ([ee9805b](https://github.com/alltuner/factoryfloor/commit/ee9805b6ba1d6400d5ddf45bf76748bcccf5421c))

## [0.1.22](https://github.com/alltuner/factoryfloor/compare/v0.1.21...v0.1.22) (2026-03-18)


### Bug Fixes

* remove double shell-escaping of tmux -e env flags ([#64](https://github.com/alltuner/factoryfloor/issues/64)) ([be08aa4](https://github.com/alltuner/factoryfloor/commit/be08aa45420f6b380dfce87298f866cb47060258))


### Miscellaneous

* update versions.json to v0.1.21 ([db0a820](https://github.com/alltuner/factoryfloor/commit/db0a820ee71fa496a9999e63b851079556862769))

## [0.1.21](https://github.com/alltuner/factoryfloor/compare/v0.1.20...v0.1.21) (2026-03-18)


### Bug Fixes

* **ci:** match local and CI build environments ([#59](https://github.com/alltuner/factoryfloor/issues/59)), add SPM cache path ([#38](https://github.com/alltuner/factoryfloor/issues/38)) ([#60](https://github.com/alltuner/factoryfloor/issues/60)) ([771dc21](https://github.com/alltuner/factoryfloor/commit/771dc2117f98cc16b0b60ea78c232418c1ad7863))
* use ObservableObject for projects to fix Release @State timing ([#43](https://github.com/alltuner/factoryfloor/issues/43)) ([#63](https://github.com/alltuner/factoryfloor/issues/63)) ([c0568c8](https://github.com/alltuner/factoryfloor/commit/c0568c84ccccd8da0761b79b8347921326e4940d))


### Miscellaneous

* update versions.json to v0.1.20 ([88939d1](https://github.com/alltuner/factoryfloor/commit/88939d16b69dd24981be021ea4fc8de3bca76052))


### Documentation

* add release command to build instructions ([#62](https://github.com/alltuner/factoryfloor/issues/62)) ([4ed8099](https://github.com/alltuner/factoryfloor/commit/4ed80997b166a35a9ba80262c2c4b38dc37715d7))

## [0.1.20](https://github.com/alltuner/factoryfloor/compare/v0.1.19...v0.1.20) (2026-03-18)


### Bug Fixes

* use notifications for project/workstream creation ([#43](https://github.com/alltuner/factoryfloor/issues/43)) ([#57](https://github.com/alltuner/factoryfloor/issues/57)) ([75ed058](https://github.com/alltuner/factoryfloor/commit/75ed058599bf263a43af98b5750f9457a1e21f5a))


### Miscellaneous

* update versions.json to v0.1.19 ([0aed24f](https://github.com/alltuner/factoryfloor/commit/0aed24f1b5ff5a656f803d819cdf22b35f988cf8))

## [0.1.19](https://github.com/alltuner/factoryfloor/compare/v0.1.18...v0.1.19) (2026-03-18)


### Bug Fixes

* delay selection after projects mutation to ensure SwiftUI commits ([#43](https://github.com/alltuner/factoryfloor/issues/43)) ([#55](https://github.com/alltuner/factoryfloor/issues/55)) ([ef451ff](https://github.com/alltuner/factoryfloor/commit/ef451ff0536d632744185b48e7b91657f9418714))


### Miscellaneous

* update versions.json to v0.1.18 ([5297fc7](https://github.com/alltuner/factoryfloor/commit/5297fc7a83ef28c566f86a84c898415bfa387899))

## [0.1.18](https://github.com/alltuner/factoryfloor/compare/v0.1.17...v0.1.18) (2026-03-18)


### Bug Fixes

* use atomic callbacks for project and workstream creation ([#43](https://github.com/alltuner/factoryfloor/issues/43)) ([#53](https://github.com/alltuner/factoryfloor/issues/53)) ([080bcb2](https://github.com/alltuner/factoryfloor/commit/080bcb2b9612934b6328aa7432e04d4d32e845c2))


### Miscellaneous

* update versions.json to v0.1.17 ([65042c2](https://github.com/alltuner/factoryfloor/commit/65042c20894d7c95ef70519009ab287f785a4556))

## [0.1.17](https://github.com/alltuner/factoryfloor/compare/v0.1.16...v0.1.17) (2026-03-18)


### Bug Fixes

* **ci:** add actions:write permission for website deploy trigger ([#50](https://github.com/alltuner/factoryfloor/issues/50)) ([272903b](https://github.com/alltuner/factoryfloor/commit/272903b156793a96a8182143fe77adaa6ebef1d9))
* defer workstream selection to let @Binding propagate ([#43](https://github.com/alltuner/factoryfloor/issues/43)) ([#52](https://github.com/alltuner/factoryfloor/issues/52)) ([d687430](https://github.com/alltuner/factoryfloor/commit/d687430d81728eb84fcd2ba224cf2f665ac0721b))


### Miscellaneous

* update versions.json to v0.1.16 ([ff602af](https://github.com/alltuner/factoryfloor/commit/ff602af9f8b7c59e551478d25382429b9e25eed4))

## [0.1.16](https://github.com/alltuner/factoryfloor/compare/v0.1.15...v0.1.16) (2026-03-17)


### Bug Fixes

* use os_log Logger with public privacy for debug logging ([#43](https://github.com/alltuner/factoryfloor/issues/43)) ([#49](https://github.com/alltuner/factoryfloor/issues/49)) ([467d749](https://github.com/alltuner/factoryfloor/commit/467d74982622974bccfe8332e2d8a9b1f96d3859))
* **website:** add brew update to upgrade instructions, trigger deploy after release ([#47](https://github.com/alltuner/factoryfloor/issues/47)) ([385f085](https://github.com/alltuner/factoryfloor/commit/385f085d5f96a711e3feabb456dffbafaa0f088a)), closes [#40](https://github.com/alltuner/factoryfloor/issues/40) [#42](https://github.com/alltuner/factoryfloor/issues/42)


### Miscellaneous

* update versions.json to v0.1.15 ([e898537](https://github.com/alltuner/factoryfloor/commit/e898537e0c959c4f36edb346df47e480cc5f4c05))

## [0.1.15](https://github.com/alltuner/factoryfloor/compare/v0.1.14...v0.1.15) (2026-03-17)


### Bug Fixes

* add comprehensive debug logging for workspace creation ([#43](https://github.com/alltuner/factoryfloor/issues/43)) ([#44](https://github.com/alltuner/factoryfloor/issues/44)) ([9e52aa1](https://github.com/alltuner/factoryfloor/commit/9e52aa1665b7f1da5c7c8a86a2ef091f5df8d749))


### Miscellaneous

* update versions.json to v0.1.14 ([b4c06bc](https://github.com/alltuner/factoryfloor/commit/b4c06bc849f1451a0a5507197d128c1f375ae16a))

## [0.1.14](https://github.com/alltuner/factoryfloor/compare/v0.1.13...v0.1.14) (2026-03-17)


### Bug Fixes

* **ci:** use correct xcodegen-action version tag (1.2.4, no v prefix) ([#36](https://github.com/alltuner/factoryfloor/issues/36)) ([70e79a6](https://github.com/alltuner/factoryfloor/commit/70e79a624e090429cb2e1e97a35ff67421dd76ed))

## [0.1.13](https://github.com/alltuner/factoryfloor/compare/v0.1.12...v0.1.13) (2026-03-17)


### Bug Fixes

* **ci:** use correct xcodegen action (xavierLowmiller/xcodegen-action) ([#34](https://github.com/alltuner/factoryfloor/issues/34)) ([abfcac3](https://github.com/alltuner/factoryfloor/commit/abfcac320332011b7cd50421a2b02e35fc53928c))

## [0.1.12](https://github.com/alltuner/factoryfloor/compare/v0.1.11...v0.1.12) (2026-03-17)


### Bug Fixes

* **ci:** correct xcodegen setup action name ([#32](https://github.com/alltuner/factoryfloor/issues/32)) ([a70ef8a](https://github.com/alltuner/factoryfloor/commit/a70ef8a0af8672665c46a851870e36257ea6d9db))

## [0.1.11](https://github.com/alltuner/factoryfloor/compare/v0.1.10...v0.1.11) (2026-03-17)


### Performance

* **ci:** replace brew with dedicated setup actions for zig and xcodegen ([#30](https://github.com/alltuner/factoryfloor/issues/30)) ([d438aaf](https://github.com/alltuner/factoryfloor/commit/d438aafae5a83a6b5f74c917abe08781f982e3ea))

## [0.1.10](https://github.com/alltuner/factoryfloor/compare/v0.1.9...v0.1.10) (2026-03-17)


### Performance

* **ci:** cache ghostty xcframework between builds ([#26](https://github.com/alltuner/factoryfloor/issues/26)) ([1d51987](https://github.com/alltuner/factoryfloor/commit/1d519873cecf52acf6ffee39c0d47ddd7f52b5a9))
* **ci:** cache SPM packages between builds ([#29](https://github.com/alltuner/factoryfloor/issues/29)) ([960b037](https://github.com/alltuner/factoryfloor/commit/960b03734755023fa4086987a4dfd15031f843a1))


### Miscellaneous

* **deps:** update actions/cache action to v5 ([#27](https://github.com/alltuner/factoryfloor/issues/27)) ([c506297](https://github.com/alltuner/factoryfloor/commit/c50629746d9936178b63399901f82dde0bbb14a2))

## [0.1.9](https://github.com/alltuner/factoryfloor/compare/v0.1.8...v0.1.9) (2026-03-17)


### Bug Fixes

* pass env vars to tmux sessions via -e flags ([#24](https://github.com/alltuner/factoryfloor/issues/24)) ([596f731](https://github.com/alltuner/factoryfloor/commit/596f7313c0a97dfb6ad092b3fb8ea2065d278681))

## [0.1.8](https://github.com/alltuner/factoryfloor/compare/v0.1.7...v0.1.8) (2026-03-17)


### Features

* **website:** add changelog page with timeline layout ([#20](https://github.com/alltuner/factoryfloor/issues/20)) ([d0b38e5](https://github.com/alltuner/factoryfloor/commit/d0b38e50c5043a5da22c8525b6145c5c1e1c1c9a))


### Bug Fixes

* **ci:** remove --deep from app re-signing, add debug logging ([#23](https://github.com/alltuner/factoryfloor/issues/23)) ([d298fb8](https://github.com/alltuner/factoryfloor/commit/d298fb898d6eb081daf244371c0a735208e175c3))
* let release-please bump version in Info.plist ([#22](https://github.com/alltuner/factoryfloor/issues/22)) ([1624a40](https://github.com/alltuner/factoryfloor/commit/1624a40be203c21b3723994b0fe1d3a2d4096fd4))


### Miscellaneous

* update versions.json to v0.1.7 ([7a67bf2](https://github.com/alltuner/factoryfloor/commit/7a67bf2ebb8cea5dc998e788a5c79e17e2f01687))

## [0.1.7](https://github.com/alltuner/factoryfloor/compare/v0.1.6...v0.1.7) (2026-03-17)


### Bug Fixes

* resolve workspace creation failure in production builds ([#18](https://github.com/alltuner/factoryfloor/issues/18)) ([ece00ab](https://github.com/alltuner/factoryfloor/commit/ece00ab0c20b17f4e169c16e1a748804a1ea8222))


### Miscellaneous

* update versions.json to v0.1.6 ([b0acea2](https://github.com/alltuner/factoryfloor/commit/b0acea2441e1fd2dc70ff7035b8b8afa12554fbc))

## [0.1.6](https://github.com/alltuner/factoryfloor/compare/v0.1.5...v0.1.6) (2026-03-17)


### Bug Fixes

* **ci:** enable hardened runtime and secure timestamps for notarization ([#16](https://github.com/alltuner/factoryfloor/issues/16)) ([5f52d57](https://github.com/alltuner/factoryfloor/commit/5f52d576c4ac87d1e88f6a002c291f9322fbafe7))

## [0.1.5](https://github.com/alltuner/factoryfloor/compare/v0.1.4...v0.1.5) (2026-03-17)


### Bug Fixes

* **ci:** fetch Apple notarization log on failure ([#14](https://github.com/alltuner/factoryfloor/issues/14)) ([7fc381e](https://github.com/alltuner/factoryfloor/commit/7fc381ee029486c13ac6e38248396683570c6087))

## [0.1.4](https://github.com/alltuner/factoryfloor/compare/v0.1.3...v0.1.4) (2026-03-17)


### Bug Fixes

* **ci:** skip ghostty app bundle build, only emit xcframework ([#12](https://github.com/alltuner/factoryfloor/issues/12)) ([c5844b3](https://github.com/alltuner/factoryfloor/commit/c5844b3b9203419281d0f61069b2dcb6307b1d9f))

## [0.1.3](https://github.com/alltuner/factoryfloor/compare/v0.1.2...v0.1.3) (2026-03-17)


### Bug Fixes

* **ci:** build ghostty xcframework before release build ([#10](https://github.com/alltuner/factoryfloor/issues/10)) ([f7be824](https://github.com/alltuner/factoryfloor/commit/f7be824119e04304c3a9c46ae84eadbb1f63489d))

## [0.1.2](https://github.com/alltuner/factoryfloor/compare/v0.1.1...v0.1.2) (2026-03-17)


### Bug Fixes

* resolve CI build failure and ff-run notarization ([#8](https://github.com/alltuner/factoryfloor/issues/8)) ([4e74409](https://github.com/alltuner/factoryfloor/commit/4e74409db010682053161d9f1c9bcffe263f1f3b))

## [0.1.1](https://github.com/alltuner/factoryfloor/compare/v0.1.0...v0.1.1) (2026-03-17)


### Features

* add accessibility labels to all interactive elements ([8fc8b9e](https://github.com/alltuner/factoryfloor/commit/8fc8b9e3bc99872af48ab12793082b300fb956b6))
* add copy-branch-name button in workstream info header ([017ea45](https://github.com/alltuner/factoryfloor/commit/017ea451e11b9ece5edb1582655de2d2d1415ba1))
* add doc tabs (README, CLAUDE, AGENTS) to project overview page ([41513e3](https://github.com/alltuner/factoryfloor/commit/41513e3ed1c8915f02acd40ea2f86595407d3138))
* add Environment tab with setup/run script terminals ([da14cfa](https://github.com/alltuner/factoryfloor/commit/da14cfafcb6e1dd2c5d56e965788bea276160490))
* add GitHub Sponsors and Buy Me a Coffee funding options ([3da86a5](https://github.com/alltuner/factoryfloor/commit/3da86a593d36ea92ea9c32e6c211b8181e6651a9))
* add keyboard shortcuts for Rebuild (⌃⇧S) and Start/Rerun (⌃⇧R) ([9d04703](https://github.com/alltuner/factoryfloor/commit/9d047035118f36bd3b435716ea1aa8460c161231))
* add onboarding view with prerequisites and getting started guide ([6b5b09c](https://github.com/alltuner/factoryfloor/commit/6b5b09c12c96dad7219617c557c21ffc673a6254))
* add run-script port detection ([360e453](https://github.com/alltuner/factoryfloor/commit/360e45343c411574bea435565b4027b957458655))
* add scripts/dev.sh for development workflow ([c0be015](https://github.com/alltuner/factoryfloor/commit/c0be0158d4f26c8971d3c642d08e5c4364d4da45))
* add Sentry crash reporting, update privacy policy ([5a2f954](https://github.com/alltuner/factoryfloor/commit/5a2f9547eafb1c6378eb037c54f6bd4a863aa464))
* add setting to disable quit confirmation ([9fb2579](https://github.com/alltuner/factoryfloor/commit/9fb25798b000d57b0bede1f7a591655b7aa8f80b))
* add sponsor message to ff CLI (~1 in 5 runs) ([2cf4428](https://github.com/alltuner/factoryfloor/commit/2cf442824e149e9a98da507f139aeb81524decc4))
* add update checker with sidebar notification badge ([21df890](https://github.com/alltuner/factoryfloor/commit/21df8907d26e08abcf020e8682c09fb5394ecd54))
* automate versions.json update in release workflow ([a5bfb02](https://github.com/alltuner/factoryfloor/commit/a5bfb02d799fc4578cd2f6f7a407b7de394e5a57))
* bundle ff CLI script in app resources ([c03257b](https://github.com/alltuner/factoryfloor/commit/c03257b12d06cd9e090a13184527e90ce1ec713e))
* change workstream navigation to Cmd+Shift+1-9 ([eae8d6a](https://github.com/alltuner/factoryfloor/commit/eae8d6a9d4018bab9206ad9726e1b70086c224c4))
* confirm before quit when workstreams are active ([ab43577](https://github.com/alltuner/factoryfloor/commit/ab435771d8f8c6cd7e48020614e125dab7d8fd1f))
* debug builds use separate identity from release ([23b0d22](https://github.com/alltuner/factoryfloor/commit/23b0d229c1db090af1f7397ba9d07889a76710d5))
* debug icon with orange band, tmux config in .config dir ([cd5d0e7](https://github.com/alltuner/factoryfloor/commit/cd5d0e7cf1e2421cd15bd202aae7ea2029369240))
* notify user when project directories are removed from disk ([e5e6238](https://github.com/alltuner/factoryfloor/commit/e5e6238ad3ea332062127ac6bf5961aa16fa670f))
* preload agent and environment terminals in background on workstream open ([ff8dd2e](https://github.com/alltuner/factoryfloor/commit/ff8dd2ec3598e1dc51adeba012a65a8567656bc7))
* replace MarkdownView with cmark-gfm WKWebView renderer ([3eb7380](https://github.com/alltuner/factoryfloor/commit/3eb7380d6fb2efcea5e8aed921162c7c95f98529))
* restore workspace tab state ([493facb](https://github.com/alltuner/factoryfloor/commit/493facb5ca593dc750b09c4a539615f6ce026ad6))
* separate URL scheme and CLI for debug builds ([ed97fc6](https://github.com/alltuner/factoryfloor/commit/ed97fc668e27371cd64fdf3d5e96b7b1a27a4b83))
* show "Run gh auth login" hint when gh is installed but not authenticated ([a224535](https://github.com/alltuner/factoryfloor/commit/a22453569301df6ceb9c60f9795f3f9f42f66030))
* show install prompt when Claude Code is not found ([49be786](https://github.com/alltuner/factoryfloor/commit/49be7865923e2b047ec9860ebcc90f311ab346ee))
* show page title in browser tab label ([f1f954d](https://github.com/alltuner/factoryfloor/commit/f1f954d65a907c8b3bbc83ce0fb6e12ba88a1dfb))
* show project icon in workstream info header if found ([5ad1966](https://github.com/alltuner/factoryfloor/commit/5ad19666c11ece9b74af9b6a16650904ef55ff71))
* show running command in terminal tab label ([895b6b6](https://github.com/alltuner/factoryfloor/commit/895b6b614971d1d056ea3010447af075a4ac2e20))
* **website:** add favicon, OG image, and SEO meta tags ([eb71e2a](https://github.com/alltuner/factoryfloor/commit/eb71e2ad16457ecd08787f5785d98dcb3c279f6f))
* **website:** add privacy policy page in 4 languages ([6c60735](https://github.com/alltuner/factoryfloor/commit/6c60735e9923a1643a42d6b173d1a8b5ed33a54d))
* **website:** add versions.json and /get page for update notifications ([0e9889d](https://github.com/alltuner/factoryfloor/commit/0e9889ded1a041915a3639527d13d55fbb285148))
* **website:** replace OG image with branded banner ([4c45058](https://github.com/alltuner/factoryfloor/commit/4c4505863760bb9ca277d1d545c4cbdc1ffa437c))
* **website:** replace terminal simulation with real app screenshots ([93cef2f](https://github.com/alltuner/factoryfloor/commit/93cef2f0bfa4a003d440926ce2ec714b8b838ee8))


### Bug Fixes

* add Cmd+E to help view, align Claude install URLs, remove dead code ([ba61ffa](https://github.com/alltuner/factoryfloor/commit/ba61ffa4a0beba8527e9dd4dee3c456782f1f74c))
* add missing localization strings for Settings, HelpView, BrowserView, ProjectOverview ([489a7b8](https://github.com/alltuner/factoryfloor/commit/489a7b83e84cf25d93c58379446de7062373e637))
* address security audit findings ([13e846f](https://github.com/alltuner/factoryfloor/commit/13e846fa54d26ce1cf2e860b7d951b2d75e5b7f0))
* avoid worktree path collision for `/` vs `-` in names ([36ec6d5](https://github.com/alltuner/factoryfloor/commit/36ec6d557222b823eba067883dc12b4742185ecd))
* browser retry hint, dead retryBrowser notification, settings persistence ([0e2e439](https://github.com/alltuner/factoryfloor/commit/0e2e43959c17afbe351d051a834243f5681e3653))
* change workstream shortcuts to Ctrl+1-9 (Cmd+Shift collides with screenshots) ([c90bb91](https://github.com/alltuner/factoryfloor/commit/c90bb916b6ebadcd01766fdcf5a84904a913f998))
* correct embedded terminal selection coordinates ([80a72db](https://github.com/alltuner/factoryfloor/commit/80a72db0c546934a7decb958dd458ced558ec72d))
* disable wait-after-command, fix restart, add favicon sizes ([a0ecbb9](https://github.com/alltuner/factoryfloor/commit/a0ecbb92e0d11e7e8496776bc152dc6de5b60171))
* dispatch surfaceRegistry deinit removal to main thread ([e09edd3](https://github.com/alltuner/factoryfloor/commit/e09edd3d9517dc916d35aefbf46fdca213443999))
* drop redundant .atomic option in FilePersistence ([e95b36b](https://github.com/alltuner/factoryfloor/commit/e95b36baeb2cc6d7512826faae68904b19041c8c))
* eliminate AppleScript command injection in openInTerminal ([82df6f2](https://github.com/alltuner/factoryfloor/commit/82df6f2cc60c082f2c7fb7a8adb57cce1bac3320))
* explicitly free ghostty surface on restart to prevent launch failures ([a489892](https://github.com/alltuner/factoryfloor/commit/a4898929fb76a3d7242450ebc2a85505b1ac8d66))
* hide CLI install when already correctly installed ([1b1c7a1](https://github.com/alltuner/factoryfloor/commit/1b1c7a11a66db5bd4cfafc12fd5e75ca1020368e))
* improve worktree creation error message clarity ([3db0f24](https://github.com/alltuner/factoryfloor/commit/3db0f24ab08456066e470b53f30d75f3e3059549))
* improve worktree creation error message with specific failure reasons ([b85d39a](https://github.com/alltuner/factoryfloor/commit/b85d39a414032c41c51bf86d90516f5029d548d8))
* isolate test config storage from app roster ([e95916c](https://github.com/alltuner/factoryfloor/commit/e95916cfe38a3ae9807ded916c177e24a35f2328))
* localize all remaining hardcoded strings ([a611245](https://github.com/alltuner/factoryfloor/commit/a6112452102e4cc3d4f14237e957e0dfda7b9a14))
* make wait_after_command per-surface, restore agent respawn ([14689b3](https://github.com/alltuner/factoryfloor/commit/14689b30a65342a6fb228e5e2418cf30fbfb2dcb))
* mention all config formats in environment tab instructions ([743ac36](https://github.com/alltuner/factoryfloor/commit/743ac36d205108c4fcc659d00a32e9efe923c6c8))
* move ghostty callbacks out of main actor init ([a0ec131](https://github.com/alltuner/factoryfloor/commit/a0ec1314c65b55fc33c11ad7d0ff9f97631b4889))
* normalize detached HEAD branch name to nil ([339917f](https://github.com/alltuner/factoryfloor/commit/339917fe63328113db508fdf8ad6dc5a123c2921))
* pin third-party CI actions to commit SHAs ([aebdb70](https://github.com/alltuner/factoryfloor/commit/aebdb7080cea6e0edd94a6212d15f880ae7fb32b))
* pretty-print JSON config files for readability ([72092b2](https://github.com/alltuner/factoryfloor/commit/72092b2fbe98cba17df91fa3a84f9d83c66629db))
* prevent env scripts from respawning, add help view links ([6001cec](https://github.com/alltuner/factoryfloor/commit/6001cec83a82f4b7320a85a030c6b82772b28087))
* prevent git flag injection via names starting with dash ([8804fab](https://github.com/alltuner/factoryfloor/commit/8804fab9da62405ca3ddfedf7c9cf5f1c8ca0a79))
* prevent shell injection in TmuxSession.wrapCommand ([b9a26c2](https://github.com/alltuner/factoryfloor/commit/b9a26c25cdee2794e335a662c9bee2bfe3d5418c))
* prevent surfaceRegistry use-after-free and Cmd+W monitor accumulation ([b681cd4](https://github.com/alltuner/factoryfloor/commit/b681cd44fda1078743238c7fde995648139dd749))
* proc_listchildpids returns count not bytes, add Stop button ([70f24b3](https://github.com/alltuner/factoryfloor/commit/70f24b31ff22026aae794292f04b6d6288951d1e))
* propagate errors from FilePersistence.writeAtomically instead of swallowing ([7bbea7f](https://github.com/alltuner/factoryfloor/commit/7bbea7ff5ec2e040bddba426008ca9377d67999d))
* rebuild cached claude command when workstreamName changes ([b0be7e0](https://github.com/alltuner/factoryfloor/commit/b0be7e07d4ba114527ad25ea22aa12d3e18d8d14))
* remove .factoryfloor/config.json, fix website i18n and nav ([79d9776](https://github.com/alltuner/factoryfloor/commit/79d97760e905ecad4c7facecb656832da5e6102e))
* remove cat workaround, fix env script restart timing ([e98cd5b](https://github.com/alltuner/factoryfloor/commit/e98cd5b7becb56342dee25ef21409947aa6a7b9f))
* remove hard cap on surface cleanup in removeWorkstreamSurfaces ([5ea7ea2](https://github.com/alltuner/factoryfloor/commit/5ea7ea208f50e2b92815ac6dbc138a460bb572ee))
* remove redundant codesign --deep --force on .app bundle ([f44028c](https://github.com/alltuner/factoryfloor/commit/f44028c740655d267e9f6ce354c8817b710e7ebf))
* remove wait_after_command override, let ghostty use its default ([3610a86](https://github.com/alltuner/factoryfloor/commit/3610a86a9af31fc786738ce039d06975e0168310))
* rename "Projects Removed" alert to "Projects Not Found" and use comma-separated list ([0d09a84](https://github.com/alltuner/factoryfloor/commit/0d09a849049dbf247c0523f8e0baf85d27dc1f1b))
* replace favicon PNGs with alltuner icons, kill tmux on restart ([af7adc9](https://github.com/alltuner/factoryfloor/commit/af7adc91ebcd42dd5b10b8a9b9262a3e47530c3e))
* replace predictable /tmp filenames with shell variables in CI ([102b3fc](https://github.com/alltuner/factoryfloor/commit/102b3fc9865d3af853a46df59165ffed7e9dd0b1))
* resolve relative image paths in markdown info view ([21807de](https://github.com/alltuner/factoryfloor/commit/21807dedc794b836107f6b74e08f57a887796e08))
* restore keyboard focus rings on browser nav buttons ([e22b4b9](https://github.com/alltuner/factoryfloor/commit/e22b4b9df358a2f2de77cc086dd555d5b31744c2))
* restore native mouse behavior in tmux terminals ([a455855](https://github.com/alltuner/factoryfloor/commit/a4558559fcc13e740f75b0b14becd71e8a90a286))
* restore tmux environment sessions ([d606c1d](https://github.com/alltuner/factoryfloor/commit/d606c1d87f0afdcf692dcc4c5a84692d4605aac0))
* revert CI action SHA pinning to version tags, fix deinit deadlock ([5027aa2](https://github.com/alltuner/factoryfloor/commit/5027aa2615a42273bfac4958d182b169db335284))
* rewrite website translations as native copywriting ([c3af758](https://github.com/alltuner/factoryfloor/commit/c3af7585af24b7303de6ca7f3b40ea0558862d5b))
* scope CI permissions per job for least privilege ([2711fae](https://github.com/alltuner/factoryfloor/commit/2711fae56bc9e510158d4c2dcbdb2f4eec32dd11))
* show alert when adding workstream to non-git directory ([b3356dd](https://github.com/alltuner/factoryfloor/commit/b3356dd53dc8706b1fb43d6921c4ae8b256c7756))
* show error dialog when ghostty fails to initialize ([991214b](https://github.com/alltuner/factoryfloor/commit/991214b6bd9896c43e87e3197c7f923e664217ce))
* show error when worktree creation fails ([1af1cce](https://github.com/alltuner/factoryfloor/commit/1af1cce6e10b39a71c313282294961212079b809))
* show pointer cursor on sidebar bottom buttons ([a185708](https://github.com/alltuner/factoryfloor/commit/a185708fa6762d9fbd0bdf1f241588ec80dadd5c))
* sidebar bottom bar always visible, not clipped by drop zone ([13c057b](https://github.com/alltuner/factoryfloor/commit/13c057b4d63c542116dc100d27242fc6f269347d))
* sign bundled ff-run and stabilize project identity ([aa2d863](https://github.com/alltuner/factoryfloor/commit/aa2d863c34338568d981dbcd5386e90864390a62))
* skip doc tabs for markdown files smaller than 20 bytes ([4e406c6](https://github.com/alltuner/factoryfloor/commit/4e406c695659b3c1972308a3746464ef037d9e8a))
* sleep after env script exits instead of returning to shell ([bb147b2](https://github.com/alltuner/factoryfloor/commit/bb147b2d2e7f434084a912740a645ac2447420d0))
* split tmux/non-tmux env terminal approach, fix rebuild loop ([cc5ee14](https://github.com/alltuner/factoryfloor/commit/cc5ee1482e0cf50fe0490dded9d2c5bf1733a8c8))
* stop swallowing Gatekeeper failures in release script ([7c8b5e5](https://github.com/alltuner/factoryfloor/commit/7c8b5e5c9b247a582b770dafdd23ada50e0c000b))
* surface cleanup now covers all prefixes and generation numbers ([eeb3dba](https://github.com/alltuner/factoryfloor/commit/eeb3dba8dd756125e258e706ff4212c1f42ebf43))
* swap env shortcuts (Rebuild ⌃⇧R, Start/Rerun ⌃⇧S) ([8efc198](https://github.com/alltuner/factoryfloor/commit/8efc198b45fc6a0992aaf448f4c6aa50cf8dbcad))
* translation audit across all 4 languages ([0c8c10c](https://github.com/alltuner/factoryfloor/commit/0c8c10c99f2d8dac0d1cf11a9dcb9f0c46588afd))
* update Buy Me a Coffee URL to alltuner account ([856b7fb](https://github.com/alltuner/factoryfloor/commit/856b7fbdeed1428250d5b2ec1a2cb32c9fd05162))
* use cat to keep env terminals open, add Rebuild/Rerun/Start labels ([32286f5](https://github.com/alltuner/factoryfloor/commit/32286f5b0bf12e6b06df4bdb3a8c12f452b6f415))
* use initialInput for all env terminals, fix tmux restart loop ([1e3b3cf](https://github.com/alltuner/factoryfloor/commit/1e3b3cf052e23732bf053c2acddefb4f6581471c))
* use initialInput instead of command for env scripts ([d7c70c9](https://github.com/alltuner/factoryfloor/commit/d7c70c9f47509365e0c3b3552d4430f02019a1dc))
* use keychain profile for CI notarization instead of CLI password ([115050a](https://github.com/alltuner/factoryfloor/commit/115050a70bad4a0de3a1899ffc6789429d6af5f1))
* use smaller font and colon in gh auth login hint ([9dfde67](https://github.com/alltuner/factoryfloor/commit/9dfde67281b786b77e19d8d5609908a5026d40e8))
* validate .env symlink source and fix derivedUUID comment ([4a79d74](https://github.com/alltuner/factoryfloor/commit/4a79d74740743170c7f7522f4cd851742fe9ffe4))
* **website:** add --cask to brew install commands ([efed35e](https://github.com/alltuner/factoryfloor/commit/efed35e39c6a91b550bcc1213d76e0fe43cd6b22))
* **website:** add Claude Code link in features, enable HTML in descriptions ([8cdbdee](https://github.com/alltuner/factoryfloor/commit/8cdbdee832e7682b4f2fb59b9f06cf1404cc4ec5))
* **website:** add Claude Code link in hero text, add tmux to credits ([822e712](https://github.com/alltuner/factoryfloor/commit/822e7129ba1b64801248ca282be2c7f62d02fae5))
* **website:** add copy-to-clipboard visual feedback on /get page ([6fef3b6](https://github.com/alltuner/factoryfloor/commit/6fef3b67315adac0539698338b57efe234d5846d))
* **website:** add upgrade command to /get page ([1da011a](https://github.com/alltuner/factoryfloor/commit/1da011a0eea156bd345aec2a60c1f67fbe175949))
* **website:** adjust skyline spacing (more top margin, less bottom gap) ([77f0a19](https://github.com/alltuner/factoryfloor/commit/77f0a19137190b2883a38c18377ef05ba94feedf))
* **website:** clarify that Claude Code sends code to Anthropic's API ([ae8d649](https://github.com/alltuner/factoryfloor/commit/ae8d64941f43f434b2a7dfbb3900da878e46ceda))
* **website:** compact footer and add sponsor link ([7cc5961](https://github.com/alltuner/factoryfloor/commit/7cc59614717310eda7d00307416aa7a92a592889))
* **website:** fix hreflang x-default, add privacy link, localize sponsor link ([781f0ac](https://github.com/alltuner/factoryfloor/commit/781f0aca05866467b32b7363e4944af5f425b1b4))
* **website:** localize page titles, simplify config section ([e5e673e](https://github.com/alltuner/factoryfloor/commit/e5e673ee772ddf3bb216d38886bcc8d91b461da1))
* **website:** regenerate favicons from hi-res 1024x1024 source ([bab5c34](https://github.com/alltuner/factoryfloor/commit/bab5c34af0a3ab2e291367158d618b88b2c2e1e0))
* **website:** reorder sponsor page, financial support first ([ddd02d1](https://github.com/alltuner/factoryfloor/commit/ddd02d159eb52906646a24c7e7c82d9515fbc0a9))
* **website:** sponsor page sections, ghostty URL, remove duplicate credit ([9966a76](https://github.com/alltuner/factoryfloor/commit/9966a7633da06bb9e6e5c188d000bd4aa81180f7))
* **website:** tighten skyline viewBox to match terminal preview width ([5fb9fb5](https://github.com/alltuner/factoryfloor/commit/5fb9fb5e6f311ee430e7d9e098dcbd5af328932a))
* **website:** translate sponsor page to all 4 languages ([9b906f3](https://github.com/alltuner/factoryfloor/commit/9b906f3352efacc5a1a6c8693b4ac5f75654f641))
* **website:** translate sponsor page to all 4 languages ([2573ebd](https://github.com/alltuner/factoryfloor/commit/2573ebd6f7de4f966070249540825e6819832d89))
* **website:** update built CSS ([f4a0153](https://github.com/alltuner/factoryfloor/commit/f4a015345077c64731d03a7e280b56fd16c276e9))
* **website:** update favicons from alltuner.com ([cec8a2d](https://github.com/alltuner/factoryfloor/commit/cec8a2daaa0b5dab400f6c1df0c69733239caa14))
* **website:** update OG image to correct dimensions (1669x630) ([72c3caf](https://github.com/alltuner/factoryfloor/commit/72c3cafc83d8e3dd0da95cc6c9737d4076326693))
* **website:** update OG image to standard 1200x630 dimensions ([e9100dc](https://github.com/alltuner/factoryfloor/commit/e9100dc4da84a89cc824b649a39aa29a3ee026d9))
* **website:** update stylesheet ([4b75d80](https://github.com/alltuner/factoryfloor/commit/4b75d80f53cd00be11379fcb8e57ceac797697f5))
* **website:** use descriptive homepage title for SEO ([77088bb](https://github.com/alltuner/factoryfloor/commit/77088bbe9c138eea72466536a9d07f7631c6cd27))
* **website:** use proper hero title for CA/ES ([e8e3ea5](https://github.com/alltuner/factoryfloor/commit/e8e3ea5511fcd1ed36e56d0481b68c5edc9f2cbd))


### Refactoring

* consolidate duplicated performArchive into shared function ([68b6885](https://github.com/alltuner/factoryfloor/commit/68b6885e0636e4ae88a375cfd93779816e180fd2))
* extract abbreviatePath into shared String extension ([5dcf9a4](https://github.com/alltuner/factoryfloor/commit/5dcf9a47329e73e7b48abb61d1cd7df8ce743d4e))
* move derivedUUID to PathUtilities ([7035f33](https://github.com/alltuner/factoryfloor/commit/7035f33fbeb423056d106b80c3520faf9830e444))
* move persistence from UserDefaults to JSON files ([d79a80b](https://github.com/alltuner/factoryfloor/commit/d79a80b8209104ad0603eb946fd09adec9653f51))
* move retroactive Identifiable conformances to PathUtilities ([12f47a7](https://github.com/alltuner/factoryfloor/commit/12f47a7c953bfa44bf6c9560192def1c1e74d445))
* remove dead code and misleading async ([089ab29](https://github.com/alltuner/factoryfloor/commit/089ab29fe41032ee2ef1d1e87e27f1b50f1ca2a3))
* remove emdash/conductor/superset config compatibility ([ddcb924](https://github.com/alltuner/factoryfloor/commit/ddcb92473b291b45acd546de73cf588cf4baaa74))
* remove emdash/conductor/superset, make run script on-demand ([c2272c7](https://github.com/alltuner/factoryfloor/commit/c2272c728c49de45b6d3ee3faaf923e6033940f3))
* remove redundant objectWillChange handler for cachedClaudeCommand ([6a41461](https://github.com/alltuner/factoryfloor/commit/6a41461c69deebfa1460610f97b2799557e4dc24))
* rename bridging header, pin ghostty v1.3.1, modernize project ([c78270c](https://github.com/alltuner/factoryfloor/commit/c78270c70474277259a64284d2da599311dd35a1))
* **website:** remove dead HTML content from homepage ([5e8f015](https://github.com/alltuner/factoryfloor/commit/5e8f0153d9fb7c71535c56fe4720d49dfbc8200f))


### Performance

* cache projectIndex/workstreamIndex in ProjectSidebar ([b275ffa](https://github.com/alltuner/factoryfloor/commit/b275ffac0178bc607546a61adb501b3f3e600675))
* consolidate polling timers ([4e816e1](https://github.com/alltuner/factoryfloor/commit/4e816e19fd90f065afdf6b192f1a724e689d816c))
* occlude non-visible terminal surfaces to save GPU ([e1cf600](https://github.com/alltuner/factoryfloor/commit/e1cf60063abc2460fb8d80c013283b663a899da4))
* parallelize git subprocess calls in refreshPathValidity ([63671ba](https://github.com/alltuner/factoryfloor/commit/63671ba3c89c8550db901ab9f015ebb8898a9ed4))


### Miscellaneous

* add OG banner design to future TODO ([07fea3c](https://github.com/alltuner/factoryfloor/commit/07fea3cdcd61b11ec3f7c6131fd0c039d5bfabba))
* clean up TODO list ([7caf9ad](https://github.com/alltuner/factoryfloor/commit/7caf9ada4f65d89159e2c05f61d3a1d1cf76d052))
* clean up TODO, deduplicate, record terminal lifecycle fixes ([c1ab179](https://github.com/alltuner/factoryfloor/commit/c1ab17979581712a1d43609b2098497642b815d8))
* consolidate TODO list, mark completed items ([ff0a2b2](https://github.com/alltuner/factoryfloor/commit/ff0a2b2d0af772a12fec29f09c72fcf1b5da8aeb))
* **deps:** update actions/checkout action to v6 ([#6](https://github.com/alltuner/factoryfloor/issues/6)) ([c9ea157](https://github.com/alltuner/factoryfloor/commit/c9ea157442af9f42b5b5238bfb20270fb3ca56e6))
* **deps:** update dependency macos to v15 ([#7](https://github.com/alltuner/factoryfloor/issues/7)) ([67754f9](https://github.com/alltuner/factoryfloor/commit/67754f9ebb5fa2072977bd68f24f80c3d7416866))
* enable strict concurrency checks ([4b95cbe](https://github.com/alltuner/factoryfloor/commit/4b95cbeafe9308a7321475e697b0ef577cfe1945))
* flip project to swift 6 ([bf0c227](https://github.com/alltuner/factoryfloor/commit/bf0c227347349f7386310a65e22182f4ba546080))
* increase CLI sponsor message frequency to 1 in 2 runs ([9740718](https://github.com/alltuner/factoryfloor/commit/97407182ca13ed419c0678c8d6bbb361807e314a))
* mark CI scoping, onboarding, and persistence migration as done ([5923068](https://github.com/alltuner/factoryfloor/commit/5923068ab32f61d96c724ae998a2d6007b96d05a))
* mark completed items in TODO ([e3fbc45](https://github.com/alltuner/factoryfloor/commit/e3fbc4525ec79137c272c8b204d192c78b48c5a6))
* mark completed TODO items from latest parallel batch ([e467b93](https://github.com/alltuner/factoryfloor/commit/e467b936b1fe437fd6bf44f02ef7714b560b3d4a))
* mark completed TODO items from parallel agent work ([689a334](https://github.com/alltuner/factoryfloor/commit/689a334bfe950bd28bfa02124c193b96a68f6786))
* mark Homebrew tap as done in TODO ([a10ff74](https://github.com/alltuner/factoryfloor/commit/a10ff74b57924e693155bc4ae926983e1a8b45c1))
* mark port detection as implemented, update TODO ([7f530be](https://github.com/alltuner/factoryfloor/commit/7f530befd7a6d0f9b7051ca249c3a8e5932fc73e))
* mark projectIndex caching as done ([b911cb7](https://github.com/alltuner/factoryfloor/commit/b911cb72088f84e29aa29c6316ce8abd95af8cb1))
* mark round 2 fixes done, add release routine documentation task ([9b6457e](https://github.com/alltuner/factoryfloor/commit/9b6457e64e9752c77fc0ed2ce38c58e81bf9d7bd))
* mark round 2/3 UX and website fixes as done ([2435d54](https://github.com/alltuner/factoryfloor/commit/2435d549c158a96329b7fdf470dddf7c4acbc365))
* move distribution and release docs to pre-release ([6658477](https://github.com/alltuner/factoryfloor/commit/66584772bbaf469c8de57ada890e038f8c805789))
* remove node_modules from repo, add to .gitignore ([6753168](https://github.com/alltuner/factoryfloor/commit/675316869598b330bc80488216aaf4559146914e))
* triage TODO for pre-release push ([eda0c40](https://github.com/alltuner/factoryfloor/commit/eda0c40d78bc885e851e93f825ec94fce99902f2))
* update style ([3b1b9fa](https://github.com/alltuner/factoryfloor/commit/3b1b9fad00b42a913ee50449d41f28ff9eaa8a42))
* update todo ([77bbdcf](https://github.com/alltuner/factoryfloor/commit/77bbdcfba75da3db14cf07b78cbd7dc1082a71e6))
* update TODO with round 2 fixes and new planning tasks ([94514db](https://github.com/alltuner/factoryfloor/commit/94514db959f149b463d858e0a292d5605710e1e8))
* update TODO, remove stale config.json reference ([805e3f1](https://github.com/alltuner/factoryfloor/commit/805e3f12cbcec6ce1a62731682750e64bdc8b60a))


### Documentation

* add CONTRIBUTING.md and CODE_OF_CONDUCT.md ([ae5694f](https://github.com/alltuner/factoryfloor/commit/ae5694f234fac7d67e99db801e76279fc69e5580))
* add credits section to README and update TODO ([24aa040](https://github.com/alltuner/factoryfloor/commit/24aa040102afe5425b9198a0579c8108041e4ffd))
* add distribution and auto-update strategy ([1e33fdf](https://github.com/alltuner/factoryfloor/commit/1e33fdf8e37b27f18335482784fd1f1a36977243))
* add remaining audit findings to TODO ([e8381bb](https://github.com/alltuner/factoryfloor/commit/e8381bbc06527a105ea8163672e40603698f3f6e))
* add round 2 audit findings to TODO ([7e5d8e2](https://github.com/alltuner/factoryfloor/commit/7e5d8e2ec1885c366049f1dd4f7522011ef44757))
* add slow background polling fallback for port detection ([37a9cec](https://github.com/alltuner/factoryfloor/commit/37a9cecd5d1f3151e4c18b3270f7152444516bd9))
* add support section to README ([f75de3d](https://github.com/alltuner/factoryfloor/commit/f75de3d2e05bd73c870a3b58f97cc2be3202567d))
* add Swift 6 strict concurrency migration plan ([97193fd](https://github.com/alltuner/factoryfloor/commit/97193fdb753a26e036bc16e60b4b714e69d922b0))
* clarify ff-run crash recovery (user hits Rerun, no special handling) ([78cffae](https://github.com/alltuner/factoryfloor/commit/78cffae2aaa014bb8a24a80003368754f3e4f204))
* comprehensive TODO from security and architecture audit ([a2032da](https://github.com/alltuner/factoryfloor/commit/a2032da665e541c3a5f44915c9fcb53c3820b2fd))
* comprehensive TODO rewrite, add missing items ([275f839](https://github.com/alltuner/factoryfloor/commit/275f839ba0b0f40080f1b170843953cd994828b1))
* consolidate distribution docs ([9678046](https://github.com/alltuner/factoryfloor/commit/9678046f447707208eb68fabd3ab7a3f870ce7ed))
* consolidate port detection into final implementation plan ([3f351c4](https://github.com/alltuner/factoryfloor/commit/3f351c4e3db96b9db755e7d8f16182a7687cec21))
* fix README install/upgrade instructions, update CLAUDE.md ([8286c99](https://github.com/alltuner/factoryfloor/commit/8286c9939536cdab3a3bea1743c4fe1545c3d493))
* recommend public_repo scope for HOMEBREW_TAP_TOKEN ([36fc5c5](https://github.com/alltuner/factoryfloor/commit/36fc5c5bac32f68f17ef15dfee6d7f832fa6f1cb))
* remove port detection disable setting question (not needed) ([3f1757b](https://github.com/alltuner/factoryfloor/commit/3f1757b686ed01197ab119d378b6614afc075ad6))
* rename CLAUDE.md to AGENTS.md, update README and TODO ([26dd2ad](https://github.com/alltuner/factoryfloor/commit/26dd2ad9de8591ad91cbb15b92c2eb291d37c6f6))
* scope crash reporting options and implementation plan ([e19d437](https://github.com/alltuner/factoryfloor/commit/e19d437d7204e55bc018cca41220c5f1d5900d09))
* scope port detection for run scripts ([bd49c43](https://github.com/alltuner/factoryfloor/commit/bd49c433db94049a72cbffc4530f053e8814ae78))
* update distribution.md with current CI workflow and release routine ([a7bb738](https://github.com/alltuner/factoryfloor/commit/a7bb73808c8c8b9d92e9645169d8c7b2c7d2a536))
* update README, AGENTS.md, website, TODO for port detection ([5e63d17](https://github.com/alltuner/factoryfloor/commit/5e63d171bb3a66ce52c984be168aebe98550b7b9))
* update shortcuts in README and CLAUDE.md ([c92817e](https://github.com/alltuner/factoryfloor/commit/c92817e2f17ac225ae4ffaeca52b11101f74aa64))
* use FSEvents instead of polling for port detection state ([2510b6f](https://github.com/alltuner/factoryfloor/commit/2510b6f3222b016917b1a471ab858aef75c50ef9))


### CI/CD

* add weekly Ghostty compatibility test workflow ([6ab12f6](https://github.com/alltuner/factoryfloor/commit/6ab12f68354bd681ced75408ace18cfde03672cd))
* automate build, sign, notarize, DMG, and release upload ([ac60ae1](https://github.com/alltuner/factoryfloor/commit/ac60ae152066eb1d71bc8625f3cd16296accaabc))
