# BlueUDMotion 

# TODO : Pages and Functions on ONE Page? pssh - sloppy...

# Common Variables

# Your Motion API - TODO: Auth LOL!
$Cache:MotionManagementURL = 'http://192.168.99.168'
# Motion PORT 
$Cache:MotionManagementPort = '8080'
# UD Server should have a share receiving Motion Captures - this will be expoxed by the webserver.
$Cache:PictureSharePath = 'C:\Share\MotionDumpFolder'


Function Get-CameraShareContents
{

	Try{

		$ChildItems = Get-ChildItem -Path $Cache:PictureSharePath
		return $ChildItems

	}
	Catch{
	
		return $null
	
	}
	
}


$HomePage = New-UDPage -Name "Home" -Icon home -Endpoint {

	New-UDRow -Columns {

		New-UDColumn {
			New-UDImage -Id "img_LivePreview" -Url ($Cache:MotionManagementURL + ':8081/') -Height 720 -Width 1280
		}
		
	}

	New-UDRow -Columns {

		New-UDColumn {

			New-UDButton -Id "btn_TakeSnap" -Text "Take Snapshot" -Icon camera -OnClick {
				$REQ = Invoke-WebRequest -Uri ($Cache:MotionManagementURL + ':' + $Cache:MotionManagementPort + '/0/action/snapshot') -UseBasicParsing
				New-UDInputAction -Toast "Taking SnapShot!" -Duration 10
			}
			New-UDButton -Id "btn_MakeMovie" -Text "Take Video" -Icon camera_retro -OnClick {
				$REQ = Invoke-WebRequest -Uri ($Cache:MotionManagementURL + ':' + $Cache:MotionManagementPort + '/0/action/makemovie') -UseBasicParsing
				New-UDInputAction -Toast "Taking Video!" -Duration 10
			}
			New-UDButton -Id "btn_PauseMotionDetection" -Text "Pause Motion Detection" -Icon pause -OnClick {
				$REQ = Invoke-WebRequest -Uri ($Cache:MotionManagementURL + ':' + $Cache:MotionManagementPort + '/0/detection/pause') -UseBasicParsing
				New-UDInputAction -Toast "Stopping Motion Detection!" -Duration 10
			}
			New-UDButton -Id "btn_StartMotionDetection" -Text "Resume Motion Detection" -Icon play -OnClick {
				$REQ = Invoke-WebRequest -Uri ($Cache:MotionManagementURL + ':' + $Cache:MotionManagementPort + '/0/detection/start') -UseBasicParsing
				New-UDInputAction -Toast "Starting Motion Detection!" -Duration 10
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

$Pages = @($HomePage, $FilePage)

$Endpoints = New-UDEndpointInitialization -Function @("Get-CameraShareContents")

$DownloadsFolder = Publish-UDFolder -Path ($Cache:PictureSharePath+'\') -RequestPath '/Downloads'

$Dashboard = New-UDDashboard -Title "BlueUDMotion 🎥 🐈 🐕" -Pages $Pages -EndpointInitialization $Endpoints

Start-UDDashboard -Dashboard $Dashboard -Port 10000 -PublishedFolder $DownloadsFolder🐕