class DirectSoundPlayer {
; A class to play PCM audio WAV files
; and manage DirectSound buffers
; partially written using Claude Sonnet 4.5
; by Marius Șucan: https://marius.sucan.ro/
; https://github.com/marius-sucan/
; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=139385
;
; USAGE: 
; DirectSoundPlayer.Create() 
; - creates DirectSound buffers ready to play.
; - pass allowDupe=1 to be able to play the same file simultaneously
; - you can pass bufferData and BufferSize instead of filePath
; - it returns and index number on success, 0 on failure
;
; DirectSoundPlayer.RemoveByIndex() to discard a DirectSound buffer 
;
; DirectSoundPlayer.PlayFile() 
; - it creates a DirectSound buffer or reuses an exiting buffer and plays the WAV file
; - pass allowDupe=1 to be able to play the same file simultaneously
; - it returns and index number on success, 0 on failure

; DirectSoundPlayer.DiscardAllFiles()
; - discards all DirectSound buffers

    ; Static arrays to store buffer data (no objects)
    static FilePaths := []
    static pDSBuffers := []
    static DataSizes := []
    static ByteRates := []
    static AllowedDupes := []
    static Count := 0
    static hasInit := 0
    static hDsound
    static pDS
    static LastError
    
    ; Create and store a sound buffer
    Create(filePath, allowDupe:=0, ByRef bufferData:="", BufferSize:=0) {
        ; Check if buffer already exists for this file
        foundIndex := this.FindByPath(filePath)
        if (foundIndex>0)
        {
           ; fnOutputDebug("Buffer already exists at index: " foundIndex)
           if (allowDupe=0)
              return foundIndex
           else
              return this.Duplicate(foundIndex)
        }

        if !this.hasInit
        {
            ; Load required DLLs
            this.hDsound := DllCall("LoadLibrary", "Str", "dsound.dll", "Ptr")
            if (!this.hDsound)
            {
                this.LastError := "LoadLibrary dsound.dll: failed."
                fnOutputDebug(this.lastError)
                return 0
            }

            ; Create DirectSound object
            VarSetCapacity(GUID_IID_IDirectSound, 16)
            DllCall("ole32\CLSIDFromString", "Str", "{279AFA83-4981-11CE-A521-0020AF0BE560}", "Ptr", &GUID_IID_IDirectSound)
            
            pDS := 0
            hr := DllCall("dsound\DirectSoundCreate", "Ptr", 0, "Ptr*", pDS, "Ptr", 0)
            if (hr!=0 || !pDS)
            {
                this.LastError := "DirectSoundCreate failed -- HRESULT: 0x" Format("{:X}", hr) " pDS: " pDS
                fnOutputDebug(this.lastError)
                DllCall("FreeLibrary", "Ptr", this.hDsound)
                return 0
            }
            this.pDS := pDS
            
            ; Set cooperative level
            SetCooperativeLevelMethod := NumGet(NumGet(this.pDS + 0), 6*A_PtrSize)
            hr := DllCall(SetCooperativeLevelMethod, "Ptr", this.pDS, "Ptr", A_ScriptHwnd, "Int", 2)
            ; fnOutputDebug(this.pDS " SetCooperativeLevel HRESULT: 0x" . Format("{:X}", hr))
            this.hasInit := 1
        }

        If (BufferSize>256)
        {
            bytesRead := totalSize := BufferSize
            fileData := bufferData
            ; fnOutputDebug(A_ThisFunc ": buffered cached=" totalSize " | " filePath)
        } else
        {
            ; Read the provided WAV file
            file := FileOpen(filePath, "r")
            if !file
            {
               this.LastError := "File open failed: " filePath
               fnOutputDebug(this.lastError)
               return 0
            }

            totalSize := file.Length
            VarSetCapacity(fileData, totalSize)
            bytesRead := file.RawRead(fileData, totalSize)
            file.Close()
            ; fnOutputDebug(A_ThisFunc ": file read =" totalSize " | " filePath)
        }

        ; verify RIFF header
        if (StrGet(&fileData, 4, "CP0") != "RIFF") {
             this.LastError := "Failed open to file - not a RIFF file: " filePath
             fnOutputDebug(this.LastError)
             return 0
        }

        if (totalSize<256)
        {
           fileData := ""
           this.LastError := "File malformed or read error: " filePath
           fnOutputDebug(this.lastError)
           return 0
        }

        offset := 12 ; Skip RIFF (4) + Size (4) + WAVE (4)
        foundFmt := 0
        foundData := 0
        pDataPtr := 0 ; Pointer to the actual audio data

        ; Iterate through chunks to find 'fmt ' and 'data'
        while (offset < totalSize - 8) 
        {
            chunkID := StrGet(&fileData + offset, 4, "CP0")
            chunkSize := NumGet(fileData, offset + 4, "UInt")
            if (chunkID="fmt ")
            {
                ; Read standard PCM format fields
                channels := NumGet(fileData, offset + 8 + 2, "UShort")
                sampleRate := NumGet(fileData, offset + 8 + 4, "UInt")
                bitsPerSample := NumGet(fileData, offset + 8 + 14, "UShort")
                
                ; Validations
                if (channels = 0 || channels > 16 || sampleRate < 100 || bitsPerSample = 0)
                {
                     this.LastError := "Invalid format detected: " filePath
                     fnOutputDebug(this.LastError)
                     return 0
                }

                ; Recalculate these strictly to ensure DirectSound stability
                ; (Trusting the file header for these can cause issues with 22khz mono)
                blockAlign := (channels * bitsPerSample) // 8
                byteRate := sampleRate * blockAlign
                foundFmt := 1
            } else if (chunkID="data")
            {
                dataSize := chunkSize
                pDataPtr := &fileData + offset + 8
                foundData := 1
                break ; We found the data, we can stop scanning
            }

            ; Move to next chunk (aligned to 2 bytes, though usually chunks are even)
            offset += 8 + chunkSize
            if (offset & 1) 
                offset += 1
        }

        if (!foundFmt || !foundData || !pDataPtr)
        {
           fileData := ""
           this.LastError := "WAV Parse Error (missing format or data chunk): " filePath
           fnOutputDebug(this.lastError)
           return 0
        }

        ; fnOutputDebug("=== WAV Info ===")
        ; fnOutputDebug("Channels: " . channels)
        ; fnOutputDebug("Sample Rate: " . sampleRate)
        ; fnOutputDebug("Bits: " . bitsPerSample)
        ; fnOutputDebug("Data Size: " . dataSize)

        ; Setup WAVEFORMATEX structure
        VarSetCapacity(wfx, 18, 0)
        NumPut(1, wfx, 0, "UShort")              ; wFormatTag (WAVE_FORMAT_PCM)
        NumPut(channels, wfx, 2, "UShort")       ; nChannels
        NumPut(sampleRate, wfx, 4, "UInt")       ; nSamplesPerSec
        NumPut(byteRate, wfx, 8, "UInt")         ; nAvgBytesPerSec (Calculated)
        NumPut(blockAlign, wfx, 12, "UShort")    ; nBlockAlign (Calculated)
        NumPut(bitsPerSample, wfx, 14, "UShort") ; wBitsPerSample
        NumPut(0, wfx, 16, "UShort")             ; cbSize

        ; Setup DSBUFFERDESC structure
        VarSetCapacity(dsbd, 16 + A_PtrSize, 0)
        NumPut(16 + A_PtrSize, dsbd, 0, "UInt")  ; dwSize
        NumPut(0x000080C0, dsbd, 4, "UInt")      ; dwFlags: DSBCAPS_GLOBALFOCUS | DSBCAPS_CTRLVOLUME | DSBCAPS_CTRLPAN
        NumPut(dataSize, dsbd, 8, "UInt")        ; dwBufferBytes
        NumPut(0, dsbd, 12, "UInt")              ; dwReserved
        NumPut(&wfx, dsbd, 16, "Ptr")            ; lpwfxFormat

        ; Create sound buffer
        pDSBuffer := 0
        hr := DllCall(NumGet(NumGet(this.pDS+0), 3*A_PtrSize), "Ptr", this.pDS, "Ptr", &dsbd, "Ptr*", pDSBuffer, "Ptr", 0)
        if (hr!=0 || !pDSBuffer)
        {
            this.LastError := "DirectSound CreateSoundBuffer failed -- HRESULT: 0x" Format("{:X}", hr) " pDSBuffer: " pDSBuffer
            fnOutputDebug(this.LastError)
            return 0
        }

        ; Lock buffer
        pAudioPtr1 := 0
        audioBytes1 := 0
        lockMethod := NumGet(NumGet(pDSBuffer + 0), 11*A_PtrSize, "Ptr")
        hr := DllCall(lockMethod, "Ptr", pDSBuffer, "UInt", 0, "UInt", 0, "Ptr*", pAudioPtr1, "UInt*", audioBytes1, "Ptr*", 0, "UInt*", 0, "UInt", 2, "Int")
        if (hr=0 && pAudioPtr1)
        {
            ; Copy audio data using the dynamic pointer
            DllCall("RtlMoveMemory", "Ptr", pAudioPtr1, "Ptr", pDataPtr, "UInt", audioBytes1)
            unlockMethod := NumGet(NumGet(pDSBuffer + 0), 19*A_PtrSize, "Ptr")
            hr := DllCall(unlockMethod, "Ptr", pDSBuffer, "Ptr", pAudioPtr1, "UInt", audioBytes1, "Ptr", 0, "UInt", 0, "Int")
            if (hr!=0)
            {
               ; release buffer on error
               this.LastError := "DirectSound Unlock failed -- HRESULT: 0x" Format("{:X}", hr)
               fnOutputDebug(this.LastError)
               DllCall(NumGet(NumGet(pDSBuffer+0), 2*A_PtrSize), "Ptr", pDSBuffer)
               return 0
            }
        } else
        {
            ; release buffer on error
            this.LastError := "DirectSound Lock failed"
            fnOutputDebug(this.LastError)
            DllCall(NumGet(NumGet(pDSBuffer+0), 2*A_PtrSize), "Ptr", pDSBuffer)
            return 0
        }

        ; Store buffer information
        this.Count++
        this.FilePaths.Push(filePath)
        this.pDSBuffers.Push(pDSBuffer)
        this.DataSizes.Push(dataSize)
        this.ByteRates.Push(byteRate)
        this.AllowedDupes.Push(allowDupe)
        wfx := ""
        dsbd := ""
        return this.Count
    }

