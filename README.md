# Classic-EPGP
**Do not redistribute this addon. Post a link to this github page instead**

An addon designed to handle your guild's EPGP standings by storing the respective values in your Officer Notes. Another primary function of the addon is to handle loot moderation which you must be the master looter to utilise.

For this addon to work, anyone using the addon must be able to at the very least view Officer Notes. To adjust EP and GP values you must be able to edit Officer Notes.

The addon is entirely GUI based and the frame is designed to only appear automatically on raid bosses from Molten Core, Onyxia's Lair and World Bosses all the way up to Naxxramas.

Functionality:
* /cepgp show - Shows the CEPGP window
* /cepgp debug - Enables debug mode
* /cepgp setdefaultchannel - Changes the default reporting channel. This is set to Guild by default
* /cepgp version - Allows you to check if each raid member is running the addon - and if so, what version of the addon they are using

**Note: CEPGP is a context sensitive addon and elements will be visible when they are relevent**

Any function that involves modifying EPGP standings requires you to be able to edit officer notes to have it available to you.

The following commands can be used to get EPGP reports.

**The player you whisper must be able to at least view officer notes**
* /w player !info - Gets your current EPGP standings
* /w player !infoguild - Gets your current EPGP standings and PR rank within your guild
* /w player !inforaid - Gets your current EPGP standings and PR rank within the raid
* /w player !infoclass - Gets your current EPGP standings and PR rank among your class within the raid

Definitions:
* EP: Effort points. Points gained from what ever criteria.
* GP: Gear points. Points gained from being awarded gear.
* PR: Priority. Calculated by EP / GP.
* Decay: Reduces the EP and GP of every guild member by a given percent.
* Initial/Minimum GP: The GP that all new guild members start at. This also defines the minimum amount of GP any guild member can have.

__**IMPORTANT**__ - The initial/minimum GP should NEVER be exactly 0.

* Standby EP: EP awarded to guild members that are not in the raid.
* Standby EP Percent: The percent of standard EP allocation should awarded to standby members.

To install:
  1. Download this addon 
  2. Extract it to ../Interface/AddOns/ 
  3. Rename the extracted folder from CEPGP-master to CEPGP

**Note:**
Automatic retrieval of a recipient's item they currently have in slot when they whisper you !need has been added. This is only possible **if the loot master has the item that the recipient is wearing, in their game cache**. This is a restriction enforced by the 1.12.1 API.

**Note:**
If you are getting the message "Error - Player not found in guild roster." when the player is definitely in your guild, then ensure that the player is online, and if they're not online, then ensure that Show Offline Members is checked in your guild tab.
Another restriction of the 1.12.1 API is that addons cannot read guild members that you cannot see. Meaning, if the player is offline and you're not viewing offline members, then the addon cannot see them either.

Patch Version: 1.12.1

Build Number: 5875

Author: Alumian
