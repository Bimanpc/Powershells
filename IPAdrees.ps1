# Show your remote IP address
# wanip.php contains only this code: <?php print $_SERVER['REMOTE_ADDR']; ?>
Write-Host 'My Real IP address is:' ( Invoke-WebRequest -Uri https://www.bing.com).Content