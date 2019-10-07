# First Tutorial: Introduction to Ghidra

[import_settings]: ./import_settings.png "Logo Title Text 2"

## Info

- Ghidra Version: 9.04

- Youtube tutorial can be found
  [here](https://www.youtube.com/watch?v=fTGTnrgjuGA)

- The test code we use for this tutorial is found
  [here](https://crackmes.one/crackme/5b8a37a433c5d45fc286ad83), the password is
  `crackmes.one`

## Key information

- Make sure Ghidra detects the format and other information correctly.
- Try and help the decompiler by fixing method signatures and variable
  names/types. Always fix the main method with `int main (int argc, char**
  argv)`

## What I did

Now before doing anything with the file in Ghidra,lets try and run it. I have
Ubuntu 19.04 as dual boot.

First I have to make it so I can run it

```bash
sudo chmod a+x rev50_linux64-bit
```

Then running the binary

```bash
$ ./rev50_linux64-bit
> USAGE: ./rev50_linux64-bit <password>
> try again!
```

Now we know what our objective is, **Find the password**.

1. After creating a project, non-shared, and extracting the crackme file, I
   dragged the drag the file over into Ghidra.
2. This is what my import screen looked like, I didnt change any of the import
   settings as they where all detected correctly. ![Import
   Settings][import_settings]
3. You can read the summary report if you want, none of it matters for this
   crackme.
4. Then drag the file to the funny little green dragon in the top left and
   experience that very pixelated transition.
5. Ghidra will ask if you want to analyze the file, say yes and it will bring up
   a list of options which you can leave as is **but** add `Decompiler parameter
   ID` which we want as according to the description it `Creates parameter and
   local variables for a Function using Decompiler.` which sounds very helpful.
6. Let Ghidra do its thing, it wont take too long.
7. Here is a screenshot of the menu. Theres only 2 sections that I think are
   important because the rest dont make sense to me. The **symbol tree** on the
   left middle side,and the **decompiler menu** on the right. The symbol tree is
   used to search for the main function,since every executable C/C++ program
   needs a main() function. The decompiler menu is important because is **shows
   the code** which is much better then looking at assembly code.

So we have to find the password right? Well since we know that every executable
C/C++ program needs a main() function, why dont we search for that?

1. In the symbol tree menu,search for `main`. Under the `functions` folder you
   will see main
2. Double click on that and on the right the decompiler menu will show the code.
3. But the main() function looks weird, it shows as

```c
undefined8 main(int param_1,undefined8 *param_2)
```

but should be something like

```c
int main(int argc, char *argv[])
```

4. I guess that means we have to replace it. Right click and select `Edit
   Function Signature`. Now replace the signature with `int main (int argc, char** argv)`
5. Now if you noticed I had `char** argv` instead of `char* argv[]`. The reason
   for this is that Ghidra thinks that `argv[]` is the name of the parameter, as
   in it doesnt see the `[]` as array data type. So adding that extra `*` tells
   Ghidra that `argv` is a pointer to a pointer type data which results in
   `argv` being treated as an array.
6. So this seems pretty readable now, theres some missiong data types like
   `size_t` should probably be a int since all it is doing is saving the length
   of the string in `argv[1]`. So right click on the variable and select `Rename
   variable` option and give it a name you want.
7. We can also fix the type of that variable with `Retype variable` and put
   `int`

The code should look like this now

```c
int main(int argc,char **argv)
{
  int string_length;
  
  if (argc == 2) {
    _string_length = strlen(argv[1]);
    if (_string_length == 10) {
      if (argv[1][4] == '@') {
        puts("Nice Job!!");
        printf("flag{%s}\n",argv[1]);
      }
      else {
        usage(*argv);
      }
    }
    else {
      usage(*argv);
    }
  }
  else {
    usage(*argv);
  }
  return 0;
}
```

So looking at lines 9 and 10 we see that the password has to be length 10,and
the 5th charater has to be an '@' symbol. So lets try `1234@67890` as the
password
