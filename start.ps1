# BlueUDMotion 

# TODO : Pages and Functions on ONE Page? pssh - sloppy...

# Common Variables

# UD Server should have a share receiving Motion Captures - this will be expoxed by the webserver.
$Cache:PictureSharePath = 'C:\Share\MotionDumpFolder'
$Cache:CameraFolder =  'C:\Users\lee\git\DuoUDDemo\BlueUDMotion\Cameras'
$Session:CurrentlySelectedCamera = ''




$HomePage = New-UDPage -Name "Home" -Icon home -Endpoint {

	$Cameras = Get-JSONCameras
	$DefaultCamera = ($Cameras | Select-Object -First 1)
	$Session:CurrentlySelectedCamera = $DefaultCamera
	New-UDRow -Columns {

		New-UDColumn {
			New-UDInput -Title "Select Camera" -Id "Input_HomePage_Camera" -Content {
								
				New-UDInputField -Type 'select' -Name 'CameraName' -Values $Cameras.cameraName -DefaultValue (($Cameras | Select-Object -First 1).Name)

			} -Endpoint {
				$Session:CurrentlySelectedCamera | where {$_.cameraName -eq $cameraName}
				Sync-UDElement -Id "img_LivePreview" -Broadcast
			}
			
		}

		New-UDImage -Id "img_LivePreview" -Url ('http://' + $Session:CurrentlySelectedCamera.motionIP + ':' + $Session:CurrentlySelectedCamera.cameraPort + '/') -Height 720 -Width 1280
	}
		

	New-UDRow -Columns {

		New-UDColumn {

			New-UDButton -Id "btn_TakeSnap" -Text "Take Snapshot" -Icon camera -OnClick {
				$REQ = Invoke-WebRequest -Uri ('http://' + $Session:CurrentlySelectedCamera.motionIP + ':' + $Session:CurrentlySelectedCamera.motionPort + '/0/action/snapshot') -UseBasicParsing
				New-UDInputAction -Toast "Taking SnapShot!" -Duration 10
			}
			New-UDButton -Id "btn_MakeMovie" -Text "Take Video" -Icon camera_retro -OnClick {
				$REQ = Invoke-WebRequest -Uri ('http://' + $Session:CurrentlySelectedCamera.motionIP + ':' + $Session:CurrentlySelectedCamera.motionPort + '/0/action/makemovie') -UseBasicParsing
				New-UDInputAction -Toast "Taking Video!" -Duration 10
			}
			New-UDButton -Id "btn_PauseMotionDetection" -Text "Pause Motion Detection" -Icon pause -OnClick {
				$REQ = Invoke-WebRequest -Uri ('http://' + $Session:CurrentlySelectedCamera.motionIP + ':' + $Session:CurrentlySelectedCamera.motionPort + '/0/detection/pause') -UseBasicParsing
				New-UDInputAction -Toast "Stopping Motion Detection!" -Duration 10
			}
			New-UDButton -Id "btn_StartMotionDetection" -Text "Resume Motion Detection" -Icon play -OnClick {
				$REQ = Invoke-WebRequest -Uri ('http://' + $Session:CurrentlySelectedCamera.motionIP + ':' + $Session:CurrentlySelectedCamera.motionPort + '/0/detection/start') -UseBasicParsing
				New-UDInputAction -Toast "Starting Motion Detection!" -Duration 10
			}
		}

	}
	
}


$CameraSetupPage = New-UDPage -Name "Setup" -Icon camera_retro -Endpoint {

	New-UDRow -Columns {

		New-UDColumn {

			New-UDGrid -Id "grdCameras" -Title "Configured Cameras" -Headers @("Camera Name","Motion IP","Motion Port","Camera Live Port") -Properties @("cameraName", "motionIP", "motionPort","cameraPort") -Endpoint {    

				$Cameras = Get-JSONCameras
				$Cameras | ForEach-Object {

					[PSCustomObject]@{
						cameraName = $_.cameraName
						motionIP = $_.motionIP
						motionPort = $_.motionPort
						cameraPort = $_.cameraPort
					}

				} | Out-UDGridData

			}

		}

	}
	
	New-UDRow -Columns {

		New-UDColumn {

			New-UDInput -Title "Assign New Camera" -SubmitText "Assign" -Content {
				
				New-UDInputField -Name "CameraName" -Placeholder "Name" -Type "textbox" 
				New-UDInputField -Name "MotionIP" -Placeholder "Motion IP" -Type "textbox" 
				New-UDInputField -Name "MotionPort" -Placeholder "Motion Port" -Type "textbox" 
				New-UDInputField -Name "CameraPort" -Placeholder "Camera Live Port" -Type "textbox"

		   } -Endpoint {

				New-JSONCamera -cameraName $CameraName -motionIP $MotionIP -motionPort $MotionPort -cameraPort $CameraPort
				Sync-UDElement -Id 'grdCameras' -Broadcast
				Show-UDToast -Message "Created Camera: $CameraName" -Duration 10000
			
		   }
		}

	}
	
}



$FilePage = New-UDPage -Name "Downloads" -Icon download -Content {
	
	
	New-UdGrid -Id 'grd_Files' -Title "Files" -Headers @("Name","LastWriteTime","Preview","Open") -Properties @("Name","LastWriteTime","Preview","Open") -Endpoint {

		$Files = Get-CameraShareContents

		$Files | Sort-Object -Property LastWriteTime -Descending | ForEach-Object{

			$ImageFile = 'Downloads/' + $_.Name

			[PSCustomObject]@{
				Name = $_.BaseName
				LastWriteTime = $_.LastWriteTime
				Preview = New-UDMuAvatar -Image $ImageFile -Alt 'preview' -Style @{width = 128; height = 72; borderRadius = '1px'}
				Open = New-UDButton -Text "Download" -OnClick (New-UDEndpoint -Endpoint{
						
					$FilePath = $ArgumentList[0]
					$FileName = $ArgumentList[1]

					# Get Image
					Copy-Item -Path $FilePath -Destination $Cache:DownloadsFolder -Force

					#$FullPathWeb = $Cache:DownloadsFolder + '/' + $FileName
					#$#FullPathWeb = $FullPathWeb.Replace('\',"/")

					Invoke-UDRedirect -Url ('Downloads/' + $FileName) -OpenInNewWindow
	
				} -ArgumentList $_.FullName, $_.Name)
			}
		
		} | Out-UDGridData
	}
	
}

Get-UDDashboard | Stop-UDDashboard

$Pages = @($HomePage, $CameraSetupPage, $FilePage)

$Endpoints = New-UDEndpointInitialization -Module @("Modules\BlueMotionFunctions.ps1") 

$DownloadsFolder = Publish-UDFolder -Path ($Cache:PictureSharePath+'\') -RequestPath '/Downloads'

$Dashboard = New-UDDashboard -Title "BlueUDMotion 🎥 🐈 🐕" -Pages $Pages -EndpointInitialization $Endpoints

Start-UDDashboard -Dashboard $Dashboard -Port 10000 -PublishedFolder $DownloadsFolder