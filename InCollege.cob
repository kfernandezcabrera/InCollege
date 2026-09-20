*>================================================================
      *> InCollege.cob
      *> InCollege Alpha - Epic 1 + Epic 2 + Epic 3:
      *> Login, Profile Management, Profile Viewing & Basic Search
      *>
      *> Modular design:
      *>   1000 series  - startup / shutdown / persistence load-save
      *>   2000 series  - account creation & login
      *>   3000 series  - post-login navigation (menu, skills, profile,
      *>                  profile display, user search)
      *>   9000 series  - shared I/O helpers (screen+file, input+echo)
      *>================================================================
       >>SOURCE FORMAT FREE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INCOLLEGE.
       AUTHOR. InCollege Dev Team.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO "InCollege-Input.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN-STATUS.

           SELECT OUT-FILE ASSIGN TO "InCollege-Output.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT-STATUS.

           SELECT ACCOUNT-FILE ASSIGN TO "InCollege-Accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCT-STATUS.

      *> [EPIC2] New persistence file for profile data
           SELECT PROFILE-FILE ASSIGN TO "InCollege-Profiles.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PROF-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-RECORD                      PIC X(150).

       FD  OUT-FILE.
       01  OUT-RECORD                     PIC X(150).

       FD  ACCOUNT-FILE.
       01  ACCOUNT-RECORD.
           05  AR-USERNAME                PIC X(20).
           05  AR-PASSWORD                PIC X(12).

      *> [EPIC2] Profile record layout written to disk
       FD  PROFILE-FILE.
       01  PROFILE-RECORD.
           05  PR-USERNAME                PIC X(20).
           05  PR-FIRST-NAME              PIC X(30).
           05  PR-LAST-NAME               PIC X(30).
           05  PR-UNIVERSITY              PIC X(50).
           05  PR-MAJOR                   PIC X(50).
           05  PR-GRAD-YEAR               PIC 9(4).
           05  PR-ABOUT-ME                PIC X(200).
           05  PR-EXP-COUNT               PIC 9.
           05  PR-EXP OCCURS 3 TIMES.
               10  PR-EXP-TITLE           PIC X(50).
               10  PR-EXP-COMPANY         PIC X(50).
               10  PR-EXP-DATES           PIC X(30).
               10  PR-EXP-DESC            PIC X(100).
           05  PR-EDU-COUNT               PIC 9.
           05  PR-EDU OCCURS 3 TIMES.
               10  PR-EDU-DEGREE          PIC X(50).
               10  PR-EDU-UNIV            PIC X(50).
               10  PR-EDU-YEARS           PIC X(20).

       WORKING-STORAGE SECTION.

      *> ---------- File status / control flags ----------
       01  WS-IN-STATUS                   PIC XX VALUE SPACES.
       01  WS-OUT-STATUS                  PIC XX VALUE SPACES.
       01  WS-ACCT-STATUS                 PIC XX VALUE SPACES.
       01  WS-PROF-STATUS                 PIC XX VALUE SPACES.   *> [EPIC2]
       01  WS-EOF-FLAG                    PIC X  VALUE 'N'.
           88  END-OF-INPUT               VALUE 'Y'.
       01  WS-LOGOUT-FLAG                 PIC X  VALUE 'N'.
           88  USER-LOGGED-OUT            VALUE 'Y'.
       01  WS-LOGGED-IN-FLAG              PIC X  VALUE 'N'.
           88  IS-LOGGED-IN               VALUE 'Y'.

      *> ---------- Working input / message buffers ----------
       01  WS-RAW-LINE                    PIC X(150).
       01  WS-MESSAGE                     PIC X(150).
       01  WS-CHOICE                      PIC X(20).
       01  WS-USERNAME-INPUT              PIC X(20).
       01  WS-PASSWORD-INPUT              PIC X(12).
       01  WS-CURRENT-USER                PIC X(20).

      *> ---------- Account table (max 5 accounts) ----------
       01  WS-ACCOUNT-COUNT               PIC 9      VALUE 0.
       01  WS-ACCOUNTS-TABLE.
           05  WS-ACCOUNT-ENTRY OCCURS 5 TIMES INDEXED BY ACCT-IDX.
               10  WS-ACC-USERNAME        PIC X(20).
               10  WS-ACC-PASSWORD        PIC X(12).

      *> ---------- Password validation working fields ----------
       01  WS-TRIMMED-PWD                 PIC X(12).
       01  WS-PWD-LEN                     PIC 99     VALUE 0.
       01  WS-UPPER-COUNT                 PIC 99     VALUE 0.
       01  WS-DIGIT-COUNT                 PIC 99     VALUE 0.
       01  WS-SPECIAL-COUNT               PIC 99     VALUE 0.
       01  WS-CHAR                        PIC X.
       01  WS-I                           PIC 99.
       01  WS-J                           PIC 99.                *> [EPIC2]
       01  WS-PASSWORD-OK                 PIC X      VALUE 'N'.
       01  WS-USERNAME-OK                 PIC X      VALUE 'N'.
       01  WS-DUPLICATE-FOUND             PIC X      VALUE 'N'.

      *> ---------- Skills list ----------
       01  WS-SKILL-TABLE.
           05  FILLER                     PIC X(20) VALUE "Excel".
           05  FILLER                     PIC X(20) VALUE "Public Speaking".
           05  FILLER                     PIC X(20) VALUE "Python Programming".
           05  FILLER                     PIC X(20) VALUE "Data Analysis".
           05  FILLER                     PIC X(20) VALUE "Networking".
       01  WS-SKILL-REDEFINED REDEFINES WS-SKILL-TABLE.
           05  WS-SKILL-NAME OCCURS 5 TIMES PIC X(20).
       01  WS-SKILL-MENU-FLAG             PIC X      VALUE 'N'.
           88  SKILL-MENU-DONE            VALUE 'Y'.

      *> ---------- [EPIC2] Profile table (one per account) ----------
       01  WS-PROFILE-TABLE.
           05  WS-PROFILE-ENTRY OCCURS 5 TIMES INDEXED BY PROF-IDX.
               10  WS-PROF-USERNAME       PIC X(20).
               10  WS-PROF-FIRST-NAME     PIC X(30).
               10  WS-PROF-LAST-NAME      PIC X(30).
               10  WS-PROF-UNIVERSITY     PIC X(50).
               10  WS-PROF-MAJOR          PIC X(50).
               10  WS-PROF-GRAD-YEAR      PIC 9(4).
               10  WS-PROF-ABOUT-ME       PIC X(200).
               10  WS-PROF-EXP-COUNT      PIC 9.
               10  WS-PROF-EXP OCCURS 3 TIMES.
                   15  WS-PROF-EXP-TITLE   PIC X(50).
                   15  WS-PROF-EXP-COMPANY PIC X(50).
                   15  WS-PROF-EXP-DATES   PIC X(30).
                   15  WS-PROF-EXP-DESC    PIC X(100).
               10  WS-PROF-EDU-COUNT      PIC 9.
               10  WS-PROF-EDU OCCURS 3 TIMES.
                   15  WS-PROF-EDU-DEGREE  PIC X(50).
                   15  WS-PROF-EDU-UNIV    PIC X(50).
                   15  WS-PROF-EDU-YEARS   PIC X(20).

       01  WS-PROFILE-COUNT               PIC 9      VALUE 0.
       01  WS-PROFILE-SLOT                PIC 9      VALUE 0.
       01  WS-PROFILE-FOUND               PIC X      VALUE 'N'.
           88  PROFILE-EXISTS             VALUE 'Y'.

      *> ---------- [EPIC2] Profile input working fields ----------
       01  WS-IN-FIRST-NAME               PIC X(30).
       01  WS-IN-LAST-NAME                PIC X(30).
       01  WS-IN-UNIVERSITY               PIC X(50).
       01  WS-IN-MAJOR                    PIC X(50).
       01  WS-IN-GRAD-YEAR                PIC X(10).
       01  WS-IN-ABOUT-ME                 PIC X(200).
       01  WS-IN-EXP-TITLE                PIC X(50).
       01  WS-IN-EXP-COMPANY              PIC X(50).
       01  WS-IN-EXP-DATES                PIC X(30).
       01  WS-IN-EXP-DESC                 PIC X(100).
       01  WS-IN-EDU-DEGREE               PIC X(50).
       01  WS-IN-EDU-UNIV                 PIC X(50).
       01  WS-IN-EDU-YEARS                PIC X(20).
       01  WS-GRAD-YEAR-NUM               PIC 9(4).
       01  WS-GRAD-YEAR-OK                PIC X      VALUE 'N'.
           88  GRAD-YEAR-VALID            VALUE 'Y'.
       01  WS-REQUIRED-OK                 PIC X      VALUE 'N'.
           88  REQUIRED-FIELD-OK          VALUE 'Y'.
       01  WS-ADD-MORE-FLAG               PIC X      VALUE 'N'.
           88  ADD-MORE                   VALUE 'Y'.
       01  WS-EXP-IDX                     PIC 9      VALUE 0.
       01  WS-EDU-IDX                     PIC 9      VALUE 0.

      *> ---------- [EPIC3] User search working fields ----------
      *> A full name is "first last": 30 + 1 + 30 characters.
       01  WS-SEARCH-NAME                 PIC X(61)  VALUE SPACES.
       01  WS-CANDIDATE-NAME              PIC X(61)  VALUE SPACES.
       01  WS-SEARCH-SLOT                 PIC 9      VALUE 0.
       01  WS-SEARCH-FLAG                 PIC X      VALUE 'N'.
           88  SEARCH-HIT                 VALUE 'Y'.

       PROCEDURE DIVISION.

       0000-MAIN-LOGIC.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-TOP-LEVEL-MENU
               UNTIL END-OF-INPUT OR USER-LOGGED-OUT
           PERFORM 1900-TERMINATE
           STOP RUN.

      *>----------------------------------------------------------------
      *> 1000 SERIES - STARTUP / SHUTDOWN / PERSISTENCE
      *>----------------------------------------------------------------
       1000-INITIALIZE.
           OPEN INPUT  IN-FILE
           OPEN OUTPUT OUT-FILE
           PERFORM 1100-LOAD-ACCOUNTS
           PERFORM 1300-LOAD-PROFILES                            *> [EPIC2]
           MOVE "Welcome to InCollege!" TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE.

       1100-LOAD-ACCOUNTS.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCT-STATUS = "00"
               PERFORM UNTIL WS-ACCT-STATUS NOT = "00"
                   READ ACCOUNT-FILE
                       AT END
                           CONTINUE
                       NOT AT END
                           SET ACCT-IDX TO WS-ACCOUNT-COUNT
                           ADD 1 TO ACCT-IDX
                           ADD 1 TO WS-ACCOUNT-COUNT
                           MOVE AR-USERNAME TO WS-ACC-USERNAME(ACCT-IDX)
                           MOVE AR-PASSWORD TO WS-ACC-PASSWORD(ACCT-IDX)
                   END-READ
               END-PERFORM
               CLOSE ACCOUNT-FILE
           END-IF.

       1200-SAVE-ACCOUNTS.
           OPEN OUTPUT ACCOUNT-FILE
           PERFORM VARYING ACCT-IDX FROM 1 BY 1
                   UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
               MOVE WS-ACC-USERNAME(ACCT-IDX) TO AR-USERNAME
               MOVE WS-ACC-PASSWORD(ACCT-IDX) TO AR-PASSWORD
               WRITE ACCOUNT-RECORD
           END-PERFORM
           CLOSE ACCOUNT-FILE.

      *> [EPIC2] Load profile records from InCollege-Profiles.txt
       1300-LOAD-PROFILES.
           OPEN INPUT PROFILE-FILE
           IF WS-PROF-STATUS = "00"
               PERFORM UNTIL WS-PROF-STATUS NOT = "00"
                   READ PROFILE-FILE
                       AT END
                           CONTINUE
                       NOT AT END
                           ADD 1 TO WS-PROFILE-COUNT
                           SET PROF-IDX TO WS-PROFILE-COUNT
                           MOVE PR-USERNAME    TO WS-PROF-USERNAME(PROF-IDX)
                           MOVE PR-FIRST-NAME  TO WS-PROF-FIRST-NAME(PROF-IDX)
                           MOVE PR-LAST-NAME   TO WS-PROF-LAST-NAME(PROF-IDX)
                           MOVE PR-UNIVERSITY  TO WS-PROF-UNIVERSITY(PROF-IDX)
                           MOVE PR-MAJOR       TO WS-PROF-MAJOR(PROF-IDX)
                           MOVE PR-GRAD-YEAR   TO WS-PROF-GRAD-YEAR(PROF-IDX)
                           MOVE PR-ABOUT-ME    TO WS-PROF-ABOUT-ME(PROF-IDX)
                           MOVE PR-EXP-COUNT   TO WS-PROF-EXP-COUNT(PROF-IDX)
                           MOVE PR-EDU-COUNT   TO WS-PROF-EDU-COUNT(PROF-IDX)
                           PERFORM VARYING WS-I FROM 1 BY 1
                                   UNTIL WS-I > 3
                               MOVE PR-EXP-TITLE(WS-I)
                                   TO WS-PROF-EXP-TITLE(PROF-IDX, WS-I)
                               MOVE PR-EXP-COMPANY(WS-I)
                                   TO WS-PROF-EXP-COMPANY(PROF-IDX, WS-I)
                               MOVE PR-EXP-DATES(WS-I)
                                   TO WS-PROF-EXP-DATES(PROF-IDX, WS-I)
                               MOVE PR-EXP-DESC(WS-I)
                                   TO WS-PROF-EXP-DESC(PROF-IDX, WS-I)
                               MOVE PR-EDU-DEGREE(WS-I)
                                   TO WS-PROF-EDU-DEGREE(PROF-IDX, WS-I)
                               MOVE PR-EDU-UNIV(WS-I)
                                   TO WS-PROF-EDU-UNIV(PROF-IDX, WS-I)
                               MOVE PR-EDU-YEARS(WS-I)
                                   TO WS-PROF-EDU-YEARS(PROF-IDX, WS-I)
                           END-PERFORM
                   END-READ
               END-PERFORM
               CLOSE PROFILE-FILE
           END-IF.

      *> [EPIC2] Write all profile records back to InCollege-Profiles.txt
       1400-SAVE-PROFILES.
           OPEN OUTPUT PROFILE-FILE
           PERFORM VARYING PROF-IDX FROM 1 BY 1
                   UNTIL PROF-IDX > WS-PROFILE-COUNT
               MOVE WS-PROF-USERNAME(PROF-IDX)   TO PR-USERNAME
               MOVE WS-PROF-FIRST-NAME(PROF-IDX) TO PR-FIRST-NAME
               MOVE WS-PROF-LAST-NAME(PROF-IDX)  TO PR-LAST-NAME
               MOVE WS-PROF-UNIVERSITY(PROF-IDX) TO PR-UNIVERSITY
               MOVE WS-PROF-MAJOR(PROF-IDX)      TO PR-MAJOR
               MOVE WS-PROF-GRAD-YEAR(PROF-IDX)  TO PR-GRAD-YEAR
               MOVE WS-PROF-ABOUT-ME(PROF-IDX)   TO PR-ABOUT-ME
               MOVE WS-PROF-EXP-COUNT(PROF-IDX)  TO PR-EXP-COUNT
               MOVE WS-PROF-EDU-COUNT(PROF-IDX)  TO PR-EDU-COUNT
               PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3
                   MOVE WS-PROF-EXP-TITLE(PROF-IDX, WS-I)
                       TO PR-EXP-TITLE(WS-I)
                   MOVE WS-PROF-EXP-COMPANY(PROF-IDX, WS-I)
                       TO PR-EXP-COMPANY(WS-I)
                   MOVE WS-PROF-EXP-DATES(PROF-IDX, WS-I)
                       TO PR-EXP-DATES(WS-I)
                   MOVE WS-PROF-EXP-DESC(PROF-IDX, WS-I)
                       TO PR-EXP-DESC(WS-I)
                   MOVE WS-PROF-EDU-DEGREE(PROF-IDX, WS-I)
                       TO PR-EDU-DEGREE(WS-I)
                   MOVE WS-PROF-EDU-UNIV(PROF-IDX, WS-I)
                       TO PR-EDU-UNIV(WS-I)
                   MOVE WS-PROF-EDU-YEARS(PROF-IDX, WS-I)
                       TO PR-EDU-YEARS(WS-I)
               END-PERFORM
               WRITE PROFILE-RECORD
           END-PERFORM
           CLOSE PROFILE-FILE.

       1900-TERMINATE.
           CLOSE IN-FILE
           CLOSE OUT-FILE.

      *>----------------------------------------------------------------
      *> 2000 SERIES - TOP LEVEL MENU / ACCOUNT CREATION / LOGIN
      *>----------------------------------------------------------------
       2000-TOP-LEVEL-MENU.
           MOVE "Log In" TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE
           MOVE "Create New Account" TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE
           MOVE "Enter your choice:" TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE
           PERFORM 9200-READ-AND-ECHO
           IF NOT END-OF-INPUT
               EVALUATE FUNCTION TRIM(WS-RAW-LINE)
                   WHEN "1"
                       PERFORM 2300-LOGIN
                   WHEN "2"
                       PERFORM 2100-CREATE-ACCOUNT
                   WHEN OTHER
                       MOVE "Invalid choice, please try again." TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
               END-EVALUATE
               IF IS-LOGGED-IN
                   PERFORM 3000-POST-LOGIN-MENU
                       UNTIL END-OF-INPUT OR USER-LOGGED-OUT
               END-IF
           END-IF.

       2100-CREATE-ACCOUNT.
           IF WS-ACCOUNT-COUNT >= 5
               MOVE "All permitted accounts have been created, please come back later"
                   TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
           ELSE
               MOVE 'N' TO WS-USERNAME-OK
               PERFORM UNTIL WS-USERNAME-OK = 'Y' OR END-OF-INPUT
                   MOVE "Please enter your username:" TO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
                   PERFORM 9200-READ-AND-ECHO
                   IF NOT END-OF-INPUT
                       MOVE FUNCTION TRIM(WS-RAW-LINE) TO WS-USERNAME-INPUT
                       PERFORM 2110-CHECK-USERNAME-UNIQUE
                       IF WS-DUPLICATE-FOUND = 'Y'
                           MOVE "That username is already taken. Please choose another."
                               TO WS-MESSAGE
                           PERFORM 9100-DISPLAY-AND-WRITE
                       ELSE
                           MOVE 'Y' TO WS-USERNAME-OK
                       END-IF
                   END-IF
               END-PERFORM

               IF NOT END-OF-INPUT
                   MOVE 'N' TO WS-PASSWORD-OK
                   PERFORM UNTIL WS-PASSWORD-OK = 'Y' OR END-OF-INPUT
                       MOVE "Please enter your password:" TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                       PERFORM 9200-READ-AND-ECHO
                       IF NOT END-OF-INPUT
                        IF FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-LINE)) > 12
                            MOVE "Password must be 8-12 characters and include at least one capital letter, one digit, and one special character. Please try again."
                                TO WS-MESSAGE
                            PERFORM 9100-DISPLAY-AND-WRITE
                        ELSE
                            MOVE FUNCTION TRIM(WS-RAW-LINE) TO WS-PASSWORD-INPUT
                            PERFORM 2120-VALIDATE-PASSWORD
                            IF WS-PASSWORD-OK = 'N'
                                MOVE "Password must be 8-12 characters and include at least one capital letter, one digit, and one special character. Please try again."
                                    TO WS-MESSAGE
                                PERFORM 9100-DISPLAY-AND-WRITE
                            END-IF
                        END-IF
                    END-IF
                   END-PERFORM

                   IF NOT END-OF-INPUT
                       ADD 1 TO WS-ACCOUNT-COUNT
                       SET ACCT-IDX TO WS-ACCOUNT-COUNT
                       MOVE WS-USERNAME-INPUT TO WS-ACC-USERNAME(ACCT-IDX)
                       MOVE WS-PASSWORD-INPUT TO WS-ACC-PASSWORD(ACCT-IDX)
                       PERFORM 1200-SAVE-ACCOUNTS
                       MOVE "Account created successfully! You can now log in."
                           TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                   END-IF
               END-IF
           END-IF.

       2110-CHECK-USERNAME-UNIQUE.
           MOVE 'N' TO WS-DUPLICATE-FOUND
           PERFORM VARYING ACCT-IDX FROM 1 BY 1
                   UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
               IF WS-ACC-USERNAME(ACCT-IDX) = WS-USERNAME-INPUT
                   MOVE 'Y' TO WS-DUPLICATE-FOUND
               END-IF
           END-PERFORM.

       2120-VALIDATE-PASSWORD.
           MOVE 'N' TO WS-PASSWORD-OK
           MOVE FUNCTION TRIM(WS-PASSWORD-INPUT) TO WS-TRIMMED-PWD
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-PASSWORD-INPUT))
               TO WS-PWD-LEN
           MOVE 0 TO WS-UPPER-COUNT
           MOVE 0 TO WS-DIGIT-COUNT
           MOVE 0 TO WS-SPECIAL-COUNT

           IF WS-PWD-LEN >= 8 AND WS-PWD-LEN <= 12
               PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-PWD-LEN
                   MOVE WS-TRIMMED-PWD(WS-I:1) TO WS-CHAR
                   EVALUATE TRUE
                       WHEN WS-CHAR >= 'A' AND WS-CHAR <= 'Z'
                           ADD 1 TO WS-UPPER-COUNT
                       WHEN WS-CHAR >= 'a' AND WS-CHAR <= 'z'
                           CONTINUE
                       WHEN WS-CHAR >= '0' AND WS-CHAR <= '9'
                           ADD 1 TO WS-DIGIT-COUNT
                       WHEN OTHER
                           ADD 1 TO WS-SPECIAL-COUNT
                   END-EVALUATE
               END-PERFORM

               IF WS-UPPER-COUNT > 0 AND WS-DIGIT-COUNT > 0
                       AND WS-SPECIAL-COUNT > 0
                   MOVE 'Y' TO WS-PASSWORD-OK
               END-IF
           END-IF.

       2300-LOGIN.
           MOVE 'N' TO WS-LOGGED-IN-FLAG
           PERFORM UNTIL IS-LOGGED-IN OR END-OF-INPUT
               MOVE "Please enter your username:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   MOVE FUNCTION TRIM(WS-RAW-LINE) TO WS-USERNAME-INPUT
                   MOVE "Please enter your password:" TO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
                   PERFORM 9200-READ-AND-ECHO
               END-IF
               IF NOT END-OF-INPUT
                   MOVE FUNCTION TRIM(WS-RAW-LINE) TO WS-PASSWORD-INPUT
                   PERFORM 2310-CHECK-CREDENTIALS
                   IF IS-LOGGED-IN
                       MOVE "You have successfully logged in." TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                       MOVE WS-USERNAME-INPUT TO WS-CURRENT-USER
                   ELSE
                       MOVE "Incorrect username/password, please try again"
                           TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                   END-IF
               END-IF
           END-PERFORM.

       2310-CHECK-CREDENTIALS.
           MOVE 'N' TO WS-LOGGED-IN-FLAG
           PERFORM VARYING ACCT-IDX FROM 1 BY 1
                   UNTIL ACCT-IDX > WS-ACCOUNT-COUNT
               IF WS-ACC-USERNAME(ACCT-IDX) = WS-USERNAME-INPUT
                   AND WS-ACC-PASSWORD(ACCT-IDX) = WS-PASSWORD-INPUT
                   MOVE 'Y' TO WS-LOGGED-IN-FLAG
               END-IF
           END-PERFORM.

      *>----------------------------------------------------------------
      *> 3000 SERIES - POST LOGIN NAVIGATION
      *>----------------------------------------------------------------
       3000-POST-LOGIN-MENU.
           IF WS-LOGOUT-FLAG = 'N'
               MOVE SPACES TO WS-MESSAGE
               STRING "Welcome, " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-CURRENT-USER) DELIMITED BY SIZE
                   "!" DELIMITED BY SIZE
                   INTO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
           END-IF

           PERFORM UNTIL USER-LOGGED-OUT OR END-OF-INPUT
      *> [EPIC2] Updated menu with profile options first
               MOVE "1. Create/Edit My Profile" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "2. View My Profile" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "3. Search for a job" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "4. Find someone you know" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "5. Learn a New Skill" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "6. Logout" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "Enter your choice:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   EVALUATE FUNCTION TRIM(WS-RAW-LINE)
                       WHEN "1"
                           PERFORM 3200-CREATE-EDIT-PROFILE   *> [EPIC2]
                       WHEN "2"
                           PERFORM 3300-VIEW-PROFILE          *> [EPIC2]
                       WHEN "3"
                           MOVE "Job search/internship is under construction."
                               TO WS-MESSAGE
                           PERFORM 9100-DISPLAY-AND-WRITE
                       WHEN "4"
                           PERFORM 3500-FIND-SOMEONE          *> [EPIC3]
                       WHEN "5"
                           PERFORM 3100-LEARN-SKILL-MENU
                       WHEN "6"
                           MOVE 'Y' TO WS-LOGOUT-FLAG
                       WHEN OTHER
                           MOVE "Invalid choice, please try again."
                               TO WS-MESSAGE
                           PERFORM 9100-DISPLAY-AND-WRITE
                   END-EVALUATE
               END-IF
           END-PERFORM.

       3100-LEARN-SKILL-MENU.
           MOVE 'N' TO WS-SKILL-MENU-FLAG
           PERFORM UNTIL SKILL-MENU-DONE OR END-OF-INPUT
               MOVE "Learn a New Skill:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
                   MOVE WS-SKILL-NAME(WS-I) TO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
               END-PERFORM
               MOVE "Go Back" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "Enter your choice:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   EVALUATE FUNCTION TRIM(WS-RAW-LINE)
                       WHEN "1" THRU "5"
                           MOVE "This skill is under construction."
                               TO WS-MESSAGE
                           PERFORM 9100-DISPLAY-AND-WRITE
                       WHEN "6"
                           MOVE 'Y' TO WS-SKILL-MENU-FLAG
                       WHEN OTHER
                           MOVE "Invalid choice, please try again."
                               TO WS-MESSAGE
                           PERFORM 9100-DISPLAY-AND-WRITE
                   END-EVALUATE
               END-IF
           END-PERFORM.

      *>----------------------------------------------------------------
      *> [EPIC2] PROFILE MANAGEMENT
      *>----------------------------------------------------------------
      *> Locate the current user's profile slot (if it exists).
       3240-FIND-PROFILE.
           MOVE 'N' TO WS-PROFILE-FOUND
           MOVE 0  TO WS-PROFILE-SLOT
           PERFORM VARYING PROF-IDX FROM 1 BY 1
                   UNTIL PROF-IDX > WS-PROFILE-COUNT
               IF WS-PROF-USERNAME(PROF-IDX) = WS-CURRENT-USER
                   MOVE 'Y' TO WS-PROFILE-FOUND
                   MOVE PROF-IDX TO WS-PROFILE-SLOT
               END-IF
           END-PERFORM.

      *> Validate that a required field is not blank.
       3250-CHECK-REQUIRED.
           IF FUNCTION TRIM(WS-RAW-LINE) = SPACES
               MOVE 'N' TO WS-REQUIRED-OK
           ELSE
               MOVE 'Y' TO WS-REQUIRED-OK
           END-IF.

      *> Validate graduation year: numeric, >2025, <2034.
       3210-VALIDATE-GRAD-YEAR.
           MOVE 'N' TO WS-GRAD-YEAR-OK
           IF FUNCTION TRIM(WS-IN-GRAD-YEAR) IS NUMERIC
               MOVE FUNCTION TRIM(WS-IN-GRAD-YEAR) TO WS-GRAD-YEAR-NUM
               IF WS-GRAD-YEAR-NUM > 2025 AND WS-GRAD-YEAR-NUM < 2034
                   MOVE 'Y' TO WS-GRAD-YEAR-OK
               END-IF
           END-IF.

      *> Prompt and collect up to 3 experience entries.
       3220-ADD-EXPERIENCE.
           MOVE 0 TO WS-EXP-IDX
           MOVE 'Y' TO WS-ADD-MORE-FLAG
           PERFORM UNTIL WS-EXP-IDX >= 3 OR END-OF-INPUT
                   OR NOT ADD-MORE
               MOVE "Add Experience (optional, max 3 entries. Enter 'DONE' to finish):"
                   TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   IF FUNCTION TRIM(WS-RAW-LINE) = "DONE"
                       MOVE 'N' TO WS-ADD-MORE-FLAG
                   ELSE
                       ADD 1 TO WS-EXP-IDX
                       MOVE FUNCTION TRIM(WS-RAW-LINE) TO WS-IN-EXP-TITLE

                       MOVE SPACES TO WS-MESSAGE
                       STRING "Experience #" DELIMITED BY SIZE
                           WS-EXP-IDX DELIMITED BY SIZE
                           " - Company/Organization: " DELIMITED BY SIZE
                           INTO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                       PERFORM 9200-READ-AND-ECHO
                       IF NOT END-OF-INPUT
                           MOVE FUNCTION TRIM(WS-RAW-LINE)
                               TO WS-IN-EXP-COMPANY
                       END-IF

                       MOVE SPACES TO WS-MESSAGE
                       STRING "Experience #" DELIMITED BY SIZE
                           WS-EXP-IDX DELIMITED BY SIZE
                           " - Dates (e.g., Summer 2024): "
                           DELIMITED BY SIZE
                           INTO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                       PERFORM 9200-READ-AND-ECHO
                       IF NOT END-OF-INPUT
                           MOVE FUNCTION TRIM(WS-RAW-LINE)
                               TO WS-IN-EXP-DATES
                       END-IF

                       MOVE SPACES TO WS-MESSAGE
                       STRING "Experience #" DELIMITED BY SIZE
                           WS-EXP-IDX DELIMITED BY SIZE
                           " - Description (optional, max 100 chars, blank to skip): "
                           DELIMITED BY SIZE
                           INTO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                       PERFORM 9200-READ-AND-ECHO
                       IF NOT END-OF-INPUT
                           MOVE FUNCTION TRIM(WS-RAW-LINE)
                               TO WS-IN-EXP-DESC
                       END-IF

                       MOVE WS-IN-EXP-TITLE
                           TO WS-PROF-EXP-TITLE(WS-PROFILE-SLOT, WS-EXP-IDX)
                       MOVE WS-IN-EXP-COMPANY
                           TO WS-PROF-EXP-COMPANY(WS-PROFILE-SLOT, WS-EXP-IDX)
                       MOVE WS-IN-EXP-DATES
                           TO WS-PROF-EXP-DATES(WS-PROFILE-SLOT, WS-EXP-IDX)
                       MOVE WS-IN-EXP-DESC
                           TO WS-PROF-EXP-DESC(WS-PROFILE-SLOT, WS-EXP-IDX)
                   END-IF
               END-IF
           END-PERFORM.

      *> Prompt and collect up to 3 education entries.
       3230-ADD-EDUCATION.
           MOVE 0 TO WS-EDU-IDX
           MOVE 'Y' TO WS-ADD-MORE-FLAG
           PERFORM UNTIL WS-EDU-IDX >= 3 OR END-OF-INPUT
                   OR NOT ADD-MORE
               MOVE "Add Education (optional, max 3 entries. Enter 'DONE' to finish):"
                   TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   IF FUNCTION TRIM(WS-RAW-LINE) = "DONE"
                       MOVE 'N' TO WS-ADD-MORE-FLAG
                   ELSE
                       ADD 1 TO WS-EDU-IDX
                       MOVE FUNCTION TRIM(WS-RAW-LINE)
                           TO WS-IN-EDU-DEGREE

                       MOVE SPACES TO WS-MESSAGE
                       STRING "Education #" DELIMITED BY SIZE
                           WS-EDU-IDX DELIMITED BY SIZE
                           " - University/College: " DELIMITED BY SIZE
                           INTO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                       PERFORM 9200-READ-AND-ECHO
                       IF NOT END-OF-INPUT
                           MOVE FUNCTION TRIM(WS-RAW-LINE)
                               TO WS-IN-EDU-UNIV
                       END-IF

                       MOVE SPACES TO WS-MESSAGE
                       STRING "Education #" DELIMITED BY SIZE
                           WS-EDU-IDX DELIMITED BY SIZE
                           " - Years Attended (e.g., 2023-2025): "
                           DELIMITED BY SIZE
                           INTO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                       PERFORM 9200-READ-AND-ECHO
                       IF NOT END-OF-INPUT
                           MOVE FUNCTION TRIM(WS-RAW-LINE)
                               TO WS-IN-EDU-YEARS
                       END-IF

                       MOVE WS-IN-EDU-DEGREE
                           TO WS-PROF-EDU-DEGREE(WS-PROFILE-SLOT, WS-EDU-IDX)
                       MOVE WS-IN-EDU-UNIV
                           TO WS-PROF-EDU-UNIV(WS-PROFILE-SLOT, WS-EDU-IDX)
                       MOVE WS-IN-EDU-YEARS
                           TO WS-PROF-EDU-YEARS(WS-PROFILE-SLOT, WS-EDU-IDX)
                   END-IF
               END-IF
           END-PERFORM.

      *> [EPIC2] Create or edit the current user's profile.
       3200-CREATE-EDIT-PROFILE.
           MOVE "--- Create/Edit Profile ---" TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE

      *> Determine the target slot BEFORE collecting entries so the
      *> experience/education paragraphs know where to store them.
           PERFORM 3240-FIND-PROFILE
           IF NOT PROFILE-EXISTS
               ADD 1 TO WS-PROFILE-COUNT
               MOVE WS-PROFILE-COUNT TO WS-PROFILE-SLOT
               MOVE WS-CURRENT-USER
                   TO WS-PROF-USERNAME(WS-PROFILE-SLOT)
           END-IF

      *> First name
           MOVE 'N' TO WS-REQUIRED-OK
           PERFORM UNTIL REQUIRED-FIELD-OK OR END-OF-INPUT
               MOVE "Enter First Name:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   PERFORM 3250-CHECK-REQUIRED
                   IF REQUIRED-FIELD-OK
                       MOVE FUNCTION TRIM(WS-RAW-LINE)
                           TO WS-IN-FIRST-NAME
                   ELSE
                       MOVE "First Name is required. Please try again."
                           TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                   END-IF
               END-IF
           END-PERFORM

      *> Last name
           MOVE 'N' TO WS-REQUIRED-OK
           PERFORM UNTIL REQUIRED-FIELD-OK OR END-OF-INPUT
               MOVE "Enter Last Name:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   PERFORM 3250-CHECK-REQUIRED
                   IF REQUIRED-FIELD-OK
                       MOVE FUNCTION TRIM(WS-RAW-LINE)
                           TO WS-IN-LAST-NAME
                   ELSE
                       MOVE "Last Name is required. Please try again."
                           TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                   END-IF
               END-IF
           END-PERFORM

      *> University
           MOVE 'N' TO WS-REQUIRED-OK
           PERFORM UNTIL REQUIRED-FIELD-OK OR END-OF-INPUT
               MOVE "Enter University/College Attended:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   PERFORM 3250-CHECK-REQUIRED
                   IF REQUIRED-FIELD-OK
                       MOVE FUNCTION TRIM(WS-RAW-LINE)
                           TO WS-IN-UNIVERSITY
                   ELSE
                       MOVE "University is required. Please try again."
                           TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                   END-IF
               END-IF
           END-PERFORM

      *> Major
           MOVE 'N' TO WS-REQUIRED-OK
           PERFORM UNTIL REQUIRED-FIELD-OK OR END-OF-INPUT
               MOVE "Enter Major:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   PERFORM 3250-CHECK-REQUIRED
                   IF REQUIRED-FIELD-OK
                       MOVE FUNCTION TRIM(WS-RAW-LINE)
                           TO WS-IN-MAJOR
                   ELSE
                       MOVE "Major is required. Please try again."
                           TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                   END-IF
               END-IF
           END-PERFORM

      *> Graduation year
           MOVE 'N' TO WS-GRAD-YEAR-OK
           PERFORM UNTIL GRAD-YEAR-VALID OR END-OF-INPUT
               MOVE "Enter Graduation Year (YYYY):" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   MOVE FUNCTION TRIM(WS-RAW-LINE)
                       TO WS-IN-GRAD-YEAR
                   PERFORM 3210-VALIDATE-GRAD-YEAR
                   IF NOT GRAD-YEAR-VALID
                       MOVE "Graduation Year must be a 4-digit year greater than 2025 and less than 2034. Please try again."
                           TO WS-MESSAGE
                       PERFORM 9100-DISPLAY-AND-WRITE
                   END-IF
               END-IF
           END-PERFORM

      *> About Me (optional, blank = skip)
           MOVE "Enter About Me (optional, max 200 chars, enter blank line to skip):"
               TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE
           PERFORM 9200-READ-AND-ECHO
           IF NOT END-OF-INPUT
               MOVE FUNCTION TRIM(WS-RAW-LINE) TO WS-IN-ABOUT-ME
           END-IF

      *> Experience (stores directly into WS-PROFILE-SLOT)
           PERFORM 3220-ADD-EXPERIENCE

      *> Education (stores directly into WS-PROFILE-SLOT)
           PERFORM 3230-ADD-EDUCATION

      *> Copy the simple scalar fields into the profile table
           MOVE WS-IN-FIRST-NAME
               TO WS-PROF-FIRST-NAME(WS-PROFILE-SLOT)
           MOVE WS-IN-LAST-NAME
               TO WS-PROF-LAST-NAME(WS-PROFILE-SLOT)
           MOVE WS-IN-UNIVERSITY
               TO WS-PROF-UNIVERSITY(WS-PROFILE-SLOT)
           MOVE WS-IN-MAJOR
               TO WS-PROF-MAJOR(WS-PROFILE-SLOT)
           MOVE WS-GRAD-YEAR-NUM
               TO WS-PROF-GRAD-YEAR(WS-PROFILE-SLOT)
           MOVE WS-IN-ABOUT-ME
               TO WS-PROF-ABOUT-ME(WS-PROFILE-SLOT)
           MOVE WS-EXP-IDX
               TO WS-PROF-EXP-COUNT(WS-PROFILE-SLOT)
           MOVE WS-EDU-IDX
               TO WS-PROF-EDU-COUNT(WS-PROFILE-SLOT)

           PERFORM 1400-SAVE-PROFILES

           MOVE "Profile saved successfully!" TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE.

      *> [EPIC3] Display the logged-in user's own profile.
       3300-VIEW-PROFILE.
           PERFORM 3240-FIND-PROFILE
           IF NOT PROFILE-EXISTS
               MOVE "No profile found. Please create one first."
                   TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
           ELSE
               MOVE "--- Your Profile ---" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE WS-PROFILE-SLOT TO PROF-IDX
               PERFORM 3400-DISPLAY-PROFILE
               MOVE "--------------------" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
           END-IF.

      *> [EPIC3] Render every stored field of the profile sitting in
      *> slot PROF-IDX. Shared by "View My Profile" and by the name
      *> search so both paths produce an identical layout.
       3400-DISPLAY-PROFILE.
           MOVE SPACES TO WS-MESSAGE
           STRING "==== Profile for " DELIMITED BY SIZE
               FUNCTION TRIM(WS-PROF-FIRST-NAME(PROF-IDX))
               DELIMITED BY SIZE
               " " DELIMITED BY SIZE
               FUNCTION TRIM(WS-PROF-LAST-NAME(PROF-IDX))
               DELIMITED BY SIZE
               INTO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE

           MOVE SPACES TO WS-MESSAGE
           STRING "Name: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-PROF-FIRST-NAME(PROF-IDX))
               DELIMITED BY SIZE
               " " DELIMITED BY SIZE
               FUNCTION TRIM(WS-PROF-LAST-NAME(PROF-IDX))
               DELIMITED BY SIZE
               INTO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE

           MOVE SPACES TO WS-MESSAGE
           STRING "University: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-PROF-UNIVERSITY(PROF-IDX))
               DELIMITED BY SIZE
               INTO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE

           MOVE SPACES TO WS-MESSAGE
           STRING "Major: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-PROF-MAJOR(PROF-IDX))
               DELIMITED BY SIZE
               INTO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE

           MOVE SPACES TO WS-MESSAGE
           STRING "Graduation Year: " DELIMITED BY SIZE
               WS-PROF-GRAD-YEAR(PROF-IDX)
               DELIMITED BY SIZE
               INTO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE

           MOVE SPACES TO WS-MESSAGE
           STRING "About Me: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-PROF-ABOUT-ME(PROF-IDX))
               DELIMITED BY SIZE
               INTO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE

           IF WS-PROF-EXP-COUNT(PROF-IDX) > 0
               MOVE "Experience:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-PROF-EXP-COUNT(PROF-IDX)
                   MOVE SPACES TO WS-MESSAGE
                   STRING "  Title: " DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PROF-EXP-TITLE(PROF-IDX, WS-J))
                       DELIMITED BY SIZE
                       INTO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE

                   MOVE SPACES TO WS-MESSAGE
                   STRING "  Company: " DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PROF-EXP-COMPANY(PROF-IDX, WS-J))
                       DELIMITED BY SIZE
                       INTO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE

                   MOVE SPACES TO WS-MESSAGE
                   STRING "  Dates: " DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PROF-EXP-DATES(PROF-IDX, WS-J))
                       DELIMITED BY SIZE
                       INTO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE

                   MOVE SPACES TO WS-MESSAGE
                   STRING "  Description: " DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PROF-EXP-DESC(PROF-IDX, WS-J))
                       DELIMITED BY SIZE
                       INTO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
               END-PERFORM
           ELSE
               MOVE "Experience: None" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
           END-IF

           IF WS-PROF-EDU-COUNT(PROF-IDX) > 0
               MOVE "Education:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-PROF-EDU-COUNT(PROF-IDX)
                   MOVE SPACES TO WS-MESSAGE
                   STRING "  Degree: " DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PROF-EDU-DEGREE(PROF-IDX, WS-J))
                       DELIMITED BY SIZE
                       INTO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE

                   MOVE SPACES TO WS-MESSAGE
                   STRING "  University: " DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PROF-EDU-UNIV(PROF-IDX, WS-J))
                       DELIMITED BY SIZE
                       INTO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE

                   MOVE SPACES TO WS-MESSAGE
                   STRING "  Years: " DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PROF-EDU-YEARS(PROF-IDX, WS-J))
                       DELIMITED BY SIZE
                       INTO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
               END-PERFORM
           ELSE
               MOVE "Education: None" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
           END-IF.

      *> [EPIC3] "Find someone you know": prompt for a full name, show
      *> that person's profile when it matches, otherwise say so. The
      *> post-login menu is redisplayed afterwards either way, which is
      *> how the user returns to the top level menu.
       3500-FIND-SOMEONE.
           MOVE "Enter the full name of the person you are looking for:"
               TO WS-MESSAGE
           PERFORM 9100-DISPLAY-AND-WRITE
           PERFORM 9200-READ-AND-ECHO
           IF NOT END-OF-INPUT
               MOVE FUNCTION TRIM(WS-RAW-LINE) TO WS-SEARCH-NAME
               PERFORM 3510-SEARCH-BY-FULL-NAME
               IF SEARCH-HIT
                   MOVE "--- Found User Profile ---" TO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
                   MOVE WS-SEARCH-SLOT TO PROF-IDX
                   PERFORM 3400-DISPLAY-PROFILE
                   MOVE "-------------------------" TO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
               ELSE
                   MOVE "No one by that name could be found."
                       TO WS-MESSAGE
                   PERFORM 9100-DISPLAY-AND-WRITE
               END-IF
           END-IF.

      *> Exact match of "first last" against every stored profile.
      *> A partial name never matches because the whole assembled
      *> name has to be identical to what was typed.
       3510-SEARCH-BY-FULL-NAME.
           MOVE 'N' TO WS-SEARCH-FLAG
           MOVE 0   TO WS-SEARCH-SLOT
           PERFORM VARYING PROF-IDX FROM 1 BY 1
                   UNTIL PROF-IDX > WS-PROFILE-COUNT OR SEARCH-HIT
               MOVE SPACES TO WS-CANDIDATE-NAME
               STRING FUNCTION TRIM(WS-PROF-FIRST-NAME(PROF-IDX))
                   DELIMITED BY SIZE
                   " " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-PROF-LAST-NAME(PROF-IDX))
                   DELIMITED BY SIZE
                   INTO WS-CANDIDATE-NAME
               IF WS-CANDIDATE-NAME = WS-SEARCH-NAME
                   MOVE 'Y' TO WS-SEARCH-FLAG
                   MOVE PROF-IDX TO WS-SEARCH-SLOT
               END-IF
           END-PERFORM.

      *>----------------------------------------------------------------
      *> 9000 SERIES - SHARED I/O HELPERS
      *>----------------------------------------------------------------
      *> Displays WS-MESSAGE on the screen AND writes the identical
      *> trimmed text to the output file. The stale-padding bug from
      *> Epic #1 is fixed here by trimming before the MOVE.
       9100-DISPLAY-AND-WRITE.
           DISPLAY FUNCTION TRIM(WS-MESSAGE)
           MOVE SPACES TO OUT-RECORD
           MOVE FUNCTION TRIM(WS-MESSAGE) TO OUT-RECORD
           WRITE OUT-RECORD.

      *> Reads the next simulated "user input" line from the input
      *> file. The value is NOT displayed on screen but is written
      *> to the output file for the record.
       9200-READ-AND-ECHO.
           READ IN-FILE INTO WS-RAW-LINE
               AT END
                   MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END
                   MOVE WS-RAW-LINE TO OUT-RECORD
                   WRITE OUT-RECORD
           END-READ.
