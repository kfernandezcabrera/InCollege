# InCollege
InCollege Software Engineering Project - Log In, Part 1

# InCollege — Log In, Part 1 (Alpha)

## What this is
A console-style COBOL application (GnuCOBOL) implementing:
- New account creation (max 5 accounts, password validation)
- Login (unlimited attempts)
- Post-login navigation (job search / find someone / learn a skill), all "under construction"
- Persistence of accounts across runs
- Dual output: everything shown on screen is also written, verbatim, to an output file — and every simulated user input is written to that same output file (but not echoed to the screen), per spec.

## Files
- `InCollege.cob` — the program source
- `InCollege-Input.txt` — sample input file (one simulated user entry per line)
- `InCollege-Output.txt` — the output produced by running the program against the sample input
- `InCollege-Accounts.txt` — persistence file (created/updated automatically by the program; safe to delete to reset to zero accounts)

## How to compile
Requires GnuCOBOL (`gnucobol4` package on Ubuntu/Debian: `apt-get install gnucobol4`).

```bash
cobc -x -free InCollege.cob -o InCollege
```

- `-x` builds an executable (not just a module)
- `-free` tells the compiler the source uses free-format (the source starts with `>>SOURCE FORMAT FREE`)

## How to prepare the input file
`InCollege-Input.txt` must sit in the same directory as the compiled `InCollege` executable. Put one simulated "typed" value per line, in the exact order the program will ask for it. For example, to create an account and log in:

```
2
jsmith
Pass123!
1
jsmith
Pass123!
4
```

Line-by-line meaning above: `2` = choose "Create New Account", then username, then password; `1` = choose "Log In", then username, then password; `4` = choose "Logout" from the post-login menu.

Menu inputs the program understands:
- Top menu: `1` = Log In, `2` = Create New Account
- Post-login menu: `1` = Search for a job, `2` = Find someone you know, `3` = Learn a new skill, `4` = Logout
- Learn-a-skill submenu: `1`–`5` = pick a skill, `6` = Go Back

**Important — unlimited login attempts**: if a login attempt fails, the program does NOT return to the top menu; it immediately re-prompts for username/password again (per spec, "unlimited attempts" happens inside the login flow). Keep this in mind when laying out lines in the input file, since the next two lines will always be consumed as the next username/password guess.

## Where to find the output
After running:
```bash
./InCollege
```
Two things are produced:
1. Everything is printed live to the terminal (standard output).
2. The identical screen output — plus every simulated input line — is written to `InCollege-Output.txt` in the same directory.

`InCollege-Accounts.txt` is also written/updated automatically; it's the persistence file and is read back in on the next run so previously created accounts still work.

## Notable design decisions / assumptions (flagged for the team)
- **Password validation** (2120-VALIDATE-PASSWORD): 8–12 chars, and requires at least one uppercase letter, one digit, and one non-alphanumeric character. On failure the student is re-prompted for a new password (they keep their already-accepted username) rather than starting the whole registration over.
- **Account limit**: implemented as "6th account already exists" (`WS-ACCOUNT-COUNT >= 5`) rather than a separate attempts counter, since every valid attempt fills a slot — functionally identical to "the 6th attempt" as worded in the spec, as long as attempts that fail validation don't consume a slot (they don't, in this implementation).
- **"Learn a New Skill" list**: the 5 skills are invented per the assignment's instructions (Excel, Public Speaking, Python Programming, Data Analysis, Networking) — swap in `WS-SKILL-TABLE` if your team wants different ones.
- **Logout on the post-login menu**: the spec explicitly calls for a Logout option on the "top level" (post-login) menu, so a 4th item was added there even though the sample transcript in the spec doesn't show it being exercised.
- **Screen vs. file content**: per the spec's explicit note, prompts/messages are shown on screen and also written to the file, but raw user input is written to the file only (never printed back to the screen), matching the sample transcript, which never echoes what was typed.

## Suggested module breakdown (for Jira tasks)
- `1000` series — startup, shutdown, persistence load/save
- `2000` series — top-level menu, account creation, password/username validation, login
- `3000` series — post-login menu, learn-a-skill submenu
- `9000` series — shared I/O helpers (`9100` dual display+write, `9200` read+echo-to-file)
