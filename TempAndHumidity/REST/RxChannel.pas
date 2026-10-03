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
unit RxChannel;

interface 

uses
  SysUtils, Classes, Unix, BaseUnix, Linux, DmaTypes, Utilities;

const 
  RX_CHANNEL_COUNT = 1;
  RxChannelNames: array [0..0] of PChar = ('dma_proxy_rx'); //add unique channel names here 

type
  PRxChannelBuffers = ^TRxChannelBuffers;
  TRxChannelBuffers = array[0..(RX_BUFFER_COUNT - 1)] of TChannelBuffer;

  PRxChannel = ^TRxChannel;
  TRxChannel = record
    ChannelBuffers: PRxChannelBuffers;
    FileDescriptor: Integer;
	  ThreadId: Uint64;
  end;

var
  RxChannels: array[0 .. (RX_CHANNEL_COUNT -1)] of TRxChannel;


function ReadData: Cardinal;
// The following function is the transmit thread to allow the transmit and the receive channels to be
// operating simultaneously. Some of the ioctl calls are blocking so that multiple threads are required.
//function RxThread(AChannel: PRxChannel): Pointer;  

implementation

function ReadData: Cardinal;
var 
  ioctl_result, buffer_id: Integer;
  channel_name: String;
begin
  channel_name := '/dev/' + RxChannelNames[0];
  buffer_id := 0;
  // Open file descriptor for character device (/dev/dma_proxy_rx)
  // that was created when kernel module was loaded
  RxChannels[buffer_id].FileDescriptor := fpOpen(channel_name, O_RDWR);
  if RxChannels[buffer_id].FileDescriptor < 1 then
  begin
    WriteLn(Format('Unable to open DMA proxy device file: %s', [channel_name]));
    Result := 0;
    Exit;
  end;
  try
    // Can't use virtual memory for dma since the firmware DMA controller is seen by kernel as part of the hardware.
    // We need to use physical memory. Physical memory isn't allocated/deallocated by the OS using GetMem (or malloc)
    // since it always exists independent of our application running.
    // Instead we need to MAP a PHYSICAL address in the memory reserved for the DMA proxy to our Channel Buffers pointer
    RxChannels[buffer_id].ChannelBuffers := PRxChannelBuffers(fpMmap(nil, sizeof(TRxChannelBuffers), PROT_READ or PROT_WRITE, MAP_SHARED, RxChannels[buffer_id].FileDescriptor, 0));
    if (RxChannels[buffer_id].ChannelBuffers = MAP_FAILED) then 
    begin
      WriteLn('Failed to mmap rx channel');
      Result := 0;
      Exit;
    end;

    RxChannels[buffer_id].ChannelBuffers^[0].Length := 4; // 4 bytes only

    // Start the DMA transfer and this call is non-blocking
    // Use ioctl to send file descriptor to the dma proxy kernel module for our character device.
    ioctl_result := fpIoctl(RxChannels[buffer_id].FileDescriptor, START_XFER, @buffer_id);
    if 0 <> ioctl_result then
      WriteLn(Format('fpIoctl START_XFER returned: %d', [ioctl_result]));

    // finish up the read
    ioctl_result := fpIoctl(RxChannels[buffer_id].FileDescriptor, FINISH_XFER, @buffer_id);  
    
    if 0 <> ioctl_result then
      WriteLn(Format('fpIoctl FINISH_XFER returned: %d', [ioctl_result]));

    if (RxChannels[buffer_id].ChannelBuffers^[0].Status <> psNoError) then
      WriteLn(Format('Proxy rx transfer error %s', [ProxyStatusToString(RxChannels[buffer_id].ChannelBuffers^[0].Status)]));

    // Now we read data out of our ChannelBuffers array which will read it out of the physical memory
    Result := RxChannels[buffer_id].ChannelBuffers^[0].Buffer[0];

    fpMunmap(RxChannels[buffer_id].ChannelBuffers, SizeOf(TRxChannelBuffers));

  finally
    fpClose(RxChannels[0].FileDescriptor);
  end;
end;

end.