#Version 0.3.2
#Set empty variable
set-variable -name info -value "empty"

#Is iTunes Running
if(get-process | ?{$_.path -eq "C:\Program Files (x86)\iTunes\iTunes.exe"})

 {
    #Create iTunes Object
    $itunes = New-Object -ComObject iTunes.Application

    #Is iTunes playing 0-> Ready; 1-> Playing
    set-variable -name playing -value ($iTunes.PlayerState)

    If($playing -eq 1)
     {
        #Set variables for items we want
        set-variable -name album -value ($itunes.CurrentTrack.Album)
        set-variable -name rating -value ($itunes.CurrentTrack.Rating)
        set-variable -name track -value ($itunes.CurrentTrack.Name)
        set-variable -name artist -value ($itunes.CurrentTrack.Artist)

        #Output data
        $album
        $rating
        $track
        $artist
        "$($album)\n$($artist)\n$($rating)\n$($track)" | out-file -filepath "C:\Users\majorsl\Desktop\tunes.txt"
        New-SSHSession teletraan1 -Credential (Get-Credential majorsl)
        Invoke-SSHCommand -Index 0 -Command 
        Remove-SSHSession
    }
 }