    Duplicate(index) {
        filePath := this.FilePaths[index]
        pDSBuffer := this.pDSBuffers[index]
        dataSize := this.DataSizes[index]
        byteRate := this.ByteRates[index]
        allowDupe := this.AllowedDupes[index]

        pDSBufferDuplicate := 0
        hr := DllCall(NumGet(NumGet(this.pDS+0), 5*A_PtrSize), "Ptr", this.pDS, "Ptr", pDSBuffer, "Ptr*", pDSBufferDuplicate)
        if (hr!=0)
        {
           this.LastError := "DirectSound Duplicate buffer failed -- HRESULT: 0x" Format("{:X}", hr)
           fnOutputDebug(this.LastError)
           return 0
        }

        this.Count++
        this.FilePaths.Push(filePath)
        this.pDSBuffers.Push(pDSBufferDuplicate)
        this.DataSizes.Push(dataSize)
        this.ByteRates.Push(byteRate)
        this.AllowedDupes.Push(allowDupe)
        return this.Count
    }

    ; Find buffer index by file path
    FindByPath(filePath) {
        Loop, % this.FilePaths.Length()
        {
            if (this.FilePaths[A_Index] = filePath)
               return A_Index
        }
        return 0
    }
    
    ; Play a buffer by index
    Play(index, looped:=0) {
        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return 0
        }
        
