# Capture the Connect IQ simulator window to a PNG (works even when the window is covered).
#   .\tools\capture.ps1 -Out shot.png
param([string]$Out = "sim.png")
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W32 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
}
"@
[W32]::SetProcessDPIAware() | Out-Null
$p = Get-Process simulator -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ([W32]::IsIconic($p.MainWindowHandle)) { [W32]::ShowWindow($p.MainWindowHandle, 4) | Out-Null; Start-Sleep -Milliseconds 800 }   # SW_SHOWNOACTIVATE
$r = New-Object W32+RECT
[W32]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
$bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[W32]::PrintWindow($p.MainWindowHandle, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out),[System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
