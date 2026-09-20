# InCollege
InCollege Software Engineering Project — Login, Profiles, Profile Viewing & Basic Search

# InCollege — Alpha (Epics 1–3)

## What this is
A console-style COBOL application (GnuCOBOL) implementing:
- New account creation (max 5 accounts, password validation)
- Login (unlimited attempts)
- Create/Edit My Profile — name, university, major, graduation year, About Me, up to 3 experience entries, up to 3 education entries
- View My Profile — the full saved profile, headed by `==== Profile for <first> <last>`
- Find someone you know — search other registered users by full name and view their profile
- Job search and Learn a New Skill are still "under construction"
- Persistence of accounts and profiles across runs
- Dual output: everything shown on screen is also written, verbatim, to an output file — and every simulated user input is written to that same output file (but not echoed to the screen), per spec.

## Files
- `InCollege.cob` — the program source
- `InCollege-Input.txt` — sample input file (one simulated user entry per line)
- `InCollege-Output.txt` — the output produced by running the program against the sample input
- `InCollege-Accounts.txt` — account persistence file (created/updated automatically; safe to delete to reset to zero accounts)
- `InCollege-Profiles.txt` — profile persistence file, keyed by username (created/updated automatically; safe to delete to reset all profiles)

## How to compile
Requires GnuCOBOL (`gnucobol4` package on Ubuntu/Debian: `apt-get install gnucobol4`).

```bash
cobc -x -free InCollege.cob -o InCollege
```

- `-x` builds an executable (not just a module)
- `-free` tells the compiler the source uses free-format (the source starts with `>>SOURCE FORMAT FREE`)

## How to prepare the input file
`InCollege-Input.txt` must sit in the same directory as the compiled `InCollege` executable. Put one simulated "typed" value per line, in the exact order the program will ask for it.

Menu inputs the program understands:
- Top menu: `1` = Log In, `2` = Create New Account
- Post-login menu: `1` = Create/Edit My Profile, `2` = View My Profile, `3` = Search for a job, `4` = Find someone you know, `5` = Learn a New Skill, `6` = Logout
- Learn-a-skill submenu: `1`–`5` = pick a skill, `6` = Go Back

**Important — unlimited login attempts**: if a login attempt fails, the program does NOT return to the top menu; it immediately re-prompts for username/password again (per spec, "unlimited attempts" happens inside the login flow). Keep this in mind when laying out lines in the input file, since the next two lines will always be consumed as the next username/password guess.

### Input for profile creation/editing (option 1)
After choosing `1` the program asks, in this order: First Name, Last Name, University/College, Major, Graduation Year, About Me, then the experience loop, then the education loop.

- The first five fields are required. A blank line is rejected and the prompt repeats.
- Graduation Year must be a 4-digit number greater than 2025 and less than 2034.
- About Me is optional — a blank line skips it.
- Experience and education each accept up to 3 entries. Type the title (or degree) to start an entry, or `DONE` to finish that section. Both loops must be terminated, so a profile with no optional entries needs a blank line for About Me followed by two `DONE` lines.

### Input for profile viewing and search (options 2 and 4)
- `2` takes no further input; it prints the logged-in user's whole profile.
- `4` consumes exactly one more line: the full name being searched for.

The search is an **exact match** on `<first name> <last name>` as stored in the profile, so `Leia Organa` matches but `Leia`, `Organa`, and `leia organa` do not. When a profile matches, it is displayed in the same layout as "View My Profile"; when nothing matches, the program prints `No one by that name could be found.` Either way the post-login menu is redisplayed, which is how the user returns to the top level menu.

Example input exercising the Week 3 features (this is the committed `InCollege-Input.txt`):

```
1
Anakin
ValidPswd1!
2
4
Leia Organa
4
John Doe
6
```

Line by line: log in as `Anakin`, view own profile, search for `Leia Organa` (found), search for `John Doe` (not found), log out.

## Where to find the output
After running:
```bash
./InCollege
```
Two things are produced:
1. Everything is printed live to the terminal (standard output).
2. The identical screen output — plus every simulated input line — is written to `InCollege-Output.txt` in the same directory.

`InCollege-Accounts.txt` and `InCollege-Profiles.txt` are also written/updated automatically; they are the persistence files and are read back in on the next run, so previously created accounts and profiles still work. Viewing and searching are read-only — they never rewrite the profile file.

## Notable design decisions / assumptions (flagged for the team)
- **Password validation** (2120-VALIDATE-PASSWORD): 8–12 chars, and requires at least one uppercase letter, one digit, and one non-alphanumeric character. On failure the student is re-prompted for a new password (they keep their already-accepted username) rather than starting the whole registration over.
- **Account limit**: implemented as "6th account already exists" (`WS-ACCOUNT-COUNT >= 5`) rather than a separate attempts counter, since every valid attempt fills a slot — functionally identical to "the 6th attempt" as worded in the spec, as long as attempts that fail validation don't consume a slot (they don't, in this implementation).
- **"Learn a New Skill" list**: the 5 skills are invented per the assignment's instructions (Excel, Public Speaking, Python Programming, Data Analysis, Networking) — swap in `WS-SKILL-TABLE` if your team wants different ones.
- **Logout on the post-login menu**: the spec explicitly calls for a Logout option on the "top level" (post-login) menu, so it was added as item 6 even though the sample transcripts in the spec don't show it.
- **Screen vs. file content**: per the spec's explicit note, prompts/messages are shown on screen and also written to the file, but raw user input is written to the file only (never printed back to the screen), matching the sample transcript, which never echoes what was typed.
- **One display routine for both views** (3400-DISPLAY-PROFILE): "View My Profile" and a successful search render the exact same fields in the exact same order, so the two can never drift apart. Only the surrounding banner differs (`--- Your Profile ---` vs `--- Found User Profile ---`).
- **Empty optional sections**: a profile with no experience or no education prints `Experience: None` / `Education: None` rather than omitting the heading, matching the Week 3 sample transcript.
- **Search is case-sensitive**: the spec calls for an exact match against the stored names, so no case folding is applied. If the team decides `john doe` should find `John Doe`, wrap both sides of the comparison in 3510-SEARCH-BY-FULL-NAME with `FUNCTION UPPER-CASE`.

## Suggested module breakdown (for Jira tasks)
- `1000` series — startup, shutdown, account and profile persistence load/save
- `2000` series — top-level menu, account creation, password/username validation, login
- `3000` series — post-login menu, learn-a-skill submenu, profile create/edit (`3200`), view own profile (`3300`), shared profile display (`3400`), find someone you know (`3500`/`3510`)
- `9000` series — shared I/O helpers (`9100` dual display+write, `9200` read+echo-to-file)
