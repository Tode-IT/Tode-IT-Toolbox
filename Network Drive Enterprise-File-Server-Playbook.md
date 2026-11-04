# Enterprise File Server Build Playbook

## 1. Storage Provisioning (VHDX)
Never store corporate data on the OS `C:\` drive. 
1. In Hyper-V Manager, attach a new dynamically expanding VHDX to the VM's SCSI Controller.
2. Inside the VM, open **Disk Management** (`diskmgmt.msc`).
3. Initialize the disk as **GPT**.
4. Create a New Simple Volume, format as **NTFS**, and assign a dedicated drive letter (e.g., `E:\ CorpData`).

## 2. Share Creation & Access-Based Enumeration (ABE)
1. On the data drive, create a root folder (e.g., `E:\CorpShares`) and create department subfolders inside it.
2. Open **Server Manager** -> **File and Storage Services** -> **Shares**.
3. Create a **New SMB Share - Quick** pointing to the custom path `E:\CorpShares`.
4. In the settings tab, **Enable access-based enumeration** (ABE) to hide folders from users without permissions. Leave offline caching enabled.

## 3. NTFS Permissions Lockdown
1. In File Explorer, right-click a department subfolder -> **Properties** -> **Security** -> **Advanced**.
2. Click **Disable inheritance** -> **Convert inherited permissions into explicit permissions**.
3. Remove the default **Users** group to block standard access.
4. Add the appropriate Domain Local group (e.g., `DL_FinanceShare_Modify`) and grant **Modify** permissions.
