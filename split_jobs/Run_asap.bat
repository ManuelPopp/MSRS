:start
TIMEOUT /T 1800
if exist "G:\Projekt\out\mod\mod0.4.Rdata" (
"C:\Program Files\R\R-4.0.2\bin\Rscript.exe" "D:\Dateien\Studium_KIT\Master_GOEK\10_FS_Geooekologie\Multi-skalige_Fernerkundungsverfahren\Projekt\rsc\split_jobs\Parallel_job4.R" 1 1
) else (
echo "Previous script not yet finished."
goto :start
)
pause