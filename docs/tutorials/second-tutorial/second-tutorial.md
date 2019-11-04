# First Tutorial: Breaking an embedded firmware encryption scheme

[entropyv2]: ./entropy_v2.2.png "entropy" 
[entropyv1]: ./entropy_v1.11.png "entropy" 
[settings]: ./import_settings.png "settings"

[aes]: ./aes.png "AES functions"

[call_graph]: ./call_graph.png "Call Graph"

## Info

- Ghidra Version: 9.1

- Youtube tutorial can be found
  [here](https://www.youtube.com/watch?v=4urMITJKQQs)

- Firmware code website is
  [here](https://www.moxa.com/en/products/industrial-edge-connectivity/serial-device-servers/wireless-device-servers/nport-w2150a-w2250a-series)
- We will download the v2.2 version found
  [here](https://www.moxa.com/Moxa/media/PDIM/S100000210/moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom)
- Also we need the v1.11 version found
  [here](https://www.moxa.com/Moxa/media/PDIM/S100000210/moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom)

- Have the `binwalk` command installed with `sudo apt install binwalk` to view
  entropy of a file.

  ## Key information

- commands like

```bash
hexdump -C moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom  | head -n 15
```

and

```bash
binwalk moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom
```

can help discover the file structure of signatures of compression methods or
other information about the file.

## What I did

### Viewing Entropy

After downloading the v2.2 file from the links above if you run,  

```bash
binwalk -E moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom
```

 you will see the following

![Entropy of file][entropyv2]

What this will tell us is if the file is encrypted. If you look at the graph we
se that the yellow line is mostly at 1.0, which means the entropy is high, which
means the randomness of the file is high which then suggests that the file is
encrypted.

Lets do the same for the v1.11 by running

```bash
binwalk -E moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom
```

which results

![Entropy of file][entropyv1]

As we see with the graph, there is much more fluctuation in the randomness of
the file which suggests that theres no encryption

### Opening v1.11 file

If we run this

```bash
binwalk moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom
```

we see that its able to indentify several file formats. We can have binwalk
extract all those files with.

```bash
binwalk -e moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom
```

There will be a new foldered called
`moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom.extracted` which will
contain 2 folders with the names `squashfs-root` and `squashfs-root-0`.
**Note:** I had to run `chmod -R +x squashfs-root*` to edit the file permissions
so I could open in terminal.

After managing to open those two folders, if we say open `squashfs-root-0` we
can see a similar file structure to Ubuntu with sutff like a `bin` folder,
`home`, `lib` and so on.

If you go to `squashfs-root-0/lib` you will see a very interestingly named file
called `libupgradeFirmware.so`, now we have a file we can open with Ghidra

### Using Ghidra

Opening the file in Ghidra, this is the detected settings

![Detected import settings][settings]

Make sure you enable the decompiler parameter ID, just like in the last
tutorial.

So lets look at the functions by clicking the `Windows` tab at the top and
selecting `functions`. After looking around and sorting by name there should be
these 4 functions

![AES functions][aes]

Very cool, later down theres a function called `fw_decrpyt` which has lots of
line of code unlike the previous 4 which strangley has 1-2 lines of code.

So lets start digging inot `fw_decrpyt`. First lets find out what calls this
function. We can do so by going to `Windows` at the top and selecting `Function
call graph` which gives us a nice picture like so

![Call graph][call_graph]

What these means is, there 3 nodes we see (`cal_crc32`, `memcpy` and
`ecb128Decrpyt`) are the 3 functions that `fw_decrpyt` call. The last one seems
very interesting. If you click on that node it expans out and shows 4 more
nodes, of which 2 of them are the AES functions we saw earlier.

### Editing ecb128Decrpyt

So heres the code for the `ecb128Decrpyt`

```c

void ecb128Decrypt(void *param_1,void *param_2,int param_3,char *param_4)
{
  int iVar1;
  uchar *out;
  uchar *in;
  AES_KEY AStack292;
  uchar auStack48 [20];
  
  strncpy((char *)auStack48,param_4,0x10);
  AES_set_decrypt_key(auStack48,0x80,&AStack292);
  in = (uchar *)((int)param_1 + 0x28);
  out = (uchar *)((int)param_2 + 0x28);
  iVar1 = 0;
  while (iVar1 < param_3 + -0x28) {
    AES_ecb_encrypt(in,out,&AStack292,0);
    iVar1 = iVar1 + 0x10;
    in = in + 0x10;
    out = out + 0x10;
  }
  memcpy(param_2,param_1,0x28);
  *(undefined *)((int)param_2 + 0xe) = 0;
  return;
}

```

If you hover over `AES_set_decrypt_key` at line 12 you will see that Ghidra has
the method signature, so lets start renaming the variables to make sense

- `auStack48` to `userKey`
- Double clicking on `0x80` and gong to the `Listing` view, if we right clickand
  select convery we can have it show the hex digits as decimal, which we see
  becomes 128.
- Finaly `auStack48` to `aes_key`
- If we look at line 10, we see that `param_4` is 16 bits and is copied into
  `userKey`, so that must be the decrpyt key, lets rename it to `decrypt_key`
- Now lets look at lines 13,14,17. We see two variables `in` and `out`, and the
  function on line 17 says that their types are `uchar`. So we can edit the
  method params from `void` to `uchar`
The method signature shoudl look like this   
`void ecb128Decrypt(uchar *param_1,uchar *param_2,int param_3,char *decrypt_key)`
- Lets call `param_1` as `decrpyt_in` and `param_2` as `decrpy_out`
- Lets go ahead and call `iVar1` `loop_counter`
- Lets call `param_3` the `decrypt_size`

At the end we get this

```c
void ecb128Decrypt(uchar *decrpy_in,uchar *decrypt_out,int decrypt_size,char *decrypt_key)
{
  int loop_counter;
  uchar *out;
  uchar *in;
  AES_KEY aes_key;
  uchar userKey [20];
  
  strncpy((char *)userKey,decrypt_key,0x10);
  AES_set_decrypt_key(userKey,128,&aes_key);
  in = decrpy_in + 0x28;
  out = decrypt_out + 0x28;
  loop_counter = 0;
  while (loop_counter < decrypt_size + -0x28) {
    AES_ecb_encrypt(in,out,&aes_key,0);
    loop_counter = loop_counter + 0x10;
    in = in + 0x10;
    out = out + 0x10;
  }
  memcpy(decrypt_out,decrpy_in,0x28);
  decrypt_out[0xe] = '\0';
  return;
}
```

We have a function that given the area to decrpy, and the output size and key will decrypt that area.

Now lets go back to `fw_decrypt`

### Back to fw_decrypt

Starting at line 36 we see where `ecb128Decrypt` is called

lets retype the `param_1` back to `uchar *` first. We notice that the first two
parameters are the same, so that means that the firmware is decrypted in place,
so it decrypts it self.

- Lets rename `param_1` to `fw_buff`
- Lets change `param_2` to `fw_buff_size`

On line 15 we see a if statment where there is this variable called `uVar2`,
which if we look around is the return value. Let change the `uint` on line 6 to
`int` we see decimal values. Lets rename `local_r0_24` to `return_value`