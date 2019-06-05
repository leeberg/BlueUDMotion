
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



function New-JSONCamera {
    param (
        [Parameter(Mandatory=$true)] $cameraName,
        [Parameter(Mandatory=$true)] $motionIP,
        [Parameter(Mandatory=$true)] $motionPort,
        [Parameter(Mandatory=$true)] $cameraPort
    )
    
    $CameraObject = [PSCustomObject]@{
        cameraName = $cameraName
        motionIP = $motionIP
        motionPort = $motionPort
        cameraPort = $cameraPort
    }
    
    Write-JSONCamera -CameraObject $CameraObject

}




function Get-JSONCameras {

    Try
    {  
        $Cameras = @()
        $Files = Get-ChildItem -Path $Cache:CameraFolder -File
        $Files | ForEach-Object{

            $CameraJSON = Get-Content -Path $_.FullName -Raw
            $CameraObject = $CameraJSON | ConvertFrom-Json
            $Cameras += $CameraObject

        }
        
        Return $Cameras
    }
    Catch
    {
        Return $null
    }

    

}



Function Write-JSONCamera
{
    Param (
    [Parameter(Mandatory=$true)] $CameraObject
    )

    $Path = ($Cache:CameraFolder + '\' + $CameraObject.cameraName + '.json' )

    if(Test-Path($Path))
    {
        # Clear Existings
        Clear-Content $Path -Force
    }
        
    $CameraObject | ConvertTo-Json | Out-File $Path -Append

}
