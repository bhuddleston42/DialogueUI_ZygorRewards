# Dialogue UI - Zygor Rewards

Version: **0.1.0-beta.1** | World of Warcraft Retail

See Zygor's recommended quest reward without leaving Dialogue UI.

[CurseForge](https://www.curseforge.com/wow/addons/dialogue-ui-zygor-rewards)
| [GitHub releases](https://github.com/bhuddleston42/DialogueUI_ZygorRewards/releases)

Requires Dialogue UI and Zygor Guides Viewer. Enable Zygor's quest reward
suggestions. Zygor's silver gear-and-Z emblem marks the upper-right corner of
its recommended reward. Dialogue UI's own upgrade and vendor icons remain
separate, so multiple item-level upgrades do not obscure Zygor's single pick.
Hover over the marker to see the Zygor recommendation tooltip.
Click the reward itself to select it as usual.

Uses Zygor's own scoring, waits for item information, and clears markers when
quests close or change. Does not select rewards or turn in quests.
Neither upstream addon is modified. Future changes to their internal APIs may
require updating this bridge.

## Installation

1. Install and enable Dialogue UI and Zygor Guides Viewer separately.
2. Extract the ZIP into `_retail_/Interface/AddOns`. The resulting folder must
   be `DialogueUI_ZygorRewards`, with its `.toc` file directly inside it.
3. Restart WoW if the new addon is not listed; enable it in the AddOns menu.
4. Enable quest reward suggestions in Zygor, then open a quest with reward choices.

The emblem identifies Zygor's choice; Dialogue UI's arrows may identify several
item-level upgrades (or Pawn upgrades when its integration is active).
This bridge does not add its own gear scoring or auto-selection.

## Troubleshooting and bug reports

Use `/duizygor` for the bridge status, dependency versions, and any compatibility
error. An incompatible reward API pauses the bridge until `/reload` and prints
one notification, rather than repeatedly failing.

No emblem can mean Zygor suggestions are disabled, item data is still loading,
there is no meaningful choice, or Zygor did not recommend a reward. After an
item-data timeout, reopen the quest to retry.

For a bug report include `/duizygor` output, WoW version, quest name/ID, your
class/spec, and a screenshot of the reward choices. Mention Dialogue UI theme,
UI size, and whether you use a controller. Do not upload your WTF folder.

## Beta compatibility

Built against the installed Dialogue UI 1.0.5 and Zygor 9.6 metadata, for Retail
interface versions 120100/120105. Classic is not supported by this package.
The recommendation and silver emblem have been confirmed working in-game by
the author. Broader theme/size and controller coverage has not been verified.
The added diagnostics and error handling have automated coverage.

Lua 5.1 syntax validation and 12 isolated behavior tests passed. Those tests
mock WoW's UI and do not establish in-game rendering or protected-action safety.

## Independence

Unofficial compatibility addon; not affiliated with or endorsed by the authors
of Dialogue UI or Zygor. Requires both addons and does not bundle their code,
guides, fonts, or artwork. The emblem references a texture in the user's Zygor
installation. Pawn support remains provided by Dialogue UI itself.

## Development and releases

From the addon directory, run `lua tests/regression.lua`,
`luac -p Bridge.lua`, and `python tests/validate_toc.py`.

GitHub Actions validates Lua and TOC metadata on pushes and pull requests.
Pushes to `main` produce preview ZIP artifacts. A `v` tag matching the TOC
version publishes a packaged GitHub release after validation. The first beta
tag is `v0.1.0-beta.1`. Tests and development metadata are excluded from packages.
CurseForge project 1708099 is linked to the same repository with packaging of
tagged commits enabled. The first beta was uploaded directly; new-project and
file moderation are handled by CurseForge.

## License

No license selected yet. All rights reserved.
