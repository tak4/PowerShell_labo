Add-Type -AssemblyName System.Windows.Forms

If ([Windows.Forms.Clipboard]::ContainsImage() -eq $True) {
  $Image = [Windows.Forms.Clipboard]::GetImage()
  $FilePath = "D:\Users\takashi\user_folder_stable_diffusion\screen_shots"
  $FileName = (Get-Date -Format "yyyyMMddHHmmss") + ".jpg"
  $ImagePath = Join-Path $FilePath $FileName
  $Image.Save($ImagePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
}
