Test-NetConnection -ComputerName a1098lddashboard.file.core.windows.net -Port 445
# Save the password so the drive will persist on reboot
Invoke-Expression -Command "cmdkey /add:a1098lddashboard.file.core.windows.net /user:Azure\a1098lddashboard /pass:i7tcVzqjGj94DTgHpB4R7VEifdJj4CeFX/pbnR5uPQmIiffFhaPscvklvzIp9tOlCOrmEXgCDo8sliAVrju0TQ=="
# Mount the drive
New-PSDrive -Name Y -PSProvider FileSystem -Root "\\a1098lddashboard.file.core.windows.net\remotefiles"