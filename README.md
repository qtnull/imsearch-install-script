# Quick installation script for [lolishinshi/imsearch](https://github.com/lolishinshi/imsearch) for WSL Ubuntu 20.04
This is a quick installation script of lolishinshi/imsearch (a image similarity search system based on FAISS, ORB_SLAM3 and OpenCV).

This script will attempt to install all the required dependencies via APT to compile imsearch.

## Prerequisite
- OS: **Ubuntu (Preferably WSL) 20.04**
- WSL Host OS: Windows 10 or Windows 11
- Sudo privileges, obviously

Warning: this script **WILL NOT** work on other Debian derivatives such as Kali linux (WSL) or Debian (WSL), trust me, I've tested them. Debian (and its other derivatives) will fail to run custom build.rs (some bizarre compiling and linking error of ORB_SLAM3 or FAISS binding), OpenCV or opencv-binding-generator will fail to link OpenCV. And some other batshit insane errors when running `cargo install`. I suspect the problem is in the different compiler, linker and dependency version.

OpenCV and FAISS are notoriously difficult to link and compile, I've even tried out compiling these two dependencies myself on other systems, and sadly compiling failed (FAISS OK, OpenCV failed). On top of that, imsearch's custom build.rs will also fail with some strange linking errors.

This is just a compiling hell for me, either I'm stupid, or the compiler and linker (and rust) god hates me.

## Procedure
1. Download this repository via git or anything you want
 
    ```shell
    $ git clone https://github.com/qtnull/imsearch-install-script.git
    ```

2. Change into the imsearch-install-script directory
    
    ```shell
    $ cd imsearch-install-script
    ```

3. Run `p1.bash` using bash (don't put sudo, it's already in the script)

    ```shell
    $ bash p1.bash
    ```

4. After the script completes, **RESTART your terminal**

5. After restarting, you should see your usual prompt with conda's `base` environment. Run p2.bash
   
   ```shell
   $ bash p2.bash
   ```

6. `imsearch` and enjoy

## What's up with compiling imsearch?
To compile imsearch, there are two main dependencies that we need to sort out: OpenCV and FAISS (and your incredible amount of patience).

First of all, OpenCV is on APT, you could've just grabbed that from the APT, but that has some problems, we'll see why later, I just compile OpenCV myself. FAISS is NOT on APT, so we must compile and install it ourselves.

Compiling FAISS and OpenCV requires other dependencies. FAISS requires only `python3-dev python3-numpy swig` from APT, you'll also need Intel's OneAPI MKL; and OpenCV... HOLY MOLY, what the FUCK is up with those required dependencies, no seriously, [take a look for yourself](https://gist.github.com/raulqf/f42c718a658cddc16f9df07ecc627be7), things get even more complicated when you thrown in GPU support (which I did, I know imsearch won't use GPU, but I compiled all dependencies with GPU support anyway).

The funny thing is, even with just these two dependencies, it's already causing a lot of headache for me. FAISS is quite relatively simple to compile, but OpenCV will refuse to build with other OS that isn't Ubuntu in my experiments. Some strange compiler errors stating that there were errors in the OpenCV's codebase that I wasn't able to fix, good luck fixing errors on a large codebase with no prior knowledge of C++. lol.

After the trouble of building these two dependencies, we have finally reached the stage of compiling imseach with `cargo install --path .` or just `cargo build --release`. A few other problems arise, first of all, imsearch actually requires the nightly build of rust toolchain, otherwise it refuses to compile stating that there were errors in the code. Now, if you've installed OpenCV via Ubuntu's apt repository, you might need to patch the `src/config.rs` at line 161 slightly:

Change
```rust
flann::SearchParams::new_1(32, 0.0, true).expect("failed to build SearchParams"),
```
To
```rust
flann::SearchParams::new(32, 0.0, true).expect("failed to build SearchParams"),
```

This patch isn't required if you compiled OpenCV from source. This is just confusing for me.

`cargo` might throw some errors because it couldn't find `clang`, so make sure you install them as well (`clang libclang-dev`), also, be prepared with any error that you might find, imsearch is notoriously difficult to compile for me (along with OpenCV).

## What's happening in the script?
We don't need to compile all dependencies ourselves, FAISS is already compiled in conda's pytorch channel, OpenCV is available on Ubuntu's APT repository, so we could've just used those.

This script installs just the necessary amount of dependencies to compile imsearch, it also installs miniconda (to fetch the compiled FAISS) and rustup (rust toolchain manager to compile imsearch).

The script installs the required dependencies via APT (OpenCV, compiler tools, clang and some BLAS libraries), and installs miniconda, using miniconda's virtual environment, we install FAISS via conda.

After that, we clone imsearch's source code and then make two patches to our code, one is the APT's OpenCV code patch mentioned before, and the other is in build.rs, where we tell rust's compiler to include the FAISS' include directory, `ld` linker won't find FAISS anywhere installed in the system, so we must tell the compiler the FAISS' include path ourselves.

```rust
        .file("src/faiss/IndexBinaryIVF_c.cpp")
        // .include("/home/yhb/.miniconda3/include")
        .flag("-Wno-strict-aliasing")
```

```rust
        .file("src/faiss/IndexBinaryIVF_c.cpp")
        .include("/home/user/miniconda3/envs/imsearch/include")
        .flag("-Wno-strict-aliasing")
```

Some environment variables also needs to be set, when compiling, the "LIBRARY_PATH" must include miniconda's environment's `lib` folder (e.g. `/home/user/miniconda3/envs/imsearch/lib`), otherwise linking will fail. But you must NOT set "LD_LIBRARY_PATH", because if you set that one, linking will also fail (I think Conda's `ncurse` is conflicting with system's native `ncurse`).

After that, the compiling should succeed, unless you're on other OS other than Ubuntu, at that point you might face some even more crazy batshit errors that the rust's compiler throw at you.

When running imsearch, you must set "LD_LIBRARY_PATH" to miniconda's environment's `lib` path, otherwise you will find `faiss_avx2.so not found` and the program won't run. But the problem with this environment variable is, once you set it, other programs won't function properly, like `nano`, there will be some errors when you exit `nano`

To solve the LD_LIBRARY_PATH issue, I just move the `imsearch` binary to `/bin` and its required shared objects to `/usr/lib/x86_64-linux-gnu`.

Now imsearch should run flawlessly. This scipt will move imsearch's binary and its required objects to system's directory and removes miniconda and rust toolchains. You could optionally skip removing miniconda and rust by commenting out the respective code in `part2.bash`.

If you with to install faiss-gpu instead of faiss-cpu that the script installs, just change it in `part2.bash`