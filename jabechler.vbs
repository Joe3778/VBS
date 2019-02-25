Option Explicit
' =======================================================================
'	
'	Title:					Joe.Bechler Personal Network Login Script
'	Programmed By:			Joe Bechler
'	Originally created:  	01/14/2019
'	Description:			User Login script to map specific 
'                       	network drives or run applications.
'region Changelog
'endregion

' =======================================================================

' Declare Variables
Dim AdInfo, objUser, objFSO, objNetwork, WShell, UserEnvironmentVariable, SysEnvironmentVariable, objPrinterFile
Dim UserSite, SitePrefix, SiteServer, UserEmploymentLocation, UserName, UserADPath, DeptFolder, UserGroups
Dim strHdrive

' Active Directory Variables
Set AdInfo = CreateObject("AdSystemInfo")
Set objUser = GetObject("LDAP://" & Adinfo.UserName)

' Create Program objects
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objNetwork = CreateObject("WScript.Network")
Set WShell = WScript.CreateObject("WScript.Shell")
Set UserEnvironmentVariable = WShell.Environment("USER")

Sub ErrorMsg( strMsg )
' Displays a Warning message box to the user if
' a drive mapping fails.
	
   MsgBox strMsg, 4144, "Drive Mapping Error" 

End Sub

Function MapDrive( strDrive, strShare )
 ' Function to map network share to a drive letter.
 ' If the drive letter specified is already in use, the function
 ' attempts to remove the network connection.
 ' objFSO is the File System Object, with global scope.
 ' objNetwork is the Network object, with global scope.
 ' Returns True if drive mapped, False otherwise.
 
   Dim objDrive
 
   On Error Resume Next
	
   If objFSO.DriveExists(strDrive) Then
      Set objDrive = objFSO.GetDrive(strDrive)
      If Err.Number <> 0 Then
         On Error GoTo 0
         MapDrive = False
         Exit Function
      End If
      If CBool(objDrive.DriveType = 3) Then
         objNetwork.RemoveNetworkDrive strDrive, True, True
      Else
         MapDrive = False
         Exit Function
      End If
      Set objDrive = Nothing
   End If
	
   objNetwork.MapNetworkDrive strDrive, strShare
   If Err.Number = 0 Then
      MapDrive = True
   Else
      Err.Clear
      MapDrive = False
   End If
   On Error GoTo 0
End Function

Function CreateMemberOfObject( strDomain, strUserName )
' Given a domain name and username, returns a Dictionary
' object of groups to which the user is a member of.

   Dim objUser, objGroup

   Set CreateMemberOfObject = CreateObject("Scripting.Dictionary")
   CreateMemberOfObject.CompareMode = vbTextCompare
   Set objUser = GetObject("WinNT://" & strDomain & "/" & strUserName & ",user")

   For Each objGroup In objUser.Groups

      CreateMemberOfObject.Add objGroup.Name, "-"

   Next

   Set objUser = Nothing

End Function

Function MemberOf( strGroupName )

' Check if the user is a member of the given group name

    MemberOf = CBool( UserGroups.Exists( strGroupName ))

End Function


''''''''''''''' Initialize Variables '''''''''''''''

' Determine user's site
UserSite = AdInfo.SiteName

' Fully Qualified Distinguished Name
UserADPath = objUser.AdsPath

' Login User Name
UserName = objNetwork.UserName

' Get all of the user's Group Memberships (determines department folder and groups)
Set UserGroups = CreateMemberOfObject("tmg.net", UserName)

''''''''''''''' Map User's Specific Drives '''''''''''''''

strHdrive = "\\scpfs1\fs1users\joe.bechler"

' P Drive
   If Not MapDrive( "H:", strHdrive ) Then
	   ErrorMsg( "Failed to map P: to " & strHdrive &"." )
   End If

'If MemberOf( "Windows 7 Restricted" ) Then
'   If Not MapDrive( "Z:", "\\artemis\Vault\Citrix Profiles" ) Then
'      ErrorMsg( "Failed to map Z: to \\artemis\Vault\Citrix Profiles" )
'   End If
'End If

' Run Specific User Program
'If objFSO.FileExists("C:\APPS\program.exe") Then
'	   Wshell.Exec("C:\APPS\program.exe")
'	Else
'	   MsgBox "The program is not installed on your computer.  Please contact the Help Desk.", 4144, "Program Not Installed"
'End If
