Option Explicit

Dim WshShell
Set WshShell = CreateObject("WScript.Shell")

' Εκκίνηση Windows Speech Recognition
WshShell.Run "control.exe /name Microsoft.SpeechRecognition", 1, False

MsgBox "Η Αναγνώριση Ομιλίας άνοιξε." & vbCrLf & _
       "Μίλησε στο μικρόφωνο και χρησιμοποίησε Υπαγόρευση.", _
       vbInformation, "Voice To Text"

Set WshShell = Nothing
