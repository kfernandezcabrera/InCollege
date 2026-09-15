      *>================================================================
      *> InCollege.cob
      *> InCollege Alpha - Epic 1: Log In, Part 1
      *>
      *> Modular design:
      *>   1000 series  - startup / shutdown / persistence load-save
      *>   2000 series  - account creation & login
      *>   3000 series  - post-login navigation
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

       WORKING-STORAGE SECTION.

      *> ---------- File status / control flags ----------
       01  WS-IN-STATUS                   PIC XX VALUE SPACES.
       01  WS-OUT-STATUS                  PIC XX VALUE SPACES.
       01  WS-ACCT-STATUS                 PIC XX VALUE SPACES.
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
*>                      Check length of the raw input before truncation
                        IF FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-LINE)) > 12
                            MOVE "Password must be 8-12 characters and include at least one capital letter, one digit, and one special character. Please try again."
                                TO WS-MESSAGE
                            PERFORM 9100-DISPLAY-AND-WRITE
                        ELSE
*>                          Safe to move and perform character validation
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
               MOVE "1. Search for a job" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "2. Find someone you know" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "3. Learn a new skill" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "4. Logout" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               MOVE "Enter your choice:" TO WS-MESSAGE
               PERFORM 9100-DISPLAY-AND-WRITE
               PERFORM 9200-READ-AND-ECHO
               IF NOT END-OF-INPUT
                   EVALUATE FUNCTION TRIM(WS-RAW-LINE)
                       WHEN "1"
                           MOVE "Job search/internship is under construction."
                               TO WS-MESSAGE
                           PERFORM 9100-DISPLAY-AND-WRITE
                       WHEN "2"
                           MOVE "Find someone you know is under construction."
                               TO WS-MESSAGE
                           PERFORM 9100-DISPLAY-AND-WRITE
                       WHEN "3"
                           PERFORM 3100-LEARN-SKILL-MENU
                       WHEN "4"
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
      *> 9000 SERIES - SHARED I/O HELPERS
      *>----------------------------------------------------------------
      *> Displays WS-MESSAGE on the screen AND writes the identical
      *> text to the output file (satisfies dual-output requirement).
       9100-DISPLAY-AND-WRITE.
           DISPLAY FUNCTION TRIM(WS-MESSAGE)
           MOVE WS-MESSAGE TO OUT-RECORD
           WRITE OUT-RECORD.

      *> Reads the next simulated "user input" line from the input
      *> file. The value is NOT displayed on screen (the sample
      *> output never echoes what the user typed) but per the spec
      *> it MUST still be written to the output file for the record.
       9200-READ-AND-ECHO.
           READ IN-FILE INTO WS-RAW-LINE
               AT END
                   MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END
                   MOVE WS-RAW-LINE TO OUT-RECORD
                   WRITE OUT-RECORD
           END-READ.
