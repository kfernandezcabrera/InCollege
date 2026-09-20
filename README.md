# InCollege

A console-style COBOL (GnuCOBOL) application. Input is read from a file, output is printed to the screen, and that same output is written verbatim to an output file.

## Epic 3 — Profile Viewing & Basic Search

What was built this week:

- **Enhanced "View My Profile"** — the profile now opens with `==== Profile for <first name> <last name>` before listing every stored field: name, university, major, graduation year, About Me, and each experience and education entry.
- **"Find someone you know" is functional** — previously an "under construction" message. It prompts for a full name, searches the stored profiles, and displays that person's complete profile on a match.
- **Not-found handling** — an unmatched search prints `No one by that name could be found.`
- **Shared display routine** — `3400-DISPLAY-PROFILE` renders the profile for both "View My Profile" and a successful search, so the two views can never drift apart. Only the banner differs: `--- Your Profile ---` versus `--- Found User Profile ---`.
- **Empty optional sections** — a profile with no experience or education prints `Experience: None` / `Education: None` instead of dropping the heading.

Carried over from earlier epics: account creation, login, and Create/Edit My Profile. "Search for a job" and "Learn a New Skill" are still under construction.

### Where the Epic 3 code lives

| Paragraph | Purpose |
|---|---|
| `3300-VIEW-PROFILE` | Looks up the logged-in user and wraps the display in the `--- Your Profile ---` banner |
| `3400-DISPLAY-PROFILE` | Prints every field of the profile in slot `PROF-IDX` |
| `3500-FIND-SOMEONE` | Prompts for a name, then shows the profile or the not-found message |
| `3510-SEARCH-BY-FULL-NAME` | Assembles `<first> <last>` for each stored profile and compares it to the query |

## Files

- `InCollege.cob` — program source
- `InCollege-Input.txt` — sample input (one simulated user entry per line)
- `InCollege-Output.txt` — output from running the program against that sample input
- `InCollege-Accounts.txt` — account persistence, created and updated automatically
- `InCollege-Profiles.txt` — profile persistence keyed by username, created and updated automatically

## Compile and run

Requires GnuCOBOL (`apt-get install gnucobol4` on Ubuntu/Debian).

```bash
cobc -x -free InCollege.cob -o InCollege
./InCollege
```

`InCollege-Input.txt` must sit beside the executable. Everything printed to the terminal is also written to `InCollege-Output.txt`, along with each simulated input line (inputs go to the file only, never echoed to the screen).

Viewing and searching are read-only — neither rewrites `InCollege-Profiles.txt`.

## Preparing input for the Epic 3 features

Post-login menu: `1` Create/Edit My Profile, `2` View My Profile, `3` Search for a job, `4` Find someone you know, `5` Learn a New Skill, `6` Logout.

- **Option `2`** consumes no further lines; it prints the logged-in user's whole profile.
- **Option `4`** consumes exactly one more line: the full name to search for.

The search is an **exact match** on `<first name> <last name>` as stored, so `Leia Organa` matches while `Leia`, `Organa`, and `leia organa` do not. After either outcome the post-login menu reappears, which is how the user returns to the top level menu.

The committed `InCollege-Input.txt` exercises both paths:

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

Log in as `Anakin`, view own profile, search `Leia Organa` (found), search `John Doe` (not found), log out. The matching run is in `InCollege-Output.txt`.

To search for someone, that person needs a saved profile first — log in as them and use option `1`, which asks for first name, last name, university, major, and graduation year (all required), then About Me (blank line skips), then the experience and education loops (type `DONE` to end each).

## Design notes

- **Search is case-sensitive.** The spec calls for an exact match against stored names, so no case folding is applied. To make `john doe` find `John Doe`, wrap both sides of the comparison in `3510-SEARCH-BY-FULL-NAME` with `FUNCTION UPPER-CASE`.
- **Partial names never match** because the whole assembled `<first> <last>` string has to be identical to the query.
- **Logout** is item 6 on the post-login menu even though the Epic 3 sample transcript doesn't show it, since Epic 1 requires it.
