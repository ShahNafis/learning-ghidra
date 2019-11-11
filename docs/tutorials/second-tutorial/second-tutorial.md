# Second Tutorial: Breaking an embedded firmware encryption scheme

[entropyv2]: ./entropy_v2.2.png "entropy" 
[entropyv1]: ./entropy_v1.11.png "entropy" 
[settings]: ./import_settings.png "settings"

[aes]: ./aes.png "AES functions"

[call_graph]: ./call_graph.png "Call Graph"

[de_entropy]: ./de_entropy.png "Decrpyted entropy"

## Information

!!! info "Files and links"
    - Ghidra Version: 9.1

    - Youtube tutorial can be found
      [here](https://www.youtube.com/watch?v=4urMITJKQQs)

    -  [this](https://www.moxa.com/en/products/industrial-edge-connectivity/serial-device-servers/wireless-device-servers/nport-w2150a-w2250a-series) is the website where we will download two different versions of a firmware for a device.
    - The v2.2 version can be found
      [here](https://www.moxa.com/Moxa/media/PDIM/S100000210/moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom)
    - The v1.11 version can be found
      [here](https://www.moxa.com/Moxa/media/PDIM/S100000210/moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom)

    - Have the `binwalk` command installed with `sudo apt install binwalk` to view
      entropy of a file.

!!! note
    - `binwalk -E <file_name>` can be used to view the entropy of a file.
    Entropy is the measure of randomness for a file. The more entropy the more
    random which suggests that a file is encrypted. 
    - Ghidra has a function
    table that you can view by going to `windows/functions` at the top. - Along
    with that function table, Ghidra has a function call graph that can show you
    what functions are called by a specific function. You can view an example [here](#function-call-graph)

## The Objective

The objective is to be able to decrypt the v2.2 file.

### Viewing Entropy

Lets first check teh v2.2 file downloaded from above. As mentioned before
entropy can suggest if a file is encrpyted or not. So running the below command.

```shell
binwalk -E moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom
```

 you will see the following window open up.

#### Entropy of v2.2 file

![Entropy of file][entropyv2]

If you look at the 2nd window on right we see that the yellow line solid and
mostly at 1.0 for the Y axis. What this means is that the entropy of the file is
high which means that hte randomness of the file is high. This suggests that the file is encrypted.

Lets do the same for the v1.11 by running

```bash
binwalk -E moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom
```

which results

#### Entropy of v1.11 file

![Entropy of file][entropyv1]

As we see with the graph, there is much more fluctuation in the randomness of
the file which suggests that theres no encryption. The times we see the file at
high entropy is most likely due to compression.

### Opening v1.11 file

So since we can assume that the v1.11 file in not encrypted, we can try to open
it. If we run

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

!!! warning
    I had to run `chmod -R +x squashfs-root*` to edit the file permissions
    so I could open in terminal.

After managing to open those two folders, if we say open `squashfs-root-0` we
can see a similar file structure to Ubuntu with sutff like a `/bin` folder,
`/home`, `/lib` and so on. Thats pretty cool to see embedded systems use linux
type OS.

If you go to `squashfs-root-0/lib` you will see a very interestingly named file
called `libupgradeFirmware.so`. Now I personally have no idea what a `.so` file
type is, but Im sure Ghidra can

### Opening Ghidra

Opening `libupgradeFirmware.so` in Ghidra, this is the detected settings

#### Import settings

![Detected import settings][settings]

Make sure you enable the decompiler parameter ID, just like in the last
tutorial.

So lets look at the functions by clicking the `Windows` tab at the top and
selecting `functions`. After looking around and sorting by name there should be
these 4 functions

#### AES functions in function table

![AES functions][aes]

Very cool, later down theres a function called `fw_decrpyt`.

So lets start digging in to `fw_decrpyt`. First lets find out what calls this
function. We can do so by going to `Windows` at the top and selecting `Function
call graph` which gives us a nice picture like so

#### Function call graph

![Call graph][call_graph]

The 3 nodes we see (`cal_crc32`, `memcpy` and
`ecb128Decrpyt`) are the 3 functions that `fw_decrpyt` call. The last one seems
very interesting. If you click on that node it expans out and shows 4 more
nodes, of which 2 of them are the AES functions we saw earlier.

### Editing ecb128Decrpyt

So heres the code for the `ecb128Decrpyt`

```c hl_lines="10"

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

If you hover over `AES_set_decrypt_key` at line 10 you will see that Ghidra has
the method signature, so lets start renaming the variables to make sense

- `auStack48` to `userKey` since in `AES_set_decrypt_key` thats what the first
  parameter is called
- Double clicking on `0x80` on line 10 and gong to the `Listing` view, if we right click and
  select convert we can have it show the hex digits as decimal, which we see
  becomes 128. I guess they are using AES 128
- Finaly `&AStack292` to `aes_key`
- If we look at line 9, we see that `param_4` is 16 bits and is copied into
  `userKey`, so that must be the decrpyt key, lets rename it to `decrypt_key`
- Time to fix the method signature. Looking at lines 11,12 we see two variables
  `in` and `out` being type cast to `uchar`. So we can edit the method params
  from `void` to `uchar`
The method signature should look like this  
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

So we see that `ecb128Decrypt` is a function that if given the memory area to
decrpy, the output size and decrypt key, will just decrypt that area in place.

Now lets go back to `fw_decrypt`

### Getting the key

Here is the `fw_decrpyt` function

```c hl_lines="25 35"
int fw_decrypt(uchar *fw_buff,uint *fw_buff_size,undefined4 param_3)

{
  byte bVar1;
  byte bVar2;
  int return_value;
  uint *puVar3;
  byte *password;
  uint decrypt_size;
  uint uVar4;
  uint *local_24;
  undefined4 uStack32;
  
  decrypt_size = *fw_buff_size;
  if (fw_buff == (uchar *)0x0) {
    return_value = -1;
  }
  else {
    if (fw_buff[0xe] == '\x01') {
      if ((((decrypt_size < 0x29) || (decrypt_size < ((uint)fw_buff[0xd] + 10) * 4)) ||
          (decrypt_size < *(uint *)(fw_buff + 8))) || ((decrypt_size - 0x28 & 0xf) != 0)) {
        return_value = -2;
      }
      else {
        password = &passwd.3309;
        while (password + 4 != ubuf) {
          *password = *password ^ 0xa7;
          password[1] = password[1] ^ 0x8b;
          password[2] = password[2] ^ 0x2d;
          password[3] = password[3] ^ 5;
          password = password + 4;
        }
        local_24 = fw_buff_size;
        uStack32 = param_3;
        ecb128Decrypt(fw_buff,fw_buff,decrypt_size,&passwd.3309);
        uVar4 = *(uint *)(fw_buff + 8);
        if (((0x28 < uVar4) && (bVar1 = fw_buff[0xd], ((uint)bVar1 + 10) * 4 < uVar4)) &&
           (bVar2 = fw_buff[0xe], bVar2 == 0)) {
          memcpy(&local_24,fw_buff + (uint)bVar1 * 4 + 0x24,4);
          puVar3 = (uint *)cal_crc32((int)(fw_buff + (uint)bVar1 * 4 + 0x24 + 4),
                                     uVar4 + ((uint)fw_buff[0xd] + 10) * -4,(uint)bVar2);
          if (puVar3 == local_24) {
            if ((int)uVar4 <= (int)decrypt_size) {
              *fw_buff_size = uVar4;
              return (uint)bVar2;
            }
            return -5;
          }
        }
        return_value = -4;
      }
    }
    else {
      return_value = 0;
    }
  }
  return return_value;
}
```

Starting at line 35 we see where `ecb128Decrypt` is called

lets retype the `param_1` back to `uchar *` first. We notice that the first two
parameters are the same, so that means that the firmware is decrypted in place,
so it decrypts it self.

- Lets rename `param_1` to `fw_buff`
- Lets change `param_2` to `fw_buff_size`

On line 15 we see a if statment where there is this variable called `uVar2`,
which if we look around is the return value. Let change the `uint` on line 6 to
`int` we see decimal values. Lets rename `local_r0_24` to `return_value`

- Lets edit the method return type to `int`

On line 25 we see something that looks alot like the password, so lets call it `password`

We see that theres some XOR going on.

This next part is rather difficult to explain without a video, just know we are
trying to reimpliment this in python, and we need to copy the byte code of the
password. If you want to follow the video for this part, click
[here](https://youtu.be/4urMITJKQQs?t=590) for the timestamp.

Here is the python code that we have

```python
# This is the hard part,getting the byte code of the password
passwd=[0x95, 0xb3, 0x15, 0x32, 0xe4, 0xe4, 0x43, 0x6b, 0x90, 0xbe, 0x1b, 0x31, 0xa7, 0x8b, 0x2d, 0x05]

i =0

# Do the magic
while(i <len(passwd)):
    passwd[i] ^= 0Xa7
    passwd[i+1] ^= 0x8b
    passwd[i+2] ^= 0x2d
    passwd[i+3] ^= 5
    i += 4

# Print password
for c in passwd:
    print(chr(c),end="")
print("")

# Used to give the hex representation of the password
for c in passwd:
    print(hex(c)[2:],end="")
print("")
```

and running

```bash
python3 fw_decrypt_key.py
```

we get the output

```
2887Conn7564
```

Hey,thats the key, wowe.

The hex key is `32383837436f6e6e373536340000`

### Time to decrypt

With the hex key of `32383837436f6e6e373536340000` and the fact that Ubuntu has
openssl with the ability to decrypt aes-128-ecb, lets go ahead and try that

However, there was a offset,which was 0x28 which is 40 in decimal, that we see in `ecb128Decrypt`

So we need that offset removed, simply run

```bash
dd if=moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom of=firmware_offset.encrypted bs=1 skip=40
```

to get that offset fixed.

Now lets decrpyt that file with

```bash
openssl aes-128-ecb -d -K "32383837436f6e6e373536340000" -in firmware_offset.encrypted -out firmware.decrypted
```

ignore the warning.

Now lets run binwalk and we see that we can see the file structure

Then if we check the entropy we see that its much different from before.

![Entropy of file][de_entropy]

We now have the ability to extract the file, jus run the `binwalk` command we did back in v1.11 [here](#opening-v111-file)