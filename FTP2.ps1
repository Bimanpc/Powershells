if ($PSEdition -eq 'Core') {
    Add-Type -Path $PSScriptRoot\Lib\Standard\FluentFTP.dll
    Add-Type -Path $PSScriptRoot\Lib\Standard\Renci.SshNet.dll
    Add-Type -Path $PSScriptRoot\Lib\Standard\SshNet.Security.Cryptography.dll
} else {
    Add-Type -Path $PSScriptRoot\Lib\Standard\FluentFTP.dll
    Add-Type -Path $PSScriptRoot\Lib\Standard\Renci.SshNet.dll
    Add-Type -Path $PSScriptRoot\Lib\Standard\SshNet.Security.Cryptography.dll
}
# SIG # Begin signature block
# RBXizyDwO/qnWC4pjEwpzW4KDhxxuHUn6g+lUiea0rxrLte1u6aVw3yZ320e75Xt
# PsO6WxMcAnGeKlb8B7itY0/UYCKdF7xnT8zWZkaE8YG7JiwZToJA3Uj2yDMELaTY
# qEvorNX2gU9+TJHdYbnn7TPK557SRVZ2fggGd27hFg+LFhhTP0t7SrlD302A9SeW
# Van6KG7DrPSqQDwPPLK1M/J42R7HMvkxVqNAVY06S7MAc2DamZZSCXJCL2uB3Pza
# m+XiveR0gGyJTtG27BFOhQsvUD9V4E4dZyv1eSEX3olGCvbmq5g3A6StFCvhnBfy
# XnQ6yYAEfBgMZZNc8vtdwcpwwRFsD/uB6PXe2c4/4TXP5f26bww1aiNbN1gtSuyr
# ZA2YZNfTQ6OAV/UG6cx29h2aMl+Val3fSvKhehuKX5osrsA409NVQUqiV+T0a7fv
# p2N1MYD/CcyYrKKIVLErZJDM18MQjLd6YsTX30fMge8ixgE6WPVfYm4fqIlPXkQM
# W0I=
# SIG # End signature block