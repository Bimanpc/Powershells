﻿Get-CimInstance -ClassName Win32_Service |
    Select-Object -Property Status,Name,DisplayName