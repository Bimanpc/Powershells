Option Explicit

Dim targetDirectory
Dim fileExtensionsToDelete

' Set the target directory and file extensions to delete
targetDirectory = "C:\Path\To\Target\Directory"
fileExtensionsToDelete = Array("*.log", "*.tmp")

' Create the file system object
Dim objFSO
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Function to delete files with specified extensions
Sub DeleteFiles(directory, extensions)
    Dim objFolder
    Set objFolder = objFSO.GetFolder(directory)
    
    Dim fileExtension
    For Each fileExtension In extensions
        Dim files
        Set files = objFolder.Files(fileExtension)
        
        Dim file
        For Each file In files
            objFSO.DeleteFile file.Path
            WScript.Echo "Deleted: " & file.Path
        Next
    Next
End Sub

' Call the function to delete files
DeleteFiles targetDirectory, fileExtensionsToDelete

' Clean up the file system object
Set objFSO = Nothing
