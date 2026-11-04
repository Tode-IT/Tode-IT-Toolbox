# GPO Drive Mapping & AGDLP Playbook

## 1. AGDLP Group Structure
Utilize the Baseline + Elevated model for department permissions:
*   **Global Groups (Roles):** `G_Finance` (All staff), `G_Finance_Managers` (Senior staff).
*   **Domain Local Groups (Permissions):** `DL_FinanceShare_Read`, `DL_FinanceShare_Modify`.

**Nesting Execution:**
1. Add standard users to `G_Finance` and senior users to `G_Finance_Managers`.
2. Nest `G_Finance` inside `DL_FinanceShare_Read`.
3. Nest `G_Finance_Managers` inside `DL_FinanceShare_Modify`.

## 2. Automated Drive Mapping GPO
Map a single root share for the entire company using Item-Level Targeting to prevent GPO sprawl.
1. Open **Group Policy Management** and link a new GPO (e.g., `GPO_DriveMapping_CorpShares`) to the target Organizational Unit.
2. Edit the GPO: **User Configuration** -> **Preferences** -> **Windows Settings** -> **Drive Maps**.
3. Create a **New Mapped Drive**:
    *   **Action:** Update
    *   **Location:** `\\DC-01\CorpShares`
    *   **Drive Letter:** `S:`
4. On the **Common** tab, check **Item-level targeting** -> **Targeting...**
5. Add the Global Security Groups (e.g., `G_Finance`, `G_IT`, `G_Sales`).
6. **Crucial:** Change the logic operator between the groups from `AND` to `OR`.
7. Run `gpupdate /force` on client endpoints to verify the mapped drive and ABE functionality.
