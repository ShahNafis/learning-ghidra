# First Tutorial: Introduction to Ghidra

Ghidra Version: 9.04

Youtube tutorial can be found [here](https://www.youtube.com/watch?v=fTGTnrgjuGA)

The test code we use for this tutorial is found [here](https://crackmes.one/crackme/5b8a37a433c5d45fc286ad83), the password is `crackmes.one`

## What I did

Now before doing anything with the file in Ghidra,lets try and run it. Im using virtual box with ubuntu 19.04.

```bash
$ ./rev50_linux64-bit
> USAGE: ./rev50_linux64-bit <password>
> try again!
```

Now we know what our objective is, **Find the password**.

1. After creating a project, non-shared, and extracting the crackme file, I dragged the drag the file over into Ghidra.
2. This is what my import screen looked like, I didnt change any of the import settings as they where all detected correctly.
3. You can read the summary report if you want, none of it matters for this crackme.
4. Then drag the file to the funny little green dragon in the top left and experience that very pixelated transition.
5. Ghidra will ask if you want to analyze the file, say yes and it will bring up a list of options which you can leave as is **but** add `Decompiler parameter ID` which we want as according to the description it `Creates parameter and local variables for a Function using Decompiler.` which sounds very helpful.
6. Let Ghidra do its thing, it wont take too long.