        pDSBuffer := this.pDSBuffers[index]
        if (!pDSBuffer) {
           this.LastError := "Buffer at index " index " is null"
           fnOutputDebug(this.LastError)
           return 0
        }
        
        ; Reset buffer position to start using SetCurrentPosition
        this.SetCurrentPosition(0)
        playMethod := NumGet(NumGet(pDSBuffer + 0), 12*A_PtrSize, "Ptr")
        hr := DllCall(playMethod, "Ptr", pDSBuffer, "UInt", 0, "UInt", 0, "UInt", looped, "Int")
        if (hr!=0)
        {
           this.LastError := "DirectSound Play buffer at index " index " failed: HRESULT: 0x" Format("{:X}", hr) " | " this.FilePaths[index]
           fnOutputDebug(this.LastError)
        }
        return (hr=0) ? index : 0
    }

    SetCurrentPosition(index, newPos) {
        ; The SetCurrentPosition method sets the position of the play cursor in bytes,
        ; which is the point at which the next byte of data is read from the buffer.

        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return 0
        }

        pDSBuffer := this.pDSBuffers[index]
        if (!pDSBuffer) {
           this.LastError := "Buffer at index " index " is null"
           fnOutputDebug(this.LastError)
           return 0
        }

        SetCurrentPosition := NumGet(NumGet(pDSBuffer + 0), 13*A_PtrSize, "Ptr")
        hr := DllCall(SetCurrentPosition, "Ptr", pDSBuffer, "UInt", newPos, "Int")
        if (hr!=0)
        {
           this.LastError := "DirectSound SetCurrentPosition for buffer at index " index " failed: HRESULT: 0x" Format("{:X}", hr) " | " this.FilePaths[index]
           fnOutputDebug(this.LastError)
           return 0
        }
        return 1
    }

    SetVolume(index, newVolume) {
        ; newVolume is the attenuation level in hundredths of a decibel (dB).
        ; newVolume from 0 to -10000.
        ; DSBVOLUME_MAX (0): No attenuation, full volume
        ; DSBVOLUME_MIN (-10,000): Maximum attenuation, silence

        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return 0
        }
        
        pDSBuffer := this.pDSBuffers[index]
        if (!pDSBuffer) {
           this.LastError := "Buffer at index " index " is null"
           fnOutputDebug(this.LastError)
           return 0
        }
        If (newVolume>0)
           newVolume := -newVolume

        SetVolume := NumGet(NumGet(pDSBuffer + 0), 15*A_PtrSize, "Ptr")
        hr := DllCall(SetVolume, "Ptr", pDSBuffer, "UInt", newVolume, "Int")
        if (hr!=0)
        {
           this.LastError := "DirectSound SetVolume for buffer at index " index " failed: HRESULT: 0x" Format("{:X}", hr) " | " this.FilePaths[index]
           fnOutputDebug(this.LastError)
           return 0
        }
        return 1
    }

    SetPan(index, newPan) {
        ; Sets the relative volume between the left and right channels.
        ; newPan ranges from -10000 to 10000
        ; DSBPAN_LEFT (-10,000): Right channel is silent, sound fully to the left
        ; DSBPAN_CENTER (0): Both channels at full volume (neutral/center position)
        ; DSBPAN_RIGHT (10,000): Left channel is silent, sound fully to the right
        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return 0
        }
        
        pDSBuffer := this.pDSBuffers[index]
        if (!pDSBuffer) {
           this.LastError := "Buffer at index " index " is null"
           fnOutputDebug(this.LastError)
           return 0
        }

        SetPan := NumGet(NumGet(pDSBuffer + 0), 16*A_PtrSize, "Ptr")
        hr := DllCall(SetPan, "Ptr", pDSBuffer, "UInt", newPan, "Int")
        if (hr!=0)
        {
           this.LastError := "DirectSound SetPan for buffer at index " index " failed: HRESULT: 0x" Format("{:X}", hr) " | " this.FilePaths[index]
           fnOutputDebug(this.LastError)
           return 0
        }
        return 1
    }

    ; Stop a buffer by index
    Stop(index) {
        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return 0
        }
        
        pDSBuffer := this.pDSBuffers[index]
        if (!pDSBuffer) {
           this.LastError := "Buffer at index " index " is null"
           fnOutputDebug(this.LastError)
           return 0
        }

        stopMethod := NumGet(NumGet(pDSBuffer + 0), 18*A_PtrSize, "Ptr")
        hr := DllCall(stopMethod, "Ptr", pDSBuffer, "Int")
        if (hr!=0)
        {
           this.LastError := "DirectSound Stop buffer at index " index " failed: HRESULT: 0x" . Format("{:X}", hr) " | " this.FilePaths[index]
           fnOutputDebug(this.LastError)
        }
        return (hr = 0) ? 1 : 0
    }
    
    ; Get status of a buffer
    GetStatusByIndex(index) {
        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return
        }

        pDSBuffer := this.pDSBuffers[index]
        if (!pDSBuffer) {
           this.LastError := "Buffer at index " index " is null"
           fnOutputDebug(this.LastError)
           return
       }
        
       status := 0
       getStatusMethod := NumGet(NumGet(pDSBuffer + 0), 9*A_PtrSize, "Ptr")
       DllCall(getStatusMethod, "Ptr", pDSBuffer, "UInt*", status, "Int")
       return status
    }
    
    ; Check if buffer is playing
    IsPlayingByIndex(index) {
        status := this.GetStatusByIndex(index)
        return (status & 0x1) ? 1 : 0
    }
    
    ; Cleanup/remove a specific buffer by index
    RemoveByIndex(index, rind, onlyNotPlaying:=0) {
        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return 0
        }

        if (onlyNotPlaying=1)
        {
           if (this.IsPlayingByIndex(index)=1)
              return 0
        }
        
        pDSBuffer := this.pDSBuffers[index]
        filePath := this.FilePaths[index]
        this.Stop(index) ; Stop if playing
        if pDSBuffer     ; Release buffer
           DllCall(NumGet(NumGet(pDSBuffer+0), 2*A_PtrSize), "Ptr", pDSBuffer)

        ; Remove from arrays
        this.FilePaths.RemoveAt(index)
        this.pDSBuffers.RemoveAt(index)
        this.DataSizes.RemoveAt(index)
        this.ByteRates.RemoveAt(index)
        this.AllowedDupes.RemoveAt(index)
        this.Count--
        return 1
    }

    UnInitialize() {
        this.DiscardAllFiles()
        Sleep, 1
        if pDS      ; Release DirectSound
           DllCall(NumGet(NumGet(pDS+0), 2*A_PtrSize), "Ptr", pDS)
        if hDsound  ; Free library
           DllCall("FreeLibrary", "Ptr", hDsound)

        this.hasInit := 0
        this.pDS := ""
        this.hDsound := ""
        return 1
    }

    ; Get buffer info
    GetInfoByIndex(index) {
        if (index < 1 || index > this.Count) {
           this.LastError := "Invalid buffer index: " index
           fnOutputDebug(this.LastError)
           return 0
        }

        info := "Index: " . index . "`n"
        info .= "File: " . this.FilePaths[index] . "`n"
        info .= "Data Size: " . this.DataSizes[index] . "`n"
        info .= "Byte Rate: " . this.ByteRates[index] . "`n"
        info .= "Duration: " . Round((this.DataSizes[index] * 1000) / this.ByteRates[index]) . " ms`n"
        info .= "Playing: " . (this.IsPlayingByIndex(index) ? "Yes" : "No")
        return info
    }

    ; Get file info
    GetFileInfo(filePath) {
        index := this.FindByPath(filePath)
        if !index
           return 0
        else
           return this.GetInfoByIndex(index)
    }

    ; Play sound by file path (it gets loaded if not already loaded)
    PlayFile(filePath, allowDupe:=0, looped:=0, vol:=0, pan:=0) {
        index := this.Create(filePath, allowDupe)
        if (index>0)
        {
           if pan
              this.SetPan(index, pan)
           if vol
              this.SetVolume(index, vol)
           return this.Play(index, looped)
        }

        return 0
    }

    StopFile(filePath) {
        index := this.FindByPath(filePath)
        if (index=0) {
            this.LastError := "No buffer index found for: " filePath
            fnOutputDebug(this.LastError)
            return 0
        }
        return this.Stop(index)
    }

    ; Stop all sounds
    StopAllFiles() {
        Loop, % this.Count
            this.Stop(A_Index)
    }

    ; Cleanup/remove buffer by file path
    DiscardFile(filePath) {
        index := this.FindByPath(filePath)
        if (index=0) {
            this.LastError := "No buffer index found for: " filePath
            fnOutputDebug(this.LastError)
            return 0
        }
        return this.RemoveByIndex(index)
    }

    ; Cleanup all buffers
    DiscardAllFiles(onlyNotPlaying:=0) {
        p := this.Count
        x := 0
        Loop, % this.Count
            x += this.RemoveByIndex(1, A_Index, onlyNotPlaying)
            ; Always remove index 1 since array shrinks
        
        fnOutputDebug(x " / " p " buffer[s] discarded.")
        return 1
    }

    DiscardFirstBuffers(n, onlyNotPlaying:=0) {
        p := this.Count
        Loop, % n
            this.RemoveByIndex(1, A_Index, onlyNotPlaying)
        ; fnOutputDebug(p " buffer[s]. Oldest discarded.")
        return 1
    }

    ; Get count of loaded sounds
    FilesLoaded() {
        return this.Count
    }
    
    ; List all loaded sounds
    ListAllFiles() {
        list := ""
        Loop, % this.Count
        {
            list .= A_Index . ": " . this.FilePaths[A_Index]
            if (this.IsPlayingByIndex(A_Index))
                list .= " [PLAYING]"
            list .= "`n"
        }
        return list
    }
}
