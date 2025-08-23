# LogonAudit.ps1

_A PowerShell script for auditing user session activity on Windows systems._

**Version:** 1.0  
**Last Updated:** 2025-08-23 22:06 AEST  
**License:** [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)

---

## 📦 Features

- ✅ Tracks interactive, remote, and cached logons  
- ✅ Detects user-initiated and session-ended logoffs  
- ✅ Monitors workstation lock/unlock activity  
- ✅ Logs planned and unexpected shutdowns/restarts  
- ✅ Filters out system and service accounts  
- ✅ Automatically creates a timestamped results file  
- ✅ Ensures output directory exists (`\powershell\data`)  

---

## 📁 Folder Structure

Place the script in:

```
\powershell\src\LogonAudit.ps1
```

The results will be saved to:

```
\powershell\data\LogonEvents_YYYYMMDD_HHMMSS.csv
```

If the `data` folder does not exist, it will be created automatically.

---

## 🛠 Requirements

- Windows PowerShell 5.1 or later  
- **Must be run as Administrator** to access Security and System event logs

---

## 🚀 How to Run

1. **Open PowerShell as Administrator**  
   Right-click the PowerShell icon and select **"Run as administrator"**

2. **Navigate to the script directory**  
   ```powershell
   cd \powershell\src
   ```

3. **Execute the script**  
   ```powershell
   .\LogonAudit.ps1
   ```

4. **Review the output**  
   The results will be saved in the `\powershell\data` folder with a timestamped filename.

---

## 📄 Output Format

Each row in the CSV includes:

| TimeStamp           | User                            | EventID | Type                      |
|---------------------|----------------------------------|---------|---------------------------|
| 2025-08-23 21:32:00 | MicrosoftAccount\vincent@...     | 4624    | Logon                     |
| 2025-08-23 21:45:00 | MicrosoftAccount\vincent@...     | 4800    | Locked                    |
| 2025-08-23 22:01:00 | SYSTEM                           | 1074    | Shutdown/Restart (Planned)|

---

## ⚠ Notes

- The script uses event IDs from both the **Security** and **System** logs.
- It filters out background service accounts to focus on real user activity.
- Each run creates a new file to avoid overwrite or file-lock errors.
- If event log access fails, warnings will be displayed in the console.

---

## 🧠 Author & License

Crafted by **Vincent** — a pragmatic innovator blending technical mastery with elegant, future-proof design.

This project is licensed under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).  
You are free to share, adapt, and build upon this work for any purpose, even commercially — just give appropriate credit.