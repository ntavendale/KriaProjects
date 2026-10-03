// Copyright 2026 Nigel Tavendale
// Permission is hereby granted, free of charge, to any person obtaining a copy of this code
// associated documentation files (the "Code"), to deal in the Code without restriction, including
// without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Code, and to permit persons to whom the Code is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Code.
//
// THE CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
// SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE CODE OR THE USE OR
// OTHER DEALINGS IN THE CODE.
{$MODE DELPHIUNICODE}
unit TxChannel;

interface 

uses
  SysUtils, Classes, Unix, BaseUnix, Linux, DmaTypes, Utilities;

const 
  TX_CHANNEL_COUNT = 1;  
  TxChannelNames: array [0..(TX_CHANNEL_COUNT -1)] of String = ('dma_proxy_tx'); //add unique channel names here 

type 
  PTxChannelBuffers = ^TTxChannelBuffers;
  TTxChannelBuffers = array[0..(TX_BUFFER_COUNT - 1)] of TChannelBuffer;

  PTxChannel = ^TTxChannel;
  TTxChannel = record
    ChannelBuffers: PTxChannelBuffers;
    FileDescriptor: Integer;
	  ThreadId: Uint64;
  end;

var
  TxChannels: array[0 .. (TX_CHANNEL_COUNT -1)] of TTxChannel;

function SendData(AData: Cardinal): Boolean;

implementation

function SendData(AData: Cardinal): Boolean;
var 
  ioctl_result, buffer_id: Integer;
  channel_name: String;
begin
  channel_name := '/dev/' + TxChannelNames[0];
  buffer_id := 0;
  // Open file descriptor for character device (/dev/dma_proxy_tx)
  // that was created when kernel module was loaded
  TxChannels[buffer_id].FileDescriptor := fpOpen(channel_name, O_RDWR);

  if TxChannels[buffer_id].FileDescriptor < 1 then
  begin
    WriteLn(Format('Unable to open DMA proxy device file: %s', [channel_name]));
    Result := FALSE;
    Exit;
  end;

  try
    // Can't use virtual memory for dma since the firmware DMA controller is seen by kernel as part of the hardware.
    // We need to use physical memory. Physical memory isn't allocated/deallocated by the OS using GetMem (or malloc)
    // since it always exists independent of our application running.
    // Instead we need to MAP a PHYSICAL address in the memory reserved for the DMA proxy to our Channel Buffers pointer
    TxChannels[buffer_id].ChannelBuffers := PTxChannelBuffers(fpMmap(nil, SizeOf(TTxChannelBuffers), PROT_READ or PROT_WRITE, MAP_SHARED, TxChannels[buffer_id].FileDescriptor, 0));
    if (TxChannels[buffer_id].ChannelBuffers = MAP_FAILED) then 
    begin
      WriteLn('Failed to mmap tx channel');
      Result := FALSE;
      Exit;
    end;

    // Now we put data in our ChannelBuffers array which will write it to the physical memory
    TxChannels[buffer_id].ChannelBuffers^[0].Length := 4; // 4 bytes only
    TxChannels[buffer_id].ChannelBuffers^[0].Buffer[0] := AData;

    // Start the DMA transfer and this call is non-blocking
    // Use ioctl to send file descriptor to the dma proxy kernel module for our character device.
    ioctl_result := fpIoctl(TxChannels[buffer_id].FileDescriptor, START_XFER, @buffer_id);
    if 0 <> ioctl_result then
      WriteLn(Format('fpIoctl returned: %d', [ioctl_result]));

    // finish up the write
    fpIoctl(TxChannels[buffer_id].FileDescriptor, FINISH_XFER, @buffer_id);  

    // Check status
    if (TxChannels[buffer_id].ChannelBuffers^[0].Status <> psNoError) then
      WriteLn(Format('Proxy tx transfer error %s', [ProxyStatusToString(TxChannels[buffer_id].ChannelBuffers^[0].Status)]));

    fpMunmap(TxChannels[buffer_id].ChannelBuffers, SizeOf(TTxChannelBuffers));
  finally
    fpClose(TxChannels[0].FileDescriptor);
  end;
  Result := TRUE;
end;

end.